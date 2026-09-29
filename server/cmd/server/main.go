// Command server 启动 IM 后端服务（HTTP + WebSocket）。
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/tss/depth/server/internal/auth"
	"github.com/tss/depth/server/internal/chat"
	"github.com/tss/depth/server/internal/gateway"
	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/internal/presence"
	"github.com/tss/depth/server/internal/push"
	"github.com/tss/depth/server/internal/user"
	"github.com/tss/depth/server/pkg/config"
	"github.com/tss/depth/server/pkg/logger"
)

func main() {
	cfg := config.Load()
	log := logger.Init(cfg.Env)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, cfg, log); err != nil {
		log.Error("server exited with error", "err", err.Error())
		os.Exit(1)
	}
}

func run(ctx context.Context, cfg *config.Config, log *slog.Logger) error {
	// 连接 PostgreSQL
	pool, err := pgxpool.New(ctx, cfg.PostgresDSN)
	if err != nil {
		return err
	}
	defer pool.Close()
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		return err
	}

	// 连接 Redis
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddr,
		Password: cfg.RedisPassword,
		DB:       cfg.RedisDB,
	})
	defer rdb.Close()
	if err := rdb.Ping(ctx).Err(); err != nil {
		return err
	}

	// 仓储层
	userRepo := user.NewRepository(pool)
	chatRepo := chat.NewRepository(pool)
	msgRepo := message.NewRepository(pool)

	// 认证
	tokens, err := auth.NewTokenManager(cfg)
	if err != nil {
		return err
	}
	authSvc := auth.NewService(userRepo, tokens, rdb, cfg.RefreshTokenTTL)
	authHandler := auth.NewHandler(authSvc)

	// 在线状态
	presSvc := presence.NewService(rdb, cfg.PongTimeout*2)

	// WebSocket 服务端（先建，Hub 供消息服务作 Router）
	wsServer := gateway.NewWSServer(tokens, presSvc, log, cfg.PingInterval)

	// 消息服务
	pusher := push.NewNoop(log)
	msgSvc := message.NewService(
		msgRepo, chatRepo, wsServer.Hub(), pusher, rdb,
		gateway.EncodeMessage, log,
	)
	wsServer.SetMessageService(msgSvc)

	// HTTP 处理器
	userHandler := user.NewHandler(userRepo)
	chatHandler := chat.NewHandler(chatRepo, msgSvc)

	// 组装路由
	go wsServer.Hub().Run(ctx)
	router := gateway.NewRouter(gateway.RouterDeps{
		Cfg:      cfg,
		Log:      log,
		Auth:     authHandler,
		Users:    userHandler,
		Chats:    chatHandler,
		Tokens:   tokens,
		WSServer: wsServer,
	})

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	// 启动
	errCh := make(chan error, 1)
	go func() {
		log.Info("server listening", "addr", cfg.HTTPAddr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	// 优雅关停
	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
		log.Info("shutting down...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		return srv.Shutdown(shutdownCtx)
	}
}
