// Package ws 基于 github.com/coder/websocket 实现连接管理中心。
//
// 传输协议：MVP 阶段使用 JSON 信封（Envelope），后续可将 Envelope 的
// 编解码替换为 Protobuf 而无需改动 Hub 与业务层——只需实现 codec。
package ws

import "encoding/json"

// Envelope 是所有 WebSocket 消息的统一信封。
type Envelope struct {
	Type    string          `json:"type"`    // 事件类型，如 send_message / new_message
	Payload json.RawMessage `json:"payload"` // 具体负载，按 Type 解析
}

// 客户端 → 服务端 事件类型。
const (
	EventSendMessage = "send_message"
	EventMarkRead    = "mark_read"
	EventTyping      = "typing"
	EventSync        = "sync"           // 断线重连后按 last_seq 补拉
	EventRecall      = "recall_message" // 撤回一条自己发的消息
	EventEdit        = "edit_message"   // 编辑一条文本消息
	EventDelete      = "delete_message" // 本地删除（仅对己隐藏）
	EventReact       = "react_message"  // 表情回应（添加/取消）
)

// 服务端 → 客户端 事件类型。
const (
	EventNewMessage    = "new_message"
	EventMsgAck        = "msg_ack"
	EventMsgRead       = "msg_read"
	EventMessageUpdate = "message_update" // 撤回/编辑后的就地更新
	EventPresence      = "presence_update"
	EventError         = "error"
)

// Encode 将负载包装为信封字节流。
func Encode(eventType string, payload any) ([]byte, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	return json.Marshal(Envelope{Type: eventType, Payload: raw})
}

// Decode 解析信封外壳。
func Decode(data []byte) (*Envelope, error) {
	var env Envelope
	err := json.Unmarshal(data, &env)
	return &env, err
}
