--USE volunteer_db_test;
USE volunteer_web_05;
GO

PRINT N'--- 开始测试管理员相关存储过程 ---';
GO

--------------------------------------------------------------------------------
-- 测试 sp_AdminLogin (管理员登录)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_AdminLogin ---';
-- 1.1 成功登录 (使用AdminID)
PRINT N'尝试使用 AdminID "adm_001" 和正确密码 "adminPass1" 登录:';
EXEC dbo.sp_AdminLogin @AdminIdentifier = 'adm_001', @Password = 'adminPass1';
GO
-- 期望：返回 0，并显示管理员信息。

-- 1.3 用户不存在
PRINT N'尝试使用不存在的 AdminID "adm_999" 登录:';
EXEC dbo.sp_AdminLogin @AdminIdentifier = 'adm_999', @Password = 'anypassword';
GO
-- 期望：返回 -1，并提示管理员ID不存在。

-- 1.4 密码错误
PRINT N'尝试使用 AdminID "adm_001" 和错误密码 "wrongPass" 登录:';
EXEC dbo.sp_AdminLogin @AdminIdentifier = 'adm_001', @Password = 'wrongPass';
GO
-- 期望：返回 -2，并提示密码错误。

--------------------------------------------------------------------------------
-- 测试 sp_ChangeAdminPassword (管理员修改自己的密码)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ChangeAdminPassword ---';
-- 先查看 adm_003 的当前密码 (假设是 'liuPass3' 来自初始数据)
-- 2.1 修改密码成功
PRINT N'尝试为 "adm_003" 修改密码，旧密码 "liuPass3", 新密码 "newLiuPass456":';
EXEC dbo.sp_ChangeAdminPassword @AdminID = 'adm_003', @OldPassword = 'liuPass3', @NewPassword = 'newLiuPass456';
GO
-- 期望：返回 0。
PRINT N'验证 "adm_003" 是否能用新密码 "newLiuPass456" 登录:';
EXEC dbo.sp_AdminLogin @AdminIdentifier = 'adm_003', @Password = 'newLiuPass456';
GO

-- 2.2 旧密码错误
PRINT N'尝试为 "adm_003" 修改密码，旧密码 "wrongOldPass", 新密码 "anotherNewPass":';
EXEC dbo.sp_ChangeAdminPassword @AdminID = 'adm_003', @OldPassword = 'wrongOldPass', @NewPassword = 'anotherNewPass';
GO
-- 期望：返回 -2，并提示旧密码错误。

-- 2.3 新密码与旧密码相同
PRINT N'尝试为 "adm_003" 修改密码，新旧密码均为 "newLiuPass456":';
EXEC dbo.sp_ChangeAdminPassword @AdminID = 'adm_003', @OldPassword = 'newLiuPass456', @NewPassword = 'newLiuPass456';
GO
-- 期望：返回 -3，并提示新密码不能与旧密码相同。

-- 2.4 管理员不存在
PRINT N'尝试为不存在的管理员 "adm_999" 修改密码:';
EXEC dbo.sp_ChangeAdminPassword @AdminID = 'adm_999', @OldPassword = 'any', @NewPassword = 'anynew';
GO
-- 期望：返回 -1，并提示管理员不存在。

-- 恢复 adm_003 的密码为 liuPass3，以便其他测试或重复执行
PRINT N'恢复 "adm_003" 的密码为 "liuPass3":';
EXEC dbo.sp_ChangeAdminPassword @AdminID = 'adm_003', @OldPassword = 'newLiuPass456', @NewPassword = 'liuPass3';
GO

--------------------------------------------------------------------------------
-- 测试 sp_ReviewOrganizationRegistration (管理员审核组织机构注册申请)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ReviewOrganizationRegistration ---';
-- 查看 org_003 的当前状态 (应该是 '待认证' 来自初始数据)
PRINT N'查看 org_003 当前状态 (前):';
SELECT OrgID, OrgName, OrgAccountStatus FROM dbo.tbl_Organization WHERE OrgID = 'org_003';
GO

-- 3.1 审核通过 (设置为 已认证)
PRINT N'管理员 "adm_001" 审核组织 "org_003" 为 "已认证":';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_001', @OrgID = 'org_003', @NewStatus = N'已认证';
GO
-- 期望：返回 0。
PRINT N'查看 org_003 审核后状态 (已认证):';
SELECT OrgID, OrgName, OrgAccountStatus FROM dbo.tbl_Organization WHERE OrgID = 'org_003';
GO

-- 3.1b 审核不通过 (设置为 认证未通过)
-- 先将 org_003 状态改回 '待认证'
UPDATE dbo.tbl_Organization SET OrgAccountStatus = N'待认证' WHERE OrgID = 'org_003';
PRINT N'管理员 "adm_001" 审核组织 "org_003" 为 "认证未通过":';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_001', @OrgID = 'org_003', @NewStatus = N'认证未通过';
GO
-- 期望：返回 0。
PRINT N'查看 org_003 审核后状态 (认证未通过):';
SELECT OrgID, OrgName, OrgAccountStatus FROM dbo.tbl_Organization WHERE OrgID = 'org_003';
GO


-- 3.2 尝试审核一个非“待认证”状态的组织 (例如，再次审核org_003, 当前为 认证未通过)
PRINT N'尝试再次审核非“待认证”的组织 "org_003":';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_001', @OrgID = 'org_003', @NewStatus = N'已认证';
GO
-- 期望：返回 -2，提示状态不正确。

-- 3.3 无效的审核员ID
PRINT N'尝试使用无效的管理员ID "adm_invalid" 审核组织:';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_invalid', @OrgID = 'org_003', @NewStatus = N'已认证';
GO
-- 期望：返回 -4。

-- 3.4 组织ID不存在
PRINT N'尝试审核不存在的组织 "org_999":';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_001', @OrgID = 'org_999', @NewStatus = N'已认证';
GO
-- 期望：返回 -1。

-- 3.5 无效的新状态值
PRINT N'尝试将组织 "org_003" (先改回待认证) 审核为无效状态 "审核中":';
UPDATE dbo.tbl_Organization SET OrgAccountStatus = N'待认证' WHERE OrgID = 'org_003';
EXEC dbo.sp_ReviewOrganizationRegistration @ReviewingAdminID = 'adm_001', @OrgID = 'org_003', @NewStatus = N'审核中';
GO
-- 期望：返回 -3。
-- 存储过程中的校验是 IF @NewStatus NOT IN (N'已认证', N'认证未通过', N'冻结')。 '审核中' 不在此列。

-- 清理：将 org_003 状态恢复为初始的 '待认证'
UPDATE dbo.tbl_Organization SET OrgAccountStatus = N'待认证' WHERE OrgID = 'org_003';
GO

--------------------------------------------------------------------------------
-- 测试 sp_ReviewVolunteerActivityByAdmin (管理员审核志愿活动)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ReviewVolunteerActivityByAdmin ---';
-- 查看活动 'act_003' 的当前状态 (应该是 '待审核' 来自初始数据)
PRINT N'查看活动 "act_003" 当前状态 (前):';
SELECT ActivityID, ActivityName, ActivityStatus, ReviewerAdminID FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_003';
GO

-- 4.1 审核通过
PRINT N'管理员 "adm_002" 审核通过活动 "act_003":';
EXEC dbo.sp_ReviewVolunteerActivityByAdmin @ReviewingAdminID = 'adm_002', @ActivityID = 'act_003', @NewStatus = N'审核通过';
GO
-- 期望：返回 0。
PRINT N'查看活动 "act_003" 审核后状态和审核员:';
SELECT ActivityID, ActivityName, ActivityStatus, ReviewerAdminID FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_003';
GO
-- 清理：将 act_003 状态恢复为初始的 '待审核' 并清除审核员
UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = N'待审核', ReviewerAdminID = NULL WHERE ActivityID = 'act_003';
GO

--------------------------------------------------------------------------------
-- 测试 sp_ReviewVolunteerTrainingByAdmin (管理员审核志愿培训)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ReviewVolunteerTrainingByAdmin ---';
-- 准备一条待审核的培训数据
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01')
    DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
INSERT INTO tbl_VolunteerTraining (TrainingID, OrgID, TrainingName, Theme, StartTime, EndTime, Location, RecruitmentCount, TrainingStatus, CreationTime, ContactPersonPhone)
VALUES ('trn_test_01', 'org_001', N'待审核测试培训', N'测试主题', '2025-09-01 09:00', '2025-09-01 12:00', N'测试地点', 10, N'待审核', GETDATE(), '13000000000');
GO

PRINT N'查看新插入的培训 "trn_test_01" 当前状态:';
SELECT TrainingID, TrainingName, TrainingStatus, ReviewerAdminID FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
GO

-- 5.1 审核不通过
PRINT N'管理员 "adm_001" 审核不通过培训 "trn_test_01":';
EXEC dbo.sp_ReviewVolunteerTrainingByAdmin @ReviewingAdminID = 'adm_001', @TrainingID = 'trn_test_01', @NewStatus = N'审核不通过';
GO
-- 期望：返回 0。
PRINT N'查看培训 "trn_test_01" 审核后状态和审核员 (审核不通过):';
SELECT TrainingID, TrainingName, TrainingStatus, ReviewerAdminID FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
GO

-- 将 trn_test_01 状态改回 '待审核' 以便进行下一个测试
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'待审核', ReviewerAdminID = NULL WHERE TrainingID = 'trn_test_01';
GO

-- 5.2 审核通过 (设置为 审核通过)
PRINT N'管理员 "adm_002" 审核通过培训 "trn_test_01":';
EXEC dbo.sp_ReviewVolunteerTrainingByAdmin @ReviewingAdminID = 'adm_002', @TrainingID = 'trn_test_01', @NewStatus = N'审核通过';
GO
-- 期望：返回 0。
PRINT N'查看培训 "trn_test_01" 审核后状态和审核员 (审核通过):';
SELECT TrainingID, TrainingName, TrainingStatus, ReviewerAdminID FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
GO

-- 将 trn_test_01 状态改回 '待审核' 以便进行下一个测试
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'待审核', ReviewerAdminID = NULL WHERE TrainingID = 'trn_test_01';
GO

-- 5.3 尝试设置为无效的审核后状态 (例如 N'运行中')
PRINT N'管理员 "adm_001" 尝试将培训 "trn_test_01" 审核为 "运行中" (此状态不应由审核直接设置):';
EXEC dbo.sp_ReviewVolunteerTrainingByAdmin @ReviewingAdminID = 'adm_001', @TrainingID = 'trn_test_01', @NewStatus = N'运行中';
GO
-- 期望：返回 -3 (因为存储过程 sp_ReviewVolunteerTrainingByAdmin 中允许的审核后状态为 '审核通过', '审核不通过', '已停用')。
PRINT N'查看培训 "trn_test_01" 状态 (应仍为待审核):';
SELECT TrainingID, TrainingName, TrainingStatus, ReviewerAdminID FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
GO

-- 清理测试数据
DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_test_01';
GO


--------------------------------------------------------------------------------
-- 测试 sp_AdminHandleComplaint (管理员处理投诉)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_AdminHandleComplaint ---';
-- 查看投诉 'cmpl_001' 的当前状态 (应该是 '未处理' 来自初始数据)
PRINT N'查看投诉 "cmpl_001" 当前状态 (前):';
SELECT ComplaintID, ComplaintContent, ProcessingStatus, HandlerAdminID, ProcessingResult FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO

-- 6.1 处理投诉
PRINT N'管理员 "adm_002" 处理投诉 "cmpl_001"，状态改为 "处理中":';
EXEC dbo.sp_AdminHandleComplaint @HandlingAdminID = 'adm_002', @ComplaintID = 'cmpl_001', @NewProcessingStatus = N'处理中', @ProcessingResult = N'已联系双方了解情况。';
GO
-- 期望：返回 0。
PRINT N'查看投诉 "cmpl_001" 处理后状态和处理人:';
SELECT ComplaintID, ComplaintContent, ProcessingStatus, HandlerAdminID, ProcessingResult, LatestProcessingTime FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_001';
GO
-- 清理：将 cmpl_001 状态恢复为初始的 '未处理' 并清除处理信息
UPDATE dbo.tbl_Complaint 
SET ProcessingStatus = N'未处理', HandlerAdminID = NULL, ProcessingResult = NULL, LatestProcessingTime = NULL 
WHERE ComplaintID = 'cmpl_001';
GO

--------------------------------------------------------------------------------
-- 测试 sp_ReviewVolunteerIdentity (管理员审核志愿者身份)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ReviewVolunteerIdentity ---';
-- 查看志愿者 'vol_004' 的当前账户状态 (应该是 '未实名认证' 来自初始数据)
PRINT N'查看志愿者 "vol_004" 当前账户状态 (前):';
SELECT VolunteerID, Name, AccountStatus FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_004';
GO

-- 7.1 审核通过，状态改为“已实名认证”
PRINT N'管理员 "adm_001" 审核通过志愿者 "vol_004" 的身份:';
EXEC dbo.sp_ReviewVolunteerIdentity @ReviewingAdminID = 'adm_001', @VolunteerID = 'vol_004', @NewAccountStatus = N'已实名认证';
GO
-- 期望：返回 0。
PRINT N'查看志愿者 "vol_004" 审核后账户状态 (已实名认证):';
SELECT VolunteerID, Name, AccountStatus FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_004';
GO

-- 7.1b 审核不通过，状态改为“认证未通过”
-- 先将 vol_004 状态改回 '未实名认证'
UPDATE dbo.tbl_Volunteer SET AccountStatus = N'未实名认证' WHERE VolunteerID = 'vol_004';
PRINT N'管理员 "adm_001" 审核志愿者 "vol_004" 为 "认证未通过":';
EXEC dbo.sp_ReviewVolunteerIdentity @ReviewingAdminID = 'adm_001', @VolunteerID = 'vol_004', @NewAccountStatus = N'认证未通过';
GO
-- 期望：返回 0。
PRINT N'查看志愿者 "vol_004" 审核后账户状态 (认证未通过):';
SELECT VolunteerID, Name, AccountStatus FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_004';
GO

-- 7.2 尝试审核一个已经是“已实名认证”的志愿者 (vol_001 来自初始数据是已实名认证)
PRINT N'尝试再次审核已实名认证的志愿者 "vol_001":';
EXEC dbo.sp_ReviewVolunteerIdentity @ReviewingAdminID = 'adm_001', @VolunteerID = 'vol_001', @NewAccountStatus = N'已实名认证';
GO
-- 期望：存储过程返回提示信息（级别10），因为 vol_001 状态不是 '未实名认证' 或 '认证未通过'。

-- 7.3 无效的新状态
PRINT N'尝试将志愿者 "vol_004" (先改回未实名认证) 审核为无效状态 "审核中":';
UPDATE dbo.tbl_Volunteer SET AccountStatus = N'未实名认证' WHERE VolunteerID = 'vol_004';
EXEC dbo.sp_ReviewVolunteerIdentity @ReviewingAdminID = 'adm_001', @VolunteerID = 'vol_004', @NewAccountStatus = N'审核中';
GO
-- 期望：返回 -3 (因为存储过程 sp_ReviewVolunteerIdentity 中允许的审核后状态为 '已实名认证', '认证未通过', '已冻结')。

-- 清理：将 vol_004 状态恢复为初始的 '未实名认证'
UPDATE dbo.tbl_Volunteer SET AccountStatus = N'未实名认证' WHERE VolunteerID = 'vol_004';
GO

PRINT N'--- 管理员相关存储过程测试结束 ---';
GO