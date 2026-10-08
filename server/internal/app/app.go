// Package app 负责服务端依赖装配：连接基础设施、按模块构建各组件、
// 组装 HTTP 路由并管理其生命周期。cmd/server 只需调用 New 与 Run。
package app

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/tss/depth/server/internal/chat"
	"github.com/tss/depth/server/internal/gateway"
	"github.com/tss/depth/server/internal/message"
	"github.com/tss/depth/server/internal/user"
	"github.com/tss/depth/server/pkg/config"
)

// App 是装配完成的服务实例，持有 HTTP 服务器与需回收的基础设施。
type App struct {
	cfg      *config.Config
	log      *slog.Logger
	httpSrv  *http.Server
	wsServer *gateway.WSServer
	cleanups []func()
}

// New 依序连接基础设施、装配各业务模块并组装路由。任一步失败即回收
// 已建立的连接后返回错误，调用方无需关心清理。
func New(ctx context.Context, cfg *config.Config, log *slog.Logger) (*App, error) {
	a := &App{cfg: cfg, log: log}

	pool, err := newPostgres(ctx, cfg.PostgresDSN)
	if err != nil {
		return nil, err
	}
	a.cleanup(func() { pool.Close() })

	rdb, err := newRedis(ctx, cfg)
	if err != nil {
		a.close()
		return nil, err
	}
	a.cleanup(func() { _ = rdb.Close() })

	// 仓储层
	userRepo := user.NewRepository(pool)
	chatRepo := chat.NewRepository(pool)
	msgRepo := message.NewRepository(pool)

	// 各业务模块装配
	authz, err := buildAuth(cfg, userRepo, rdb)
	if err != nil {
		a.close()
		return nil, err
	}

	msg := buildMessaging(cfg, log, authz.tokens, chatRepo, msgRepo, rdb)
	a.wsServer = msg.wsServer

	userHandler := user.NewHandler(userRepo)
	chatHandler := chat.NewHandler(chatRepo, msg.msgSvc)

	mediaHandler, err := buildMedia(cfg, log, pool)
	if err != nil {
		a.close()
		return nil, err
	}

	// 组装路由与 HTTP 服务器
	router := gateway.NewRouter(gateway.RouterDeps{
		Cfg:      cfg,
		Log:      log,
		Auth:     authz.handler,
		Users:    userHandler,
		Chats:    chatHandler,
		Media:    mediaHandler,
		Tokens:   authz.tokens,
		WSServer: msg.wsServer,
	})
	a.httpSrv = &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	return a, nil
}

// Run 启动 Hub 与 HTTP 服务，阻塞至 ctx 取消或服务出错，随后优雅关停并回收资源。
func (a *App) Run(ctx context.Context) error {
	defer a.close()

	go a.wsServer.Hub().Run(ctx)

	errCh := make(chan error, 1)
	go func() {
		a.log.Info("server listening", "addr", a.cfg.HTTPAddr)
		if err := a.httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
		a.log.Info("shutting down...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		return a.httpSrv.Shutdown(shutdownCtx)
	}
}

// cleanup 登记一个需在退出时执行的回收动作。
func (a *App) cleanup(f func()) { a.cleanups = append(a.cleanups, f) }

// close 逆序释放基础设施连接（与建立顺序相反），对齐原 defer 的回收语义。
func (a *App) close() {
	for i := len(a.cleanups) - 1; i >= 0; i-- {
		a.cleanups[i]()
	}
	a.cleanups = nil
}
