/*
 * ============================================================================
 * 志愿者管理系统 - 全功能ID自动生成触发器脚本 (完整修正版)
 * ============================================================================
 * 描述:
 * 此脚本为数据库中所有需要自定义格式ID的表创建了“INSTEAD OF INSERT”触发器。
 * 它首先创建所有必需的SEQUENCE对象，然后创建9个独立的触发器来自动生成
 * 格式为 “前缀 + 12位数字” 的唯一ID。
 *
 * v3.0 更新:
 * - 整合所有ID生成触发器到一个文件。
 * - 解决了 tbl_VolunteerActivityApplication 表上因存在两个
 * INSTEAD OF INSERT 触发器（一个用于时间冲突检查，一个用于ID生成）
 * 而导致的创建冲突。已将两者逻辑合并为一个新的触发器
 * trg_InsteadInsert_Application。
 * ============================================================================
*/

--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始创建ID生成所需的SEQUENCE对象 ---';
GO
-- 如果存在则删除旧的SEQUENCE对象
IF OBJECT_ID('dbo.VolunteerID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.VolunteerID_Seq;
IF OBJECT_ID('dbo.OrganizationID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.OrganizationID_Seq;
IF OBJECT_ID('dbo.AdministratorID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.AdministratorID_Seq;
IF OBJECT_ID('dbo.ActivityID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.ActivityID_Seq;
IF OBJECT_ID('dbo.TrainingID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.TrainingID_Seq;
IF OBJECT_ID('dbo.PositionID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.PositionID_Seq;
IF OBJECT_ID('dbo.ApplicationID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.ApplicationID_Seq;
IF OBJECT_ID('dbo.TimeslotID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.TimeslotID_Seq;
IF OBJECT_ID('dbo.ComplaintID_Seq', 'SO') IS NOT NULL DROP SEQUENCE dbo.ComplaintID_Seq;
GO

-- 创建新的SEQUENCE对象
CREATE SEQUENCE dbo.VolunteerID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.OrganizationID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.AdministratorID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.ActivityID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.TrainingID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.PositionID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.ApplicationID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.TimeslotID_Seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.ComplaintID_Seq START WITH 1 INCREMENT BY 1;
GO

PRINT N'--- 所有SEQUENCE对象创建完毕 ---';
GO

PRINT N'--- 开始创建ID自动生成触发器 ---';
GO

--------------------------------------------------------------------------------
-- 1. 触发器: trg_GenerateVolunteerID
-- 监控表:   dbo.tbl_Volunteer (志愿者表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的志愿者记录生成一个格式为 'VOL' + 12位数字 的 VolunteerID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateVolunteerID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateVolunteerID;
GO
CREATE TRIGGER dbo.trg_GenerateVolunteerID ON dbo.tbl_Volunteer INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_Volunteer (
        VolunteerID, Username, Name, PhoneNumber, IDCardNumber, Password, Country, Gender, ServiceArea,
        Ethnicity, PoliticalStatus, HighestEducation, EmploymentStatus, ServiceCategory, TotalVolunteerHours, VolunteerRating, AccountStatus
    )
    SELECT
        'VOL' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.VolunteerID_Seq AS VARCHAR(12)), 12),
        i.Username, i.Name, i.PhoneNumber, i.IDCardNumber, i.Password, ISNULL(i.Country, N'中国'), i.Gender, i.ServiceArea,
        ISNULL(i.Ethnicity, N'汉族'), ISNULL(i.PoliticalStatus, N'群众'), i.HighestEducation, i.EmploymentStatus, i.ServiceCategory,
        ISNULL(i.TotalVolunteerHours, 0.00), ISNULL(i.VolunteerRating, 0.00), ISNULL(i.AccountStatus, N'未实名认证')
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateVolunteerID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 2. 触发器: trg_GenerateOrganizationID
-- 监控表:   dbo.tbl_Organization (组织机构表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的组织记录生成一个格式为 'ORG' + 12位数字 的 OrgID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateOrganizationID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateOrganizationID;
GO
CREATE TRIGGER dbo.trg_GenerateOrganizationID ON dbo.tbl_Organization INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_Organization (
        OrgID, OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone, ServiceRegion,
        OrgScale, OrgRating, OrgAccountStatus, TotalServiceHours, ActivityCount, TrainingCount
    )
    SELECT
        'ORG' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.OrganizationID_Seq AS VARCHAR(12)), 12),
        i.OrgName, i.OrgLoginUserName, i.OrgLoginPassword, i.ContactPersonPhone, i.ServiceRegion,
        i.OrgScale, ISNULL(i.OrgRating, 1.0), ISNULL(i.OrgAccountStatus, N'待认证'), ISNULL(i.TotalServiceHours, 0),
        ISNULL(i.ActivityCount, 0), ISNULL(i.TrainingCount, 0)
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateOrganizationID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 3. 触发器: trg_GenerateAdministratorID
-- 监控表:   dbo.tbl_Administrator (管理员表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的管理员记录生成一个格式为 'ADM' + 12位数字 的 AdminID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateAdministratorID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateAdministratorID;
GO
CREATE TRIGGER dbo.trg_GenerateAdministratorID ON dbo.tbl_Administrator INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_Administrator (
        AdminID, Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, CurrentPosition, PermissionLevel
    )
    SELECT
        'ADM' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.AdministratorID_Seq AS VARCHAR(12)), 12),
        i.Name, i.Gender, i.IDCardNumber, i.PhoneNumber, i.Password, i.ServiceArea,
        ISNULL(i.CurrentPosition, N'普通管理员'), i.PermissionLevel
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateAdministratorID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 4. 触发器: trg_GenerateActivityID
-- 监控表:   dbo.tbl_VolunteerActivity (志愿活动表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的志愿活动记录生成一个格式为 'ACT' + 12位数字 的 ActivityID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateActivityID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateActivityID;
GO
CREATE TRIGGER dbo.trg_GenerateActivityID ON dbo.tbl_VolunteerActivity INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_VolunteerActivity (
        ActivityID, OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, AcceptedCount,
        ActivityStatus, CreationTime, ReviewerAdminID, ContactPersonPhone, ActivityDurationHours, ActivityRating, IsRatingAggregated
    )
    SELECT
        'ACT' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.ActivityID_Seq AS VARCHAR(12)), 12),
        i.OrgID, i.ActivityName, i.StartTime, i.EndTime, i.Location, i.RecruitmentCount, ISNULL(i.AcceptedCount, 0),
        ISNULL(i.ActivityStatus, N'待审核'), ISNULL(i.CreationTime, GETDATE()), i.ReviewerAdminID, i.ContactPersonPhone,
        i.ActivityDurationHours, i.ActivityRating, ISNULL(i.IsRatingAggregated, 'NO')
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateActivityID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 5. 触发器: trg_GenerateTrainingID
-- 监控表:   dbo.tbl_VolunteerTraining (志愿培训表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的志愿培训记录生成一个格式为 'TRN' + 12位数字 的 TrainingID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateTrainingID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateTrainingID;
GO
CREATE TRIGGER dbo.trg_GenerateTrainingID ON dbo.tbl_VolunteerTraining INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_VolunteerTraining (
        TrainingID, OrgID, TrainingName, Theme, StartTime, EndTime, Location, RecruitmentCount,
        TrainingStatus, CreationTime, ReviewerAdminID, ContactPersonPhone, TrainingRating, IsRatingAggregated
    )
    SELECT
        'TRN' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.TrainingID_Seq AS VARCHAR(12)), 12),
        i.OrgID, i.TrainingName, i.Theme, i.StartTime, i.EndTime, i.Location, i.RecruitmentCount,
        ISNULL(i.TrainingStatus, N'待审核'), ISNULL(i.CreationTime, GETDATE()), i.ReviewerAdminID, i.ContactPersonPhone,
        i.TrainingRating, ISNULL(i.IsRatingAggregated, 'NO')
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateTrainingID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 6. 触发器: trg_GeneratePositionID
-- 监控表:   dbo.tbl_Position (岗位表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的岗位记录生成一个格式为 'POS' + 12位数字 的 PositionID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GeneratePositionID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GeneratePositionID;
GO
CREATE TRIGGER dbo.trg_GeneratePositionID ON dbo.tbl_Position INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_Position (
        PositionID, PositionName, ActivityID, PositionServiceHours, RequiredVolunteers, RecruitedVolunteers
    )
    SELECT
        'POS' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.PositionID_Seq AS VARCHAR(12)), 12),
        i.PositionName, i.ActivityID, i.PositionServiceHours, i.RequiredVolunteers, ISNULL(i.RecruitedVolunteers, 0)
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GeneratePositionID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 7. 触发器: trg_InsteadInsert_Application (合并版)
-- 监控表:   dbo.tbl_VolunteerActivityApplication
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 替代原生的插入操作，实现两大功能：
--            1. 检查新报名活动的总体时间是否与该志愿者已有的其他活动/培训时间冲突。
--            2. 如果不冲突，则自动为新报名记录生成一个 'APP' + 12位数字 的 ApplicationID。
--------------------------------------------------------------------------------
-- 首先，删除掉可能存在的旧的、冲突的触发器
IF OBJECT_ID('dbo.trg_check_activity_application_time_conflict', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_check_activity_application_time_conflict;
IF OBJECT_ID('dbo.trg_GenerateApplicationID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateApplicationID;
GO
CREATE TRIGGER dbo.trg_InsteadInsert_Application ON dbo.tbl_VolunteerActivityApplication INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @VolunteerID CHAR(15), @NewActivityID CHAR(15), @NewActivityStartTime SMALLDATETIME, @NewActivityEndTime SMALLDATETIME;
    DECLARE @ConflictEventID CHAR(15), @ConflictEventType NVARCHAR(20);

    SELECT @VolunteerID = i.VolunteerID, @NewActivityID = i.ActivityID FROM inserted i;

    -- 步骤1: 时间冲突检查
    SELECT @NewActivityStartTime = va.StartTime, @NewActivityEndTime = va.EndTime FROM dbo.tbl_VolunteerActivity va WHERE va.ActivityID = @NewActivityID;
    IF @NewActivityStartTime IS NULL OR @NewActivityEndTime IS NULL
    BEGIN
        RAISERROR(N'无法获取新报名活动 "%s" 的有效时间范围。报名失败。', 16, 1, @NewActivityID);
        RETURN;
    END

    SELECT TOP 1 @ConflictEventID = vap.ActivityID, @ConflictEventType = N'活动'
    FROM dbo.tbl_VolunteerActivityParticipation vap
    JOIN dbo.tbl_VolunteerActivity va_existing ON vap.ActivityID = va_existing.ActivityID
    WHERE vap.VolunteerID = @VolunteerID AND NOT (@NewActivityEndTime <= va_existing.StartTime OR @NewActivityStartTime >= va_existing.EndTime);
    IF @ConflictEventID IS NOT NULL
    BEGIN
        RAISERROR(N'报名失败：新活动与您已确认参加的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
        RETURN;
    END

    SET @ConflictEventID = NULL;
    SELECT TOP 1 @ConflictEventID = vtp.TrainingID, @ConflictEventType = N'培训'
    FROM dbo.tbl_VolunteerTrainingParticipation vtp
    JOIN dbo.tbl_VolunteerTraining vt_existing ON vtp.TrainingID = vt_existing.TrainingID
    WHERE vtp.VolunteerID = @VolunteerID AND vt_existing.TrainingStatus NOT IN (N'已结束', N'已停用', N'审核不通过')
      AND NOT (@NewActivityEndTime <= vt_existing.StartTime OR @NewActivityStartTime >= vt_existing.EndTime);
    IF @ConflictEventID IS NOT NULL
    BEGIN
        RAISERROR(N'报名失败：新活动与您已报名且有效的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
        RETURN;
    END

    -- 步骤2: ID生成并插入
    INSERT INTO dbo.tbl_VolunteerActivityApplication (
        ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus
    )
    SELECT
        'APP' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.ApplicationID_Seq AS VARCHAR(12)), 12),
        i.VolunteerID, i.ActivityID, i.IntendedPositionID, ISNULL(i.ApplicationTime, GETDATE()), ISNULL(i.ApplicationStatus, N'待审核')
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_InsteadInsert_Application] (合并版) 已创建。';
GO

--------------------------------------------------------------------------------
-- 8. 触发器: trg_GenerateTimeslotID
-- 监控表:   dbo.tbl_ActivityTimeslot (活动时段表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的时段记录生成一个格式为 'TSL' + 12位数字 的 TimeslotID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateTimeslotID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateTimeslotID;
GO
CREATE TRIGGER dbo.trg_GenerateTimeslotID ON dbo.tbl_ActivityTimeslot INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_ActivityTimeslot (
        TimeslotID, EventID, StartTime, EndTime
    )
    SELECT
        'TSL' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.TimeslotID_Seq AS VARCHAR(12)), 12),
        i.EventID, i.StartTime, i.EndTime
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateTimeslotID] 已创建。';
GO

--------------------------------------------------------------------------------
-- 9. 触发器: trg_GenerateComplaintID
-- 监控表:   dbo.tbl_Complaint (投诉表)
-- 触发事件: INSTEAD OF INSERT
-- 核心功能: 自动为新插入的投诉记录生成一个格式为 'CMP' + 12位数字 的 ComplaintID。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_GenerateComplaintID', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_GenerateComplaintID;
GO
CREATE TRIGGER dbo.trg_GenerateComplaintID ON dbo.tbl_Complaint INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tbl_Complaint (
        ComplaintID, ComplaintTime, ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent,
        EvidenceLink, ProcessingStatus, ProcessingResult, LatestProcessingTime, HandlerAdminID,
        VisitTime, VisitResult, ArbitrationRound, ReviewAdminID
    )
    SELECT
        'CMP' + RIGHT('000000000000' + CAST(NEXT VALUE FOR dbo.ComplaintID_Seq AS VARCHAR(12)), 12),
        ISNULL(i.ComplaintTime, GETDATE()), i.ComplainantID, i.ComplaintTargetID, ISNULL(i.ComplaintType, N'其他'), i.ComplaintContent,
        i.EvidenceLink, ISNULL(i.ProcessingStatus, N'未处理'), i.ProcessingResult, i.LatestProcessingTime, i.HandlerAdminID,
        i.VisitTime, ISNULL(i.VisitResult, N'满意'), i.ArbitrationRound, i.ReviewAdminID
    FROM inserted i;
END;
GO
PRINT N'触发器 [trg_GenerateComplaintID] 已创建。';
GO

PRINT N'--- 所有ID自动生成触发器创建完毕 ---';
GO