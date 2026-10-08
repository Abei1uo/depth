-- 0005_message_hidden.sql
-- 本地删除：为单个用户隐藏某条消息（仅影响自己的视图，他人不受影响）。幂等。

BEGIN;

CREATE TABLE IF NOT EXISTS message_hidden (
    conversation_id uuid NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    user_id         uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    message_id      uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    hidden_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, message_id)
);

CREATE INDEX IF NOT EXISTS message_hidden_user_conv_idx
    ON message_hidden (user_id, conversation_id);

COMMIT;
