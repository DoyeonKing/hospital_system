--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始测试组织机构相关触发器 ---';
GO

--------------------------------------------------------------------------------
-- 测试触发器 0.1: trg_update_parent_event_overall_times
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_update_parent_event_overall_times ---';
-- 备份原始时间
DECLARE @act001_orig_start_T01 SMALLDATETIME, @act001_orig_end_T01 SMALLDATETIME;
DECLARE @trn001_orig_start_T01 SMALLDATETIME, @trn001_orig_end_T01 SMALLDATETIME;
DECLARE @tslot002_orig_end_T01 SMALLDATETIME;

SELECT @act001_orig_start_T01 = StartTime, @act001_orig_end_T01 = EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
SELECT @trn001_orig_start_T01 = StartTime, @trn001_orig_end_T01 = EndTime FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_001';
SELECT @tslot002_orig_end_T01 = EndTime FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'tslot_002' AND EventID = 'act_001';


PRINT N'活动 act_001 更新前总体时间:';
SELECT ActivityID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
PRINT N'培训 trn_001 更新前总体时间:';
SELECT TrainingID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_001';


-- 0.1.1 测试 INSERT: 为 act_001 添加一个更早的新时段
PRINT N'为 act_001 添加一个更早的新时段 (ts_ea_act01_t1):'; -- ID shortened
IF EXISTS(SELECT 1 FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_ea_act01_t1') DELETE FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_ea_act01_t1';
INSERT INTO dbo.tbl_ActivityTimeslot (TimeslotID, EventID, StartTime, EndTime)
VALUES ('ts_ea_act01_t1', 'act_001', '2025-06-10 08:00', '2025-06-10 08:30');

PRINT N'活动 act_001 在添加更早时段后总体时间 (StartTime应更新):';
SELECT ActivityID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';


-- 0.1.2 测试 UPDATE: 修改 act_001 中某个时段的结束时间，使其成为最晚结束时间
PRINT N'修改 act_001 中时段 tslot_002 的结束时间，使其更晚:';
UPDATE dbo.tbl_ActivityTimeslot SET EndTime = '2025-06-10 16:30' WHERE TimeslotID = 'tslot_002' AND EventID = 'act_001';

PRINT N'活动 act_001 在修改时段后总体时间 (EndTime应更新):';
SELECT ActivityID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';


-- 0.1.3 测试 DELETE: 删除刚才添加的导致最早开始时间的时段 ts_ea_act01_t1
PRINT N'删除 act_001 中导致最早开始时间的时段 ts_ea_act01_t1:';
DELETE FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_ea_act01_t1' AND EventID = 'act_001';

PRINT N'活动 act_001 在删除最早时段后总体时间 (StartTime应恢复):';
SELECT ActivityID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';


-- 恢复tslot_002的原始结束时间 和 活动的原始时间
UPDATE dbo.tbl_ActivityTimeslot SET EndTime = @tslot002_orig_end_T01 WHERE TimeslotID = 'tslot_002' AND EventID = 'act_001';
PRINT N'活动 act_001 的时段 tslot_002 结束时间已恢复。当前总体时间:';
SELECT ActivityID, StartTime AS OverallStartTime, EndTime AS OverallEndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
-- 注意: 如果其他时段（如初始数据中的 tslot_001）定义了act_001的原始边界，则上述恢复应正确。
-- 如果要精确恢复到 @act001_orig_start_T01, @act001_orig_end_T01，并且不依赖触发器重新计算，
-- 则需要直接更新父表，但这会跳过触发器对其他时段影响的验证。
-- UPDATE dbo.tbl_VolunteerActivity SET StartTime = @act001_orig_start_T01, EndTime = @act001_orig_end_T01 WHERE ActivityID = 'act_001';
GO


--------------------------------------------------------------------------------
-- 测试触发器 1.1: trg_update_org_activity_stats
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_update_org_activity_stats ---';
DECLARE @Org001_InitialActCount_T11_Restore INT, @Org001_InitialSvcHours_T11_Restore INT;
DECLARE @act001_OrigStatus_T11 NVARCHAR(10);
SELECT @Org001_InitialActCount_T11_Restore = ActivityCount, @Org001_InitialSvcHours_T11_Restore = TotalServiceHours FROM dbo.tbl_Organization WHERE OrgID = 'org_001';
SELECT @act001_OrigStatus_T11 = ActivityStatus FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
PRINT N'组织 org_001 操作前: ActivityCount=' + ISNULL(CONVERT(VARCHAR(10),@Org001_InitialActCount_T11_Restore),'NULL') + N', TotalServiceHours=' + ISNULL(CONVERT(VARCHAR(10),@Org001_InitialSvcHours_T11_Restore),'NULL');
-- 确保活动是进行中状态才能触发完成逻辑
IF @act001_OrigStatus_T11 <> N'进行中'
    UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = N'进行中' WHERE ActivityID = 'act_001';
PRINT N'将活动 act_001 状态从 "进行中" 更新为 "已结束":';
UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = N'已结束' WHERE ActivityID = 'act_001' AND ActivityStatus = N'进行中';

PRINT N'组织 org_001 操作后:';
SELECT OrgID, ActivityCount, TotalServiceHours FROM dbo.tbl_Organization WHERE OrgID = 'org_001';
-- 恢复
UPDATE dbo.tbl_VolunteerActivity SET ActivityStatus = @act001_OrigStatus_T11 WHERE ActivityID = 'act_001';
UPDATE dbo.tbl_Organization SET ActivityCount = @Org001_InitialActCount_T11_Restore, TotalServiceHours = @Org001_InitialSvcHours_T11_Restore WHERE OrgID = 'org_001';
GO

--------------------------------------------------------------------------------
-- 测试触发器 1.2: trg_update_org_training_count
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_update_org_training_count ---';
DECLARE @Org001_InitialTrainCount_T12_Restore INT;
DECLARE @trn001_OrigStatus_T12 NVARCHAR(10);
SELECT @Org001_InitialTrainCount_T12_Restore = TrainingCount FROM dbo.tbl_Organization WHERE OrgID = 'org_001';
SELECT @trn001_OrigStatus_T12 = TrainingStatus FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_001';
PRINT N'组织 org_001 操作前: TrainingCount=' + ISNULL(CONVERT(VARCHAR(10),@Org001_InitialTrainCount_T12_Restore),'NULL');
-- 确保培训是进行中状态才能触发完成逻辑
IF @trn001_OrigStatus_T12 <> N'进行中'
    UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'进行中' WHERE TrainingID = 'trn_001';
PRINT N'将培训 trn_001 状态从 "进行中" 更新为 "已结束":';
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'已结束' WHERE TrainingID = 'trn_001' AND TrainingStatus = N'进行中';

PRINT N'组织 org_001 操作后:';
SELECT OrgID, TrainingCount FROM dbo.tbl_Organization WHERE OrgID = 'org_001';
-- 恢复
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = @trn001_OrigStatus_T12 WHERE TrainingID = 'trn_001';
UPDATE dbo.tbl_Organization SET TrainingCount = @Org001_InitialTrainCount_T12_Restore WHERE OrgID = 'org_001';
GO

--------------------------------------------------------------------------------
-- 测试触发器 2.1: trg_update_act_planned_total_hours
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_update_act_planned_total_hours ---';
DECLARE @Act002_InitialDuration_T21_Restore INT;
SELECT @Act002_InitialDuration_T21_Restore = ActivityDurationHours FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_002';
PRINT N'活动 act_002 操作前 ActivityDurationHours: ' + ISNULL(CONVERT(VARCHAR(10), @Act002_InitialDuration_T21_Restore),'NULL');

PRINT N'为活动 act_002 添加一个2小时的新时段 ts_act02_t21r:'; -- ID shortened
IF EXISTS(SELECT 1 FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_act02_t21r') DELETE FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_act02_t21r';
INSERT INTO dbo.tbl_ActivityTimeslot (TimeslotID, EventID, StartTime, EndTime) VALUES ('ts_act02_t21r', 'act_002', '2025-06-15 07:00', '2025-06-15 09:00');

PRINT N'活动 act_002 添加新时段后 ActivityDurationHours:';
SELECT ActivityID, ActivityDurationHours FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_002';

PRINT N'修改活动 act_002 的时段 ts_act02_t21r，将其时长改为1小时:';
UPDATE dbo.tbl_ActivityTimeslot SET EndTime = '2025-06-15 08:00' WHERE TimeslotID = 'ts_act02_t21r' AND EventID = 'act_002';

PRINT N'活动 act_002 修改时段后 ActivityDurationHours:';
SELECT ActivityID, ActivityDurationHours FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_002';

PRINT N'删除活动 act_002 的时段 ts_act02_t21r (1小时):';
DELETE FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = 'ts_act02_t21r' AND EventID = 'act_002';

PRINT N'活动 act_002 删除时段后 ActivityDurationHours (应恢复为初始值，或基于剩余时段计算):';
SELECT ActivityID, ActivityDurationHours FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_002';


--------------------------------------------------------------------------------
-- 测试触发器 3.1: trg_update_activity_accepted_count
--------------------------------------------------------------------------------
USE volunteer_db_test;
GO

PRINT N'--- 测试触发器 3.1: trg_update_activity_accepted_count ---';
GO

-- 在这个批处理中完成声明、备份、测试和恢复
DECLARE @act001_InitialAccepted_T31 INT, @act001_RecruitmentCount_T31 INT;
DECLARE @app007_status_T31_Orig NVARCHAR(10), @app001_status_T31_Orig NVARCHAR(10);
DECLARE @app002_data_T31_Backup TABLE (
    ApplicationID CHAR(15) PRIMARY KEY, VolunteerID CHAR(15), ActivityID CHAR(15),
    IntendedPositionID CHAR(15), ApplicationTime DATETIME, ApplicationStatus NVARCHAR(10)
);

-- 备份初始状态 (假设 act_001, app_001, app_002, app_007 来自初始数据)
SELECT @act001_InitialAccepted_T31 = AcceptedCount, @act001_RecruitmentCount_T31 = RecruitmentCount
FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007')
    SELECT @app007_status_T31_Orig = ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007';
ELSE
    SET @app007_status_T31_Orig = N'待审核'; -- 如果不存在，假设一个初始状态用于恢复

IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_001')
    SELECT @app001_status_T31_Orig = ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_001';
ELSE
    SET @app001_status_T31_Orig = N'已通过';

IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_002')
    INSERT INTO @app002_data_T31_Backup SELECT * FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_002';

-- 确保测试前 app_007 为待审核, app_001 为已通过 (如果它们存在的话)
IF @app007_status_T31_Orig IS NOT NULL UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = N'待审核' WHERE ApplicationID = 'app_007';
IF @app001_status_T31_Orig IS NOT NULL UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = N'已通过' WHERE ApplicationID = 'app_001';
-- 如果 app_002 不存在于表中但备份了，稍后恢复时会插入；如果存在，则其状态已备份。

-- 重新计算一次初始 AcceptedCount 以确保准确
DECLARE @InitialAcceptedCountForTest INT;
SELECT @InitialAcceptedCountForTest = COUNT(*) FROM dbo.tbl_VolunteerActivityApplication WHERE ActivityID = 'act_001' AND ApplicationStatus = N'已通过';
UPDATE dbo.tbl_VolunteerActivity SET AcceptedCount = @InitialAcceptedCountForTest WHERE ActivityID = 'act_001';
SELECT @act001_InitialAccepted_T31 = AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001'; -- 更新备份值

PRINT N'活动 act_001 操作前: AcceptedCount=' + ISNULL(CONVERT(VARCHAR(10), @act001_InitialAccepted_T31), 'NULL') + N', RecruitmentCount=' + ISNULL(CONVERT(VARCHAR(10), @act001_RecruitmentCount_T31), 'NULL');

PRINT N'1. 批准活动 act_001 的报名申请 app_007 (从 待审核 -> 已通过):';
IF @app007_status_T31_Orig IS NOT NULL
    UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = N'已通过' WHERE ApplicationID = 'app_007';
ELSE
    PRINT N'警告: 测试用例依赖的 app_007 可能不存在于初始数据中。';
SELECT ActivityID, AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

PRINT N'2. 将活动 act_001 的报名申请 app_001 (从 已通过 -> 已拒绝):';
IF @app001_status_T31_Orig IS NOT NULL
    UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = N'已拒绝' WHERE ApplicationID = 'app_001';
ELSE
    PRINT N'警告: 测试用例依赖的 app_001 可能不存在于初始数据中。';
SELECT ActivityID, AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

PRINT N'3. 删除活动 act_001 的报名申请 app_002 (假设其初始为 已通过):';
IF EXISTS (SELECT 1 FROM @app002_data_T31_Backup WHERE ApplicationStatus = N'已通过')
    DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_002';
ELSE
    PRINT N'信息: app_002 在初始数据中不存在或非已通过状态，未执行删除。';
SELECT ActivityID, AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

PRINT N'4. 尝试为活动 act_001 插入超过招募人数的已通过报名 (预期触发器错误并回滚):';
DECLARE @CurrentAcceptedBeforeBulk INT;
SELECT @CurrentAcceptedBeforeBulk = AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
PRINT N'批量插入前 AcceptedCount: ' + CONVERT(VARCHAR(10), @CurrentAcceptedBeforeBulk);
PRINT N'活动 act_001 的招募人数为: ' + CONVERT(VARCHAR(10), @act001_RecruitmentCount_T31);

BEGIN TRY
    DECLARE @m_tc31 INT = 1;
    DECLARE @NumToInsertBeyondCapacity INT = (@act001_RecruitmentCount_T31 - @CurrentAcceptedBeforeBulk) + 2; -- 尝试插入比剩余容量多2个
    IF @NumToInsertBeyondCapacity < 1 SET @NumToInsertBeyondCapacity = 1; -- 至少尝试插入一个，以防万一

    PRINT N'准备批量插入 ' + CONVERT(VARCHAR(10), @NumToInsertBeyondCapacity) + N' 个“已通过”的报名...';
    -- 先清理可能存在的旧的批量插入的测试报名
    DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID LIKE 'app_blk_t31r%';

    WHILE @m_tc31 <= @NumToInsertBeyondCapacity
    BEGIN
        PRINT N'尝试插入 app_blk_t31r' + FORMAT(@m_tc31, '00');
        INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, ApplicationStatus, ApplicationTime, IntendedPositionID)
        VALUES ('app_blk_t31r' + FORMAT(@m_tc31, '00'), 'vol_003', 'act_001', N'已通过', GETDATE(), NULL); -- 假设 vol_003 存在
        SET @m_tc31 = @m_tc31 + 1;
    END
    PRINT N'批量插入循环完成（如果未被错误中断）。';
END TRY
BEGIN CATCH
    PRINT N'捕获到错误 (预期行为，因为超额录取): ' + ERROR_MESSAGE();
END CATCH;

PRINT N'活动 act_001 在尝试超额录取后的 AcceptedCount (应与批量插入前相同或接近，如果部分插入后错误):';
SELECT ActivityID, AcceptedCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

-- 清理和恢复阶段
PRINT N'--- 清理和恢复测试数据 ---';
DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID LIKE 'app_blk_t31r%'; -- 清理批量插入的记录

-- 恢复 app_007 和 app_001 的原始状态
IF @app007_status_T31_Orig IS NOT NULL
    UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = @app007_status_T31_Orig WHERE ApplicationID = 'app_007';
ELSE IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007') -- 如果测试中创建了它
    DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007';

IF @app001_status_T31_Orig IS NOT NULL
    UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = @app001_status_T31_Orig WHERE ApplicationID = 'app_001';
ELSE IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_001')
    DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_001';

-- 恢复 app_002 (如果它在测试开始时存在并且被删除了)
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_002') AND (SELECT COUNT(*) FROM @app002_data_T31_Backup) > 0
BEGIN
    PRINT N'恢复已删除的 app_002 数据...';
    INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus)
    SELECT ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus FROM @app002_data_T31_Backup;
END
ELSE IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_002') AND (SELECT COUNT(*) FROM @app002_data_T31_Backup) > 0
BEGIN
    PRINT N'app_002 未被删除，尝试恢复其原始状态 (如果备份中有)...';
    UPDATE vaa
    SET vaa.ApplicationStatus = bak.ApplicationStatus
    FROM dbo.tbl_VolunteerActivityApplication vaa
    JOIN @app002_data_T31_Backup bak ON vaa.ApplicationID = bak.ApplicationID
    WHERE vaa.ApplicationID = 'app_002';
END


-- 最终，重新计算并设置 act_001 的 AcceptedCount，以确保恢复到准确状态
DECLARE @FinalRecalculatedAcceptedCount_T31 INT;
SELECT @FinalRecalculatedAcceptedCount_T31 = COUNT(*)
FROM dbo.tbl_VolunteerActivityApplication
WHERE ActivityID = 'act_001' AND ApplicationStatus = N'已通过';

UPDATE dbo.tbl_VolunteerActivity
SET AcceptedCount = @FinalRecalculatedAcceptedCount_T31
WHERE ActivityID = 'act_001';

PRINT N'活动 act_001 在所有测试和恢复操作完成后的最终 AcceptedCount: ' + ISNULL(CONVERT(VARCHAR(10), @FinalRecalculatedAcceptedCount_T31), 'NULL');
SELECT ActivityID, AcceptedCount, RecruitmentCount FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
GO

PRINT N'--- trg_update_activity_accepted_count 测试结束 ---';
GO

--------------------------------------------------------------------------------
-- 测试触发器 3.2: trg_update_position_recruited_count
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_update_position_recruited_count ---';
DECLARE @pos001_InitialRecruited_T32_Restore INT, @pos002_InitialRecruited_T32_Restore INT;
SELECT @pos001_InitialRecruited_T32_Restore = RecruitedVolunteers FROM dbo.tbl_Position WHERE PositionID = 'pos_001' AND ActivityID = 'act_001';
SELECT @pos002_InitialRecruited_T32_Restore = RecruitedVolunteers FROM dbo.tbl_Position WHERE PositionID = 'pos_002' AND ActivityID = 'act_001';
PRINT N'岗位 pos_001 (活动 act_001) 操作前 RecruitedVolunteers: ' + ISNULL(CONVERT(VARCHAR(10), @pos001_InitialRecruited_T32_Restore), 'NULL');
PRINT N'岗位 pos_002 (活动 act_001) 操作前 RecruitedVolunteers: ' + ISNULL(CONVERT(VARCHAR(10), @pos002_InitialRecruited_T32_Restore), 'NULL');

PRINT N'为岗位 pos_001 (活动 act_001) 新增参与者 vol_t32_tmp04:'; -- ID shortened
-- 重要: 假设志愿者 'vol_t32_tmp04' 已存在于 tbl_Volunteer。如果不存在，以下 INSERT 会因外键约束失败。
-- 你可能需要在此处添加 INSERT INTO dbo.tbl_Volunteer (VolunteerID, ...) VALUES ('vol_t32_tmp04', ...);
PRINT N'为岗位 pos_001 (活动 act_001) 新增参与者 vol_t32_tmp04:'; -- ID shortened

-- **新增部分：确保测试志愿者 'vol_t32_tmp04' 存在于 tbl_Volunteer 表中**
-- 首先检查是否存在，如果不存在则插入。
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_t32_tmp04')
BEGIN
    PRINT N'创建临时测试志愿者 vol_t32_tmp04 ...';
    INSERT INTO dbo.tbl_Volunteer (
        VolunteerID, Username, Name, PhoneNumber, IDCardNumber, Password,
        Gender, ServiceArea, -- 其他 NOT NULL 且没有默认值的列也需要提供
        Country, Ethnicity, PoliticalStatus, HighestEducation, EmploymentStatus, ServiceCategory, AccountStatus -- 这些有默认值或允许NULL，但最好显式提供以确保完整性
    ) VALUES (
        'vol_t32_tmp04',          -- VolunteerID (CHAR(15))
        N'user_t32_tmp04',        -- Username (NVARCHAR(20), UNIQUE) - 确保唯一
        N'测试临时志愿者04',     -- Name (NVARCHAR(20))
        '13000003204',            -- PhoneNumber (VARCHAR(11), UNIQUE) - 确保唯一
        '110101202506023204',     -- IDCardNumber (VARCHAR(18), UNIQUE) - 确保唯一
        N'password_tmp04',        -- Password (NVARCHAR(50))
        N'男',                     -- Gender (NCHAR(1))
        N'北京',                   -- ServiceArea (NVARCHAR(50)) - 从 CHECK 约束中选择一个有效值
        DEFAULT,                  -- Country (有默认值 N'中国')
        DEFAULT,                  -- Ethnicity (有默认值 N'汉族')
        DEFAULT,                  -- PoliticalStatus (有默认值 N'群众')
        N'大学本科',               -- HighestEducation (从 CHECK 约束中选择一个有效值，或设为NULL如果允许)
        N'学生',                   -- EmploymentStatus (从 CHECK 约束中选择一个有效值，或设为NULL如果允许)
        N'社区志愿者',             -- ServiceCategory (从 CHECK 约束中选择一个有效值，或设为NULL如果允许)
        DEFAULT                   -- AccountStatus (有默认值 N'未实名认证')
    );
    PRINT N'临时测试志愿者 vol_t32_tmp04 已创建。';
END
ELSE
BEGIN
    PRINT N'临时测试志愿者 vol_t32_tmp04 已存在。';
END
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_t32_tmp04' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
    DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_t32_tmp04' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn) VALUES ('vol_t32_tmp04', 'act_001', 'pos_001', N'否');

PRINT N'岗位 pos_001 (活动 act_001) 新增参与者后 RecruitedVolunteers:';
SELECT PositionID, RecruitedVolunteers FROM dbo.tbl_Position WHERE PositionID = 'pos_001' AND ActivityID = 'act_001';

PRINT N'从岗位 pos_001 (活动 act_001) 移除参与者 vol_001 (来自初始数据):';
-- 确保 vol_001 的参与记录存在以便删除
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
    INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, OrgToVolunteerRating, VolunteerToOrgRating) VALUES ('vol_001', 'act_001', 'pos_001', N'是',9,9);
DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';

PRINT N'岗位 pos_001 (活动 act_001) 移除参与者后 RecruitedVolunteers:';
SELECT PositionID, RecruitedVolunteers FROM dbo.tbl_Position WHERE PositionID = 'pos_001' AND ActivityID = 'act_001';

-- Cleanup/Restore
DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_t32_tmp04' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
-- 恢复 vol_001 的参与记录 (如果它最初是存在的)
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
    INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating) 
    VALUES ('vol_001', 'act_001', 'pos_001', N'是', 9, 9); 
-- 准确恢复 RecruitedVolunteers 计数
DECLARE @Recalculated_pos001_T32_Restore INT;
SELECT @Recalculated_pos001_T32_Restore = COUNT(DISTINCT VolunteerID) FROM dbo.tbl_VolunteerActivityParticipation WHERE ActivityID='act_001' AND ActualPositionID='pos_001';
UPDATE dbo.tbl_Position SET RecruitedVolunteers = @Recalculated_pos001_T32_Restore WHERE ActivityID='act_001' AND PositionID='pos_001';
PRINT N'岗位 pos_001 (活动 act_001) 清理恢复后 RecruitedVolunteers:';
SELECT PositionID, RecruitedVolunteers FROM dbo.tbl_Position WHERE PositionID = 'pos_001' AND ActivityID = 'act_001';
GO

--------------------------------------------------------------------------------
-- 测试触发器 4.1: trg_check_activity_application_time_conflict
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_check_activity_application_time_conflict ---';
-- 准备: vol_001 已确认参与活动 act_001 (2025-06-10 09:00 - 12:00)
-- 确保 act_001 和 vol_001 参与数据符合预期 (来自初始数据或此处设定)
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001')
BEGIN
    PRINT N'警告: 测试4.1依赖 vol_001 参与 act_001 的数据，正在尝试插入。确保pos_001属于act_001';
    -- 假设 pos_001 属于 act_001
    INSERT INTO dbo.tbl_VolunteerActivityParticipation(VolunteerID, ActivityID, ActualPositionID, IsCheckedIn) VALUES ('vol_001', 'act_001', 'pos_001', N'是');
END
UPDATE dbo.tbl_VolunteerActivity SET StartTime = '2025-06-10 09:00', EndTime = '2025-06-10 12:00' WHERE ActivityID = 'act_001';


-- 4.1.1 尝试报名一个与 act_001 时间部分重叠的新活动 (预期失败)
PRINT N'4.1.1 志愿者 vol_001 尝试报名与 act_001 时间重叠的新活动 act_cnf01_t41r:'; -- ID shortened
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnf01_t41r') DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnf01_t41r';
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnf01_t41r') DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnf01_t41r';
INSERT INTO dbo.tbl_VolunteerActivity (ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, CreationTime, ContactPersonPhone)
VALUES ('act_cnf01_t41r', 'org_002', N'时间冲突活动01', '2025-06-10 11:00', '2025-06-10 14:00', N'某地', 10, N'审核通过', GETDATE(), '13912345678');
BEGIN TRY
    INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, ApplicationTime, ApplicationStatus)
    VALUES ('app_cnf01_t41r', 'vol_001', 'act_cnf01_t41r', GETDATE(), N'待审核');
END TRY BEGIN CATCH PRINT N'捕获到错误 (预期行为): ' + ERROR_MESSAGE(); END CATCH;
SELECT * FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnf01_t41r'; 
DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnf01_t41r';
DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnf01_t41r';


-- 4.1.2 尝试报名一个时间不冲突的新活动 (预期成功)
PRINT N'4.1.2 志愿者 vol_001 尝试报名时间不冲突的新活动 act_nocnf_t41r:'; -- ID shortened
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_nocnf_t41r') DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_nocnf_t41r';
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_nocnf_t41r') DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_nocnf_t41r';
INSERT INTO dbo.tbl_VolunteerActivity (ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, CreationTime, ContactPersonPhone)
VALUES ('act_nocnf_t41r', 'org_002', N'时间不冲突活动', '2025-06-11 09:00', '2025-06-11 12:00', N'某地', 10, N'审核通过', GETDATE(), '13912345678');
INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, ApplicationTime, ApplicationStatus)
VALUES ('app_nocnf_t41r', 'vol_001', 'act_nocnf_t41r', GETDATE(), N'待审核');
SELECT * FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_nocnf_t41r';
DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_nocnf_t41r';
DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_nocnf_t41r';


-- 4.1.3 测试活动报名与现有有效培训冲突
PRINT N'4.1.3 志愿者 vol_001 尝试报名与培训 trn_001 (2025-06-20 14:00-17:00, 进行中) 时间重叠的新活动 act_cnftrn_t41:'; -- ID shortened
-- 确保 vol_001 参与 trn_001 且 trn_001 是进行中
IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_001' AND TrainingID = 'trn_001')
    INSERT INTO dbo.tbl_VolunteerTrainingParticipation (VolunteerID, TrainingID, IsCheckedIn) VALUES ('vol_001', 'trn_001', N'否');
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'进行中', StartTime = '2025-06-20 14:00', EndTime = '2025-06-20 17:00' WHERE TrainingID = 'trn_001';

IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnftrn_t41') DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnftrn_t41';
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnftrn_t41') DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnftrn_t41';
INSERT INTO dbo.tbl_VolunteerActivity (ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, CreationTime, ContactPersonPhone)
VALUES ('act_cnftrn_t41', 'org_002', N'与培训冲突活动', '2025-06-20 16:00', '2025-06-20 18:00', N'某地', 10, N'审核通过', GETDATE(), '13912345678');
BEGIN TRY
    INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, ApplicationTime, ApplicationStatus)
    VALUES ('app_cnftrn_t41', 'vol_001', 'act_cnftrn_t41', GETDATE(), N'待审核');
END TRY BEGIN CATCH PRINT N'捕获到错误 (预期行为): ' + ERROR_MESSAGE(); END CATCH;
SELECT * FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnftrn_t41'; 
DELETE FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_cnftrn_t41';
DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_cnftrn_t41';
-- 恢复 trn_001 的状态和参与 (假设初始状态和参与情况)
UPDATE dbo.tbl_VolunteerTraining SET TrainingStatus = N'进行中' WHERE TrainingID = 'trn_001'; -- Or original status
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_001' AND TrainingID = 'trn_001' AND IsCheckedIn = N'否')
    DELETE FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_001' AND TrainingID = 'trn_001';
-- If vol_001 was originally participating with IsCheckedIn = N'是', re-insert that if needed.
GO

USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
GO

--------------------------------------------------------------------------------
-- 测试触发器 4.2: trg_check_training_participation_time_conflict
-- 作用：当志愿者尝试参与一个培训时，检查该培训时间是否与其已参与的其他活动或培训时间冲突。
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_check_training_participation_time_conflict ---';
GO

-- 在一个批处理中完成准备、测试和清理
DECLARE @act001_OrigStartTime_T42 SMALLDATETIME, @act001_OrigEndTime_T42 SMALLDATETIME;
DECLARE @vol002_act001_pos001_participation_exists BIT = 0;

-- 备份 act_001 的原始时间
SELECT @act001_OrigStartTime_T42 = StartTime, @act001_OrigEndTime_T42 = EndTime
FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';

-- 准备条件: 确保 vol_002 已确认参与活动 act_001 (特定时间段，特定岗位)
PRINT N'准备测试条件：确保 vol_002 参与了活动 act_001 (岗位 pos_001) 在 2025-06-10 09:00 - 12:00';
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
BEGIN
    SET @vol002_act001_pos001_participation_exists = 1;
    -- 更新其 IsCheckedIn 状态以确保记录是“有效”的参与（如果触发器逻辑考虑这个）
    UPDATE dbo.tbl_VolunteerActivityParticipation SET IsCheckedIn = N'是'
    WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
END
ELSE
BEGIN
    PRINT N'为测试插入 vol_002 参与 act_001 (pos_001) 的记录...';
    -- 假设 pos_001 属于 act_001
    INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn)
    VALUES ('vol_002', 'act_001', 'pos_001', N'是');
END
-- 确保 act_001 的时间是我们测试冲突所期望的时间
UPDATE dbo.tbl_VolunteerActivity
SET StartTime = '2025-06-10 09:00', EndTime = '2025-06-10 12:00'
WHERE ActivityID = 'act_001';
GO

-- 测试用例 4.2.1: 尝试为 vol_002 添加一个与 act_001 时间冲突的新培训参与 (预期失败)
PRINT N'--- 4.2.1: vol_002 尝试参与与活动 act_001 (09:00-12:00) 时间重叠的新培训 trn_cnf_act_t42 (10:00-13:00) ---';

-- 清理可能存在的旧测试培训和参与记录
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_cnf_act_t42')
    DELETE FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_cnf_act_t42';
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_cnf_act_t42')
    DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_cnf_act_t42';

-- 插入一个时间冲突的测试培训 (假设 org_001 已存在且已认证)
INSERT INTO dbo.tbl_VolunteerTraining (
    TrainingID, OrgID, TrainingName, Theme, StartTime, EndTime, Location,
    RecruitmentCount, TrainingStatus, CreationTime, ContactPersonPhone, IsRatingAggregated
)
VALUES (
    'trn_cnf_act_t42', 'org_001', N'与活动冲突培训T42', N'冲突测试主题',
    '2025-06-10 10:00', '2025-06-10 13:00', -- 这个时间段与 act_001 (09:00-12:00) 重叠
    N'培训地点X', 10, N'审核通过', GETDATE(), '13811223344', 'NO'
);

BEGIN TRY
    PRINT N'尝试插入 vol_002 对培训 trn_cnf_act_t42 的参与记录 (预期失败)...';
    INSERT INTO dbo.tbl_VolunteerTrainingParticipation (VolunteerID, TrainingID, IsCheckedIn)
    VALUES ('vol_002', 'trn_cnf_act_t42', N'否');
    PRINT N'错误：预期因时间冲突导致 INSERT 失败，但操作似乎成功了。';
END TRY
BEGIN CATCH
    PRINT N'捕获到错误 (预期行为，因为时间冲突): ' + ERROR_MESSAGE();
END CATCH;

PRINT N'检查 vol_002 是否参与了冲突培训 trn_cnf_act_t42 (预期为空):';
SELECT * FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_cnf_act_t42';
GO

-- 测试用例 4.2.2: 尝试为 vol_002 添加一个时间不冲突的新培训参与 (预期成功)
PRINT N'--- 4.2.2: vol_002 尝试参与与活动 act_001 (09:00-12:00) 时间不冲突的新培训 trn_nocnf_t42 (14:00-17:00) ---';

-- 清理可能存在的旧测试培训和参与记录
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_nocnf_t42')
    DELETE FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_nocnf_t42';
IF EXISTS(SELECT 1 FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_nocnf_t42')
    DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_nocnf_t42';

-- 插入一个时间不冲突的测试培训
INSERT INTO dbo.tbl_VolunteerTraining (
    TrainingID, OrgID, TrainingName, Theme, StartTime, EndTime, Location,
    RecruitmentCount, TrainingStatus, CreationTime, ContactPersonPhone, IsRatingAggregated
)
VALUES (
    'trn_nocnf_t42', 'org_001', N'无冲突培训T42', N'无冲突主题',
    '2025-06-10 14:00', '2025-06-10 17:00', -- 这个时间段与 act_001 (09:00-12:00) 不重叠
    N'培训地点Y', 10, N'审核通过', GETDATE(), '13811223355', 'NO'
);

BEGIN TRY
    PRINT N'尝试插入 vol_002 对培训 trn_nocnf_t42 的参与记录 (预期成功)...';
    INSERT INTO dbo.tbl_VolunteerTrainingParticipation (VolunteerID, TrainingID, IsCheckedIn)
    VALUES ('vol_002', 'trn_nocnf_t42', N'是');
    PRINT N'vol_002 成功参与无冲突培训 trn_nocnf_t42。';
END TRY
BEGIN CATCH
    PRINT N'捕获到错误 (非预期行为，此处应成功): ' + ERROR_MESSAGE();
END CATCH;

PRINT N'检查 vol_002 是否参与了无冲突培训 trn_nocnf_t42 (预期有一条记录):';
SELECT * FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_nocnf_t42';
GO


-- 清理阶段：删除为本测试用例创建的临时数据，并恢复原始数据
PRINT N'--- 清理测试用例 4.2 的数据 ---';
DECLARE @act001_OrigStartTime_T42_restore SMALLDATETIME, @act001_OrigEndTime_T42_restore SMALLDATETIME;
DECLARE @vol002_act001_pos001_participation_exists_restore BIT = 0;

-- 再次获取原始值以确保在同一批处理中
SELECT @act001_OrigStartTime_T42_restore = StartTime, @act001_OrigEndTime_T42_restore = EndTime
FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001')
    SET @vol002_act001_pos001_participation_exists_restore = 1;


-- 删除测试培训及其参与记录
DELETE FROM dbo.tbl_VolunteerTrainingParticipation WHERE TrainingID = 'trn_cnf_act_t42';
DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_cnf_act_t42';
DELETE FROM dbo.tbl_VolunteerTrainingParticipation WHERE TrainingID = 'trn_nocnf_t42';
DELETE FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_nocnf_t42';

-- 恢复活动 act_001 的原始时间
UPDATE dbo.tbl_VolunteerActivity
SET StartTime = @act001_OrigStartTime_T42_restore, EndTime = @act001_OrigEndTime_T42_restore
WHERE ActivityID = 'act_001';
PRINT N'活动 act_001 的时间已尝试恢复到: Start=' + ISNULL(CONVERT(VARCHAR(20),@act001_OrigStartTime_T42_restore,120),'NULL') + N', End=' + ISNULL(CONVERT(VARCHAR(20),@act001_OrigEndTime_T42_restore,120),'NULL');

-- 如果 vol_002 对 act_001 的参与记录是本测试创建的，则删除；否则，假设它来自初始数据并保留（或恢复其原始 IsCheckedIn 状态）
IF @vol002_act001_pos001_participation_exists_restore = 0 -- 如果原始不存在，则我们创建了它
    AND EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001') -- 再次检查以防万一
BEGIN
    PRINT N'删除为测试4.2添加的 vol_002 参与 act_001 的记录...';
    DELETE FROM dbo.tbl_VolunteerActivityParticipation
    WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
END
ELSE IF @vol002_act001_pos001_participation_exists_restore = 1
BEGIN
    PRINT N'vol_002 参与 act_001 的记录是初始数据的一部分，不在此处删除 (或根据需要恢复其原始IsCheckedIn状态)。';
    -- 例如，如果知道原始 IsCheckedIn 状态，可以恢复：
    -- UPDATE dbo.tbl_VolunteerActivityParticipation SET IsCheckedIn = N'原始状态' WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
END

PRINT N'--- trg_check_training_participation_time_conflict 测试结束 ---';
GO

--------------------------------------------------------------------------------
-- 测试触发器 5.1: trg_manage_volunteer_org_membership
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_manage_volunteer_org_membership ---';
DECLARE @app003_OriginalStatus_T51 NVARCHAR(10);
DECLARE @act001_OriginalStartTime_T51 SMALLDATETIME;
DECLARE @vol004_org001_OrigStatus NVARCHAR(3);

-- 备份原始状态
SELECT @app003_OriginalStatus_T51 = ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_003';
SELECT @act001_OriginalStartTime_T51 = StartTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
SELECT @vol004_org001_OrigStatus = MemberStatus FROM dbo.tbl_VolunteerOrganizationJoin WHERE VolunteerID = 'vol_004' AND OrgID = 'org_001';

-- 准备测试条件
UPDATE dbo.tbl_VolunteerOrganizationJoin SET MemberStatus = N'已加入' WHERE VolunteerID = 'vol_004' AND OrgID = 'org_001';
UPDATE dbo.tbl_VolunteerActivity SET StartTime = DATEADD(day, 1, GETDATE()) WHERE ActivityID = 'act_001'; 
UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = N'已通过' WHERE ApplicationID = 'app_003' AND VolunteerID = 'vol_004' AND ActivityID = 'act_001';

PRINT N'志愿者 vol_004 对活动 act_001 的报名状态 app_003 (退出组织前):';
SELECT ApplicationID, ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_003';

PRINT N'将志愿者 vol_004 在组织 org_001 中的状态从 "已加入" 更新为 "已退出":';
UPDATE dbo.tbl_VolunteerOrganizationJoin SET MemberStatus = N'已退出' WHERE VolunteerID = 'vol_004' AND OrgID = 'org_001' AND MemberStatus = N'已加入';

PRINT N'志愿者 vol_004 对活动 act_001 的报名状态 app_003 (退出组织后，应为 取消报名):';
SELECT ApplicationID, ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_003';

-- 恢复
UPDATE dbo.tbl_VolunteerOrganizationJoin SET MemberStatus = @vol004_org001_OrigStatus WHERE VolunteerID = 'vol_004' AND OrgID = 'org_001'; 
UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = @app003_OriginalStatus_T51 WHERE ApplicationID = 'app_003';
UPDATE dbo.tbl_VolunteerActivity SET StartTime = @act001_OriginalStartTime_T51 WHERE ActivityID = 'act_001'; 
GO

--------------------------------------------------------------------------------
-- 测试触发器 (合并版): trg_instead_update_activity_participation
--------------------------------------------------------------------------------
USE volunteer_db_test;
GO

PRINT N'--- 开始测试触发器 trg_instead_update_activity_participation (已修正版) ---';
GO

-- 准备阶段：创建测试用的活动、岗位和初始参与记录
PRINT N'--- 准备测试数据 ---';

-- 清理可能存在的旧测试数据
DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE ActivityID IN ('act_iuap_t01', 'act_iuap_t02');
DELETE FROM dbo.tbl_Position WHERE ActivityID IN ('act_iuap_t01', 'act_iuap_t02');
DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID IN ('act_iuap_t01', 'act_iuap_t02');
GO

-- 活动1: 用于测试窗口期内和窗口期外的单行更新
INSERT INTO dbo.tbl_VolunteerActivity (ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, CreationTime, ContactPersonPhone, ActivityDurationHours)
VALUES ('act_iuap_t01', 'org_001', N'IUAP测试活动01', DATEADD(day, -10, GETDATE()), DATEADD(day, -5, GETDATE()), N'测试地点01', 10, N'已结束', GETDATE(), '13000000010', 5);

-- 活动2: 用于测试批量更新，一个在窗口期，一个不在
INSERT INTO dbo.tbl_VolunteerActivity (ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, CreationTime, ContactPersonPhone, ActivityDurationHours)
VALUES ('act_iuap_t02', 'org_001', N'IUAP测试活动02', DATEADD(day, -20, GETDATE()), DATEADD(day, -15, GETDATE()), N'测试地点02', 10, N'已结束', GETDATE(), '13000000020', 5);
GO

-- 为活动创建岗位
INSERT INTO dbo.tbl_Position (PositionID, PositionName, ActivityID, PositionServiceHours, RequiredVolunteers)
VALUES ('pos_iuap_t01a', N'IUAP测试岗位A', 'act_iuap_t01', 2, 5);
INSERT INTO dbo.tbl_Position (PositionID, PositionName, ActivityID, PositionServiceHours, RequiredVolunteers)
VALUES ('pos_iuap_t01b', N'IUAP测试岗位B', 'act_iuap_t01', 2, 5);

INSERT INTO dbo.tbl_Position (PositionID, PositionName, ActivityID, PositionServiceHours, RequiredVolunteers)
VALUES ('pos_iuap_t02a', N'IUAP测试岗位C', 'act_iuap_t02', 2, 5);
INSERT INTO dbo.tbl_Position (PositionID, PositionName, ActivityID, PositionServiceHours, RequiredVolunteers)
VALUES ('pos_iuap_t02b', N'IUAP测试岗位D', 'act_iuap_t02', 2, 5);
GO

-- 插入初始参与记录
-- 参与记录1 (vol_001 @ act_iuap_t01, pos_iuap_t01a) - 活动已结束5天，在7天评价窗口内
INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating)
VALUES ('vol_001', 'act_iuap_t01', 'pos_iuap_t01a', N'是', NULL, NULL);

-- 参与记录2 (vol_002 @ act_iuap_t01, pos_iuap_t01b) - 用于测试窗口期外更新，将活动结束时间设为更早
-- (我们稍后会通过UPDATE活动时间来模拟窗口期外)

-- 参与记录3 (vol_001 @ act_iuap_t02, pos_iuap_t02a) - 活动已结束15天，在评价窗口期外
INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating)
VALUES ('vol_001', 'act_iuap_t02', 'pos_iuap_t02a', N'是', NULL, NULL);

-- 参与记录4 (vol_002 @ act_iuap_t02, pos_iuap_t02b) - 活动也已结束15天，在评价窗口期外 (用于批量更新测试)
INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating)
VALUES ('vol_002', 'act_iuap_t02', 'pos_iuap_t02b', N'是', NULL, NULL);

-- 参与记录5 (vol_003 @ act_iuap_t01, pos_iuap_t01a) - 用于批量更新，活动结束5天，在窗口期内
INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating)
VALUES ('vol_003', 'act_iuap_t01', 'pos_iuap_t01a', N'否', NULL, NULL); -- IsCheckedIn 初始为 '否'
GO

PRINT N'--- 测试数据准备完毕 ---';
SELECT * FROM dbo.tbl_VolunteerActivity WHERE ActivityID LIKE 'act_iuap_t%';
SELECT v.*, va.EndTime AS ActivityEndTime
FROM dbo.tbl_VolunteerActivityParticipation v
JOIN dbo.tbl_VolunteerActivity va ON v.ActivityID = va.ActivityID
WHERE v.ActivityID LIKE 'act_iuap_t%';
GO


PRINT N'--- 开始单行更新测试 ---';
GO

-- 测试 1.1: 在评价窗口期内更新 VolunteerToOrgRating (预期成功)
PRINT N'1.1 vol_001 对 act_iuap_t01 (结束5天) 评分 (预期成功更新 VolunteerToOrgRating):';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET VolunteerToOrgRating = 8
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
SELECT VolunteerID, ActivityID, VolunteerToOrgRating, OrgToVolunteerRating, IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
GO

-- 测试 1.2: 在评价窗口期内更新 OrgToVolunteerRating (预期成功)
PRINT N'1.2 组织对 vol_001 在 act_iuap_t01 (结束5天) 评分 (预期成功更新 OrgToVolunteerRating):';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET OrgToVolunteerRating = 9
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
SELECT VolunteerID, ActivityID, VolunteerToOrgRating, OrgToVolunteerRating, IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
GO

-- 测试 1.3: 在评价窗口期内更新 IsCheckedIn (预期成功，不受时间窗口影响)
PRINT N'1.3 更新 vol_001 在 act_iuap_t01 (结束5天) 的 IsCheckedIn 状态 (预期成功):';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET IsCheckedIn = N'否'
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
SELECT VolunteerID, ActivityID, VolunteerToOrgRating, OrgToVolunteerRating, IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
GO

-- 准备测试窗口期外的情况：将 act_iuap_t01 的结束时间修改为10天前
PRINT N'准备测试窗口期外：将 act_iuap_t01 的 EndTime 修改为10天前...';
DECLARE @OriginalEndTime_act_iuap_t01 SMALLDATETIME;
SELECT @OriginalEndTime_act_iuap_t01 = EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_iuap_t01';
UPDATE dbo.tbl_VolunteerActivity SET EndTime = DATEADD(day, -10, GETDATE()) WHERE ActivityID = 'act_iuap_t01';
SELECT ActivityID, EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_iuap_t01';
GO

-- 测试 1.4: 在评价窗口期外更新 VolunteerToOrgRating (预期 VolunteerToOrgRating 不变)
PRINT N'1.4 vol_001 对 act_iuap_t01 (已结束10天) 尝试再次评分 (预期 VolunteerToOrgRating 不会更新):';
DECLARE @VRatingBefore_T14 INT;
SELECT @VRatingBefore_T14 = VolunteerToOrgRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET VolunteerToOrgRating = 5 -- 尝试更新为新值
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
SELECT VolunteerID, ActivityID, VolunteerToOrgRating, OrgToVolunteerRating, IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
PRINT N'更新前的 VolunteerToOrgRating 是: ' + ISNULL(CONVERT(VARCHAR(5),@VRatingBefore_T14),'NULL') + N'. 如果触发器逻辑正确，此值应未改变。';
GO

-- 测试 1.5: 在评价窗口期外更新 OrgToVolunteerRating (预期 OrgToVolunteerRating 不变)
PRINT N'1.5 组织对 vol_001 在 act_iuap_t01 (已结束10天) 尝试再次评分 (预期 OrgToVolunteerRating 不会更新):';
DECLARE @ORatingBefore_T15 INT;
SELECT @ORatingBefore_T15 = OrgToVolunteerRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET OrgToVolunteerRating = 6 -- 尝试更新为新值
WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
SELECT VolunteerID, ActivityID, VolunteerToOrgRating, OrgToVolunteerRating, IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a';
PRINT N'更新前的 OrgToVolunteerRating 是: ' + ISNULL(CONVERT(VARCHAR(5),@ORatingBefore_T15),'NULL') + N'. 如果触发器逻辑正确，此值应未改变。';
GO

-- 恢复 act_iuap_t01 的原始结束时间
DECLARE @OriginalEndTime_act_iuap_t01_restore SMALLDATETIME;
SELECT @OriginalEndTime_act_iuap_t01_restore = EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_iuap_t01'; -- 此处获取的是已被改为10天前的值
-- 实际上，我们应该使用在测试1.4之前备份的值，或者固定为测试开始时的 -5天
PRINT N'恢复 act_iuap_t01 的结束时间为初始测试状态 (结束5天前)...';
UPDATE dbo.tbl_VolunteerActivity SET EndTime = DATEADD(day, -5, GETDATE()) WHERE ActivityID = 'act_iuap_t01';
SELECT ActivityID, EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_iuap_t01';
GO


PRINT N'--- 开始多行更新测试 ---';
GO
-- 准备：
-- 参与记录 vol_001 @ act_iuap_t01 (pos_iuap_t01a): 活动结束5天 (窗口期内) -> VolunteerToOrgRating 尝试从 8 更新到 10
-- 参与记录 vol_001 @ act_iuap_t02 (pos_iuap_t02a): 活动结束15天 (窗口期外) -> VolunteerToOrgRating 尝试从 NULL 更新到 7
-- 参与记录 vol_003 @ act_iuap_t01 (pos_iuap_t01a): 活动结束5天 (窗口期内) -> IsCheckedIn 尝试从 否 更新到 是

PRINT N'多行更新前的数据状态:';
SELECT v.VolunteerID, v.ActivityID, v.ActualPositionID, v.IsCheckedIn, v.VolunteerToOrgRating, v.OrgToVolunteerRating, va.EndTime AS ActivityEndTime
FROM dbo.tbl_VolunteerActivityParticipation v
JOIN dbo.tbl_VolunteerActivity va ON v.ActivityID = va.ActivityID
WHERE (v.VolunteerID = 'vol_001' AND v.ActivityID = 'act_iuap_t01' AND v.ActualPositionID = 'pos_iuap_t01a')
   OR (v.VolunteerID = 'vol_001' AND v.ActivityID = 'act_iuap_t02' AND v.ActualPositionID = 'pos_iuap_t02a')
   OR (v.VolunteerID = 'vol_003' AND v.ActivityID = 'act_iuap_t01' AND v.ActualPositionID = 'pos_iuap_t01a');
GO

PRINT N'执行多行 UPDATE 操作...';
UPDATE dbo.tbl_VolunteerActivityParticipation
SET
    VolunteerToOrgRating = CASE
                               WHEN VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' THEN 10 -- 在窗口期内，预期更新
                               WHEN VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t02' THEN 7  -- 在窗口期外，预期不更新此字段
                               ELSE VolunteerToOrgRating -- 其他行保持不变
                           END,
    IsCheckedIn = CASE
                      WHEN VolunteerID = 'vol_003' AND ActivityID = 'act_iuap_t01' THEN N'是' -- 预期更新
                      ELSE IsCheckedIn -- 其他行保持不变
                  END
WHERE
    (VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a')
 OR (VolunteerID = 'vol_001' AND ActivityID = 'act_iuap_t02' AND ActualPositionID = 'pos_iuap_t02a')
 OR (VolunteerID = 'vol_003' AND ActivityID = 'act_iuap_t01' AND ActualPositionID = 'pos_iuap_t01a');
GO

PRINT N'多行更新后的数据状态:';
SELECT v.VolunteerID, v.ActivityID, v.ActualPositionID, v.IsCheckedIn, v.VolunteerToOrgRating, v.OrgToVolunteerRating, va.EndTime AS ActivityEndTime
FROM dbo.tbl_VolunteerActivityParticipation v
JOIN dbo.tbl_VolunteerActivity va ON v.ActivityID = va.ActivityID
WHERE (v.VolunteerID = 'vol_001' AND v.ActivityID = 'act_iuap_t01' AND v.ActualPositionID = 'pos_iuap_t01a')
   OR (v.VolunteerID = 'vol_001' AND v.ActivityID = 'act_iuap_t02' AND v.ActualPositionID = 'pos_iuap_t02a')
   OR (v.VolunteerID = 'vol_003' AND v.ActivityID = 'act_iuap_t01' AND v.ActualPositionID = 'pos_iuap_t01a')
ORDER BY v.VolunteerID, v.ActivityID;
GO

PRINT N'预期结果:';
PRINT N'- vol_001 @ act_iuap_t01: VolunteerToOrgRating 应为 10, IsCheckedIn 应为之前的值 (否)。';
PRINT N'- vol_001 @ act_iuap_t02: VolunteerToOrgRating 应为 NULL (或之前的值，因为窗口期外更新被阻止), IsCheckedIn 应为之前的值 (是)。';
PRINT N'- vol_003 @ act_iuap_t01: IsCheckedIn 应为 是, VolunteerToOrgRating 应为 NULL (或之前的值)。';
GO


PRINT N'--- 清理测试数据 ---';
-- 清理参与记录
DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE ActivityID = 'act_iuap_t01' AND VolunteerID IN ('vol_001', 'vol_003');
DELETE FROM dbo.tbl_VolunteerActivityParticipation WHERE ActivityID = 'act_iuap_t02' AND VolunteerID IN ('vol_001', 'vol_002');
-- 清理岗位
DELETE FROM dbo.tbl_Position WHERE PositionID IN ('pos_iuap_t01a', 'pos_iuap_t01b', 'pos_iuap_t02a', 'pos_iuap_t02b');
-- 清理活动
DELETE FROM dbo.tbl_VolunteerActivity WHERE ActivityID IN ('act_iuap_t01', 'act_iuap_t02');
GO

PRINT N'--- trg_instead_update_activity_participation 测试结束 ---';
GO

--------------------------------------------------------------------------------
-- 测试触发器 (合并版): trg_instead_update_training_participation
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_instead_update_training_participation ---';
DECLARE @OriginalEndTime_trn002_T62_Restore SMALLDATETIME;
DECLARE @OriginalVolRating_vol002_trn002_Restore_final INT, @OriginalOrgRating_vol002_trn002_Restore_final INT, @OriginalIsCheckedIn_vol002_trn002_Restore_final NCHAR(1);
SELECT @OriginalEndTime_trn002_T62_Restore = EndTime FROM dbo.tbl_VolunteerTraining WHERE TrainingID = 'trn_002';
SELECT @OriginalVolRating_vol002_trn002_Restore_final = VolunteerToOrgRating, @OriginalOrgRating_vol002_trn002_Restore_final = OrgToVolunteerRating, @OriginalIsCheckedIn_vol002_trn002_Restore_final = IsCheckedIn
FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';

-- 6.2.1 在评价窗口期内志愿者评分 (成功)
UPDATE dbo.tbl_VolunteerTraining SET EndTime = DATEADD(day, -4, GETDATE()) WHERE TrainingID = 'trn_002'; 
UPDATE dbo.tbl_VolunteerTrainingParticipation SET VolunteerToOrgRating = NULL WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002'; 
PRINT N'志愿者 vol_002 尝试对培训 trn_002 评分 (在窗口期内):';
UPDATE dbo.tbl_VolunteerTrainingParticipation SET VolunteerToOrgRating = 9 WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';

PRINT N'志愿者 vol_002 对培训 trn_002 的评分 (窗口期内 vol评分 测试后):';
SELECT VolunteerToOrgRating, OrgToVolunteerRating FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';


-- 6.2.2 在评价窗口期外组织尝试评分 (失败)
UPDATE dbo.tbl_VolunteerTraining SET EndTime = DATEADD(day, -12, GETDATE()) WHERE TrainingID = 'trn_002'; 
PRINT N'组织尝试对培训 trn_002 中的 vol_002 评分 (在窗口期外):';
UPDATE dbo.tbl_VolunteerTrainingParticipation SET OrgToVolunteerRating = 7 WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';

PRINT N'组织对培训 trn_002 中 vol_002 的评分 (窗口期外 org评分 测试后，应未改变):';
SELECT VolunteerToOrgRating, OrgToVolunteerRating FROM dbo.tbl_VolunteerTrainingParticipation WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';

-- 恢复
UPDATE dbo.tbl_VolunteerTraining SET EndTime = @OriginalEndTime_trn002_T62_Restore WHERE TrainingID = 'trn_002';
UPDATE dbo.tbl_VolunteerTrainingParticipation SET VolunteerToOrgRating = @OriginalVolRating_vol002_trn002_Restore_final, OrgToVolunteerRating = @OriginalOrgRating_vol002_trn002_Restore_final, IsCheckedIn = @OriginalIsCheckedIn_vol002_trn002_Restore_final
WHERE VolunteerID = 'vol_002' AND TrainingID = 'trn_002';
PRINT N'培训 trn_002 的结束时间及参与记录已尝试恢复。';


PRINT N'--- 所有触发器测试结束 ---';
GO