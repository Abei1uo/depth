package message

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository 封装 messages 表访问。
type Repository struct {
	pool *pgxpool.Pool
}

// NewRepository 构造仓储。
func NewRepository(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// Insert 持久化一条消息。content 以 JSONB 存储。
func (r *Repository) Insert(ctx context.Context, m *Message) error {
	contentJSON, err := json.Marshal(m.Content)
	if err != nil {
		return err
	}
	_, err = r.pool.Exec(ctx, `
		INSERT INTO messages (id, conversation_id, sender_id, seq, type, content, media_url, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		m.ID, m.ConversationID, m.SenderID, m.Seq, m.Content.Type, contentJSON, m.Content.MediaURL, m.CreatedAt)
	if err != nil {
		return err
	}
	// 更新会话摘要（最后一条消息时间与 seq 游标）。
	_, err = r.pool.Exec(ctx, `
		UPDATE conversations SET last_msg_at = $2 WHERE id = $1`,
		m.ConversationID, m.CreatedAt)
	return err
}

// List 拉取某会话 seq 小于 beforeSeq 的最近 limit 条（倒序取、正序回）。
func (r *Repository) List(ctx context.Context, convID string, beforeSeq int64, limit int) ([]*Message, error) {
	if beforeSeq <= 0 {
		beforeSeq = int64(1) << 62
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, sender_id, seq, type, content, media_url, created_at
		FROM messages
		WHERE conversation_id = $1 AND seq < $2
		ORDER BY seq DESC
		LIMIT $3`, convID, beforeSeq, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*Message
	for rows.Next() {
		var (
			id, conv, sender string
			seq              int64
			typ              int16
			content          []byte
			mediaURL         *string
			createdAt        time.Time
		)
		if err := rows.Scan(&id, &conv, &sender, &seq, &typ, &content, &mediaURL, &createdAt); err != nil {
			return nil, err
		}
		var c Content
		_ = json.Unmarshal(content, &c)
		c.Type = typ
		if mediaURL != nil {
			c.MediaURL = *mediaURL
		}
		out = append(out, &Message{
			ID: id, ConversationID: conv, SenderID: sender, Seq: seq,
			Content: c, CreatedAt: createdAt,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	// 反转为时间正序，便于客户端直接渲染。
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out, nil
}

// ListAfter 拉取某会话 seq 大于 afterSeq 的消息（升序，用于断线重连补拉）。
func (r *Repository) ListAfter(ctx context.Context, convID string, afterSeq int64, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, sender_id, seq, type, content, media_url, created_at
		FROM messages
		WHERE conversation_id = $1 AND seq > $2
		ORDER BY seq ASC
		LIMIT $3`, convID, afterSeq, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*Message
	for rows.Next() {
		var (
			id, conv, sender string
			seq              int64
			typ              int16
			content          []byte
			mediaURL         *string
			createdAt        time.Time
		)
		if err := rows.Scan(&id, &conv, &sender, &seq, &typ, &content, &mediaURL, &createdAt); err != nil {
			return nil, err
		}
		var c Content
		_ = json.Unmarshal(content, &c)
		c.Type = typ
		if mediaURL != nil {
			c.MediaURL = *mediaURL
		}
		out = append(out, &Message{
			ID: id, ConversationID: conv, SenderID: sender, Seq: seq,
			Content: c, CreatedAt: createdAt,
		})
	}
	return out, rows.Err()
}
