// Package message 负责消息的写入、序号生成、幂等与实时路由分发。
package message

import (
	"time"
)

// 消息类型。
const (
	TypeText  int16 = 0
	TypeImage int16 = 1
	TypeFile  int16 = 2
	TypeVoice int16 = 3
	TypeSys   int16 = 4
)

// Content 是消息正文负载。
type Content struct {
	Type int16  `json:"type"`
	Text string `json:"text,omitempty"`
	// 媒体字段在 Phase 2 使用；MVP 先保留结构。
	MediaURL  string `json:"media_url,omitempty"`
	ThumbURL  string `json:"thumb_url,omitempty"`
	SizeBytes int64  `json:"size,omitempty"`
	// Duration 为语音消息时长（秒），仅 voice 类型使用。
	Duration int64 `json:"duration,omitempty"`
	// ReplyTo 非空表示本条为引用回复；随 content JSONB 存储。
	ReplyTo *ReplyInfo `json:"reply_to,omitempty"`
	// Mentions 为被 @ 的成员用户 ID 列表。
	Mentions []string `json:"mentions,omitempty"`
	// Reactions 为表情回应：emoji ->  reacted 用户 ID 列表（随 content JSONB 存储）。
	Reactions map[string][]string `json:"reactions,omitempty"`
	// Pinned 为真表示该消息被会话成员置顶（随 content JSONB 存储，无需新列）。
	Pinned bool `json:"pinned,omitempty"`
}

// ReplyInfo 是被引用消息的快照（仅用于展示摘要，不保证源消息仍存在）。
type ReplyInfo struct {
	MsgID    string `json:"msg_id"`
	SenderID string `json:"sender_id"`
	Text     string `json:"text"` // 引用正文摘要
}

// Message 是服务端落库后的完整消息实体。
type Message struct {
	ID             string    `json:"server_msg_id"`
	ClientMsgID    string    `json:"client_msg_id"`
	ConversationID string    `json:"conversation_id"`
	SenderID       string    `json:"sender_id"`
	Seq            int64     `json:"seq"`
	Content        Content   `json:"content"`
	Recalled       bool      `json:"recalled"`
	CreatedAt      time.Time `json:"timestamp"`
}

// SendInput 是客户端发送消息时的入参。
type SendInput struct {
	ClientMsgID    string  `json:"client_msg_id"`
	ConversationID string  `json:"conversation_id"`
	Content        Content `json:"content"`
}

// Ack 回执给发送方的确认信息。
type Ack struct {
	ClientMsgID string `json:"client_msg_id"`
	ServerMsgID string `json:"server_msg_id"`
	Seq         int64  `json:"seq"`
	Timestamp   int64  `json:"timestamp"`
}
