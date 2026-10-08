// Package gateway 组装 HTTP 路由与 WebSocket 接入层。
package gateway

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/coder/websocket"
	"github.com/gin-gonic/gin"

	"github.com/tss/depth/server/internal/auth"
	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/internal/presence"
	"github.com/tss/depth/server/pkg/ws"
)

// ReadMarker 提供已读游标写入与同会话其他成员查询（由 chat.Repository 实现）。
type ReadMarker interface {
	MarkRead(ctx context.Context, userID, convID string, maxSeq int64) error
	PeerMembers(ctx context.Context, userID string) ([]string, error)
}

// WSServer 负责升级 HTTP 连接为 WebSocket 并接入 Hub。
type WSServer struct {
	hub      *ws.Hub
	tokens   *auth.TokenManager
	presence *presence.Service
	msgSvc   *message.Service
	chatRead ReadMarker
	log      *slog.Logger
	ping     time.Duration
}

// NewWSServer 构造 WebSocket 服务端。为避免与消息服务的构造循环依赖，
// msgSvc 通过 SetMessageService 在装配阶段后置注入。
func NewWSServer(tokens *auth.TokenManager, presence *presence.Service, log *slog.Logger, ping time.Duration) *WSServer {
	s := &WSServer{tokens: tokens, presence: presence, log: log, ping: ping}
	s.hub = ws.NewHub(s.dispatch, log)
	return s
}

// SetMessageService 后置注入消息服务（打破循环依赖）。
func (s *WSServer) SetMessageService(svc *message.Service) { s.msgSvc = svc }

// SetReadMarker 后置注入已读写入依赖（由会话仓储实现）。
func (s *WSServer) SetReadMarker(r ReadMarker) { s.chatRead = r }

// Hub 暴露连接中心，供消息服务作为 Router 使用。
func (s *WSServer) Hub() *ws.Hub { return s.hub }

// HandleConn 是 gin 处理函数：校验令牌并升级连接。
// 认证令牌通过查询参数 ?token=<access_token> 传入（浏览器 WS 无法自定义请求头）。
func (s *WSServer) HandleConn(c *gin.Context) {
	tokenStr := c.Query("token")
	if tokenStr == "" {
		tokenStr = c.GetHeader("Authorization")
	}
	claims, err := s.tokens.Parse(replaceBearer(tokenStr))
	if err != nil {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "认证失败"})
		return
	}
	deviceID := c.Query("device_id")
	if deviceID == "" {
		deviceID = "default"
	}

	conn, err := websocket.Accept(c.Writer, c.Request, &websocket.AcceptOptions{
		// 开发环境放开来源校验；生产应配置 AllowedOriginPatterns。
		InsecureSkipVerify: true,
	})
	if err != nil {
		s.log.Error("ws accept failed", "err", err.Error())
		return
	}

	ctx := c.Request.Context()
	if err := s.presence.SetOnline(ctx, claims.UserID, deviceID); err != nil {
		s.log.Warn("presence set online failed", "err", err.Error())
	}
	s.broadcastPresence(ctx, claims.UserID, true)

	// ServeConn 阻塞至连接结束，随后清理在线状态。
	s.hub.ServeConn(ctx, conn, claims.UserID, deviceID, s.ping)
	s.broadcastPresence(context.Background(), claims.UserID, false)
	if err := s.presence.SetOffline(context.Background(), claims.UserID, deviceID); err != nil {
		s.log.Warn("presence set offline failed", "err", err.Error())
	}
}

// dispatch 是 Hub 的入站消息处理器，按事件类型路由到业务逻辑。
func (s *WSServer) dispatch(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	switch env.Type {
	case ws.EventSendMessage:
		if s.msgSvc == nil {
			return nil, errors.New("消息服务尚未就绪")
		}
		return s.handleSend(ctx, client, env)
	case ws.EventSync:
		if s.msgSvc == nil {
			return nil, errors.New("消息服务尚未就绪")
		}
		return s.handleSync(ctx, client, env)
	case ws.EventMarkRead:
		return s.handleMarkRead(ctx, client, env)
	case ws.EventTyping:
		return s.handleTyping(ctx, client, env)
	case ws.EventRecall:
		return s.handleRecall(ctx, client, env)
	case ws.EventEdit:
		return s.handleEdit(ctx, client, env)
	default:
		return nil, errors.New("未知事件类型: " + env.Type)
	}
}

func (s *WSServer) handleSend(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	var in message.SendInput
	if err := json.Unmarshal(env.Payload, &in); err != nil {
		return nil, errors.New("send_message 负载格式错误")
	}
	m, err := s.msgSvc.Send(ctx, client.UserID(), in)
	if err != nil {
		return nil, err
	}
	if m == nil { // 重复消息，忽略
		return nil, nil
	}
	ack := message.Ack{
		ClientMsgID: m.ClientMsgID,
		ServerMsgID: m.ID,
		Seq:         m.Seq,
		Timestamp:   m.CreatedAt.UnixMilli(),
	}
	return ws.Encode(ws.EventMsgAck, ack)
}

func (s *WSServer) handleSync(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	var req struct {
		ConversationID string `json:"conversation_id"`
		LastSeq        int64  `json:"last_seq"`
	}
	if err := json.Unmarshal(env.Payload, &req); err != nil {
		return nil, errors.New("sync 负载格式错误")
	}
	msgs, err := s.msgSvc.HistoryAfter(ctx, req.ConversationID, req.LastSeq, 100)
	if err != nil {
		return nil, err
	}
	// 复用 new_message 事件批量下发补拉结果。
	return ws.Encode("sync_result", gin.H{"messages": msgs})
}

func (s *WSServer) handleMarkRead(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	if s.chatRead == nil {
		return nil, errors.New("已读服务尚未就绪")
	}
	var req struct {
		ConversationID string `json:"conversation_id"`
		MaxSeq         int64  `json:"max_seq"`
	}
	if err := json.Unmarshal(env.Payload, &req); err != nil {
		return nil, errors.New("mark_read 负载格式错误")
	}
	if req.ConversationID == "" {
		return nil, nil
	}
	if err := s.chatRead.MarkRead(ctx, client.UserID(), req.ConversationID, req.MaxSeq); err != nil {
		s.log.Warn("mark_read failed", "err", err.Error())
		return nil, err
	}
	// 向同会话其他成员广播已读游标，供发送方展示“已读”回执。
	if s.msgSvc != nil {
		data, err := ws.Encode(ws.EventMsgRead, gin.H{
			"conversation_id": req.ConversationID,
			"user_id":         client.UserID(),
			"max_seq":         req.MaxSeq,
		})
		if err == nil {
			if members, err := s.msgSvc.Members(ctx, req.ConversationID); err == nil {
				for _, uid := range members {
					if uid == client.UserID() {
						continue
					}
					if s.hub.IsOnline(uid) {
						s.hub.SendToUser(uid, data)
					}
				}
			}
		}
	}
	return nil, nil
}

func (s *WSServer) handleTyping(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	if s.msgSvc == nil {
		return nil, nil
	}
	var req struct {
		ConversationID string `json:"conversation_id"`
		Typing         bool   `json:"typing"`
	}
	if err := json.Unmarshal(env.Payload, &req); err != nil || req.ConversationID == "" {
		return nil, nil
	}
	members, err := s.msgSvc.Members(ctx, req.ConversationID)
	if err != nil {
		return nil, nil
	}
	data, err := ws.Encode(ws.EventTyping, gin.H{
		"conversation_id": req.ConversationID,
		"from_user_id":    client.UserID(),
		"typing":          req.Typing,
	})
	if err != nil {
		return nil, err
	}
	for _, uid := range members {
		if uid == client.UserID() {
			continue
		}
		if s.hub.IsOnline(uid) {
			s.hub.SendToUser(uid, data)
		}
	}
	return nil, nil
}

// broadcastPresence 向与 userID 共享会话的在线成员广播其上下线事件。
func (s *WSServer) broadcastPresence(ctx context.Context, userID string, online bool) {
	if s.chatRead == nil {
		return
	}
	peers, err := s.chatRead.PeerMembers(ctx, userID)
	if err != nil || len(peers) == 0 {
		return
	}
	data, err := ws.Encode(ws.EventPresence, gin.H{
		"user_id":   userID,
		"online":    online,
		"last_seen": time.Now().UnixMilli(),
	})
	if err != nil {
		return
	}
	for _, uid := range peers {
		if s.hub.IsOnline(uid) {
			s.hub.SendToUser(uid, data)
		}
	}
}

// handleRecall 处理上行 recall_message：服务端校验归属与时间窗后撤回，
// 成功时由消息服务广播 message_update，本函数无需回包。
func (s *WSServer) handleRecall(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	if s.msgSvc == nil {
		return nil, errors.New("消息服务尚未就绪")
	}
	var req struct {
		ConversationID string `json:"conversation_id"`
		ServerMsgID    string `json:"server_msg_id"`
	}
	if err := json.Unmarshal(env.Payload, &req); err != nil || req.ServerMsgID == "" {
		return nil, errors.New("recall_message 负载格式错误")
	}
	if _, err := s.msgSvc.Recall(ctx, client.UserID(), req.ServerMsgID); err != nil {
		return nil, err
	}
	return nil, nil
}

// handleEdit 处理上行 edit_message。
func (s *WSServer) handleEdit(ctx context.Context, client *ws.Client, env *ws.Envelope) ([]byte, error) {
	if s.msgSvc == nil {
		return nil, errors.New("消息服务尚未就绪")
	}
	var req struct {
		ConversationID string `json:"conversation_id"`
		ServerMsgID    string `json:"server_msg_id"`
		Text           string `json:"text"`
	}
	if err := json.Unmarshal(env.Payload, &req); err != nil || req.ServerMsgID == "" {
		return nil, errors.New("edit_message 负载格式错误")
	}
	if _, err := s.msgSvc.Edit(ctx, client.UserID(), req.ServerMsgID, req.Text); err != nil {
		return nil, err
	}
	return nil, nil
}

// EncodeMessage 是消息下行编码器，供 message.Service 分发时调用。
func EncodeMessage(m *message.Message) ([]byte, error) {
	return ws.Encode(ws.EventNewMessage, m)
}

func replaceBearer(token string) string {
	if len(token) > 7 && token[:7] == "Bearer " {
		return token[7:]
	}
	return token
}
