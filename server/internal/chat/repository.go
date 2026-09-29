// Package chat 管理会话（单聊/群聊）及其成员。
package chat

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// 会话类型。
const (
	TypeDirect = 0 // 单聊
	TypeGroup  = 1 // 群聊
)

// Conversation 是会话实体。
type Conversation struct {
	ID        string `json:"id"`
	Type      int16  `json:"type"`
	Name      string `json:"name"`
	AvatarURL string `json:"avatar_url"`
	OwnerID   string `json:"owner_id"`
	MemberIDs []string `json:"member_ids,omitempty"`
}

// Repository 封装会话相关持久化。
type Repository struct {
	pool *pgxpool.Pool
}

// NewRepository 构造仓储。
func NewRepository(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// CreateDirect 创建或复用两个用户之间的单聊会话（幂等）。
func (r *Repository) CreateDirect(ctx context.Context, a, b string) (string, error) {
	// 规范化排序，保证同一对用户始终映射到同一会话。
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx)

	// 通过成员包含关系查找既有单聊会话（同一对用户映射到同一会话）。
	var existing string
	err = tx.QueryRow(ctx, `
		SELECT c.id FROM conversations c
		JOIN conversation_members m ON m.conversation_id = c.id
		WHERE c.type = 0
		GROUP BY c.id
		HAVING bool_or(m.user_id = $1) AND bool_or(m.user_id = $2)
		   AND COUNT(*) = 2`, a, b).Scan(&existing)
	if err == nil {
		return existing, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return "", err
	}

	var convID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO conversations (type, owner_id) VALUES (0, $1) RETURNING id`, a).Scan(&convID); err != nil {
		return "", err
	}
	for _, uid := range []string{a, b} {
		if _, err := tx.Exec(ctx, `
			INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)`, convID, uid); err != nil {
			return "", err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return convID, nil
}

// CreateGroup 创建群聊会话并把 owner 加入成员。
func (r *Repository) CreateGroup(ctx context.Context, ownerID, name string, memberIDs []string) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx)

	var convID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO conversations (type, name, owner_id) VALUES (1, $1, $2) RETURNING id`, name, ownerID).Scan(&convID); err != nil {
		return "", err
	}
	members := append([]string{ownerID}, memberIDs...)
	seen := map[string]bool{}
	for _, uid := range members {
		if seen[uid] {
			continue
		}
		seen[uid] = true
		role := int16(0)
		if uid == ownerID {
			role = 2
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO conversation_members (conversation_id, user_id, role) VALUES ($1, $2, $3)`, convID, uid, role); err != nil {
			return "", err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return convID, nil
}

// Members 返回会话全部成员 ID。
func (r *Repository) Members(ctx context.Context, convID string) ([]string, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT user_id FROM conversation_members WHERE conversation_id = $1`, convID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

// ListForUser 返回用户参与的所有会话摘要。
func (r *Repository) ListForUser(ctx context.Context, userID string) ([]*Conversation, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT c.id, c.type, COALESCE(c.name,''), COALESCE(c.avatar_url,''), COALESCE(c.owner_id::text,'')
		FROM conversations c
		JOIN conversation_members m ON m.conversation_id = c.id
		WHERE m.user_id = $1
		ORDER BY c.last_msg_at DESC NULLS LAST`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*Conversation
	for rows.Next() {
		var c Conversation
		if err := rows.Scan(&c.ID, &c.Type, &c.Name, &c.AvatarURL, &c.OwnerID); err != nil {
			return nil, err
		}
		out = append(out, &c)
	}
	return out, rows.Err()
}
