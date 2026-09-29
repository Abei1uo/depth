// Package auth 提供注册、登录与 JWT 令牌签发/校验。
package auth

import (
	"crypto/rsa"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/tss/depth/server/pkg/config"
)

// Claims 是访问令牌承载的自定义声明。
type Claims struct {
	UserID   string `json:"uid"`
	Username string `json:"uname"`
	jwt.RegisteredClaims
}

// TokenManager 负责签发与解析 JWT。
// 生产使用 RS256（配置了公私钥文件时），本地开发回退到 HS256。
type TokenManager struct {
	privateKey *rsa.PrivateKey
	publicKey  *rsa.PublicKey
	hsSecret   []byte
	useRS      bool
	accessTTL  time.Duration
	refreshTTL time.Duration
}

// NewTokenManager 依据配置构造令牌管理器。
func NewTokenManager(cfg *config.Config) (*TokenManager, error) {
	tm := &TokenManager{
		accessTTL:  cfg.AccessTokenTTL,
		refreshTTL: cfg.RefreshTokenTTL,
	}

	if cfg.JWTPrivateKeyPath != "" && cfg.JWTPublicKeyPath != "" {
		priv, err := loadPrivateKey(cfg.JWTPrivateKeyPath)
		if err != nil {
			return nil, err
		}
		pub, err := loadPublicKey(cfg.JWTPublicKeyPath)
		if err != nil {
			return nil, err
		}
		tm.privateKey = priv
		tm.publicKey = pub
		tm.useRS = true
		return tm, nil
	}

	// 开发回退：使用配置中的 HMAC 密钥。生产环境禁止使用该分支。
	if cfg.IsProduction() {
		return nil, errors.New("生产环境必须配置 JWT RSA 密钥对")
	}
	tm.hsSecret = []byte(cfg.JWTDevSecret)
	tm.useRS = false
	return tm, nil
}

// NewRefreshToken 生成一个不透明的刷新令牌（基于随机 UUID）。
func NewRefreshToken() string {
	u := uuid.New()
	return base64.RawURLEncoding.EncodeToString(u[:])
}

// SignAccessToken 签发访问令牌。
func (tm *TokenManager) SignAccessToken(userID, username string) (string, time.Time, error) {
	now := time.Now()
	exp := now.Add(tm.accessTTL)
	claims := Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			ID:        uuid.NewString(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(exp),
			NotBefore: jwt.NewNumericDate(now),
		},
	}
	return tm.sign(claims) , exp, nil
}

func (tm *TokenManager) sign(claims Claims) string {
	token := jwt.NewWithClaims(tm.method(), claims)
	if tm.useRS {
		s, _ := token.SignedString(tm.privateKey)
		return s
	}
	s, _ := token.SignedString(tm.hsSecret)
	return s
}

func (tm *TokenManager) method() jwt.SigningMethod {
	if tm.useRS {
		return jwt.SigningMethodRS256
	}
	return jwt.SigningMethodHS256
}

// Parse 校验并解析访问令牌，返回自定义声明。
func (tm *TokenManager) Parse(tokenStr string) (*Claims, error) {
	parser := jwt.NewParser(jwt.WithValidMethods([]string{tm.method().Alg()}))
	claims := &Claims{}
	_, err := parser.ParseWithClaims(tokenStr, claims, tm.keyFunc)
	if err != nil {
		return nil, err
	}
	return claims, nil
}

// UserIDFromToken 校验访问令牌并返回其归属用户 ID。
// 供 middleware.TokenVerifier 接口使用，避免 middleware 直接依赖 auth.Claims。
func (tm *TokenManager) UserIDFromToken(tokenStr string) (string, error) {
	claims, err := tm.Parse(tokenStr)
	if err != nil {
		return "", err
	}
	return claims.UserID, nil
}

func (tm *TokenManager) keyFunc(t *jwt.Token) (any, error) {
	if tm.useRS {
		if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("非预期的签名方法: %v", t.Header["alg"])
		}
		return tm.publicKey, nil
	}
	if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
		return nil, fmt.Errorf("非预期的签名方法: %v", t.Header["alg"])
	}
	return tm.hsSecret, nil
}

func loadPrivateKey(path string) (*rsa.PrivateKey, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	key, err := jwt.ParseRSAPrivateKeyFromPEM(data)
	if err != nil {
		return nil, fmt.Errorf("解析 RSA 私钥失败: %w", err)
	}
	return key, nil
}

func loadPublicKey(path string) (*rsa.PublicKey, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	key, err := jwt.ParseRSAPublicKeyFromPEM(data)
	if err != nil {
		return nil, fmt.Errorf("解析 RSA 公钥失败: %w", err)
	}
	return key, nil
}
