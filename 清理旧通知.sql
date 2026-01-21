-- 清理旧的支付成功通知（可选）
-- 注意：执行前请确认是否需要保留这些历史通知

-- 查看所有支付成功通知
SELECT 
    notification_id,
    user_id,
    title,
    content,
    created_at
FROM notifications
WHERE type = 'payment_success'
ORDER BY created_at DESC;

-- 如果确认要删除旧的支付成功通知，取消下面的注释执行
-- DELETE FROM notifications 
-- WHERE type = 'payment_success' 
-- AND created_at < NOW();

-- 提示：删除后，用户将看不到之前的支付成功通知
-- 建议只在测试环境执行此操作

