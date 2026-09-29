package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"

	"github.com/tss/depth/server/internal/user"
)

// 业务错误。
var (
	ErrUsernameTaken = errors.New("用户名已存在")
	ErrInvalidCred   = errors.New("用户名或密码错误")
	ErrInvalidToken  = errors.New("刷新令牌无效")
)

// TokenPair 返回给客户端的令牌组合。
type TokenPair struct {
	AccessToken  string     `json:"access_token"`
	RefreshToken string     `json:"refresh_token"`
	ExpiresAt    int64      `json:"expires_at"` // Unix 秒
	User         *user.User `json:"user"`
}

// Service 编排认证用例。
type Service struct {
	users      *user.Repository
	tokens     *TokenManager
	rdb        *redis.Client
	refreshTTL time.Duration
}

// NewService 构造认证服务。
func NewService(users *user.Repository, tokens *TokenManager, rdb *redis.Client, refreshTTL time.Duration) *Service {
	return &Service{users: users, tokens: tokens, rdb: rdb, refreshTTL: refreshTTL}
}

// Register 创建用户并直接返回令牌对。
func (s *Service) Register(ctx context.Context, username, nickname, password string) (*TokenPair, error) {
	if _, err := s.users.ByUsername(ctx, username); err == nil {
		return nil, ErrUsernameTaken
	} else if !errors.Is(err, user.ErrNotFound) {
		return nil, err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	u, err := s.users.Create(ctx, username, nickname, string(hash))
	if err != nil {
		return nil, err
	}
	return s.issue(ctx, u)
}

// Login 校验密码并签发令牌。
func (s *Service) Login(ctx context.Context, username, password string) (*TokenPair, error) {
	u, err := s.users.ByUsername(ctx, username)
	if errors.Is(err, user.ErrNotFound) {
		return nil, ErrInvalidCred
	}
	if err != nil {
		return nil, err
	}
	if bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)) != nil {
		return nil, ErrInvalidCred
	}
	return s.issue(ctx, u)
}

// Refresh 用刷新令牌换取新的令牌对（轮换刷新令牌）。
func (s *Service) Refresh(ctx context.Context, refreshToken string) (*TokenPair, error) {
	uid, err := s.rdb.Get(ctx, refreshKey(refreshToken)).Result()
	if err != nil {
		return nil, ErrInvalidToken
	}
	// 旧的刷新令牌一次性使用，立即失效。
	s.rdb.Del(ctx, refreshKey(refreshToken))

	u, err := s.users.ByID(ctx, uid)
	if err != nil {
		return nil, ErrInvalidToken
	}
	return s.issue(ctx, u)
}

func (s *Service) issue(ctx context.Context, u *user.User) (*TokenPair, error) {
	access, exp, err := s.tokens.SignAccessToken(u.ID, u.Username)
	if err != nil {
		return nil, err
	}
	refresh := NewRefreshToken()
	if err := s.rdb.Set(ctx, refreshKey(refresh), u.ID, s.refreshTTL).Err(); err != nil {
		return nil, fmt.Errorf("存储刷新令牌失败: %w", err)
	}
	return &TokenPair{
		AccessToken:  access,
		RefreshToken: refresh,
		ExpiresAt:    exp.Unix(),
		User:         u,
	}, nil
}

func refreshKey(token string) string { return "user:refresh:" + token }
