-- 修改身份证明材料字段：从单个文件改为身份证正面和背面两个字段

-- 修改 patient_identity_verifications 表
ALTER TABLE `patient_identity_verifications` 
  DROP COLUMN `identity_proof_url`,
  ADD COLUMN `id_card_front_url` VARCHAR(500) COMMENT '身份证正面照片URL' AFTER `patient_type`,
  ADD COLUMN `id_card_back_url` VARCHAR(500) COMMENT '身份证背面照片URL' AFTER `id_card_front_url`;

