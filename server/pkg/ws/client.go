package ws

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/coder/websocket"
)

// sendBuffer 是每个连接的发送队列容量，防止慢客户端耗尽内存。
const sendBuffer = 256

// Client 表示单个已认证的 WebSocket 连接。
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	userID   string
	deviceID string

	send chan []byte
	once sync.Once
	done chan struct{}

	log          *slog.Logger
	pingInterval time.Duration
}

func newClient(h *Hub, conn *websocket.Conn, userID, deviceID string, log *slog.Logger, ping time.Duration) *Client {
	return &Client{
		hub:          h,
		conn:         conn,
		userID:       userID,
		deviceID:     deviceID,
		send:         make(chan []byte, sendBuffer),
		done:         make(chan struct{}),
		log:          log,
		pingInterval: ping,
	}
}

// ServeConn 接管一个已升级的连接，注册到 Hub 并阻塞式运行其读写泵。
// 通常由 gateway 在 Accept 之后以独立 goroutine 调用。
func (h *Hub) ServeConn(ctx context.Context, conn *websocket.Conn, userID, deviceID string, ping time.Duration) {
	c := newClient(h, conn, userID, deviceID, h.log, ping)
	c.Serve(ctx)
}

// UserID 返回连接归属用户。
func (c *Client) UserID() string { return c.userID }

// DeviceID 返回连接的设备标识。
func (c *Client) DeviceID() string { return c.deviceID }

// enqueue 将数据投递到发送队列；队列满则丢弃并关闭连接（背压保护）。
func (c *Client) enqueue(data []byte) {
	select {
	case c.send <- data:
	case <-c.done:
	default:
		c.log.Warn("ws send buffer full, dropping connection", "user", c.userID)
		go c.close()
	}
}

// close 幂等地关闭底层连接并通知各泵退出。
func (c *Client) close() {
	c.once.Do(func() {
		close(c.done)
		_ = c.conn.Close(websocket.StatusNormalClosure, "")
	})
}

// Serve 启动读写泵与心跳，阻塞直到连接结束。
func (c *Client) Serve(ctx context.Context) {
	c.hub.register(c)
	defer c.hub.unregister(c)

	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	go c.writePump(ctx)
	go c.pingPump(ctx)
	c.readPump(ctx)
	cancel()
}

// readPump 读取入站消息并交给 Hub 的 handler 处理。
func (c *Client) readPump(ctx context.Context) {
	// 限制单条消息大小，防御超大帧。
	c.conn.SetReadLimit(1 << 20) // 1MB
	for {
		_, data, err := c.conn.Read(ctx)
		if err != nil {
			if websocket.CloseStatus(err) != websocket.StatusNormalClosure {
				c.log.Debug("ws read closed", "user", c.userID, "err", err.Error())
			}
			return
		}
		env, err := Decode(data)
		if err != nil {
			c.sendError("invalid envelope")
			continue
		}
		if c.hub.handler == nil {
			continue
		}
		resp, err := c.hub.handler(ctx, c, env)
		if err != nil {
			c.sendError(err.Error())
			continue
		}
		if resp != nil {
			c.enqueue(resp)
		}
	}
}

// writePump 从发送队列取数据写入连接。coder/websocket 不支持并发 Write，
// 因此所有出站写入都经此单一 goroutine 串行化。
func (c *Client) writePump(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case <-c.done:
			return
		case data := <-c.send:
			wctx, cancel := context.WithTimeout(ctx, 10*time.Second)
			err := c.conn.Write(wctx, websocket.MessageText, data)
			cancel()
			if err != nil {
				c.close()
				return
			}
		}
	}
}

// pingPump 周期性发起协议层 Ping，配合读超时检测死连接。
func (c *Client) pingPump(ctx context.Context) {
	ticker := time.NewTicker(c.pingInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-c.done:
			return
		case <-ticker.C:
			pctx, cancel := context.WithTimeout(ctx, c.pingInterval)
			err := c.conn.Ping(pctx)
			cancel()
			if err != nil {
				c.log.Debug("ws ping failed, closing", "user", c.userID, "err", err.Error())
				c.close()
				return
			}
		}
	}
}

func (c *Client) sendError(msg string) {
	data, err := Encode(EventError, map[string]string{"message": msg})
	if err != nil {
		return
	}
	c.enqueue(data)
}
