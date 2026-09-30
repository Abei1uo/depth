package media

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Record 是一条媒体对象登记（后端无关，obj_key 为桶内键）。
type Record struct {
	ID         string
	UploaderID string
	ObjKey     string
	Mime       string
	Size       int64
}

// Repo 封装 media_objects 表访问。
type Repo struct {
	pool *pgxpool.Pool
}

// NewRepo 构造媒体登记仓储。
func NewRepo(pool *pgxpool.Pool) *Repo { return &Repo{pool: pool} }

// Create 插入一条登记并回填生成的 id。
func (r *Repo) Create(ctx context.Context, rec *Record) error {
	return r.pool.QueryRow(ctx, `
		INSERT INTO media_objects (uploader_id, obj_key, mime, size)
		VALUES ($1, $2, $3, $4) RETURNING id`,
		rec.UploaderID, rec.ObjKey, rec.Mime, rec.Size).Scan(&rec.ID)
}

// Get 按 id 取登记；不存在返回 pgx.ErrNoRows。
func (r *Repo) Get(ctx context.Context, id string) (*Record, error) {
	var rec Record
	err := r.pool.QueryRow(ctx, `
		SELECT id, uploader_id, obj_key, mime, size
		FROM media_objects WHERE id = $1`, id).
		Scan(&rec.ID, &rec.UploaderID, &rec.ObjKey, &rec.Mime, &rec.Size)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	if err != nil {
		return nil, err
	}
	return &rec, nil
}
