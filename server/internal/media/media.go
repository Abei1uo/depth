// Package media 提供后端无关的对象存储抽象（上传/下载）与媒体对象登记。
//
// 设计目标：业务只依赖 Store 接口，MinIO/S3/OSS 等具体后端藏在实现里；
// 换后端多数只需改配置（endpoint/凭据/桶），接非 S3 服务时新增一个 Store 实现即可。
package media

import (
	"context"
	"fmt"
	"io"
)

// Store 是对象存储的后端无关接口。
type Store interface {
	// Put 写入一个对象。size 可为 -1 表示未知（实现可自行缓冲）。
	Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error
	// Get 读取对象，返回可读流与其 Content-Type。调用方负责 Close。
	Get(ctx context.Context, key string) (io.ReadCloser, string, error)
}

// Config 描述连接一个 S3 兼容后端所需参数。
type Config struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	Bucket    string
	UseSSL    bool
}

// New 按后端类型构造 Store。当前支持 s3/minio（都走 minio-go，即 S3 协议）；
// 接入非 S3 协议服务时在此加一个 case + 新的 Store 实现即可，上层无需改动。
func New(backend string, cfg Config) (Store, error) {
	switch backend {
	case "", "s3", "minio":
		return newS3Store(cfg)
	default:
		return nil, fmt.Errorf("unsupported storage backend %q", backend)
	}
}
