-- ========================================
-- 添加患者档案扩展字段
-- 用于已有数据库的迁移更新
-- 执行日期: 2025-12-11
-- 注意：如果字段已存在会报错，可以忽略错误继续执行其他字段
-- 或者使用 add_patient_profile_fields_safe.sql 安全版本
-- ========================================


-- 添加出生日期字段
ALTER TABLE patient_profiles
ADD COLUMN `birth_date` date NULL DEFAULT NULL COMMENT '出生日期';

-- 添加性别字段
ALTER TABLE patient_profiles
ADD COLUMN `gender` enum('male','female','other') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '性别';

-- 添加家庭地址字段
ALTER TABLE patient_profiles
ADD COLUMN `home_address` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '家庭地址';

-- 添加紧急联系人姓名字段
ALTER TABLE patient_profiles
ADD COLUMN `emergency_contact_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '紧急联系人姓名';

-- 添加紧急联系人电话字段
ALTER TABLE patient_profiles
ADD COLUMN `emergency_contact_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '紧急联系人电话';

-- 添加身高字段
ALTER TABLE patient_profiles
ADD COLUMN `height` decimal(5,2) NULL DEFAULT NULL COMMENT '身高(cm)';

-- 添加体重字段
ALTER TABLE patient_profiles
ADD COLUMN `weight` decimal(5,2) NULL DEFAULT NULL COMMENT '体重(kg)';

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

