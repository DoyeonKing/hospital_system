-- ========================================
-- 添加患者档案扩展字段（安全版本）
-- 先检查字段是否存在，不存在才添加
-- 用于已有数据库的迁移更新
-- 执行日期: 2025-12-11
-- ========================================

USE hospital_db;

-- 检查并添加出生日期字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'birth_date'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `birth_date` date NULL DEFAULT NULL COMMENT ''出生日期''',
    'SELECT ''字段 birth_date 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加性别字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'gender'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `gender` enum(''male'',''female'',''other'') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT ''性别''',
    'SELECT ''字段 gender 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加家庭地址字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'home_address'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `home_address` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT ''家庭地址''',
    'SELECT ''字段 home_address 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加紧急联系人姓名字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'emergency_contact_name'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `emergency_contact_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT ''紧急联系人姓名''',
    'SELECT ''字段 emergency_contact_name 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加紧急联系人电话字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'emergency_contact_phone'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `emergency_contact_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT ''紧急联系人电话''',
    'SELECT ''字段 emergency_contact_phone 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加身高字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'height'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `height` decimal(5,2) NULL DEFAULT NULL COMMENT ''身高(cm)''',
    'SELECT ''字段 height 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加体重字段
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hospital_db' 
      AND TABLE_NAME = 'patient_profiles' 
      AND COLUMN_NAME = 'weight'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE patient_profiles ADD COLUMN `weight` decimal(5,2) NULL DEFAULT NULL COMMENT ''体重(kg)''',
    'SELECT ''字段 weight 已存在，跳过'' AS result'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证修改
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT, 
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hospital_db' 
  AND TABLE_NAME = 'patient_profiles'
ORDER BY ORDINAL_POSITION;

