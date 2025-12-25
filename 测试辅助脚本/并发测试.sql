-- 并发测试辅助脚本
-- 用于任务8：检查容错性（是否自动重试、是否死锁）

-- ============================================
-- 并发测试场景1：并发读取
-- ============================================

-- 在多个MySQL客户端同时执行以下查询
-- 观察是否有锁等待或死锁

-- 会话1
START TRANSACTION;
SELECT * FROM users WHERE id = 1 FOR UPDATE;
-- 等待10秒
SELECT SLEEP(10);
COMMIT;

-- 会话2（在另一个MySQL客户端同时执行）
START TRANSACTION;
SELECT * FROM users WHERE id = 1 FOR UPDATE;
-- 如果会话1未提交，这里会等待
COMMIT;

-- ============================================
-- 并发测试场景2：死锁模拟
-- ============================================

-- 会话1
START TRANSACTION;
UPDATE users SET username = 'test1' WHERE id = 1;
-- 等待5秒
SELECT SLEEP(5);
UPDATE users SET username = 'test2' WHERE id = 2;
COMMIT;

-- 会话2（同时执行，但顺序相反）
START TRANSACTION;
UPDATE users SET username = 'test2' WHERE id = 2;
-- 等待5秒
SELECT SLEEP(5);
UPDATE users SET username = 'test1' WHERE id = 1;
COMMIT;

-- 如果发生死锁，MySQL会自动回滚其中一个事务

-- ============================================
-- 检查死锁日志
-- ============================================

-- 查看最近一次死锁信息
SHOW ENGINE INNODB STATUS;

-- 查看当前锁信息
SELECT 
    r.trx_id waiting_trx_id,
    r.trx_mysql_thread_id waiting_thread,
    r.trx_query waiting_query,
    b.trx_id blocking_trx_id,
    b.trx_mysql_thread_id blocking_thread,
    b.trx_query blocking_query
FROM information_schema.innodb_lock_waits w
INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;

-- ============================================
-- 检查事务状态
-- ============================================

-- 查看当前所有事务
SELECT 
    trx_id,
    trx_state,
    trx_started,
    trx_mysql_thread_id,
    trx_query
FROM information_schema.innodb_trx;

-- ============================================
-- 检查连接数
-- ============================================

-- 查看当前连接数
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- 查看进程列表
SHOW PROCESSLIST;

-- ============================================
-- 注意事项
-- ============================================
-- 1. 这些测试可能会锁定表，影响其他操作
-- 2. 建议在测试环境进行
-- 3. 测试后确保所有事务都已提交或回滚
-- 4. 如果测试卡住，可以手动KILL进程









