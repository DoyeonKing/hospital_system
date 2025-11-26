-- =====================================================
-- 叫号功能快速测试SQL脚本
-- 用途：快速创建测试数据并验证叫号逻辑
-- =====================================================

-- 步骤1: 查看现有数据（了解你的数据库结构）
-- SELECT * FROM schedules LIMIT 1;
-- SELECT * FROM patients LIMIT 3;
-- SELECT * FROM appointments WHERE schedule_id = 1 LIMIT 5;

-- =====================================================
-- 步骤2: 准备测试数据（根据实际情况修改ID）
-- =====================================================

-- 假设：
-- - 排班ID: 1
-- - 排班日期: 2024-01-01
-- - 排班时段: 09:00-09:30
-- - 患者ID: 1, 2, 3, 4, 5

-- 创建5个测试预约（如果还没有的话）
-- 注意：需要先确保有对应的患者和排班
-- INSERT INTO appointments (patient_id, schedule_id, appointment_number, status, payment_status, created_at)
-- VALUES 
-- (1, 1, 1, 'scheduled', 'paid', NOW()),
-- (2, 1, 2, 'scheduled', 'paid', NOW()),
-- (3, 1, 3, 'scheduled', 'paid', NOW()),
-- (4, 1, 4, 'scheduled', 'paid', NOW()),
-- (5, 1, 5, 'scheduled', 'paid', NOW())
-- ON DUPLICATE KEY UPDATE appointment_id = appointment_id;

-- =====================================================
-- 步骤3: 模拟按时签到（测试场景1）
-- =====================================================

-- 假设排班开始时间是 09:00
-- 按时签到：09:00前后20分钟内（08:40 - 09:20）

-- 1号在 09:05 签到（按时）
UPDATE appointments 
SET check_in_time = '2024-01-01 09:05:00',
    is_on_time = 1,
    status = 'CHECKED_IN'
WHERE appointment_id = 1 AND schedule_id = 1;

-- 2号在 09:10 签到（按时）
UPDATE appointments 
SET check_in_time = '2024-01-01 09:10:00',
    is_on_time = 1,
    status = 'CHECKED_IN'
WHERE appointment_id = 2 AND schedule_id = 1;

-- 3号在 09:15 签到（按时）
UPDATE appointments 
SET check_in_time = '2024-01-01 09:15:00',
    is_on_time = 1,
    status = 'CHECKED_IN'
WHERE appointment_id = 3 AND schedule_id = 1;

-- =====================================================
-- 步骤4: 查看叫号队列（应该按序号排序：1→2→3）
-- =====================================================

-- 查看当前叫号队列状态
SELECT 
    appointment_id AS '预约ID',
    appointment_number AS '就诊序号',
    status AS '状态',
    check_in_time AS '签到时间',
    is_on_time AS '是否按时',
    called_at AS '叫号时间',
    recheck_in_time AS '重新签到时间',
    missed_call_count AS '过号次数'
FROM appointments
WHERE schedule_id = 1 
  AND status = 'CHECKED_IN'
ORDER BY 
    CASE WHEN recheck_in_time IS NOT NULL THEN 1 ELSE 0 END, -- 重新签到的排最后
    CASE WHEN is_on_time = 1 THEN 0 ELSE 1 END, -- 按时签到的优先
    CASE WHEN is_on_time = 1 THEN appointment_number ELSE 0 END, -- 按时签到的按序号
    check_in_time; -- 迟到的按签到时间

-- =====================================================
-- 步骤5: 模拟叫号
-- =====================================================

-- 叫号1号患者
UPDATE appointments 
SET called_at = NOW(),
    missed_call_count = CASE WHEN called_at IS NOT NULL THEN missed_call_count + 1 ELSE 0 END
WHERE appointment_id = 1 AND schedule_id = 1;

-- =====================================================
-- 步骤6: 模拟迟到签到（测试场景2）
-- =====================================================

-- 5号在 09:25 签到（迟到，超过20分钟）
UPDATE appointments 
SET check_in_time = '2024-01-01 09:25:00',
    is_on_time = 0,
    status = 'CHECKED_IN'
WHERE appointment_id = 5 AND schedule_id = 1;

-- 再次查看队列（应该看到：2→3→5，1号已被叫号）
-- 执行步骤4的查询语句

-- =====================================================
-- 步骤7: 模拟过号后重新签到（测试场景3）
-- =====================================================

-- 1号过号，重新签到
UPDATE appointments 
SET called_at = NULL,
    recheck_in_time = '2024-01-01 09:30:00',
    is_on_time = 0,
    missed_call_count = missed_call_count + 1
WHERE appointment_id = 1 AND schedule_id = 1;

-- 再次查看队列（应该看到：2→3→5→1，1号排在最后）
-- 执行步骤4的查询语句

-- =====================================================
-- 步骤8: 验证叫号逻辑
-- =====================================================

-- 查看下一个应该叫号的（应该是2号，因为1号已被叫号）
SELECT 
    appointment_id AS '预约ID',
    appointment_number AS '就诊序号',
    check_in_time AS '签到时间',
    is_on_time AS '是否按时',
    called_at AS '叫号时间'
FROM appointments
WHERE schedule_id = 1 
  AND status = 'CHECKED_IN'
  AND called_at IS NULL  -- 未叫号的
ORDER BY 
    CASE WHEN recheck_in_time IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN is_on_time = 1 THEN 0 ELSE 1 END,
    CASE WHEN is_on_time = 1 THEN appointment_number ELSE 0 END,
    check_in_time
LIMIT 1;

-- =====================================================
-- 步骤9: 清理测试数据（可选）
-- =====================================================

-- 如果需要清理测试数据，执行以下SQL：
-- UPDATE appointments 
-- SET check_in_time = NULL,
--     is_on_time = 0,
--     called_at = NULL,
--     recheck_in_time = NULL,
--     missed_call_count = 0,
--     status = 'scheduled'
-- WHERE schedule_id = 1;

-- =====================================================
-- 使用说明
-- =====================================================
-- 1. 根据你的实际数据修改排班ID、患者ID等
-- 2. 逐步执行SQL语句
-- 3. 每执行一步后，查看结果是否符合预期
-- 4. 同时可以通过API接口验证：
--    GET http://localhost:8080/api/appointments/schedule/1/call-queue
--    GET http://localhost:8080/api/appointments/schedule/1/next-to-call

