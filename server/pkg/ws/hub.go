package ws

import (
	"context"
	"log/slog"
	"sync"
)

// Handler 处理来自某个客户端的入站消息。由 gateway 注入业务逻辑。
// 返回值 data 若非空，将直接回送给该客户端。
type Handler func(ctx context.Context, client *Client, env *Envelope) ([]byte, error)

// Hub 维护所有在线连接，支持同一用户多设备。
type Hub struct {
	mu      sync.RWMutex
	clients map[string]map[string]*Client // userID -> deviceID -> client
	handler Handler
	log     *slog.Logger
}

// NewHub 构造连接中心。
func NewHub(h Handler, log *slog.Logger) *Hub {
	return &Hub{
		clients: make(map[string]map[string]*Client),
		handler: h,
		log:     log,
	}
}

// register 将客户端纳入在线表。
func (h *Hub) register(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.clients[c.userID] == nil {
		h.clients[c.userID] = make(map[string]*Client)
	}
	// 同设备旧连接存在则先顶掉，避免僵尸连接。
	if old, ok := h.clients[c.userID][c.deviceID]; ok && old != c {
		old.close()
	}
	h.clients[c.userID][c.deviceID] = c
	h.log.Info("ws client registered", "user", c.userID, "device", c.deviceID)
}

// unregister 从在线表移除客户端。
func (h *Hub) unregister(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if devs, ok := h.clients[c.userID]; ok {
		if cur, ok := devs[c.deviceID]; ok && cur == c {
			delete(devs, c.deviceID)
		}
		if len(devs) == 0 {
			delete(h.clients, c.userID)
		}
	}
	h.log.Info("ws client unregistered", "user", c.userID, "device", c.deviceID)
}

// IsOnline 判断用户是否有任意在线设备。
func (h *Hub) IsOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients[userID]) > 0
}

// SendToUser 向某用户的所有在线设备推送已编码消息。
// 返回是否至少送达一个设备（用于决定是否需要走离线推送）。
func (h *Hub) SendToUser(userID string, data []byte) bool {
	h.mu.RLock()
	devs := h.clients[userID]
	h.mu.RUnlock()
	if len(devs) == 0 {
		return false
	}
	for _, c := range devs {
		c.enqueue(data)
	}
	return true
}

// OnlineCount 返回当前在线用户数（用于指标）。
func (h *Hub) OnlineCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// Run 驱动 Hub：处理每个连接的生命周期。此处采用每连接独立 goroutine 模型，
// Hub 仅作为连接注册表，读写泵在 Client 内部完成。
func (h *Hub) Run(ctx context.Context) {
	<-ctx.Done()
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, devs := range h.clients {
		for _, c := range devs {
			c.close()
		}
	}
}
