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

// List 拉取某会话 seq 小于 beforeSeq 的最近 limit 条（倒序取、正序回），排除 viewer 已本地删除的消息。
func (r *Repository) List(ctx context.Context, viewerID, convID string, beforeSeq int64, limit int) ([]*Message, error) {
	if beforeSeq <= 0 {
		beforeSeq = int64(1) << 62
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, sender_id, seq, type, content, media_url, recalled, created_at
		FROM messages
		WHERE conversation_id = $1 AND seq < $2
		  AND NOT EXISTS (SELECT 1 FROM message_hidden h WHERE h.message_id = messages.id AND h.user_id = $4)
		ORDER BY seq DESC
		LIMIT $3`, convID, beforeSeq, limit, viewerID)
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
			recalled         bool
			createdAt        time.Time
		)
		if err := rows.Scan(&id, &conv, &sender, &seq, &typ, &content, &mediaURL, &recalled, &createdAt); err != nil {
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
			Content: c, Recalled: recalled, CreatedAt: createdAt,
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

// ListAfter 拉取某会话 seq 大于 afterSeq 的消息（升序，用于断线重连补拉），排除 viewer 已本地删除的。
func (r *Repository) ListAfter(ctx context.Context, viewerID, convID string, afterSeq int64, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, conversation_id, sender_id, seq, type, content, media_url, recalled, created_at
		FROM messages
		WHERE conversation_id = $1 AND seq > $2
		  AND NOT EXISTS (SELECT 1 FROM message_hidden h WHERE h.message_id = messages.id AND h.user_id = $4)
		ORDER BY seq ASC
		LIMIT $3`, convID, afterSeq, limit, viewerID)
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
			recalled         bool
			createdAt        time.Time
		)
		if err := rows.Scan(&id, &conv, &sender, &seq, &typ, &content, &mediaURL, &recalled, &createdAt); err != nil {
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
			Content: c, Recalled: recalled, CreatedAt: createdAt,
		})
	}
	return out, rows.Err()
}

// scanCols 与历史查询一致的列顺序，供 GetByID / Search 复用。
const msgColumns = `id, conversation_id, sender_id, seq, type, content, media_url, recalled, created_at`

func scanMessage(
	scan func(dest ...any) error,
) (*Message, error) {
	var (
		id, conv, sender string
		seq              int64
		typ              int16
		content          []byte
		mediaURL         *string
		recalled         bool
		createdAt        time.Time
	)
	if err := scan(&id, &conv, &sender, &seq, &typ, &content, &mediaURL, &recalled, &createdAt); err != nil {
		return nil, err
	}
	var c Content
	_ = json.Unmarshal(content, &c)
	c.Type = typ
	if mediaURL != nil {
		c.MediaURL = *mediaURL
	}
	return &Message{
		ID: id, ConversationID: conv, SenderID: sender, Seq: seq,
		Content: c, Recalled: recalled, CreatedAt: createdAt,
	}, nil
}

// GetByID 按服务端消息 ID 取回单条（用于撤回/编辑前的归属与时间校验）。
func (r *Repository) GetByID(ctx context.Context, id string) (*Message, error) {
	row := r.pool.QueryRow(ctx, `SELECT `+msgColumns+` FROM messages WHERE id = $1`, id)
	return scanMessage(row.Scan)
}

// Hide 为 viewer 本地删除一条消息（幂等；仅影响自己视图）。
func (r *Repository) Hide(ctx context.Context, convID, viewerID, msgID string) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO message_hidden (conversation_id, user_id, message_id)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, message_id) DO NOTHING`, convID, viewerID, msgID)
	return err
}

// Recall 将消息标为已撤回，并清空文本与媒体 URL（保留其他元数据供审计）。
func (r *Repository) Recall(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE messages SET recalled = true, media_url = NULL,
			content = jsonb_set(content, '{text}', '""'::jsonb)
		WHERE id = $1`, id)
	return err
}

// UpdateText 编辑一条文本消息的正文（仅 type=0）。
func (r *Repository) UpdateText(ctx context.Context, id, text string) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE messages SET content = jsonb_set(content, '{text}', to_jsonb($2::text))
		WHERE id = $1 AND type = 0`, id, text)
	return err
}

// UpdateReactions 用给定映射整体替换 content.reactions（空则写入 {}）。
func (r *Repository) UpdateReactions(ctx context.Context, id string, reactions map[string][]string) error {
	if reactions == nil {
		reactions = map[string][]string{}
	}
	b, err := json.Marshal(reactions)
	if err != nil {
		return err
	}
	_, err = r.pool.Exec(ctx, `
		UPDATE messages SET content = jsonb_set(content, '{reactions}', $2::jsonb)
		WHERE id = $1`, id, string(b))
	return err
}

// SearchGlobal 跨 viewer 所在全部会话检索文本消息（排除本地已删/已撤回/非文本），时间倒序。
func (r *Repository) SearchGlobal(ctx context.Context, viewerID, q string, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 50 {
		limit = 50
	}
	rows, err := r.pool.Query(ctx, `
		SELECT m.id, m.conversation_id, m.sender_id, m.seq, m.type, m.content, m.media_url, m.recalled, m.created_at
		FROM messages m
		JOIN conversation_members cm ON cm.conversation_id = m.conversation_id AND cm.user_id = $1
		WHERE m.type = 0 AND m.recalled = false
		  AND m.content ->> 'text' ILIKE '%' || $2 || '%'
		  AND NOT EXISTS (SELECT 1 FROM message_hidden h WHERE h.message_id = m.id AND h.user_id = $1)
		ORDER BY m.created_at DESC
		LIMIT $3`, viewerID, q, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*Message
	for rows.Next() {
		m, err := scanMessage(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// Search 在某会话内按文本关键字检索（ILIKE），返回未撤回的文本消息（时间正序）。
func (r *Repository) Search(ctx context.Context, convID, q string, limit int) ([]*Message, error) {
	if limit <= 0 || limit > 50 {
		limit = 50
	}
	rows, err := r.pool.Query(ctx, `
		SELECT `+msgColumns+`
		FROM messages
		WHERE conversation_id = $1 AND recalled = false AND type = 0
			AND content ->> 'text' ILIKE '%' || $2 || '%'
		ORDER BY seq DESC
		LIMIT $3`, convID, q, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*Message
	for rows.Next() {
		m, err := scanMessage(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out, nil
}
