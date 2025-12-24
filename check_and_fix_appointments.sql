-- 检查 appointments 表结构
DESCRIBE appointments;

-- 如果 payment_deadline 字段不存在，则添加它
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS payment_deadline DATETIME DEFAULT NULL COMMENT '支付截止时间（加号专用）';

-- 再次检查表结构确认
DESCRIBE appointments;














