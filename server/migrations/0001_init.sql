-- 0001_init.sql
-- Depth IM 初始表结构。纯 SQL，可用 psql 直接执行；全部语句幂等。
-- 对应后端 internal/{user,chat,message} 仓储中的列与查询。

BEGIN;

-- gen_random_uuid() 在 PostgreSQL 13+ 已内置，无需额外扩展。

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username      text        NOT NULL,
    nickname      text        NOT NULL DEFAULT '',
    avatar_url    text        NOT NULL DEFAULT '',
    password_hash text        NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS users_username_key ON users (username);

-- 会话表（type: 0 单聊 / 1 群聊）
CREATE TABLE IF NOT EXISTS conversations (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type        smallint    NOT NULL DEFAULT 0,
    name        text,
    avatar_url  text,
    owner_id    uuid REFERENCES users (id) ON DELETE SET NULL,
    last_msg_at timestamptz
);

-- 会话成员（role: 0 普通 / 2 群主）
CREATE TABLE IF NOT EXISTS conversation_members (
    conversation_id uuid NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    user_id         uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            smallint NOT NULL DEFAULT 0,
    joined_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS conversation_members_user_idx
    ON conversation_members (user_id);

-- 消息表：seq 为会话内单调递增序号（Redis INCR 生成），content 存 JSONB。
CREATE TABLE IF NOT EXISTS messages (
    id              uuid PRIMARY KEY,
    conversation_id uuid        NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    sender_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    seq             bigint      NOT NULL,
    type            smallint    NOT NULL DEFAULT 0,
    content         jsonb       NOT NULL,
    media_url       text,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS messages_conv_seq_idx
    ON messages (conversation_id, seq DESC);

COMMIT;
