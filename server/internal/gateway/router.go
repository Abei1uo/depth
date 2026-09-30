package gateway

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/tss/depth/server/internal/auth"
	"github.com/tss/depth/server/internal/chat"
	"github.com/tss/depth/server/internal/media"
	"github.com/tss/depth/server/internal/user"
	"github.com/tss/depth/server/pkg/config"
	"github.com/tss/depth/server/pkg/middleware"
)

// RouterDeps 是构建 HTTP 路由所需的依赖集合。
type RouterDeps struct {
	Cfg          *config.Config
	Log          *slog.Logger
	Auth         *auth.Handler
	Users        *user.Handler
	Chats        *chat.Handler
	Media        *media.Handler
	Tokens       *auth.TokenManager
	WSServer     *WSServer
	PingInterval time.Duration
}

// NewRouter 组装 gin 引擎，挂载全部 REST 路由与 WebSocket 端点。
func NewRouter(d RouterDeps) *gin.Engine {
	if d.Cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(requestLogger(d.Log))

	// 健康检查
	r.GET("/healthz", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "online": d.WSServer.Hub().OnlineCount()})
	})

	// 公开路由：认证
	v1 := r.Group("/api/v1")
	d.Auth.RegisterRoutes(v1.Group("/auth"))

	// WebSocket 端点（自行通过 token 查询参数认证）
	r.GET(d.Cfg.WSPath, d.WSServer.HandleConn)

	// 受保护路由
	authed := v1.Group("", middleware.Auth(d.Tokens))
	d.Users.RegisterRoutes(authed)
	d.Chats.RegisterRoutes(authed)

	// 媒体：上传需登录（受保护组）；下载凭不可猜 id 公开（供 <img> 直接访问）。
	if d.Media != nil {
		d.Media.RegisterAuthed(authed)
		d.Media.RegisterPublic(v1)
	}

	return r
}

// requestLogger 返回一个记录请求摘要的 gin 中间件。
func requestLogger(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		log.Info("http",
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", c.Writer.Status(),
			"dur_ms", time.Since(start).Milliseconds(),
		)
	}
}
