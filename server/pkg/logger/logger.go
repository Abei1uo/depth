// Package logger 基于标准库 log/slog 提供结构化日志。
package logger

import (
	"log/slog"
	"os"
	"strings"
)

// Init 根据运行环境初始化全局 slog Logger。
func Init(env string) *slog.Logger {
	var level slog.Level
	switch strings.ToLower(env) {
	case "production":
		level = slog.LevelInfo
	default:
		level = slog.LevelDebug
	}

	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level})
	log := slog.New(handler)
	slog.SetDefault(log)
	return log
}
