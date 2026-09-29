// Package push 提供离线消息推送入队能力。
// MVP 阶段为日志占位实现，Phase 2 替换为 FCM + APNs。
package push

import (
	"context"
	"log/slog"

	"github.com/tss/depth/server/internal/message"
)

// Noop 仅记录日志，用于 MVP 打通链路。
type Noop struct {
	log *slog.Logger
}

// NewNoop 构造占位推送器。
func NewNoop(log *slog.Logger) *Noop { return &Noop{log: log} }

// Enqueue 实现 message.PushEnqueuer 接口。
func (n *Noop) Enqueue(ctx context.Context, userID string, m *message.Message) error {
	n.log.Info("offline push (noop)",
		"user", userID,
		"conversation", m.ConversationID,
		"seq", m.Seq,
	)
	return nil
}
