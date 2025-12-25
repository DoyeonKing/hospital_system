-- 修改所有学号开头为 "perf" 的患者密码
-- 密码哈希值：$2a$10$SqwNSd8QneEq0sAc1phARep9nG4WWeqs7YMmbM4BZZRx/TcXF9QNe

-- 1. 先查看会更新多少条记录（可选，用于确认）
SELECT 
    patient_id,
    identifier,
    full_name,
    password_hash AS old_password_hash,
    status
FROM patients
WHERE identifier LIKE 'perf%';

-- 2. 执行更新操作
UPDATE patients 
SET password_hash = '$2a$10$SqwNSd8QneEq0sAc1phARep9nG4WWeqs7YMmbM4BZZRx/TcXF9QNe'
WHERE identifier LIKE 'perf%';

-- 3. 查看更新结果（可选，用于验证）
SELECT 
    patient_id,
    identifier,
    full_name,
    password_hash AS new_password_hash,
    status,
    updated_at
FROM patients
WHERE identifier LIKE 'perf%';

-- 4. 查看更新的记录数
SELECT 
    COUNT(*) AS updated_count
FROM patients
WHERE identifier LIKE 'perf%' 
  AND password_hash = '$2a$10$SqwNSd8QneEq0sAc1phARep9nG4WWeqs7YMmbM4BZZRx/TcXF9QNe';












