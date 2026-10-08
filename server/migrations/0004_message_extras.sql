-- 0004_message_extras.sql
-- 消息增强：撤回标记。引用回复(reply_to)与@提醒(mentions)随 content JSONB 存储，无需列。
-- 幂等，可重复执行。

BEGIN;

-- 撤回：服务端权威标记；置为 true 后客户端以「撤回」占位渲染，正文被清空。
ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS recalled boolean NOT NULL DEFAULT false;

COMMIT;
