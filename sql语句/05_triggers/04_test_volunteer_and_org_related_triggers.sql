--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始测试志愿者及组织规模相关触发器 ---';
GO

-- 准备工作：创建假设的依赖对象 (存储过程和视图)，如果它们尚不存在
IF OBJECT_ID('dbo.proc_CalculateAvgActivityScoreForVolunteer', 'P') IS NULL
BEGIN
    EXEC('CREATE PROCEDURE dbo.proc_CalculateAvgActivityScoreForVolunteer @VolunteerID CHAR(15), @AvgScore DECIMAL(10,2) OUTPUT AS BEGIN SET @AvgScore = ISNULL((SELECT AVG(CONVERT(DECIMAL(10,2), OrgToVolunteerRating)) FROM tbl_VolunteerActivityParticipation WHERE VolunteerID = @VolunteerID AND OrgToVolunteerRating IS NOT NULL),0.0); END');
    PRINT N'创建了占位存储过程 proc_CalculateAvgActivityScoreForVolunteer';
END
GO
IF OBJECT_ID('dbo.proc_CalculateAvgTrainingScoreForVolunteer', 'P') IS NULL
BEGIN
    EXEC('CREATE PROCEDURE dbo.proc_CalculateAvgTrainingScoreForVolunteer @VolunteerID CHAR(15), @AvgScore DECIMAL(10,2) OUTPUT AS BEGIN SET @AvgScore = ISNULL((SELECT AVG(CONVERT(DECIMAL(10,2), OrgToVolunteerRating)) FROM tbl_VolunteerTrainingParticipation WHERE VolunteerID = @VolunteerID AND OrgToVolunteerRating IS NOT NULL),0.0); END');
    PRINT N'创建了占位存储过程 proc_CalculateAvgTrainingScoreForVolunteer';
END
GO
IF OBJECT_ID('dbo.v_VolunteerAuxiliaryRating', 'V') IS NULL
BEGIN
    EXEC('CREATE VIEW dbo.v_VolunteerAuxiliaryRating AS SELECT VolunteerID, CAST(5.0 AS DECIMAL(10,2)) AS StarRatingValue FROM tbl_Volunteer'); 
    PRINT N'创建了占位视图 v_VolunteerAuxiliaryRating (所有志愿者星级固定为5.0)';
END
GO

--------------------------------------------------------------------------------
-- 测试触发器 3.1: trg_UpdateVolunteerComprehensiveScore_Activity
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_UpdateVolunteerComprehensiveScore_Activity ---';
DECLARE @vol001_InitialRating_T31_Restore DECIMAL(10,2);
SELECT @vol001_InitialRating_T31_Restore = VolunteerRating FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_001';
DECLARE @original_act_part_rating INT;
SELECT @original_act_part_rating = OrgToVolunteerRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005'; -- 来自初始数据
PRINT N'志愿者 vol_001 初始综合评分: ' + ISNULL(CONVERT(NVARCHAR(20), @vol001_InitialRating_T31_Restore), 'NULL');

PRINT N'场景 3.1.1: 更新 vol_001 在 act_004, pos_005 的组织评分 (从8改为9)';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET OrgToVolunteerRating = 9 
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005';

PRINT N'志愿者 vol_001 更新活动评分后，综合评分:';
SELECT VolunteerRating FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_001';


-- 恢复
UPDATE dbo.tbl_Volunteer SET VolunteerRating = @vol001_InitialRating_T31_Restore WHERE VolunteerID = 'vol_001';
UPDATE dbo.tbl_VolunteerActivityParticipation SET OrgToVolunteerRating = @original_act_part_rating WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005';
PRINT N'志愿者 vol_001 综合评分及活动参与评分已尝试恢复。';
GO


--------------------------------------------------------------------------------
-- 测试触发器 3.2: trg_UpdateVolunteerComprehensiveScore_Training
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_UpdateVolunteerComprehensiveScore_Training (确保在评价窗口期内 - 最小修改版) ---';
GO

-- 将所有操作放在一个批处理中以确保变量作用域
DECLARE @vol002_InitialRating_T32_Restore DECIMAL(10,2);
DECLARE @original_trn_part_rating_T32 INT;
DECLARE @original_trn002_EndTime_T32 SMALLDATETIME; -- 新增：用于备份培训的原始结束时间

-- 1. 备份初始状态
PRINT N'--- 备份初始状态 ---';
SELECT @vol002_InitialRating_T32_Restore = VolunteerRating
FROM dbo.tbl_Volunteer
WHERE VolunteerID = 'vol_002';

IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_002')
BEGIN
    SELECT @original_trn002_EndTime_T32 = EndTime -- 备份原始结束时间
    FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_002';

    IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002')
    BEGIN
        SELECT @original_trn_part_rating_T32 = OrgToVolunteerRating
        FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';
    END
    ELSE
    BEGIN
        SET @original_trn_part_rating_T32 = NULL; -- 如果没有参与记录，原始评分为NULL
    END
END
ELSE
BEGIN
    PRINT N'错误: 测试依赖的培训 trn_002 不存在！';
    -- 为了脚本能继续，设置一个不会引起后续问题的默认值，但测试可能无意义
    SET @original_trn002_EndTime_T32 = GETDATE();
    SET @original_trn_part_rating_T32 = NULL;
END

PRINT N'志愿者 vol_002 初始综合评分: ' + ISNULL(CONVERT(NVARCHAR(20), @vol002_InitialRating_T32_Restore), 'NULL');
IF @original_trn002_EndTime_T32 IS NOT NULL
    PRINT N'培训 trn_002 原始结束时间: ' + ISNULL(CONVERT(VARCHAR(20), @original_trn002_EndTime_T32, 120), 'NULL');


-- 2. 调整培训结束时间以进入评价窗口期
IF @original_trn002_EndTime_T32 IS NOT NULL -- 仅当 trn_002 存在时操作
BEGIN
    PRINT N'临时调整培训 trn_002 的结束时间为3天前...';
    UPDATE dbo.tbl_VolunteerTraining
    SET EndTime = DATEADD(day, -3, GETDATE()) -- 设置为3天前
    WHERE TrainingID = 'trn_002';
END

-- 3. 执行核心测试：更新组织对志愿者的培训评分
PRINT N'--- 执行核心测试场景 ---';
PRINT N'场景 3.2.1: 更新 vol_002 在 trn_002 的组织评分 (从 ' + ISNULL(CONVERT(VARCHAR(10),@original_trn_part_rating_T32),'原始NULL') + N' 改为7)';
UPDATE dbo.tbl_VolunteerTrainingParticipation
SET OrgToVolunteerRating = 7
WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';

PRINT N'志愿者 vol_002 更新培训评分后，其实际参与评分变为:';
SELECT OrgToVolunteerRating FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';
PRINT N'志愿者 vol_002 更新培训评分后，其综合评分为 (预期会发生变化):';
SELECT VolunteerRating FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_002';


-- 4. 恢复数据
PRINT N'--- 恢复测试数据 ---';
-- 恢复志愿者的综合评分
IF @vol002_InitialRating_T32_Restore IS NOT NULL
    UPDATE dbo.tbl_Volunteer SET VolunteerRating = @vol002_InitialRating_T32_Restore WHERE VolunteerID = 'vol_002';

-- 恢复培训参与记录的原始评分
-- 注意：此恢复操作也会触发 trg_instead_update_training_participation。
-- 为简单起见，我们假设恢复操作时，培训时间仍然（或再次被调整到）在窗口期内，或者接受它可能被阻止。
-- 如果 @original_trn_part_rating_T32 是 NULL，恢复为 NULL 是安全的。
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002')
BEGIN
    -- 如果需要确保恢复成功，可以再次调整EndTime到窗口期，但通常恢复原始值更重要。
    -- 如果触发器逻辑是“只跳过不合规字段”，那么恢复为原始值应该没问题，除非原始值本身就不合规。
    UPDATE dbo.tbl_VolunteerTrainingParticipation
    SET OrgToVolunteerRating = @original_trn_part_rating_T32
    WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';
END

-- 最重要：恢复培训 trn_002 的原始结束时间
IF @original_trn002_EndTime_T32 IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_002')
BEGIN
    UPDATE dbo.tbl_VolunteerTraining
    SET EndTime = @original_trn002_EndTime_T32
    WHERE TrainingID = 'trn_002';
END
PRINT N'志愿者 vol_002 综合评分及培训参与评分已尝试恢复。培训 trn_002 的结束时间已尝试恢复。';
GO

--------------------------------------------------------------------------------
-- 测试触发器 3.3: trg_CalculateActivityServiceDuration
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_CalculateActivityServiceDuration ---';
DECLARE @vol001_InitialHours_T33_Restore DECIMAL(10,2);
SELECT @vol001_InitialHours_T33_Restore = TotalVolunteerHours FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_001';
DECLARE @act001_OriginalStatus_T33_Restore NVARCHAR(10);
SELECT @act001_OriginalStatus_T33_Restore = ActivityStatus FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
PRINT N'志愿者 vol_001 初始总服务时长: ' + ISNULL(CONVERT(NVARCHAR(20), @vol001_InitialHours_T33_Restore), '0');

UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = N'进行中' WHERE ActivityID = 'act_001';
UPDATE dbo.tbl_Position SET PositionServiceHours = 3 WHERE PositionID = 'pos_001' AND ActivityID = 'act_001'; 
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
    INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn) VALUES ('vol_001', 'act_001', 'pos_001', N'否');
UPDATE dbo.tbl_VolunteerActivityParticipation SET IsCheckedIn = N'是' WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';


PRINT N'场景 3.3.1: 将活动 act_001 状态更新为 "已结束"';
UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = N'已结束' WHERE ActivityID = 'act_001'; -- 使用 "已结束"

PRINT N'志愿者 vol_001 更新活动状态后，总服务时长 (应增加3小时):';
SELECT TotalVolunteerHours FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_001';


-- 清理/恢复
UPDATE dbo.tbl_Volunteer SET TotalVolunteerHours = @vol001_InitialHours_T33_Restore WHERE VolunteerID = 'vol_001';
UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = @act001_OriginalStatus_T33_Restore WHERE ActivityID = 'act_001';
-- 假设初始数据中 vol_001, act_001, pos_001 是签到的，如果不是，需要调整恢复逻辑
PRINT N'志愿者 vol_001 总服务时长和活动状态已尝试恢复。';
GO


--------------------------------------------------------------------------------
-- 测试触发器 V.1: trg_UpdateOrgSizeOnMembershipChange
--------------------------------------------------------------------------------
USE volunteer_db_test;
GO

PRINT N'--- 开始测试触发器 trg_UpdateOrgSizeOnMembershipChange ---';
GO -- 这个 GO 是可以的，用于分隔整个测试用例与其他脚本部分

-- #############################################################################
-- ## 开始一个大的批处理，包含所有声明、准备、测试和清理逻辑 ##
-- #############################################################################

PRINT N'--- 阶段 0: 准备测试数据 ---';

-- 定义测试中使用的ID (这些变量在此大批处理内都有效)
DECLARE @TestOrgID1_Size CHAR(15) = 'ORG_SIZE_T_01';
DECLARE @TestOrgID2_Size CHAR(15) = 'ORG_SIZE_T_02';
DECLARE @TestVolID1_Size CHAR(15) = 'VOL_SIZE_T_01';
DECLARE @TestVolID2_Size CHAR(15) = 'VOL_SIZE_T_02';
DECLARE @TestVolID3_Size CHAR(15) = 'VOL_SIZE_T_03';
DECLARE @TestVolID4_Size CHAR(15) = 'VOL_SIZE_T_04';

DECLARE @Org1_InitialScale INT, @Org2_InitialScale INT;

-- 清理可能存在的旧的测试组织和志愿者记录
PRINT N'清理旧的测试组织和志愿者参与记录 (如果存在)...';
DELETE FROM dbo.tbl_VolunteerOrganizationJoin WHERE OrgID IN (@TestOrgID1_Size, @TestOrgID2_Size) OR VolunteerID IN (@TestVolID1_Size, @TestVolID2_Size, @TestVolID3_Size, @TestVolID4_Size);
IF EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size) DELETE FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;
IF EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size) DELETE FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;
IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID1_Size) DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID1_Size;
IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID2_Size) DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID2_Size;
IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID3_Size) DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID3_Size;
IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID4_Size) DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID4_Size;

-- 创建测试组织
PRINT N'创建测试组织...';
INSERT INTO dbo.tbl_Organization (OrgID, OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone, ServiceRegion, OrgScale, OrgAccountStatus, OrgRating)
VALUES (@TestOrgID1_Size, N'规模测试组织一', 'org_size_usr1', 'pwd1', '130000000S1', '北京', 0, N'已认证', 5.0),
       (@TestOrgID2_Size, N'规模测试组织二', 'org_size_usr2', 'pwd2', '130000000S2', '上海', 0, N'已认证', 5.0);

-- 创建测试志愿者
PRINT N'创建测试志愿者...';
INSERT INTO dbo.tbl_Volunteer (VolunteerID, Username, Name, PhoneNumber, IDCardNumber, Password, Gender, ServiceArea)
VALUES (@TestVolID1_Size, N'vol_size1_usr', N'志愿者规模测试员1', '131000000S1', '1101012000010100S1', 'pwd', N'男', '北京'),
       (@TestVolID2_Size, N'vol_size2_usr', N'志愿者规模测试员2', '131000000S2', '1101012000010100S2', 'pwd', N'女', '上海'),
       (@TestVolID3_Size, N'vol_size3_usr', N'志愿者规模测试员3', '131000000S3', '1101012000010100S3', 'pwd', N'男', '北京'),
       (@TestVolID4_Size, N'vol_size4_usr', N'志愿者规模测试员4', '131000000S4', '1101012000010100S4', 'pwd', N'女', '上海');

SELECT @Org1_InitialScale = OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;
SELECT @Org2_InitialScale = OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;
PRINT N'组织 ' + @TestOrgID1_Size + N' 初始规模 (备份): ' + ISNULL(CONVERT(NVARCHAR(10), @Org1_InitialScale), 'NULL');
PRINT N'组织 ' + @TestOrgID2_Size + N' 初始规模 (备份): ' + ISNULL(CONVERT(NVARCHAR(10), @Org2_InitialScale), 'NULL');


PRINT N'--- 测试 1: INSERT 操作 ---';
-- 1.1 志愿者1加入组织1 (状态：已加入)
PRINT N'1.1: ' + @TestVolID1_Size + N' 加入 ' + @TestOrgID1_Size + N' (已加入)';
INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, MemberStatus)
VALUES (@TestVolID1_Size, @TestOrgID1_Size, N'已加入');
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期 +1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;

-- 1.2 志愿者2加入组织1 (状态：申请中)
PRINT N'1.2: ' + @TestVolID2_Size + N' 加入 ' + @TestOrgID1_Size + N' (申请中)';
INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, MemberStatus)
VALUES (@TestVolID2_Size, @TestOrgID1_Size, N'申请中');
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期不变，因为是申请中):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;

-- 1.3 志愿者3加入组织1 (状态：已加入)
PRINT N'1.3: ' + @TestVolID3_Size + N' 加入 ' + @TestOrgID1_Size + N' (已加入)';
INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, MemberStatus)
VALUES (@TestVolID3_Size, @TestOrgID1_Size, N'已加入');
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期再 +1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;


PRINT N'--- 测试 2: UPDATE 操作 ---';
-- 2.1 志愿者2在组织1的状态从“申请中”更新为“已加入”
PRINT N'2.1: ' + @TestVolID2_Size + N' 在 ' + @TestOrgID1_Size + N' 状态从 "申请中" -> "已加入"';
UPDATE dbo.tbl_VolunteerOrganizationJoin
SET MemberStatus = N'已加入'
WHERE VolunteerID = @TestVolID2_Size AND OrgID = @TestOrgID1_Size AND MemberStatus = N'申请中';
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期再 +1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;

-- 2.2 志愿者1在组织1的状态从“已加入”更新为“已退出”
PRINT N'2.2: ' + @TestVolID1_Size + N' 在 ' + @TestOrgID1_Size + N' 状态从 "已加入" -> "已退出"';
UPDATE dbo.tbl_VolunteerOrganizationJoin
SET MemberStatus = N'已退出'
WHERE VolunteerID = @TestVolID1_Size AND OrgID = @TestOrgID1_Size AND MemberStatus = N'已加入';
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期 -1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;

-- 2.3 志愿者4加入组织2 (已加入)，然后志愿者4也加入组织1 (已加入)
PRINT N'2.3.1: ' + @TestVolID4_Size + N' 加入 ' + @TestOrgID2_Size + N' (已加入)';
INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, MemberStatus)
VALUES (@TestVolID4_Size, @TestOrgID2_Size, N'已加入');
PRINT N'操作后，组织 ' + @TestOrgID2_Size + N' 规模 (预期为 1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;

PRINT N'2.3.2: ' + @TestVolID4_Size + N' 同时加入 ' + @TestOrgID1_Size + N' (已加入)';
INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, MemberStatus)
VALUES (@TestVolID4_Size, @TestOrgID1_Size, N'已加入');
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期再 +1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;
PRINT N'操作后，组织 ' + @TestOrgID2_Size + N' 规模 (应保持为 1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;


PRINT N'--- 测试 3: DELETE 操作 ---';
-- 当前 OrgID1 应有: Vol2(已加入), Vol3(已加入), Vol4(已加入) -> 规模 3 (如果1.1的Vol1已退出)
-- 修正：1.1 Vol1加入，1.3 Vol3加入，2.1 Vol2加入，2.2 Vol1退出，2.3.2 Vol4加入 => Org1当前成员：Vol2, Vol3, Vol4。规模应为3。
-- 当前 OrgID2 应有: Vol4(已加入) -> 规模 1

-- 3.1 删除志愿者3与组织1的“已加入”的参与记录
PRINT N'3.1: 删除 ' + @TestVolID3_Size + N' 与 ' + @TestOrgID1_Size + N' 的 "已加入" 记录';
DELETE FROM dbo.tbl_VolunteerOrganizationJoin
WHERE VolunteerID = @TestVolID3_Size AND OrgID = @TestOrgID1_Size AND MemberStatus = N'已加入';
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期 -1, 变为 2):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;

-- 3.2 删除志愿者2与组织1的“已加入”的参与记录
PRINT N'3.2: 删除 ' + @TestVolID2_Size + N' 与 ' + @TestOrgID1_Size + N' 的 "已加入" 记录';
DELETE FROM dbo.tbl_VolunteerOrganizationJoin
WHERE VolunteerID = @TestVolID2_Size AND OrgID = @TestOrgID1_Size AND MemberStatus = N'已加入';
PRINT N'操作后，组织 ' + @TestOrgID1_Size + N' 规模 (预期再 -1, 变为 1):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;


PRINT N'--- 阶段 4: 清理和恢复 ---';
-- 删除所有测试参与记录 (这会再次触发触发器，将OrgScale更新为0)
DELETE FROM dbo.tbl_VolunteerOrganizationJoin WHERE OrgID = @TestOrgID1_Size;
DELETE FROM dbo.tbl_VolunteerOrganizationJoin WHERE OrgID = @TestOrgID2_Size;

PRINT N'清理参与记录后，组织 ' + @TestOrgID1_Size + N' 规模 (预期为0):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;
PRINT N'清理参与记录后，组织 ' + @TestOrgID2_Size + N' 规模 (预期为0):';
SELECT OrgID, OrgScale FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;

-- 恢复组织的初始规模 (如果初始非0)。在这个测试中，初始规模是0，并且触发器最终也会将其设为0。
-- 如果需要精确恢复到脚本最开始备份的 @Org1_InitialScale 和 @Org2_InitialScale (如果它们那时不为0)，
-- 并且这些变量因为批处理分隔而失效，那么就需要在这里重新查询或确保它们在同一批处理中。
-- 由于本测试的初始规模是0，且清理后触发器也会将其置为0，所以这里可以省略显式恢复到初始备份值的步骤。
-- 如果您的初始数据中这些组织有非零的规模，且您希望恢复到那个值而不是0，那么需要更复杂的恢复逻辑或将所有操作放在一个批次。

-- 删除测试组织和志愿者
PRINT N'删除测试组织和志愿者...';
DELETE FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID1_Size;
DELETE FROM dbo.tbl_Organization WHERE OrgID = @TestOrgID2_Size;
DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID1_Size;
DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID2_Size;
DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID3_Size;
DELETE FROM dbo.tbl_Volunteer WHERE VolunteerID = @TestVolID4_Size;

PRINT N'--- trg_UpdateOrgSizeOnMembershipChange 测试结束 ---';
GO
-- #############################################################################
-- ## 结束大的批处理 ##
-- #############################################################################
PRINT N'--- 所有志愿者及组织规模相关触发器测试结束 ---';
GO