package app

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/tss/depth/server/internal/auth"
	"github.com/tss/depth/server/internal/chat"
	"github.com/tss/depth/server/internal/gateway"
	"github.com/tss/depth/server/internal/media"
	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/internal/presence"
	"github.com/tss/depth/server/internal/push"
	"github.com/tss/depth/server/internal/user"
	"github.com/tss/depth/server/pkg/config"
)

// authWiring 聚合认证链路上的组件，供路由装配使用。
type authWiring struct {
	handler *auth.Handler
	tokens  *auth.TokenManager
}

// buildAuth 装配认证模块（令牌管理器 + 服务 + 处理器）。
func buildAuth(cfg *config.Config, userRepo *user.Repository, rdb *redis.Client) (*authWiring, error) {
	tokens, err := auth.NewTokenManager(cfg)
	if err != nil {
		return nil, err
	}
	authSvc := auth.NewService(userRepo, tokens, rdb, cfg.RefreshTokenTTL)
	return &authWiring{handler: auth.NewHandler(authSvc), tokens: tokens}, nil
}

// messagingWiring 聚合 WebSocket 与消息链路上的组件。
type messagingWiring struct {
	wsServer *gateway.WSServer
	msgSvc   *message.Service
}

// buildMessaging 装配在线状态、WebSocket 服务端与消息服务。
// 存在双向依赖：消息服务需 Hub 作 Router，建成后回注 wsServer。
func buildMessaging(
	cfg *config.Config, log *slog.Logger, tokens *auth.TokenManager,
	chatRepo *chat.Repository, msgRepo *message.Repository, rdb *redis.Client,
) *messagingWiring {
	presSvc := presence.NewService(rdb, cfg.PongTimeout*2)
	wsServer := gateway.NewWSServer(tokens, presSvc, log, cfg.PingInterval)

	pusher := push.NewNoop(log)
	msgSvc := message.NewService(
		msgRepo, chatRepo, wsServer.Hub(), pusher, rdb,
		gateway.EncodeMessage, log,
	)
	wsServer.SetMessageService(msgSvc)
	wsServer.SetReadMarker(chatRepo)

	return &messagingWiring{wsServer: wsServer, msgSvc: msgSvc}
}

// buildMedia 装配媒体模块（对象存储 + 处理器）。存储后端为懒连接，
// 不可用也不阻断启动，仅在上传时失败。
func buildMedia(cfg *config.Config, log *slog.Logger, pool *pgxpool.Pool) (*media.Handler, error) {
	store, err := media.New(cfg.StorageBackend, media.Config{
		Endpoint:  cfg.S3Endpoint,
		AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey,
		Bucket:    cfg.S3Bucket,
		UseSSL:    cfg.S3UseSSL,
	})
	if err != nil {
		return nil, err
	}
	return media.NewHandler(store, media.NewRepo(pool), log), nil
}
