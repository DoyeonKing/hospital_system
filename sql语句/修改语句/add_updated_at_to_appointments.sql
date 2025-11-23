-- 为 appointments 表添加 updated_at 字段
-- 注意：不使用 ON UPDATE CURRENT_TIMESTAMP，因为我们要用触发器精确控制 completed 时的更新时间
ALTER TABLE `appointments` 
ADD COLUMN `updated_at` TIMESTAMP NULL DEFAULT NULL COMMENT '最后更新时间（status变为completed时由触发器更新）';

