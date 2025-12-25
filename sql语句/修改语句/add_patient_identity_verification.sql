-- 添加患者身份验证功能相关表结构

-- 1. 修改patients表，添加注册来源字段
ALTER TABLE `patients` 
ADD COLUMN `registration_source` ENUM('admin_created','self_registered') DEFAULT 'admin_created' COMMENT '注册来源：admin_created=管理员创建，self_registered=自主注册';

-- 2. 创建患者身份验证申请表
CREATE TABLE IF NOT EXISTS `patient_identity_verifications` (
  `verification_id` INT NOT NULL AUTO_INCREMENT COMMENT '验证ID',
  `patient_id` INT NOT NULL COMMENT '患者ID',
  `identifier` VARCHAR(100) NOT NULL COMMENT '学号/工号',
  `full_name` VARCHAR(100) NOT NULL COMMENT '姓名',
  `id_card_number` VARCHAR(18) NOT NULL COMMENT '身份证号',
  `phone_number` VARCHAR(20) NOT NULL COMMENT '手机号',
  `patient_type` ENUM('student','teacher','staff') NOT NULL COMMENT '患者类型',
  `identity_proof_url` VARCHAR(500) COMMENT '身份证明材料URL（如校园卡照片）',
  `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending' COMMENT '审核状态：pending=待审核，approved=已通过，rejected=已拒绝',
  `rejection_reason` TEXT COMMENT '拒绝原因',
  `reviewed_by` INT COMMENT '审核管理员ID',
  `reviewed_at` DATETIME COMMENT '审核时间',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`verification_id`),
  UNIQUE KEY `uk_patient_verification` (`patient_id`),
  KEY `idx_status` (`status`),
  KEY `idx_identifier` (`identifier`),
  CONSTRAINT `fk_verification_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_verification_admin` FOREIGN KEY (`reviewed_by`) REFERENCES `admins` (`admin_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='患者身份验证申请表';

