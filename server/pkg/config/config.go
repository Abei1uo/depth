// Package config 负责从环境变量加载服务端配置。
// 所有配置项均提供本地开发默认值，生产环境务必通过环境变量覆盖。
package config

import (
	"os"
	"strconv"
	"time"
)

// Config 聚合应用运行所需的全部配置。
type Config struct {
	Env           string // development / production
	HTTPAddr      string // Gin 监听地址，例如 :8080
	WSPath        string // WebSocket 端点路径
	PostgresDSN   string
	RedisAddr     string
	RedisPassword string
	RedisDB       int

	// JWT（RS256）——私钥路径为空时回退到 HMAC 开发密钥，仅供本地调试。
	JWTPrivateKeyPath string
	JWTPublicKeyPath  string
	JWTDevSecret      string
	AccessTokenTTL    time.Duration
	RefreshTokenTTL   time.Duration

	// 对象存储（后端无关；默认走 S3 协议的 MinIO）。
	StorageBackend string // s3 | minio（均走 minio-go，兼容任意 S3 服务）
	S3Endpoint     string
	S3AccessKey    string
	S3SecretKey    string
	S3Bucket       string
	S3UseSSL       bool

	// 心跳
	PingInterval time.Duration
	PongTimeout  time.Duration
}

// Load 从环境变量读取配置，缺省时使用本地开发默认值。
func Load() *Config {
	return &Config{
		Env:      getEnv("APP_ENV", "development"),
		HTTPAddr: getEnv("HTTP_ADDR", ":8080"),
		WSPath:   getEnv("WS_PATH", "/ws"),
		PostgresDSN: getEnv("POSTGRES_DSN",
			"postgres://im:im@localhost:5432/im?sslmode=disable"),
		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getIntEnv("REDIS_DB", 0),

		JWTPrivateKeyPath: getEnv("JWT_PRIVATE_KEY_PATH", ""),
		JWTPublicKeyPath:  getEnv("JWT_PUBLIC_KEY_PATH", ""),
		JWTDevSecret:      getEnv("JWT_DEV_SECRET", "dev-only-insecure-secret"),
		AccessTokenTTL:    getDurationEnv("ACCESS_TOKEN_TTL", time.Hour*2),
		RefreshTokenTTL:   getDurationEnv("REFRESH_TOKEN_TTL", time.Hour*24*30),

		StorageBackend: getEnv("STORAGE_BACKEND", "s3"),
		S3Endpoint:     getEnvAny("localhost:9000", "S3_ENDPOINT", "MINIO_ENDPOINT"),
		S3AccessKey:    getEnvAny("minioadmin", "S3_ACCESS_KEY", "MINIO_ACCESS_KEY"),
		S3SecretKey:    getEnvAny("minioadmin", "S3_SECRET_KEY", "MINIO_SECRET_KEY"),
		S3Bucket:       getEnvAny("im-media", "S3_BUCKET", "MINIO_BUCKET"),
		S3UseSSL:       getBoolAny(false, "S3_USE_SSL", "MINIO_USE_SSL"),

		PingInterval: getDurationEnv("WS_PING_INTERVAL", time.Second*30),
		PongTimeout:  getDurationEnv("WS_PONG_TIMEOUT", time.Second*60),
	}
}

// IsProduction 判断是否为生产环境。
func (c *Config) IsProduction() bool { return c.Env == "production" }

func getEnv(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

// getEnvAny 依次尝试多个环境变量名，返回首个非空值（兼容 S3_* 与旧 MINIO_*）。
func getEnvAny(def string, keys ...string) string {
	for _, k := range keys {
		if v, ok := os.LookupEnv(k); ok && v != "" {
			return v
		}
	}
	return def
}

func getBoolAny(def bool, keys ...string) bool {
	for _, k := range keys {
		if v, ok := os.LookupEnv(k); ok {
			if b, err := strconv.ParseBool(v); err == nil {
				return b
			}
		}
	}
	return def
}

func getIntEnv(key string, def int) int {
	if v, ok := os.LookupEnv(key); ok {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func getBoolEnv(key string, def bool) bool {
	if v, ok := os.LookupEnv(key); ok {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return def
}

func getDurationEnv(key string, def time.Duration) time.Duration {
	if v, ok := os.LookupEnv(key); ok {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return def
}
