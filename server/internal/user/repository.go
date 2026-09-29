// Package user 负责用户实体与数据访问。
package user

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound 表示用户不存在。
var ErrNotFound = errors.New("user not found")

// User 是核心用户实体。PasswordHash 不对外暴露。
type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	Nickname     string    `json:"nickname"`
	AvatarURL    string    `json:"avatar_url"`
	PasswordHash string    `json:"-"`
	CreatedAt    time.Time `json:"created_at"`
}

// Repository 封装 users 表的持久化操作。
type Repository struct {
	pool *pgxpool.Pool
}

// NewRepository 构造仓储实例。
func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

const insertSQL = `
INSERT INTO users (username, nickname, password_hash)
VALUES ($1, $2, $3)
RETURNING id, username, nickname, avatar_url, password_hash, created_at`

// Create 插入新用户并返回完整实体。
func (r *Repository) Create(ctx context.Context, username, nickname, passwordHash string) (*User, error) {
	var u User
	err := r.pool.QueryRow(ctx, insertSQL, username, nickname, passwordHash).
		Scan(&u.ID, &u.Username, &u.Nickname, &u.AvatarURL, &u.PasswordHash, &u.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *Repository) queryOne(ctx context.Context, column, value string) (*User, error) {
	var u User
	q := "SELECT id, username, nickname, avatar_url, password_hash, created_at FROM users WHERE " + column + " = $1 LIMIT 1"
	err := r.pool.QueryRow(ctx, q, value).
		Scan(&u.ID, &u.Username, &u.Nickname, &u.AvatarURL, &u.PasswordHash, &u.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// ByID 按主键查询。
func (r *Repository) ByID(ctx context.Context, id string) (*User, error) {
	return r.queryOne(ctx, "id", id)
}

// ByUsername 按用户名查询。
func (r *Repository) ByUsername(ctx context.Context, username string) (*User, error) {
	return r.queryOne(ctx, "username", username)
}

// Search 按用户名/昵称模糊搜索，最多返回 limit 条。
func (r *Repository) Search(ctx context.Context, keyword string, limit int) ([]*User, error) {
	q := `SELECT id, username, nickname, avatar_url, '', created_at
	      FROM users
	      WHERE username ILIKE $1 OR nickname ILIKE $1
	      LIMIT $2`
	pattern := "%" + keyword + "%"
	rows, err := r.pool.Query(ctx, q, pattern, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*User
	for rows.Next() {
		var u User
		if err := rows.Scan(&u.ID, &u.Username, &u.Nickname, &u.AvatarURL, &u.PasswordHash, &u.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, &u)
	}
	return out, rows.Err()
}
