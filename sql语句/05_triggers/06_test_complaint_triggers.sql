--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 1. 准备测试数据
--------------------------------------------------------------------------------

-- 清理可能存在的旧测试数据（如果需要，请谨慎操作）
-- DELETE FROM tbl_Complaint WHERE ComplaintID LIKE 'TESTC%';
-- DELETE FROM tbl_Administrator WHERE AdminID LIKE 'TESTA%';

-- 插入管理员数据
PRINT N'插入管理员数据...';
IF NOT EXISTS (SELECT 1 FROM tbl_Administrator WHERE AdminID = 'TESTA001')
    INSERT INTO tbl_Administrator (AdminID, Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, PermissionLevel, CurrentPosition)
    VALUES ('TESTA001', N'张三管理员', N'男', '110101199003070011', '13800138001', 'pass123', N'北京', N'高', N'审核监督员');
ELSE
    PRINT N'管理员 TESTA001 已存在。';

IF NOT EXISTS (SELECT 1 FROM tbl_Administrator WHERE AdminID = 'TESTA002')
    INSERT INTO tbl_Administrator (AdminID, Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, PermissionLevel, CurrentPosition)
    VALUES ('TESTA002', N'李四管理员', N'女', '110101199203080022', '13900139002', 'pass456', N'上海', N'中', N'普通管理员');
ELSE
    PRINT N'管理员 TESTA002 已存在。';
GO

-- 插入投诉数据
PRINT N'插入投诉数据...';
-- 投诉1: 用于测试基本状态变更和不满意升级 (初始状态：已应诉)
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC001')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, HandlerAdminID, VisitResult, ArbitrationRound)
    VALUES ('TESTC001', 'USER001', 'TARGET001', N'服务质量', N'对服务质量非常不满', N'已应诉', 'TESTA001', N'满意', NULL);
ELSE
    PRINT N'投诉 TESTC001 已存在。';

-- 投诉2: 用于测试不满意升级 (第1轮仲裁后不满意，应进入第2轮仲裁中)
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC002')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, HandlerAdminID, ReviewAdminID, VisitResult, ArbitrationRound)
    VALUES ('TESTC002', 'USER002', 'TARGET002', N'行为不当', N'某某行为不当', N'已仲裁', 'TESTA001', 'TESTA001', N'满意', 1);
ELSE
    PRINT N'投诉 TESTC002 已存在。';

-- 投诉3: 用于测试不满意但已达最大仲裁轮次
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC003')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, HandlerAdminID, ReviewAdminID, VisitResult, ArbitrationRound)
    VALUES ('TESTC003', 'USER003', 'TARGET003', N'活动违规', N'活动组织有违规行为', N'已仲裁', 'TESTA002', 'TESTA002', N'满意', 2);
ELSE
    PRINT N'投诉 TESTC003 已存在。';

-- 投诉4: 用于测试初始状态为“未处理”时，回访不满意的场景
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC004')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, VisitResult)
    VALUES ('TESTC004', 'USER004', 'TARGET004', N'信息虚假', N'发布的信息不真实', N'未处理', N'满意');
ELSE
    PRINT N'投诉 TESTC004 已存在。';

-- 投诉5: 用于测试初始状态为“仲裁中”时，回访不满意的场景
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC005')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, HandlerAdminID, ReviewAdminID, VisitResult, ArbitrationRound)
    VALUES ('TESTC005', 'USER005', 'TARGET005', N'其他', N'其他类型投诉', N'仲裁中', 'TESTA001', 'TESTA001', N'满意', 1);
ELSE
    PRINT N'投诉 TESTC005 已存在。';

-- 投诉6: 用于测试 TRG_Complaint_Audit_LatestProcessingTime (处理结果和处理人变更)
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC006')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, VisitResult)
    VALUES ('TESTC006', 'USER006', 'TARGET006', N'服务质量', N'投诉内容示例', N'未处理', N'满意');
ELSE
    PRINT N'投诉 TESTC006 已存在。';
GO

--------------------------------------------------------------------------------
-- 2. 测试 TRG_Complaint_Audit_LatestProcessingTime
--------------------------------------------------------------------------------
PRINT N'';
PRINT N'--- 开始测试 TRG_Complaint_Audit_LatestProcessingTime ---';

-- 场景 2.1: 更新 ProcessingStatus
PRINT N'场景 2.1: 更新 ProcessingStatus (TESTC006)';
SELECT ComplaintID, ProcessingStatus, LatestProcessingTime AS Old_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
WAITFOR DELAY '00:00:01'; -- 确保时间戳有变化
UPDATE tbl_Complaint SET ProcessingStatus = N'处理中' WHERE ComplaintID = 'TESTC006';
SELECT ComplaintID, ProcessingStatus, LatestProcessingTime AS New_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
PRINT N'期望：New_LatestProcessingTime 应晚于 Old_LatestProcessingTime 并且被更新。';
GO

-- 场景 2.2: 更新 ProcessingResult
PRINT N'场景 2.2: 更新 ProcessingResult (TESTC006)';
SELECT ComplaintID, ProcessingResult, LatestProcessingTime AS Old_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET ProcessingResult = N'初步处理意见已给出' WHERE ComplaintID = 'TESTC006';
SELECT ComplaintID, ProcessingResult, LatestProcessingTime AS New_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
PRINT N'期望：New_LatestProcessingTime 应晚于 Old_LatestProcessingTime 并且被更新。';
GO

-- 场景 2.3: 更新 HandlerAdminID
PRINT N'场景 2.3: 更新 HandlerAdminID (TESTC006)';
SELECT ComplaintID, HandlerAdminID, LatestProcessingTime AS Old_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET HandlerAdminID = 'TESTA001' WHERE ComplaintID = 'TESTC006';
SELECT ComplaintID, HandlerAdminID, LatestProcessingTime AS New_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
PRINT N'期望：New_LatestProcessingTime 应晚于 Old_LatestProcessingTime 并且被更新。';
GO

-- 场景 2.4: 更新 ComplaintContent (通常通过存储过程，但直接更新也会触发)
PRINT N'场景 2.4: 更新 ComplaintContent (TESTC006)';
SELECT ComplaintID, SUBSTRING(ComplaintContent,1,20) AS ContentStart, LatestProcessingTime AS Old_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET ComplaintContent = ComplaintContent + N' (补充一些新内容)' WHERE ComplaintID = 'TESTC006';
SELECT ComplaintID, SUBSTRING(ComplaintContent,1,30) AS ContentStart, LatestProcessingTime AS New_LatestProcessingTime FROM tbl_Complaint WHERE ComplaintID = 'TESTC006';
PRINT N'期望：New_LatestProcessingTime 应晚于 Old_LatestProcessingTime 并且被更新。';
GO

--------------------------------------------------------------------------------
-- 3. 测试 TRG_Complaint_AutoEscalateOnDissatisfaction
--------------------------------------------------------------------------------
PRINT N'';
PRINT N'--- 开始测试 TRG_Complaint_AutoEscalateOnDissatisfaction ---';

-- 场景 3.1 (应该升级): ProcessingStatus = '已应诉', ArbitrationRound IS NULL, VisitResult 更新为 '不满意'
PRINT N'场景 3.1: TESTC001 从 "已应诉", VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC001';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC001';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC001';
PRINT N'期望：ProcessingStatus 变为 "仲裁中", New_LPT 更新。';
GO

-- 场景 3.2 (应该升级): ProcessingStatus = '已仲裁', ArbitrationRound = 1, VisitResult 更新为 '不满意'
PRINT N'场景 3.2: TESTC002 从 "已仲裁" (Round 1), VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC002';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC002';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC002';
PRINT N'期望：ProcessingStatus 变为 "仲裁中" (为第2轮做准备), New_LPT 更新。';
GO

-- 场景 3.3 (不应升级 - 已达最大轮次): ArbitrationRound = 2, VisitResult 更新为 '不满意'
PRINT N'场景 3.3: TESTC003 从 "已仲裁" (Round 2), VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC003';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC003';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC003';
PRINT N'期望：ProcessingStatus 维持 "已仲裁" (因为 ArbitrationRound=2 已是最大值), New_LPT 更新 (因为 VisitResult 变化触发了第一个审计触发器)。';
GO

-- 场景 3.4 (不应升级 - 回访满意): VisitResult 更新为 '满意' (已经是满意，或者从不满意变为满意)
-- 我们先将 TESTC001 (目前应为 "仲裁中") 的 VisitResult 改回 "满意"
PRINT N'场景 3.4: TESTC001 (当前 "仲裁中") VisitResult "不满意" -> "满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC001';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'满意' WHERE ComplaintID = 'TESTC001';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC001';
PRINT N'期望：ProcessingStatus 维持 "仲裁中" (变为满意不会自动降级), New_LPT 更新。';
GO

-- 场景 3.5 (不应升级 - 初始状态不符): ProcessingStatus = '未处理', VisitResult 更新为 '不满意'
PRINT N'场景 3.5: TESTC004 从 "未处理", VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC004';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC004';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC004';
PRINT N'期望：ProcessingStatus 维持 "未处理" (因为初始状态不符合升级条件), New_LPT 更新。';
GO

-- 场景 3.6 (不应升级 - 初始状态不符): ProcessingStatus = '仲裁中', VisitResult 更新为 '不满意'
PRINT N'场景 3.6: TESTC005 从 "仲裁中", VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC005';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC005';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC005';
PRINT N'期望：ProcessingStatus 维持 "仲裁中" (因为初始状态不符合升级条件), New_LPT 更新。';
GO

-- 场景 3.7 (特殊情况): 测试ProcessingStatus = '已退回'时，VisitResult 更新为 '不满意'
-- 首先插入一条 '已退回' 的投诉数据
IF NOT EXISTS (SELECT 1 FROM tbl_Complaint WHERE ComplaintID = 'TESTC007')
    INSERT INTO tbl_Complaint (ComplaintID, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, HandlerAdminID, VisitResult, ArbitrationRound)
    VALUES ('TESTC007', 'USER007', 'TARGET007', N'其他', N'已退回案例', N'已退回', 'TESTA001', N'满意', NULL);
ELSE
    PRINT N'投诉 TESTC007 已存在。';
GO
PRINT N'场景 3.7: TESTC007 从 "已退回", VisitResult "满意" -> "不满意"';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS Old_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC007';
WAITFOR DELAY '00:00:01';
UPDATE tbl_Complaint SET VisitResult = N'不满意' WHERE ComplaintID = 'TESTC007';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, LatestProcessingTime AS New_LPT FROM tbl_Complaint WHERE ComplaintID = 'TESTC007';
PRINT N'期望：ProcessingStatus 维持 "已退回" (因触发器中 C.ProcessingStatus NOT IN (..., N''已退回'')), New_LPT 更新。';
GO


PRINT N'--- 测试结束 ---';
GO