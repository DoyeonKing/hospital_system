--USE volunteer_web_02; -- 确保在正确的数据库上下文中执行
GO
--USE volunter_db_test

PRINT N'--- 开始测试投诉处理相关存储过程 ---';
GO

-- 准备：确保我们有一些投诉数据用于测试
-- 初始数据中已有 cmpl_001 (vol_001 投诉 org_003, 未处理) 和 cmpl_002 (vol_004 投诉 vol_001, 处理中, adm_003处理)

-- 保存 cmpl_001 和 cmpl_002 的原始状态以便后续恢复
DECLARE @OriginalCmpl001Content NVARCHAR(MAX), @OriginalCmpl001EvidenceLink NVARCHAR(255), @OriginalCmpl001Status NVARCHAR(10), @OriginalCmpl001LatestTime DATETIME;
SELECT @OriginalCmpl001Content = ComplaintContent, @OriginalCmpl001EvidenceLink = EvidenceLink, @OriginalCmpl001Status = ProcessingStatus, @OriginalCmpl001LatestTime = LatestProcessingTime
FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';

DECLARE @OriginalCmpl002Status NVARCHAR(10), @OriginalCmpl002Result NVARCHAR(MAX), @OriginalCmpl002Handler CHAR(15), @OriginalCmpl002VisitTime DATETIME, @OriginalCmpl002VisitResult NVARCHAR(20), @OriginalCmpl002ArbitrationRound INT, @OriginalCmpl002ReviewAdmin CHAR(15), @OriginalCmpl002LatestTime DATETIME;
SELECT @OriginalCmpl002Status = ProcessingStatus, @OriginalCmpl002Result = ProcessingResult, @OriginalCmpl002Handler = HandlerAdminID, @OriginalCmpl002VisitTime = VisitTime, @OriginalCmpl002VisitResult = VisitResult, @OriginalCmpl002ArbitrationRound = ArbitrationRound, @OriginalCmpl002ReviewAdmin = ReviewAdminID, @OriginalCmpl002LatestTime = LatestProcessingTime
FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

--------------------------------------------------------------------------------
-- 测试 sp_ComplainantAddInfoToComplaint (投诉人补充投诉信息)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ComplainantAddInfoToComplaint ---';

PRINT N'投诉 "cmpl_001" 补充信息前:';
SELECT ComplaintID, ComplaintContent, EvidenceLink, ProcessingStatus FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO

-- 1.1 投诉人 vol_001 为投诉 cmpl_001 补充内容和证据 (成功)
PRINT N'1.1 投诉人 "vol_001" 为投诉 "cmpl_001" 补充信息:';
EXEC dbo.sp_ComplainantAddInfoToComplaint
    @ComplainantID = 'vol_001', @ComplaintID = 'cmpl_001',
    @AdditionalContent = N'这是我补充的详细描述，情况比我最初描述的更严重。',
    @NewEvidenceLink = 'http://example.com/new_evidence.pdf';
GO
PRINT N'投诉 "cmpl_001" 补充信息后:';
SELECT ComplaintID, ComplaintContent, EvidenceLink, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO

-- 1.2 非投诉人尝试补充信息 (失败)
PRINT N'1.2 非投诉人 "vol_002" 尝试为投诉 "cmpl_001" 补充信息:';
EXEC dbo.sp_ComplainantAddInfoToComplaint
    @ComplainantID = 'vol_002', @ComplaintID = 'cmpl_001', @AdditionalContent = N'无效的补充内容。';
GO

-- 1.3 尝试为已处理完毕的投诉补充信息 (失败)
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'已仲裁' WHERE ComplaintID = 'cmpl_001';
PRINT N'1.3 尝试为已仲裁的投诉 "cmpl_001" 补充信息:';
EXEC dbo.sp_ComplainantAddInfoToComplaint
    @ComplainantID = 'vol_001', @ComplaintID = 'cmpl_001', @AdditionalContent = N'太晚了的补充。';
GO

-- 1.4 尝试不提供任何补充信息 (失败)
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'未处理' WHERE ComplaintID = 'cmpl_001'; -- 确保状态允许补充
PRINT N'1.4 尝试为投诉 "cmpl_001" 补充信息，但不提供任何内容或链接:';
EXEC dbo.sp_ComplainantAddInfoToComplaint
    @ComplainantID = 'vol_001', @ComplaintID = 'cmpl_001',
    @AdditionalContent = NULL, @NewEvidenceLink = NULL;
GO

-- 恢复 cmpl_001 状态和内容
PRINT N'恢复 cmpl_001 的原始状态和内容';
UPDATE dbo.tbl_Complaint 
SET ComplaintContent= @OriginalCmpl001Content, 
    EvidenceLink= @OriginalCmpl001EvidenceLink, 
    ProcessingStatus = @OriginalCmpl001Status, 
    LatestProcessingTime = @OriginalCmpl001LatestTime
WHERE ComplaintID = 'cmpl_001';
GO

--------------------------------------------------------------------------------
-- 测试 sp_TargetRespondToComplaint (被投诉方回应投诉)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_TargetRespondToComplaint ---';
-- 准备：管理员将 cmpl_001 转应诉
PRINT N'管理员 "adm_002" 将投诉 "cmpl_001" 转应诉:';
EXEC dbo.sp_AdminHandleComplaint @HandlingAdminID = 'adm_002', @ComplaintID = 'cmpl_001', @NewProcessingStatus = N'转应诉', @ProcessingResult = N'已通知被投诉方 org_003 进行回应。';
GO
PRINT N'投诉 "cmpl_001" 转应诉后状态:';
SELECT ComplaintID, ProcessingStatus, ProcessingResult FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO

-- 2.1 被投诉方 org_003 回应投诉 cmpl_001 (成功)
PRINT N'2.1 被投诉方 "org_003" 回应投诉 "cmpl_001":';
EXEC dbo.sp_TargetRespondToComplaint
    @RespondingTargetID = 'org_003', @ComplaintID = 'cmpl_001',
    @ResponseContent = N'我们已经收到投诉，正在积极调查所反映的招募人数问题，并将尽快给出合理解释和处理方案。';
GO
PRINT N'投诉 "cmpl_001" 回应后状态和结果 (应为 已应诉):';
SELECT ComplaintID, ProcessingStatus, ProcessingResult, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO

-- 2.2 非被投诉方尝试回应 (失败)
PRINT N'2.2 非被投诉方 "org_001" 尝试回应投诉 "cmpl_001":';
EXEC dbo.sp_TargetRespondToComplaint
    @RespondingTargetID = 'org_001', @ComplaintID = 'cmpl_001', @ResponseContent = N'无效的回应。';
GO

-- 2.3 尝试回应一个非 '转应诉' 状态的投诉 (失败)
-- cmpl_002 的状态是 '处理中' (来自初始数据)
PRINT N'2.3 尝试回应状态为 "处理中" 的投诉 "cmpl_002":';
EXEC dbo.sp_TargetRespondToComplaint
    @RespondingTargetID = 'vol_001', @ComplaintID = 'cmpl_002', @ResponseContent = N'我没有被要求回应。';
GO

-- 2.4 尝试提交空的回应内容 (失败)
-- 先将 cmpl_001 状态改回 '转应诉' 以测试此场景
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'转应诉', ProcessingResult = N'已通知被投诉方 org_003 进行回应。' WHERE ComplaintID = 'cmpl_001';
PRINT N'2.4 被投诉方 "org_003" 尝试对投诉 "cmpl_001" 提交空的回应:';
EXEC dbo.sp_TargetRespondToComplaint
    @RespondingTargetID = 'org_003', @ComplaintID = 'cmpl_001', @ResponseContent = N'   '; -- 空白回应
GO
EXEC dbo.sp_TargetRespondToComplaint
    @RespondingTargetID = 'org_003', @ComplaintID = 'cmpl_001', @ResponseContent = NULL; -- NULL回应
GO

-- 恢复 cmpl_001 状态
PRINT N'恢复 cmpl_001 的原始状态和内容';
UPDATE dbo.tbl_Complaint 
SET ComplaintContent= @OriginalCmpl001Content, 
    EvidenceLink= @OriginalCmpl001EvidenceLink, 
    ProcessingStatus = @OriginalCmpl001Status, 
    ProcessingResult = NULL, -- 清理掉测试中添加的 ProcessingResult
    LatestProcessingTime = @OriginalCmpl001LatestTime,
    HandlerAdminID = NULL -- 清理掉测试中可能的 HandlerAdminID
WHERE ComplaintID = 'cmpl_001';
GO

--------------------------------------------------------------------------------
-- 测试 sp_AdminAssignComplaintHandler (管理员指派投诉处理人)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_AdminAssignComplaintHandler ---';
IF EXISTS (SELECT 1 FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test')
    DELETE FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test';
INSERT INTO tbl_Complaint (ComplaintID, ComplaintTime, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, VisitResult)
VALUES ('cmpl_003_test', GETDATE(), 'vol_002', 'org_002', N'活动违规', N'组织org_002的活动act_002宣传图片与实际不符。(测试指派)', N'未处理', N'满意');
GO
PRINT N'投诉 "cmpl_003_test" 指派前:';
SELECT ComplaintID, HandlerAdminID, ProcessingStatus FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test';
GO

-- 3.1 管理员 adm_001 将投诉 cmpl_003_test 指派给管理员 adm_002 (成功)
PRINT N'3.1 管理员 "adm_001" 将投诉 "cmpl_003_test" 指派给 "adm_002":';
EXEC dbo.sp_AdminAssignComplaintHandler
    @AssigningAdminID = 'adm_001', @ComplaintID = 'cmpl_003_test', @NewHandlerAdminID = 'adm_002';
GO
PRINT N'投诉 "cmpl_003_test" 指派后 (状态应为 处理中):';
SELECT ComplaintID, HandlerAdminID, ProcessingStatus, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test';
GO

-- 3.2 尝试指派一个已仲裁的投诉 (失败)
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'已仲裁' WHERE ComplaintID = 'cmpl_003_test';
PRINT N'3.2 尝试指派已仲裁的投诉 "cmpl_003_test":';
EXEC dbo.sp_AdminAssignComplaintHandler
    @AssigningAdminID = 'adm_001', @ComplaintID = 'cmpl_003_test', @NewHandlerAdminID = 'adm_001';
GO
-- 清理
IF EXISTS (SELECT 1 FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test')
    DELETE FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_003_test';
GO

--------------------------------------------------------------------------------
-- 测试 sp_AdminRecordComplaintVisit (管理员记录投诉回访结果)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_AdminRecordComplaintVisit ---';
-- 准备: 将 cmpl_002 状态设为 '已应诉' (模拟被投诉方已回应)
UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = N'已应诉', 
    ProcessingResult = N'被投诉方已回应，解释了情况。', 
    HandlerAdminID = 'adm_003', -- 假设 adm_003 是处理人
    VisitTime = NULL, 
    VisitResult = N'满意' -- 重置为默认的满意，如果初始数据是这个的话
WHERE ComplaintID = 'cmpl_002';
GO
PRINT N'投诉 "cmpl_002" 回访前:';
SELECT ComplaintID, ProcessingStatus, VisitTime, VisitResult FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

-- 4.1 管理员 adm_003 记录对投诉 cmpl_002 的回访结果为 "不满意" (成功)
PRINT N'4.1 管理员 "adm_003" 记录对投诉 "cmpl_002" 的回访结果为 "不满意":';
EXEC dbo.sp_AdminRecordComplaintVisit
    @OperatingAdminID = 'adm_003', @ComplaintID = 'cmpl_002', @VisitResult = N'不满意';
GO
PRINT N'投诉 "cmpl_002" 回访后 ("不满意"):';
SELECT ComplaintID, ProcessingStatus, VisitTime, VisitResult, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

-- 4.2 尝试对 "未处理" 状态的投诉进行回访 (失败)
-- 将 cmpl_001 设置为 '未处理' 状态
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'未处理' WHERE ComplaintID = 'cmpl_001';
PRINT N'4.2 尝试对 "未处理" 状态的投诉 "cmpl_001" 进行回访:';
EXEC dbo.sp_AdminRecordComplaintVisit
    @OperatingAdminID = 'adm_001', @ComplaintID = 'cmpl_001', @VisitResult = N'满意';
GO

-- 4.3 尝试使用无效的回访结果值 (失败)
-- 将 cmpl_001 状态设为 '已应诉' 以满足前置状态条件
UPDATE dbo.tbl_Complaint SET ProcessingStatus = N'已应诉' WHERE ComplaintID = 'cmpl_001';
PRINT N'4.3 管理员 "adm_001" 尝试对投诉 "cmpl_001" 记录无效的回访结果 "未知":';
EXEC dbo.sp_AdminRecordComplaintVisit
    @OperatingAdminID = 'adm_001', @ComplaintID = 'cmpl_001', @VisitResult = N'未知';
GO

-- 恢复 cmpl_001 和 cmpl_002 的原始状态
PRINT N'恢复 cmpl_001 和 cmpl_002 的原始状态';
UPDATE dbo.tbl_Complaint 
SET ComplaintContent= @OriginalCmpl001Content, EvidenceLink= @OriginalCmpl001EvidenceLink, 
    ProcessingStatus = @OriginalCmpl001Status, ProcessingResult = NULL, 
    LatestProcessingTime = @OriginalCmpl001LatestTime, HandlerAdminID = NULL, 
    VisitTime = NULL, VisitResult = N'满意' -- 假设初始VisitResult是满意
WHERE ComplaintID = 'cmpl_001';

UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = @OriginalCmpl002Status, ProcessingResult = @OriginalCmpl002Result, 
    HandlerAdminID = @OriginalCmpl002Handler, VisitTime = @OriginalCmpl002VisitTime, 
    VisitResult = @OriginalCmpl002VisitResult, ArbitrationRound = @OriginalCmpl002ArbitrationRound, 
    ReviewAdminID = @OriginalCmpl002ReviewAdmin, LatestProcessingTime = @OriginalCmpl002LatestTime
WHERE ComplaintID = 'cmpl_002';
GO

--------------------------------------------------------------------------------
-- 测试 sp_AdminEscalateComplaint (管理员升级投诉进行仲裁/复审)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_AdminEscalateComplaint ---';
-- 准备: cmpl_002 状态为 '已应诉'，回访结果 '不满意' (接续测试4.1的结果)
UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = N'已应诉', 
    VisitResult = N'不满意', 
    VisitTime = GETDATE(), -- 假设已回访
    ArbitrationRound = NULL, -- 清空之前的仲裁信息
    ReviewAdminID = NULL,
    HandlerAdminID = 'adm_003' -- 假设adm_003是当前处理人
WHERE ComplaintID = 'cmpl_002';
PRINT N'投诉 "cmpl_002" 升级前 (已应诉, 回访不满意):';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, ReviewAdminID, HandlerAdminID FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

-- 5.1 管理员 adm_001 将投诉 cmpl_002 升级给管理员 adm_002 进行第一轮仲裁 (成功)
PRINT N'5.1 管理员 "adm_001" 将投诉 "cmpl_002" 升级给 "adm_002" 进行第一轮仲裁:';
EXEC dbo.sp_AdminEscalateComplaint
    @EscalatingAdminID = 'adm_001', @ComplaintID = 'cmpl_002',
    @NewReviewAdminID = 'adm_002', @NewArbitrationRound = 1;
GO
PRINT N'投诉 "cmpl_002" 升级后 (第一轮仲裁中):';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, ReviewAdminID, HandlerAdminID, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

-- 5.2 尝试再次将同一投诉升级到同一轮次 (失败)
PRINT N'5.2 尝试再次将投诉 "cmpl_002" 升级到第一轮仲裁:';
EXEC dbo.sp_AdminEscalateComplaint
    @EscalatingAdminID = 'adm_001', @ComplaintID = 'cmpl_002',
    @NewReviewAdminID = 'adm_001', @NewArbitrationRound = 1;
GO

-- 5.3 假设第一轮仲裁后，管理员更新状态为'已仲裁'，然后回访结果仍然是 "不满意"
UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = N'已仲裁', -- 模拟第一轮仲裁结束
    VisitResult = N'不满意',     -- 模拟回访不满意
    VisitTime = GETDATE(),
    ArbitrationRound = 1,      -- 确认当前是第一轮
    HandlerAdminID = 'adm_002',  -- 假设第一轮仲裁员是adm_002
    ReviewAdminID = 'adm_002'
WHERE ComplaintID = 'cmpl_002';
PRINT N'投诉 "cmpl_002" 模拟第一轮仲裁后、回访不满意状态:';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO
PRINT N'5.3 管理员 "adm_003" 将投诉 "cmpl_002" 升级给 "adm_001" 进行第二轮仲裁:';
EXEC dbo.sp_AdminEscalateComplaint
    @EscalatingAdminID = 'adm_003', @ComplaintID = 'cmpl_002',
    @NewReviewAdminID = 'adm_001', @NewArbitrationRound = 2;
GO
PRINT N'投诉 "cmpl_002" 第二轮升级后 (第二轮仲裁中):';
SELECT ComplaintID, ProcessingStatus, VisitResult, ArbitrationRound, ReviewAdminID, HandlerAdminID FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_002';
GO

-- 5.4 尝试升级超过最大轮次 (失败)
PRINT N'5.4 尝试将投诉 "cmpl_002" 升级到第三轮仲裁:';
EXEC dbo.sp_AdminEscalateComplaint
    @EscalatingAdminID = 'adm_001', @ComplaintID = 'cmpl_002',
    @NewReviewAdminID = 'adm_003', @NewArbitrationRound = 3;
GO

-- 最终恢复 cmpl_002 的原始状态
PRINT N'恢复 cmpl_002 的原始状态';
UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = @OriginalCmpl002Status, ProcessingResult = @OriginalCmpl002Result, 
    HandlerAdminID = @OriginalCmpl002Handler, VisitTime = @OriginalCmpl002VisitTime, 
    VisitResult = @OriginalCmpl002VisitResult, ArbitrationRound = @OriginalCmpl002ArbitrationRound, 
    ReviewAdminID = @OriginalCmpl002ReviewAdmin, LatestProcessingTime = @OriginalCmpl002LatestTime
WHERE ComplaintID = 'cmpl_002';
GO

PRINT N'--- 投诉处理相关存储过程测试结束 ---';
GO