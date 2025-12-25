-- 修复 appointments 表缺少 payment_deadline 字段的问题
ALTER TABLE appointments ADD COLUMN payment_deadline DATETIME DEFAULT NULL COMMENT '支付截止时间（加号专用）';
















