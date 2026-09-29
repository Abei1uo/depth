package message

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// Router 抽象在线消息投递（由 ws.Hub 实现）。返回是否送达至少一个设备。
type Router interface {
	IsOnline(userID string) bool
	SendToUser(userID string, data []byte) bool
}

// MemberLister 提供会话成员查询（由 chat.Repository 实现）。
type MemberLister interface {
	Members(ctx context.Context, convID string) ([]string, error)
}

// PushEnqueuer 离线推送入队（Phase 2 实现，MVP 可为空实现）。
type PushEnqueuer interface {
	Enqueue(ctx context.Context, userID string, m *Message) error
}

// Service 编排消息写入与分发。
type Service struct {
	repo    *Repository
	chat    MemberLister
	hub     Router
	push    PushEnqueuer
	rdb     *redis.Client
	encode  func(*Message) ([]byte, error) // 出站编码（可替换为 Protobuf）
	log     *slog.Logger
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
}

// History 返回某会话的历史消息。
func (s *Service) History(ctx context.Context, convID string, beforeSeq int64, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	return s.repo.List(ctx, convID, beforeSeq, limit)
}
