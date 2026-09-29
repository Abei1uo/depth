-- 0002_add_reads.sql
-- 已读游标表：记录每个用户在每个会话已读到的最大 seq，用于未读数计算。
-- 幂等，可重复执行。

BEGIN;

CREATE TABLE IF NOT EXISTS conversation_reads (
    user_id         uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    conversation_id uuid NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    last_read_seq   bigint      NOT NULL DEFAULT 0,
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, conversation_id)
);

CREATE INDEX IF NOT EXISTS conversation_reads_conv_idx
    ON conversation_reads (conversation_id);

COMMIT;
