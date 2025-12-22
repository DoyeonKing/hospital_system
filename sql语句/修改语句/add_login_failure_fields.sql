-- =====================================================
-- 添加登录失败锁定机制相关字段
-- 为 patients、doctors、admins 三个表添加：
-- 1. failed_login_count: 登录失败次数
-- 2. last_failed_login_time: 最后一次失败登录时间
-- 3. locked_until: 锁定到期时间（用于自动解锁）
-- =====================================================

-- =====================================================
-- 1. 为 patients 表添加字段
-- =====================================================
ALTER TABLE `patients` 
ADD COLUMN `failed_login_count` INT NOT NULL DEFAULT 0 COMMENT '登录失败次数' AFTER `updated_at`,
ADD COLUMN `last_failed_login_time` TIMESTAMP NULL COMMENT '最后一次失败登录时间' AFTER `failed_login_count`,
ADD COLUMN `locked_until` TIMESTAMP NULL COMMENT '锁定到期时间（为NULL表示永久锁定，需管理员解锁）' AFTER `last_failed_login_time`;

-- =====================================================
-- 2. 为 doctors 表添加字段
-- =====================================================
ALTER TABLE `doctors` 
ADD COLUMN `failed_login_count` INT NOT NULL DEFAULT 0 COMMENT '登录失败次数' AFTER `updated_at`,
ADD COLUMN `last_failed_login_time` TIMESTAMP NULL COMMENT '最后一次失败登录时间' AFTER `failed_login_count`,
ADD COLUMN `locked_until` TIMESTAMP NULL COMMENT '锁定到期时间（为NULL表示永久锁定，需管理员解锁）' AFTER `last_failed_login_time`;

-- =====================================================
-- 3. 为 admins 表添加字段
-- =====================================================
ALTER TABLE `admins` 
ADD COLUMN `failed_login_count` INT NOT NULL DEFAULT 0 COMMENT '登录失败次数' AFTER `created_at`,
ADD COLUMN `last_failed_login_time` TIMESTAMP NULL COMMENT '最后一次失败登录时间' AFTER `failed_login_count`,
ADD COLUMN `locked_until` TIMESTAMP NULL COMMENT '锁定到期时间（为NULL表示永久锁定，需管理员解锁）' AFTER `last_failed_login_time`;

-- =====================================================
-- 验证字段添加结果
-- =====================================================
-- 检查 patients 表
-- DESCRIBE `patients`;

-- 检查 doctors 表
-- DESCRIBE `doctors`;

-- 检查 admins 表
-- DESCRIBE `admins`;

-- =====================================================
-- 功能说明
-- =====================================================
-- 1. 登录失败次数达到 5 次（Constants.MAX_LOGIN_FAILURE_COUNT）后，账户自动锁定
-- 2. 锁定时间为 30 分钟（Constants.ACCOUNT_LOCK_DURATION_MINUTES）
-- 3. 锁定到期后，账户自动解锁，状态恢复为 active
-- 4. 成功登录后，失败次数自动重置为 0
-- 5. 如果 locked_until 为 NULL，表示永久锁定，需要管理员手动解锁




