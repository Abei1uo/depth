package message

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/tss/depth/server/pkg/ws"
)

// Router 抽象在线消息投递（由 ws.Hub 实现）。返回是否送达至少一个设备。
type Router interface {
	IsOnline(userID string) bool
	SendToUser(userID string, data []byte) bool
}

// MemberLister 提供会话成员查询（由 chat.Repository 实现）。
type MemberLister interface {
	Members(ctx context.Context, convID string) ([]string, error)
	Unhide(ctx context.Context, convID string, userIDs []string) error
}

// PushEnqueuer 离线推送入队（Phase 2 实现，MVP 可为空实现）。
type PushEnqueuer interface {
	Enqueue(ctx context.Context, userID string, m *Message) error
}

// Service 编排消息写入与分发。
type Service struct {
	repo   *Repository
	chat   MemberLister
	hub    Router
	push   PushEnqueuer
	rdb    *redis.Client
	encode func(*Message) ([]byte, error) // 出站编码（可替换为 Protobuf）
	log    *slog.Logger
}

// NewService 构造消息服务。encode 将消息编码为下行字节。
func NewService(repo *Repository, chat MemberLister, hub Router, push PushEnqueuer, rdb *redis.Client, encode func(*Message) ([]byte, error), log *slog.Logger) *Service {
	return &Service{repo: repo, chat: chat, hub: hub, push: push, rdb: rdb, encode: encode, log: log}
}

// NextSeq 使用 Redis INCR 原子生成会话内递增序号。
func (s *Service) NextSeq(ctx context.Context, convID string) (int64, error) {
	key := fmt.Sprintf("conv:seq:%s", convID)
	return s.rdb.Incr(ctx, key).Result()
}

// checkIdempotent 通过 Redis SETNX 对 client_msg_id 去重（5 分钟窗口）。
// 返回 true 表示首次出现（可处理），false 表示重复。
func (s *Service) checkIdempotent(ctx context.Context, convID, clientMsgID string) (bool, error) {
	if clientMsgID == "" {
		return true, nil // 客户端未提供幂等 ID，则不去重
	}
	key := fmt.Sprintf("msg:dedup:%s:%s", convID, clientMsgID)
	return s.rdb.SetNX(ctx, key, "1", 5*time.Minute).Result()
}

// Send 处理一条来自 senderID 的消息：去重 → 生成 seq → 落库 → 分发。
// 若为重复消息，返回既有处理结果（此处返回 nil ack 表示已忽略）。
func (s *Service) Send(ctx context.Context, senderID string, in SendInput) (*Message, error) {
	first, err := s.checkIdempotent(ctx, in.ConversationID, in.ClientMsgID)
	if err != nil {
		return nil, err
	}
	if !first {
		s.log.Debug("duplicate message ignored", "client_msg_id", in.ClientMsgID)
		return nil, nil
	}

	seq, err := s.NextSeq(ctx, in.ConversationID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	m := &Message{
		ID:             uuid.NewString(),
		ClientMsgID:    in.ClientMsgID,
		ConversationID: in.ConversationID,
		SenderID:       senderID,
		Seq:            seq,
		Content:        in.Content,
		CreatedAt:      now,
	}

	if err := s.repo.Insert(ctx, m); err != nil {
		return nil, err
	}

	members, err := s.chat.Members(ctx, in.ConversationID)
	if err != nil {
		return nil, err
	}
	s.Deliver(ctx, m, members, senderID)
	return m, nil
}

// Deliver 向除发送者外的成员分发：在线走 WebSocket 直推，离线走推送队列。
func (s *Service) Deliver(ctx context.Context, m *Message, receivers []string, exclude string) {
	data, err := s.encode(m)
	if err != nil {
		s.log.Error("encode message failed", "err", err.Error())
		return
	}
	for _, uid := range receivers {
		if uid == exclude {
			continue
		}
		if s.hub.IsOnline(uid) {
			s.hub.SendToUser(uid, data)
		} else if s.push != nil {
			if err := s.push.Enqueue(ctx, uid, m); err != nil {
				s.log.Warn("push enqueue failed", "user", uid, "err", err.Error())
			}
		}
	}
	// 收到他人新消息：解除接收方对该会话的「隐藏」（从列表删除后重新显示）。
	var recipients []string
	for _, uid := range receivers {
		if uid != exclude {
			recipients = append(recipients, uid)
		}
	}
	if err := s.chat.Unhide(ctx, m.ConversationID, recipients); err != nil {
		s.log.Warn("unhide on new message failed", "conv", m.ConversationID, "err", err.Error())
	}
}

// Members 返回会话成员 ID（供上行如 typing 广播使用）。
func (s *Service) Members(ctx context.Context, convID string) ([]string, error) {
	return s.chat.Members(ctx, convID)
}

// History 返回某会话的历史消息（排除 viewer 本地删除的）。
func (s *Service) History(ctx context.Context, viewerID, convID string, beforeSeq int64, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	return s.repo.List(ctx, viewerID, convID, beforeSeq, limit)
}

// HistoryAfter 返回某会话 seq 大于 afterSeq 的消息（用于断线重连补拉）。
func (s *Service) HistoryAfter(ctx context.Context, viewerID, convID string, afterSeq int64, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	return s.repo.ListAfter(ctx, viewerID, convID, afterSeq, limit)
}

// HideForMe 为 viewer 本地删除一条消息（仅影响其自身历史视图）。
func (s *Service) HideForMe(ctx context.Context, viewerID, msgID string) error {
	m, err := s.repo.GetByID(ctx, msgID)
	if err != nil {
		return err
	}
	return s.repo.Hide(ctx, m.ConversationID, viewerID, msgID)
}

// Search 在某会话内按文本关键字检索消息。
func (s *Service) Search(ctx context.Context, convID, q string, limit int) ([]*Message, error) {
	if strings.TrimSpace(q) == "" {
		return []*Message{}, nil
	}
	return s.repo.Search(ctx, convID, strings.TrimSpace(q), limit)
}

// 撤回 / 编辑的时间窗口与校验错误。
const (
	actionWindow = 2 * time.Minute
)

var (
	ErrNotSender    = errors.New("只能操作自己发送的消息")
	ErrWindowPassed = errors.New("已超过可操作时间")
	ErrNotEditable  = errors.New("该消息不可编辑")
	ErrEmptyText    = errors.New("内容不能为空")
)

// Recall 撤回一条自己发送且在窗口内的消息：清空正文并广播更新。
func (s *Service) Recall(ctx context.Context, userID, msgID string) (*Message, error) {
	m, err := s.repo.GetByID(ctx, msgID)
	if err != nil {
		return nil, err
	}
	if m.SenderID != userID {
		return nil, ErrNotSender
	}
	if m.Recalled {
		return m, nil // 幂等
	}
	if time.Since(m.CreatedAt) > actionWindow {
		return nil, ErrWindowPassed
	}
	if err := s.repo.Recall(ctx, msgID); err != nil {
		return nil, err
	}
	m.Recalled = true
	m.Content.Text = ""
	m.Content.MediaURL = ""
	s.broadcastUpdate(ctx, m)
	return m, nil
}

// Edit 编辑一条自己发送、文本类型且在窗口内的消息。
func (s *Service) Edit(ctx context.Context, userID, msgID, text string) (*Message, error) {
	text = strings.TrimSpace(text)
	if text == "" {
		return nil, ErrEmptyText
	}
	m, err := s.repo.GetByID(ctx, msgID)
	if err != nil {
		return nil, err
	}
	if m.SenderID != userID {
		return nil, ErrNotSender
	}
	if m.Recalled || m.Content.Type != TypeText {
		return nil, ErrNotEditable
	}
	if time.Since(m.CreatedAt) > actionWindow {
		return nil, ErrWindowPassed
	}
	if err := s.repo.UpdateText(ctx, msgID, text); err != nil {
		return nil, err
	}
	m.Content.Text = text
	s.broadcastUpdate(ctx, m)
	return m, nil
}

// broadcastUpdate 向会话全体成员（含发送者各设备）下发 message_update。
func (s *Service) broadcastUpdate(ctx context.Context, m *Message) {
	members, err := s.chat.Members(ctx, m.ConversationID)
	if err != nil {
		s.log.Warn("members for update broadcast failed", "conv", m.ConversationID, "err", err.Error())
		return
	}
	data, err := ws.Encode(ws.EventMessageUpdate, m)
	if err != nil {
		s.log.Error("encode message_update failed", "err", err.Error())
		return
	}
	for _, uid := range members {
		if s.hub.IsOnline(uid) {
			s.hub.SendToUser(uid, data)
		}
	}
}
