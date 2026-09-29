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
}

// Message 是服务端落库后的完整消息实体。
type Message struct {
	ID             string    `json:"server_msg_id"`
	ClientMsgID    string    `json:"client_msg_id"`
	ConversationID string    `json:"conversation_id"`
	SenderID       string    `json:"sender_id"`
	Seq            int64     `json:"seq"`
	Content        Content   `json:"content"`
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
