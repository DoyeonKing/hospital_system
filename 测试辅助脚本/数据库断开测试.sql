-- 数据库断开测试辅助脚本
-- 用于任务1：模拟数据库断开，观察系统恢复能力

-- ============================================
-- 步骤1：记录当前数据库状态
-- ============================================

-- 查看当前连接数
SHOW STATUS LIKE 'Threads_connected';

-- 查看当前进程列表
SHOW PROCESSLIST;

-- 查看数据库基本信息
SELECT 
    DATABASE() as current_database,
    VERSION() as mysql_version,
    NOW() as current_time;

-- ============================================
-- 步骤2：模拟数据库断开（在MySQL客户端执行）
-- ============================================

-- 方法1：停止MySQL服务（在PowerShell中执行）
-- Stop-Service MySQL80

-- 方法2：拒绝新连接（需要root权限，谨慎使用）
-- SET GLOBAL max_connections = 0;  -- 设置为0会拒绝新连接
-- 恢复：SET GLOBAL max_connections = 151;

-- 方法3：杀死所有连接（谨慎使用，仅用于测试）
-- SELECT CONCAT('KILL ', id, ';') FROM information_schema.processlist 
-- WHERE user = 'root' AND id != CONNECTION_ID();

-- ============================================
-- 步骤3：恢复数据库连接后验证
-- ============================================

-- 验证数据库连接
SELECT 1 as connection_test;

-- 查看连接池状态
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Connections';
SHOW STATUS LIKE 'Max_used_connections';

-- 查看HikariCP连接池信息（如果启用了监控）
-- SELECT * FROM information_schema.processlist WHERE user = 'root';

-- ============================================
-- 步骤4：检查数据库表是否正常
-- ============================================

-- 检查主要表是否存在
SHOW TABLES LIKE 'users';
SHOW TABLES LIKE 'appointments';
SHOW TABLES LIKE 'doctors';

-- 测试查询
SELECT COUNT(*) as user_count FROM users LIMIT 1;
SELECT COUNT(*) as appointment_count FROM appointments LIMIT 1;

-- ============================================
-- 注意事项
-- ============================================
-- 1. 测试前请备份数据库
-- 2. 在测试环境进行，不要在生产环境执行
-- 3. 测试后检查数据完整性
-- 4. 记录断开和恢复的时间点







