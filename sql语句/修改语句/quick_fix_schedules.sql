-- =====================================================
-- 快速修复：为 schedules 表添加缺失的字段
-- 解决错误: Unknown column 's1_0.is_add_on_slot' in 'field list'
-- =====================================================

-- 添加缺失的字段（如果字段已存在会报错，可以忽略）
ALTER TABLE `schedules` 
ADD COLUMN IF NOT EXISTS `is_add_on_slot` TINYINT(1) DEFAULT 0 COMMENT '是否为加号虚拟号源（0=否，1=是）',
ADD COLUMN IF NOT EXISTS `reserved_for_patient_id` BIGINT NULL COMMENT '预留给指定患者ID（加号专用，锁定该号源）',
ADD COLUMN IF NOT EXISTS `slot_application_id` INT NULL COMMENT '关联的加号申请ID（追溯来源）';

-- 添加索引（如果索引已存在会报错，可以忽略）
ALTER TABLE `schedules` 
ADD INDEX IF NOT EXISTS `idx_reserved_patient` (`reserved_for_patient_id`),
ADD INDEX IF NOT EXISTS `idx_slot_application` (`slot_application_id`);

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'schedules'
  AND COLUMN_NAME IN ('is_add_on_slot', 'reserved_for_patient_id', 'slot_application_id');

