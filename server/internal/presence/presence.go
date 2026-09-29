// Package presence 基于 Redis 维护用户在线设备，支持多节点共享在线状态。
package presence

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Service 记录 userId -> deviceId 的在线集合，带 TTL 依赖心跳续期。
type Service struct {
	rdb *redis.Client
	ttl time.Duration
}

// NewService 构造在线状态服务，ttl 建议为心跳间隔的 2 倍。
func NewService(rdb *redis.Client, ttl time.Duration) *Service {
	return &Service{rdb: rdb, ttl: ttl}
}

func key(userID string) string { return fmt.Sprintf("online:%s", userID) }

// SetOnline 标记某设备在线。
func (s *Service) SetOnline(ctx context.Context, userID, deviceID string) error {
	k := key(userID)
	if err := s.rdb.SAdd(ctx, k, deviceID).Err(); err != nil {
		return err
	}
	return s.rdb.Expire(ctx, k, s.ttl).Err()
}

// Refresh 心跳续期在线状态。
func (s *Service) Refresh(ctx context.Context, userID string) {
	_ = s.rdb.Expire(ctx, key(userID), s.ttl)
}

// SetOffline 移除某设备的在线标记。
func (s *Service) SetOffline(ctx context.Context, userID, deviceID string) error {
	k := key(userID)
	if err := s.rdb.SRem(ctx, k, deviceID).Err(); err != nil {
		return err
	}
	// 若无剩余设备则删除键。
	if n, _ := s.rdb.SCard(ctx, k).Result(); n == 0 {
		return s.rdb.Del(ctx, k).Err()
	}
	return nil
}

// OnlineUsers 返回当前在线的用户 ID 列表（用于 presence_update 广播）。
func (s *Service) OnlineUsers(ctx context.Context) ([]string, error) {
	keys, err := s.rdb.Keys(ctx, "online:*").Result()
	if err != nil {
		return nil, err
	}
	out := make([]string, 0, len(keys))
	for _, k := range keys {
		out = append(out, k[len("online:"):])
	}
	return out, nil
}
