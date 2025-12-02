-- =====================================================
-- 修复 schedules 表缺少的字段
-- 解决错误: Unknown column 's1_0.is_add_on_slot' in 'field list'
-- =====================================================

-- 检查字段是否已存在，如果不存在则添加
-- 1. 添加 is_add_on_slot 字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'schedules'
      AND COLUMN_NAME = 'is_add_on_slot'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `is_add_on_slot` TINYINT(1) DEFAULT 0 COMMENT ''是否为加号虚拟号源（0=否，1=是）''',
    'SELECT ''字段 is_add_on_slot 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 添加 reserved_for_patient_id 字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'schedules'
      AND COLUMN_NAME = 'reserved_for_patient_id'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `reserved_for_patient_id` BIGINT NULL COMMENT ''预留给指定患者ID（加号专用，锁定该号源）''',
    'SELECT ''字段 reserved_for_patient_id 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 添加 slot_application_id 字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'schedules'
      AND COLUMN_NAME = 'slot_application_id'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `schedules` ADD COLUMN `slot_application_id` INT NULL COMMENT ''关联的加号申请ID（追溯来源）''',
    'SELECT ''字段 slot_application_id 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. 添加索引（如果不存在）
-- 为 reserved_for_patient_id 添加索引
SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'schedules'
      AND INDEX_NAME = 'idx_reserved_patient'
);

SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE `schedules` ADD INDEX `idx_reserved_patient` (`reserved_for_patient_id`)',
    'SELECT ''索引 idx_reserved_patient 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为 slot_application_id 添加索引
SET @idx_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'schedules'
      AND INDEX_NAME = 'idx_slot_application'
);

SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE `schedules` ADD INDEX `idx_slot_application` (`slot_application_id`)',
    'SELECT ''索引 idx_slot_application 已存在，跳过'' AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'schedules'
  AND COLUMN_NAME IN ('is_add_on_slot', 'reserved_for_patient_id', 'slot_application_id')
ORDER BY COLUMN_NAME;

-- =====================================================
-- 执行说明：
-- 1. 此脚本会自动检查字段是否存在，避免重复添加
-- 2. 如果字段已存在，会跳过并显示提示信息
-- 3. 执行后请重启 Spring Boot 后端服务
-- =====================================================

