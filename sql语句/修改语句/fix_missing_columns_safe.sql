-- =====================================================
-- 安全修复数据库表缺少的字段（带检查，避免重复添加）
-- 解决错误: Unknown column 's1_0.is_add_on_slot' in 'field list'
-- =====================================================

-- 1. 修复 schedules 表
-- 检查并添加 is_add_on_slot 字段
SET @db_name = DATABASE();
SET @table_name = 'schedules';
SET @column_name = 'is_add_on_slot';
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND COLUMN_NAME = @column_name
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `is_add_on_slot` TINYINT(1) DEFAULT 0 COMMENT ''是否为加号虚拟号源（0=否，1=是）''',
    'SELECT ''字段 is_add_on_slot 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 reserved_for_patient_id 字段
SET @column_name = 'reserved_for_patient_id';
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND COLUMN_NAME = @column_name
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `reserved_for_patient_id` BIGINT NULL COMMENT ''预留给指定患者ID（加号专用，锁定该号源）''',
    'SELECT ''字段 reserved_for_patient_id 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 slot_application_id 字段
SET @column_name = 'slot_application_id';
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND COLUMN_NAME = @column_name
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `slot_application_id` INT NULL COMMENT ''关联的加号申请ID（追溯来源）''',
    'SELECT ''字段 slot_application_id 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加索引 idx_reserved_patient
SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND INDEX_NAME = 'idx_reserved_patient'
);

SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE `schedules` ADD INDEX `idx_reserved_patient` (`reserved_for_patient_id`)',
    'SELECT ''索引 idx_reserved_patient 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加索引 idx_slot_application
SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND INDEX_NAME = 'idx_slot_application'
);

SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE `schedules` ADD INDEX `idx_slot_application` (`slot_application_id`)',
    'SELECT ''索引 idx_slot_application 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 修复 appointments 表（带检查）
-- 检查并添加 payment_deadline 字段
SET @table_name = 'appointments';
SET @column_name = 'payment_deadline';
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND COLUMN_NAME = @column_name
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `appointments` ADD COLUMN `payment_deadline` DATETIME NULL COMMENT ''支付截止时间（加号专用，参考候补的notification_sent_at+15分钟模式）''',
    'SELECT ''字段 payment_deadline 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加索引 idx_payment_deadline
SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = @db_name
      AND TABLE_NAME = @table_name
      AND INDEX_NAME = 'idx_payment_deadline'
);

SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE `appointments` ADD INDEX `idx_payment_deadline` (`payment_deadline`)',
    'SELECT ''索引 idx_payment_deadline 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否添加成功
SELECT '=== schedules 表字段检查 ===' AS info;
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'schedules'
  AND COLUMN_NAME IN ('is_add_on_slot', 'reserved_for_patient_id', 'slot_application_id')
ORDER BY COLUMN_NAME;

SELECT '=== appointments 表字段检查 ===' AS info;
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'appointments'
  AND COLUMN_NAME = 'payment_deadline';

-- =====================================================
-- 执行说明：
-- 1. 此脚本会自动检查字段是否存在，如果已存在会跳过
-- 2. 执行后请重启 Spring Boot 后端服务
-- 3. 如果遇到其他错误，请检查相关表是否存在
-- =====================================================

