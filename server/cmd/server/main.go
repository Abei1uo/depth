// Command server 启动 IM 后端服务（HTTP + WebSocket）。
package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/tss/depth/server/internal/app"
	"github.com/tss/depth/server/pkg/config"
	"github.com/tss/depth/server/pkg/logger"
)

func main() {
	cfg := config.Load()
	log := logger.Init(cfg.Env)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	a, err := app.New(ctx, cfg, log)
	if err != nil {
		log.Error("server init failed", "err", err.Error())
		os.Exit(1)
	}
	if err := a.Run(ctx); err != nil {
		log.Error("server exited with error", "err", err.Error())
		os.Exit(1)
	}
}
