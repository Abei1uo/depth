-- 0006_profile_and_announcement.sql
-- 群公告：会话级公告文本（仅群主可改，成员可见）。users 已有 nickname/avatar_url，无需新列。
-- 全部幂等，可重复执行。

BEGIN;

ALTER TABLE conversations
    ADD COLUMN IF NOT EXISTS announcement text NOT NULL DEFAULT '';

COMMIT;
