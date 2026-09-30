package media

import (
	"context"
	"io"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// s3Store 是基于 minio-go（S3 协议）的 Store 实现，
// 覆盖 MinIO / AWS S3 / 阿里云 OSS(S3 兼容) / Ceph 等。
type s3Store struct {
	client *minio.Client
	bucket string
}

func newS3Store(cfg Config) (*s3Store, error) {
	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
	})
	if err != nil {
		return nil, err
	}
	return &s3Store{client: client, bucket: cfg.Bucket}, nil
}

// ensureBucket 惰性建桶（首次上传时）。
func (s *s3Store) ensureBucket(ctx context.Context) error {
	ok, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return err
	}
	if ok {
		return nil
	}
	return s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{})
}

func (s *s3Store) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error {
	if err := s.ensureBucket(ctx); err != nil {
		return err
	}
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	_, err := s.client.PutObject(ctx, s.bucket, key, r, size,
		minio.PutObjectOptions{ContentType: contentType})
	return err
}

func (s *s3Store) Get(ctx context.Context, key string) (io.ReadCloser, string, error) {
	obj, err := s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, "", err
	}
	info, err := obj.Stat()
	if err != nil {
		obj.Close()
		return nil, "", err
	}
	ct := info.ContentType
	if ct == "" {
		ct = "application/octet-stream"
	}
	return obj, ct, nil
}
