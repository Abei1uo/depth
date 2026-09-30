-- 0003_group_and_prefs.sql
-- 会话成员偏好（置顶/免打扰/从列表隐藏）+ 媒体对象登记表。
-- 全部幂等，可重复执行。

BEGIN;

-- 成员级偏好：置顶/免打扰是每用户各自的设置，故挂在成员表。
-- hidden=true 表示「我从会话列表中删除」，不删数据，来新消息可复位。
ALTER TABLE conversation_members
    ADD COLUMN IF NOT EXISTS pinned boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS muted  boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS hidden boolean NOT NULL DEFAULT false;

-- 富媒体对象登记（对象存储后端无关，obj_key 为桶内键）。
CREATE TABLE IF NOT EXISTS media_objects (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    uploader_id uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    obj_key     text        NOT NULL,
    mime        text        NOT NULL DEFAULT 'application/octet-stream',
    size        bigint      NOT NULL DEFAULT 0,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS media_objects_uploader_idx
    ON media_objects (uploader_id);

COMMIT;
