// Package chat 管理会话（单聊/群聊）及其成员。
package chat

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// 会话类型。
const (
	TypeDirect = 0 // 单聊
	TypeGroup  = 1 // 群聊
)

// 群管理相关错误（HTTP 由 respondConvErr 统一映射）。
var (
	ErrForbidden      = errors.New("需要管理员权限")
	ErrNotMember      = errors.New("目标不是群成员")
	ErrOwnerImmutable = errors.New("不能修改群主角色")
)

// Conversation 是会话实体。
type Conversation struct {
	ID           string     `json:"id"`
	Type         int16      `json:"type"`
	Name         string     `json:"name"`
	AvatarURL    string     `json:"avatar_url"`
	OwnerID      string     `json:"owner_id"`
	Unread       int        `json:"unread"`
	Pinned       bool       `json:"pinned"`
	Muted        bool       `json:"muted"`
	Preview      string     `json:"preview"`
	LastAt       *time.Time `json:"last_at,omitempty"`
	MentionMe    bool       `json:"mention_me"`
	MemberIDs    []string   `json:"member_ids,omitempty"`
	Announcement string     `json:"announcement,omitempty"`
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

// PeerMembers 返回与 userID 处于同一会话的所有其他用户 ID（去重，不含自己）。
// 用于上线/下线时向相关成员广播在线状态。
func (r *Repository) PeerMembers(ctx context.Context, userID string) ([]string, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT m2.user_id
		FROM conversation_members m1
		JOIN conversation_members m2 ON m2.conversation_id = m1.conversation_id
		WHERE m1.user_id = $1 AND m2.user_id <> $1`, userID)
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

// setRole 直接设置成员角色（0 普通 / 1 管理员 / 2 群主），不做权限校验。
func (r *Repository) setRole(ctx context.Context, convID, userID string, role int16) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE conversation_members SET role = $3 WHERE conversation_id = $1 AND user_id = $2`,
		convID, userID, role)
	return err
}

// memberRole 返回某成员角色；非成员返回 -1。
func (r *Repository) memberRole(ctx context.Context, convID, userID string) (int16, error) {
	var role int16
	err := r.pool.QueryRow(ctx,
		`SELECT role FROM conversation_members WHERE conversation_id = $1 AND user_id = $2`,
		convID, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return -1, nil
	}
	if err != nil {
		return 0, err
	}
	return role, nil
}

// isMember 判断用户是否为会话成员。
func (r *Repository) isMember(ctx context.Context, convID, userID string) (bool, error) {
	role, err := r.memberRole(ctx, convID, userID)
	return role >= 0, err
}

// assertGroupAdmin 校验 userID 是该群的群主或管理员（role>=1）。
func (r *Repository) assertGroupAdmin(ctx context.Context, convID, userID string) error {
	var n int
	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM conversations c
		JOIN conversation_members m ON m.conversation_id = c.id
		WHERE c.id = $1 AND c.type = 1 AND m.user_id = $2 AND m.role >= 1`, convID, userID).Scan(&n); err != nil {
		return err
	}
	if n == 0 {
		return ErrForbidden
	}
	return nil
}

// TransferOwner 转让群主（仅群主）：新群主须为成员，原群主降为普通成员。
func (r *Repository) TransferOwner(ctx context.Context, convID, actorID, targetID string) error {
	if err := r.assertGroupOwner(ctx, convID, actorID); err != nil {
		return err
	}
	if actorID == targetID {
		return nil
	}
	ok, err := r.isMember(ctx, convID, targetID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrNotMember
	}
	if err := r.setRole(ctx, convID, targetID, 2); err != nil {
		return err
	}
	return r.setRole(ctx, convID, actorID, 0)
}

// SetMemberRole 设/取消管理员（仅群主）；仅允许 0/1，且目标不能是群主。
func (r *Repository) SetMemberRole(ctx context.Context, convID, actorID, targetID string, role int16) error {
	if err := r.assertGroupOwner(ctx, convID, actorID); err != nil {
		return err
	}
	if role != 0 && role != 1 {
		return ErrForbidden
	}
	cur, err := r.memberRole(ctx, convID, targetID)
	if err != nil {
		return err
	}
	if cur < 0 {
		return ErrNotMember
	}
	if cur == 2 {
		return ErrOwnerImmutable
	}
	return r.setRole(ctx, convID, targetID, role)
}

// DisplayName 返回用户的展示名（昵称优先，回退用户名），用于系统消息文案。
func (r *Repository) DisplayName(ctx context.Context, userID string) (string, error) {
	var name string
	err := r.pool.QueryRow(ctx, `
		SELECT CASE WHEN nickname <> '' THEN nickname ELSE username END
		FROM users WHERE id = $1`, userID).Scan(&name)
	if err != nil {
		return "", err
	}
	return name, nil
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

// ListForUser 返回用户参与的所有会话摘要（含未读数）。
func (r *Repository) ListForUser(ctx context.Context, userID string) ([]*Conversation, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT c.id, c.type, COALESCE(c.name,''), COALESCE(c.avatar_url,''), COALESCE(c.owner_id::text,''),
		       (SELECT COUNT(*) FROM messages msg
		          WHERE msg.conversation_id = c.id
		            AND msg.sender_id <> $1
		            AND msg.seq > COALESCE(r.last_read_seq, 0)),
		       m.pinned, m.muted,
		       CASE
		         WHEN lm.id IS NULL THEN ''
		         WHEN lm.recalled THEN '[撤回了一条消息]'
		         WHEN lm.type = 1 THEN '[图片]'
		         WHEN lm.type = 2 THEN '[文件]'
		         WHEN lm.type = 3 THEN '[语音]'
		         ELSE COALESCE(lm.text,'')
		       END AS preview,
		       COALESCE(lm.created_at, c.last_msg_at) AS last_at,
		       COALESCE(
		         (lm.sender_id <> $1) AND (
		           (lm.content -> 'mentions' @> jsonb_build_array($1::text))
		           OR (lm.content ->> 'mention_all' = 'true')
		         ),
		         false) AS mention_me
		FROM conversations c
		JOIN conversation_members m ON m.conversation_id = c.id
		LEFT JOIN conversation_reads r ON r.conversation_id = c.id AND r.user_id = m.user_id
				LEFT JOIN LATERAL (
				  SELECT msg2.id, msg2.type, msg2.recalled, msg2.created_at,
				         msg2.sender_id,
				         msg2.content->>'text' AS text, msg2.content AS content
				  FROM messages msg2
				  WHERE msg2.conversation_id = c.id
				  ORDER BY msg2.seq DESC
				  LIMIT 1
				) lm ON true
		WHERE m.user_id = $1 AND m.hidden = false
		ORDER BY m.pinned DESC, c.last_msg_at DESC NULLS LAST`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*Conversation
	for rows.Next() {
		var c Conversation
		if err := rows.Scan(&c.ID, &c.Type, &c.Name, &c.AvatarURL, &c.OwnerID,
			&c.Unread, &c.Pinned, &c.Muted, &c.Preview, &c.LastAt, &c.MentionMe); err != nil {
			return nil, err
		}
		out = append(out, &c)
	}
	return out, rows.Err()
}

// Member 会话成员（含用户展示信息）。
type Member struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	Nickname  string `json:"nickname"`
	AvatarURL string `json:"avatar_url"`
	Role      int16  `json:"role"`
}

// Detail 返回单个会话及其成员列表。
func (r *Repository) Detail(ctx context.Context, convID string) (*Conversation, []Member, error) {
	var c Conversation
	err := r.pool.QueryRow(ctx, `
		SELECT id, type, COALESCE(name,''), COALESCE(avatar_url,''), COALESCE(owner_id::text,''), COALESCE(announcement,'')
		FROM conversations WHERE id = $1`, convID).Scan(&c.ID, &c.Type, &c.Name, &c.AvatarURL, &c.OwnerID, &c.Announcement)
	if err != nil {
		return nil, nil, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT m.user_id, u.username, u.nickname, COALESCE(u.avatar_url,''), m.role
		FROM conversation_members m
		JOIN users u ON u.id = m.user_id
		WHERE m.conversation_id = $1
		ORDER BY m.role DESC, m.joined_at ASC`, convID)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	var members []Member
	for rows.Next() {
		var mb Member
		if err := rows.Scan(&mb.UserID, &mb.Username, &mb.Nickname, &mb.AvatarURL, &mb.Role); err != nil {
			return nil, nil, err
		}
		members = append(members, mb)
		c.MemberIDs = append(c.MemberIDs, mb.UserID)
	}
	return &c, members, rows.Err()
}

// MarkRead 更新用户在某会话的已读游标（取较大值，幂等 upsert）。
func (r *Repository) MarkRead(ctx context.Context, userID, convID string, maxSeq int64) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO conversation_reads (user_id, conversation_id, last_read_seq, updated_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (user_id, conversation_id) DO UPDATE
		  SET last_read_seq = GREATEST(conversation_reads.last_read_seq, EXCLUDED.last_read_seq),
		      updated_at    = now()`,
		userID, convID, maxSeq)
	return err
}

// assertGroupOwner 校验 userID 是该群聊会话（type=1）的群主（role=2）。
func (r *Repository) assertGroupOwner(ctx context.Context, convID, userID string) error {
	var n int
	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM conversations c
		JOIN conversation_members m ON m.conversation_id = c.id
		WHERE c.id = $1 AND c.type = 1 AND m.user_id = $2 AND m.role = 2`, convID, userID).Scan(&n); err != nil {
		return err
	}
	if n == 0 {
		return ErrForbidden
	}
	return nil
}

// Rename 群改名（仅群主）。
func (r *Repository) Rename(ctx context.Context, convID, byUserID, name string) error {
	if err := r.assertGroupOwner(ctx, convID, byUserID); err != nil {
		return err
	}
	_, err := r.pool.Exec(ctx, `UPDATE conversations SET name = $1 WHERE id = $2`, name, convID)
	return err
}

// SetAnnouncement 设置群公告（仅群主）。
func (r *Repository) SetAnnouncement(ctx context.Context, convID, byUserID, text string) error {
	if err := r.assertGroupOwner(ctx, convID, byUserID); err != nil {
		return err
	}
	_, err := r.pool.Exec(ctx, `UPDATE conversations SET announcement = $1 WHERE id = $2`, text, convID)
	return err
}

// AddMembers 加成员（群主或管理员）；已存在则忽略。
func (r *Repository) AddMembers(ctx context.Context, convID, byUserID string, ids []string) error {
	if err := r.assertGroupAdmin(ctx, convID, byUserID); err != nil {
		return err
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	for _, uid := range ids {
		if _, err := tx.Exec(ctx, `
			INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)
			ON CONFLICT (conversation_id, user_id) DO NOTHING`, convID, uid); err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

// RemoveMember 踢成员（群主或管理员，不可踢群主）。
func (r *Repository) RemoveMember(ctx context.Context, convID, byUserID, targetID string) error {
	if err := r.assertGroupAdmin(ctx, convID, byUserID); err != nil {
		return err
	}
	_, err := r.pool.Exec(ctx, `
		DELETE FROM conversation_members
		WHERE conversation_id = $1 AND user_id = $2 AND role <> 2`, convID, targetID)
	return err
}

// Leave 退出会话（删除自身成员关系）。
func (r *Repository) Leave(ctx context.Context, convID, userID string) error {
	_, err := r.pool.Exec(ctx, `
		DELETE FROM conversation_members WHERE conversation_id = $1 AND user_id = $2`, convID, userID)
	return err
}

// SetPin 设置置顶。
func (r *Repository) SetPin(ctx context.Context, convID, userID string, on bool) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE conversation_members SET pinned = $3 WHERE conversation_id = $1 AND user_id = $2`, convID, userID, on)
	return err
}

// SetMute 设置免打扰。
func (r *Repository) SetMute(ctx context.Context, convID, userID string, on bool) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE conversation_members SET muted = $3 WHERE conversation_id = $1 AND user_id = $2`, convID, userID, on)
	return err
}

// Hide 从我的会话列表删除（软隐藏，不删数据）。
func (r *Repository) Hide(ctx context.Context, convID, userID string) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE conversation_members SET hidden = true WHERE conversation_id = $1 AND user_id = $2`, convID, userID)
	return err
}

// Unhide 收到他人新消息时解除隐藏（供消息分发调用）。
func (r *Repository) Unhide(ctx context.Context, convID string, userIDs []string) error {
	if len(userIDs) == 0 {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE conversation_members SET hidden = false
		WHERE conversation_id = $1 AND user_id::text = ANY($2::text[]) AND hidden = true`, convID, userIDs)
	return err
}
