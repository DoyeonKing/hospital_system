--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织机构注册 (sp_RegisterOrganization)
-- 描述: 处理新组织机构的注册申请。
-- 参数:
--   @OrgName NVARCHAR(20): 组织名称
--   @OrgLoginUserName NVARCHAR(20): 组织登录用户名
--   @OrgLoginPassword NVARCHAR(50): 登录密码 (明文)
--   @ContactPersonPhone NVARCHAR(11): 联系人手机号
--   @ServiceRegion NVARCHAR(50): 服务区域
--   @OrgScale INT: 组织规模
-- 返回值:
--   0: 成功，返回自动生成的ID
--  -1: 组织登录用户名已存在
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RegisterOrganization', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegisterOrganization;
GO

CREATE PROCEDURE dbo.sp_RegisterOrganization (
    -- @OrgID CHAR(15), -- 此参数已移除，ID由触发器生成
    @OrgName NVARCHAR(20),
    @OrgLoginUserName NVARCHAR(20),
    @OrgLoginPassword NVARCHAR(50),
    @ContactPersonPhone NVARCHAR(11),
    @ServiceRegion NVARCHAR(50),
    @OrgScale INT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @GeneratedOrgID CHAR(15);

    IF EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgLoginUserName = @OrgLoginUserName)
    BEGIN
        RAISERROR(N'组织登录用户名 "%s" 已存在。', 16, 1, @OrgLoginUserName);
        RETURN -1; -- 用户名已存在
    END

    BEGIN TRY
        -- 注意：INSERT语句中不再包含OrgID列，其值将由触发器 trg_GenerateOrganizationID 自动填充
        INSERT INTO dbo.tbl_Organization (
            OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone,
            ServiceRegion, OrgScale, OrgRating, OrgAccountStatus,
            TotalServiceHours, ActivityCount, TrainingCount
        )
        VALUES (
            @OrgName, @OrgLoginUserName, @OrgLoginPassword, @ContactPersonPhone,
            @ServiceRegion, @OrgScale, 1.0, N'待认证', -- 初始评分和状态
            0, 0, 0 -- 初始服务时长和计数
        );

        -- 获取由触发器生成的新OrgID
        SELECT @GeneratedOrgID = OrgID 
        FROM dbo.tbl_Organization 
        WHERE OrgLoginUserName = @OrgLoginUserName;

        -- 返回新生成的OrgID给调用者
        SELECT @GeneratedOrgID AS GeneratedOrgID;
        
        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        DECLARE @ErrorLine INT;
        DECLARE @ErrorProcedure NVARCHAR(200);

        SELECT
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ErrorLine = ERROR_LINE(),
            @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');

        DECLARE @FormattedErrorMessage NVARCHAR(4000);
        SET @FormattedErrorMessage = N'组织机构注册过程中发生错误。过程: %s, 行: %d, 错误信息: %s';

        RAISERROR(@FormattedErrorMessage, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);
        RETURN -99; -- 其他错误
    END CATCH
END
GO
PRINT N'存储过程 [sp_RegisterOrganization] 已修改。';
GO
--------------------------------------------------------------------------------
-- 存储过程: 组织机构登录 (sp_OrganizationLogin)
-- 描述: 验证组织机构登录凭据。
-- 参数:
--   @OrgIdentifier NVARCHAR(20): 可以是OrgID或OrgLoginUserName
--   @Password NVARCHAR(50): 明文密码
-- 返回值:
--   0: 登录成功 (并返回组织基本信息)
--  -1: 用户名或ID不存在
--  -2: 密码错误
--  -3: 账户被冻结
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrganizationLogin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrganizationLogin;
GO

CREATE PROCEDURE dbo.sp_OrganizationLogin (
    @OrgIdentifier NVARCHAR(20),
    @Password NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CorrectPassword NVARCHAR(50);
    DECLARE @OrgID_found CHAR(15);
    DECLARE @OrgAccountStatus NVARCHAR(10);
    DECLARE @OrgName_found NVARCHAR(20);
    DECLARE @LoginIdentifierUsed NVARCHAR(20);

    SET @LoginIdentifierUsed = @OrgIdentifier;

    SELECT @CorrectPassword = OrgLoginPassword,
           @OrgID_found = OrgID,
           @OrgAccountStatus = OrgAccountStatus,
           @OrgName_found = OrgName
    FROM dbo.tbl_Organization
    WHERE OrgID = @OrgIdentifier OR OrgLoginUserName = @OrgIdentifier;

    IF @OrgID_found IS NULL
    BEGIN
        RAISERROR(N'组织ID或登录用户名 "%s" 不存在。', 16, 1, @LoginIdentifierUsed);
        RETURN -1;
    END

    IF @OrgAccountStatus = N'冻结'
    BEGIN
        RAISERROR(N'组织账户 "%s" (ID: %s) 已被冻结，无法登录。', 16, 1, @OrgName_found, @OrgID_found);
        RETURN -3;
    END

    IF @CorrectPassword = @Password
    BEGIN
        SELECT OrgID, OrgName, OrgAccountStatus, ServiceRegion
        FROM dbo.tbl_Organization
        WHERE OrgID = @OrgID_found;
        RETURN 0;
    END
    ELSE
    BEGIN
        RAISERROR(N'组织 "%s" (ID: %s) 密码错误。', 16, 1, @OrgName_found, @OrgID_found);
        RETURN -2;
    END
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织更新自己的基本信息 (sp_UpdateOrganizationProfile)
-- 描述: 组织机构更新自己的基本信息（例如名称、联系电话、规模、服务区域）。
-- 参数:
--   @OrgID CHAR(15): 要更新的组织ID
--   @OrgName NVARCHAR(20): 新的组织名称 (可选,传入NULL则不更新)
--   @ContactPersonPhone NVARCHAR(11): 新的联系电话 (可选,传入NULL则不更新)
--   @ServiceRegion NVARCHAR(50): 新的服务区域 (可选,传入NULL则不更新)
--   @OrgScale INT: 新的组织规模 (可选,传入NULL或负值则不更新)
-- 返回值:
--   0: 更新成功
--  -1: 组织ID不存在
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_UpdateOrganizationProfile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateOrganizationProfile;
GO

CREATE PROCEDURE dbo.sp_UpdateOrganizationProfile (
    @OrgID CHAR(15),
    @OrgName NVARCHAR(20) = NULL,
    @ContactPersonPhone NVARCHAR(11) = NULL,
    @ServiceRegion NVARCHAR(50) = NULL,
    @OrgScale INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OrgID)
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在，无法更新。', 16, 1, @OrgID);
        RETURN -1;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Organization
        SET OrgName = ISNULL(@OrgName, OrgName),
            ContactPersonPhone = ISNULL(@ContactPersonPhone, ContactPersonPhone),
            ServiceRegion = ISNULL(@ServiceRegion, ServiceRegion),
            OrgScale = CASE WHEN @OrgScale IS NOT NULL AND @OrgScale > 0 THEN @OrgScale ELSE OrgScale END
        WHERE OrgID = @OrgID;

        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'更新组织信息过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织修改自己的登录密码 (sp_ChangeOrganizationPassword)
-- 描述: 组织机构修改自己的登录密码。
-- 参数:
--   @OrgID CHAR(15): 组织ID
--   @OldPassword NVARCHAR(50): 旧的明文密码
--   @NewPassword NVARCHAR(50): 新的明文密码
-- 返回值:
--   0: 修改成功
--  -1: 组织不存在
--  -2: 旧密码错误
--  -3: 新密码与旧密码相同
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ChangeOrganizationPassword', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ChangeOrganizationPassword;
GO

CREATE PROCEDURE dbo.sp_ChangeOrganizationPassword (
    @OrgID CHAR(15),
    @OldPassword NVARCHAR(50),
    @NewPassword NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StoredPassword NVARCHAR(50);

    SELECT @StoredPassword = OrgLoginPassword FROM dbo.tbl_Organization WHERE OrgID = @OrgID;

    IF @StoredPassword IS NULL
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在。', 16, 1, @OrgID);
        RETURN -1;
    END

    IF @StoredPassword <> @OldPassword
    BEGIN
        RAISERROR(N'旧密码错误。', 16, 1);
        RETURN -2;
    END

    IF @NewPassword = @OldPassword
    BEGIN
        RAISERROR(N'新密码不能与旧密码相同。', 16, 1);
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Organization
        SET OrgLoginPassword = @NewPassword
        WHERE OrgID = @OrgID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'修改组织密码过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织发布志愿活动 (sp_CreateVolunteerActivityByOrg)
-- 描述: 组织发布新的志愿活动。ActivityDurationHours 初始为0。
-- 参数:
--   @ActivityID CHAR(15): 活动ID (应用生成)
--   @OrgID CHAR(15): 执行此操作的组织ID
--   @ActivityName NVARCHAR(20): 活动名称
--   @StartTime SMALLDATETIME: 活动开始时间
--   @EndTime SMALLDATETIME: 活动结束时间
--   @Location NVARCHAR(30): 活动地点
--   @RecruitmentCount INT: 招募人数
--   @ContactPersonPhone NVARCHAR(11): 联系人手机号
-- 返回值:
--   0: 成功
--  -1: 组织ID不存在或尚未认证
--  -2: 开始时间晚于或等于结束时间
--  -3: 招募人数无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_CreateVolunteerActivityByOrg', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateVolunteerActivityByOrg;
GO

CREATE PROCEDURE dbo.sp_CreateVolunteerActivityByOrg (
    @ActivityID CHAR(15),
    @OrgID CHAR(15),
    @ActivityName NVARCHAR(20),
    @StartTime SMALLDATETIME,
    @EndTime SMALLDATETIME,
    @Location NVARCHAR(30),
    @RecruitmentCount INT,
    @ContactPersonPhone NVARCHAR(11)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OrgID AND OrgAccountStatus = N'已认证')
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在或尚未认证，无法发布活动。', 16, 1, @OrgID);
        RETURN -1;
    END

    IF @StartTime >= @EndTime
    BEGIN
        RAISERROR(N'活动开始时间必须早于结束时间。', 16, 1);
        RETURN -2;
    END

    IF @RecruitmentCount <= 0
    BEGIN
        RAISERROR(N'招募人数必须大于0。', 16, 1);
        RETURN -3;
    END

    BEGIN TRY
        INSERT INTO dbo.tbl_VolunteerActivity (
            ActivityID, OrgID, ActivityName, StartTime, EndTime, Location,
            RecruitmentCount, AcceptedCount, ActivityStatus, CreationTime,
            ContactPersonPhone, ActivityDurationHours, IsRatingAggregated, ReviewerAdminID
        )
        VALUES (
            @ActivityID, @OrgID, @ActivityName, @StartTime, @EndTime, @Location,
            @RecruitmentCount, 0, N'待审核', GETDATE(),
            @ContactPersonPhone, 0, 'NO', NULL
        );
        RETURN 0;
    END TRY
    BEGIN CATCH
    -- 声明变量以存储错误详情
    DECLARE @ErrorMessage_Detail NVARCHAR(4000);
    DECLARE @ErrorSeverity_Detail INT;
    DECLARE @ErrorState_Detail INT;
    DECLARE @ErrorNumber_Detail INT;
    DECLARE @ErrorLine_Detail INT;
    DECLARE @ErrorProcedure_Detail NVARCHAR(200);

    SELECT
        @ErrorNumber_Detail = ERROR_NUMBER(),
        @ErrorMessage_Detail = ERROR_MESSAGE(),
        @ErrorSeverity_Detail = ERROR_SEVERITY(),
        @ErrorState_Detail = ERROR_STATE(),
        @ErrorLine_Detail = ERROR_LINE(),
        @ErrorProcedure_Detail = ISNULL(ERROR_PROCEDURE(), '-');

    -- 准备一个包含更多信息的错误消息
    DECLARE @FormattedErrorMessage_Detail NVARCHAR(4000);
    SET @FormattedErrorMessage_Detail = N'错误号: %d, 过程: %s, 行: %d, 原始错误: %s';

    -- 重新抛出包含详细信息的错误，或者你可以选择 PRINT 出来进行调试
    RAISERROR(@FormattedErrorMessage_Detail,
              @ErrorSeverity_Detail,
              @ErrorState_Detail,
              @ErrorNumber_Detail,
              @ErrorProcedure_Detail,
              @ErrorLine_Detail,
              @ErrorMessage_Detail); -- 将原始错误消息作为参数传递

    RETURN -99; -- 其他错误
END CATCH
END
GO
PRINT N'存储过程 [sp_CreateVolunteerActivityByOrg] 已更新 (移除显式ActivityDurationHours参数处理逻辑，默认为0)。';
GO


--------------------------------------------------------------------------------
-- 存储过程: 组织发布志愿培训 (sp_CreateVolunteerTrainingByOrg)
-- 描述: 组织发布新的志愿培训。
-- 参数:
--   @TrainingID CHAR(15): 培训ID (应用生成)
--   @OrgID CHAR(15): 执行此操作的组织ID
--   @TrainingName NVARCHAR(20): 培训名称
--   @Theme NVARCHAR(15): 培训主题
--   @StartTime SMALLDATETIME: 培训开始时间
--   @EndTime SMALLDATETIME: 培训结束时间
--   @Location NVARCHAR(30): 培训地点
--   @RecruitmentCount INT: 招募人数
--   @ContactPersonPhone NVARCHAR(11): 联系人手机号
-- 返回值:
--   0: 成功
--  -1: 组织ID不存在或尚未认证
--  -2: 开始时间晚于或等于结束时间
--  -3: 招募人数无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_CreateVolunteerTrainingByOrg', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateVolunteerTrainingByOrg;
GO
CREATE PROCEDURE dbo.sp_CreateVolunteerTrainingByOrg (
    @TrainingID CHAR(15),
    @OrgID CHAR(15),
    @TrainingName NVARCHAR(20),
    @Theme NVARCHAR(15),
    @StartTime SMALLDATETIME,
    @EndTime SMALLDATETIME,
    @Location NVARCHAR(30),
    @RecruitmentCount INT,
    @ContactPersonPhone NVARCHAR(11)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OrgID AND OrgAccountStatus = N'已认证')
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在或尚未认证，无法发布培训。', 16, 1, @OrgID);
        RETURN -1;
    END

    IF @StartTime >= @EndTime
    BEGIN
        RAISERROR(N'培训开始时间必须早于结束时间。', 16, 1);
        RETURN -2;
    END

     IF @RecruitmentCount <= 0
    BEGIN
        RAISERROR(N'招募人数必须大于0。', 16, 1);
        RETURN -3;
    END

    BEGIN TRY
        INSERT INTO dbo.tbl_VolunteerTraining (
            TrainingID, OrgID, TrainingName, Theme, StartTime, EndTime, Location,
            RecruitmentCount, TrainingStatus, CreationTime, ContactPersonPhone, IsRatingAggregated, ReviewerAdminID
        )
        VALUES (
            @TrainingID, @OrgID, @TrainingName, @Theme, @StartTime, @EndTime, @Location,
            @RecruitmentCount, N'待审核', GETDATE(), @ContactPersonPhone, 'NO', NULL
        );
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'发布志愿培训过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO
PRINT N'存储过程 [sp_CreateVolunteerTrainingByOrg] 已更新。';
GO


--------------------------------------------------------------------------------
-- 存储过程: 组织审核志愿者的加入申请 (sp_OrgReviewVolunteerJoinApplication)
-- 描述: 组织审核志愿者的加入申请。
-- 参数:
--   @OperatingOrgID CHAR(15): 执行审核的组织ID
--   @VolunteerID CHAR(15): 被审核的志愿者ID
--   @NewStatus NVARCHAR(3): 新的成员状态 (N'已加入', N'已退出' (代表拒绝))
-- 返回值:
--   0: 成功
--  -1: 未找到申请记录
--  -2: 申请状态不正确 (非'申请中')
--  -3: 无效的新状态值
--  -4: 操作的组织ID无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgReviewVolunteerJoinApplication', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgReviewVolunteerJoinApplication;
GO

CREATE PROCEDURE dbo.sp_OrgReviewVolunteerJoinApplication (
    @OperatingOrgID CHAR(15),
    @VolunteerID CHAR(15),
    @NewStatus NVARCHAR(3)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentStatus NVARCHAR(3);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -4;
    END

    SELECT @CurrentStatus = MemberStatus
    FROM dbo.tbl_VolunteerOrganizationJoin
    WHERE VolunteerID = @VolunteerID AND OrgID = @OperatingOrgID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'未找到志愿者 "%s" 对组织 "%s" 的加入申请记录。', 16, 1, @VolunteerID, @OperatingOrgID);
        RETURN -1;
    END

    IF @CurrentStatus <> N'申请中'
    BEGIN
        RAISERROR(N'该申请当前状态为 "%s"，并非“申请中”，无法执行此审核操作。', 16, 1, @CurrentStatus);
        RETURN -2;
    END

    IF @NewStatus NOT IN (N'已加入', N'已退出')
    BEGIN
        RAISERROR(N'无效的目标审核状态 "%s"。有效值为 "已加入" 或 "已退出"。', 16, 1, @NewStatus);
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerOrganizationJoin
        SET MemberStatus = @NewStatus
        WHERE VolunteerID = @VolunteerID AND OrgID = @OperatingOrgID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'审核志愿者加入申请过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织审核志愿者对活动的报名 (sp_OrgReviewActivityApplication)
-- 描述: 组织审核志愿者对本组织活动的报名申请。
-- 参数:
--   @OperatingOrgID CHAR(15): 执行审核的组织ID
--   @ApplicationID CHAR(15): 报名申请ID
--   @NewStatus NVARCHAR(10): 新的报名状态 (N'已通过', N'已拒绝')
--   @ActualPositionID CHAR(15): 如果通过，分配的实际岗位ID (可选)
-- 返回值:
--   0: 成功
--  -1: 报名申请ID不存在
--  -2: 申请状态不正确 (非'待审核')
--  -3: 无效的新状态值
--  -4: 审核通过时必须指定岗位ID
--  -5: 指定的岗位ID在活动中不存在或不匹配
--  -6: 活动录取人数已满
--  -7: 岗位招募人数已满
--  -10: 操作的组织ID无效
--  -11: 无权审核非本组织的活动报名
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgReviewActivityApplication', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgReviewActivityApplication;
GO
CREATE PROCEDURE dbo.sp_OrgReviewActivityApplication (
    @OperatingOrgID CHAR(15),
    @ApplicationID CHAR(15),
    @NewStatus NVARCHAR(10),
    @ActualPositionID CHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @VolunteerID CHAR(15);
    DECLARE @ActivityID CHAR(15);
    DECLARE @IntendedPositionID CHAR(15);
    DECLARE @CurrentApplicationStatus NVARCHAR(10);
    DECLARE @ActivityOrgID CHAR(15);
    DECLARE @ActivityRecruitmentCount INT;
    DECLARE @ActivityAcceptedCount INT;
    DECLARE @PositionRequired INT;
    DECLARE @PositionRecruited INT;
    DECLARE @FinalPositionID CHAR(15);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -10;
    END

    SELECT
        @VolunteerID = vaa.VolunteerID,
        @ActivityID = vaa.ActivityID,
        @IntendedPositionID = vaa.IntendedPositionID,
        @CurrentApplicationStatus = vaa.ApplicationStatus,
        @ActivityOrgID = va.OrgID
    FROM dbo.tbl_VolunteerActivityApplication vaa
    JOIN dbo.tbl_VolunteerActivity va ON vaa.ActivityID = va.ActivityID
    WHERE vaa.ApplicationID = @ApplicationID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'报名申请ID "%s" 不存在。', 16, 1, @ApplicationID);
        RETURN -1;
    END

    IF @ActivityOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权审核活动 "%s" 的报名申请，该活动不属于此组织。', 16, 1, @OperatingOrgID, @ActivityID);
        RETURN -11;
    END

    IF @CurrentApplicationStatus <> N'待审核'
    BEGIN
        RAISERROR(N'该报名申请当前状态为 "%s"，并非“待审核”，无法执行此审核操作。', 16, 1, @CurrentApplicationStatus);
        RETURN -2;
    END

    IF @NewStatus NOT IN (N'已通过', N'已拒绝')
    BEGIN
        RAISERROR(N'无效的目标审核状态 "%s"。', 16, 1, @NewStatus);
        RETURN -3;
    END

    SET @FinalPositionID = ISNULL(@ActualPositionID, @IntendedPositionID);

    IF @NewStatus = N'已通过' AND @FinalPositionID IS NULL
    BEGIN
        RAISERROR(N'审核通过时必须指定一个有效的实际岗位ID。', 16, 1);
        RETURN -4;
    END

    IF @NewStatus = N'已通过' AND @FinalPositionID IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Position WHERE PositionID = @FinalPositionID AND ActivityID = @ActivityID)
        BEGIN
            RAISERROR(N'指定的实际岗位ID "%s" 在活动 "%s" 中不存在或不匹配。', 16, 1, @FinalPositionID, @ActivityID);
            RETURN -5;
        END

        SELECT @ActivityRecruitmentCount = RecruitmentCount, @ActivityAcceptedCount = AcceptedCount
        FROM dbo.tbl_VolunteerActivity WHERE ActivityID = @ActivityID;

        SELECT @PositionRequired = RequiredVolunteers, @PositionRecruited = RecruitedVolunteers
        FROM dbo.tbl_Position WHERE PositionID = @FinalPositionID;

        IF @ActivityAcceptedCount >= @ActivityRecruitmentCount
        BEGIN
            RAISERROR(N'活动 "%s" 录取人数已满。', 16, 1, @ActivityID);
            RETURN -6;
        END

        IF @PositionRecruited >= @PositionRequired
        BEGIN
            RAISERROR(N'岗位 "%s" 招募人数已满。', 16, 1, @FinalPositionID);
            RETURN -7;
        END
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivityApplication
        SET ApplicationStatus = @NewStatus
        WHERE ApplicationID = @ApplicationID;

        IF @NewStatus = N'已通过' AND @FinalPositionID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @FinalPositionID)
            BEGIN
                INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn)
                VALUES (@VolunteerID, @ActivityID, @FinalPositionID, N'否');
            END

            UPDATE dbo.tbl_Position
            SET RecruitedVolunteers = RecruitedVolunteers + 1
            WHERE PositionID = @FinalPositionID;

            UPDATE dbo.tbl_VolunteerActivity
            SET AcceptedCount = AcceptedCount + 1
            WHERE ActivityID = @ActivityID;
        END

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(N'审核活动报名过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织更新志愿活动信息 (sp_OrgUpdateVolunteerActivity)
-- 描述: 组织更新已发布的志愿活动信息 (在特定条件下，例如活动未开始且处于待审核或审核通过状态)
-- 参数:
--   @OperatingOrgID CHAR(15): 执行操作的组织ID
--   @ActivityID CHAR(15): 要更新的活动ID
--   @ActivityName NVARCHAR(20): 新的活动名称 (可选)
--   @StartTime SMALLDATETIME: 新的开始时间 (可选)
--   @EndTime SMALLDATETIME: 新的结束时间 (可选)
--   @Location NVARCHAR(30): 新的地点 (可选)
--   @RecruitmentCount INT: 新的招募人数 (可选)
--   @ContactPersonPhone NVARCHAR(11): 新的联系电话 (可选)
--   @ActivityDurationHours INT: 新的活动时长 (可选, 但SP内部不会直接使用此值更新时长，时长通常由时段计算)
-- 返回值:
--   0: 更新成功
--  -1: 操作组织ID无效
--  -2: 活动ID不存在
--  -3: 无权修改非本组织的活动
--  -4: 活动状态或时间不允许修改
--  -5: 更新后的时间逻辑错误 (开始>=结束)
--  -6: 更新后的招募人数无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgUpdateVolunteerActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgUpdateVolunteerActivity;
GO

CREATE PROCEDURE dbo.sp_OrgUpdateVolunteerActivity (
    @OperatingOrgID CHAR(15),
    @ActivityID CHAR(15),
    @ActivityName NVARCHAR(20) = NULL,
    @StartTime SMALLDATETIME = NULL,
    @EndTime SMALLDATETIME = NULL,
    @Location NVARCHAR(30) = NULL,
    @RecruitmentCount INT = NULL,
    @ContactPersonPhone NVARCHAR(11) = NULL,
    @ActivityDurationHours INT = NULL -- SP不直接使用此参数更新 ActivityDurationHours，若表有此列，它可能由其他逻辑（如时段触发器）更新
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentActivityStatus NVARCHAR(10);
    DECLARE @ActivityOrgID CHAR(15);
    DECLARE @CurrentDbStartTime SMALLDATETIME; 

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -1;
    END

    SELECT @CurrentActivityStatus = ActivityStatus,
           @ActivityOrgID = OrgID,
           @CurrentDbStartTime = StartTime
    FROM dbo.tbl_VolunteerActivity
    WHERE ActivityID = @ActivityID;

    IF @ActivityOrgID IS NULL
    BEGIN
        RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @ActivityID);
        RETURN -2;
    END

    IF @ActivityOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权修改活动 "%s"，该活动不属于此组织。', 16, 1, @OperatingOrgID, @ActivityID);
        RETURN -3;
    END

    IF NOT (@CurrentActivityStatus IN (N'待审核', N'审核通过') AND @CurrentDbStartTime > GETDATE())
    BEGIN
        RAISERROR(N'活动 "%s" 当前状态为 "%s" 或已开始/已过开始时间，不允许修改。', 16, 1, @ActivityID, @CurrentActivityStatus);
        RETURN -4;
    END
    
    DECLARE @EffectiveStartTime SMALLDATETIME = ISNULL(@StartTime, @CurrentDbStartTime);
    DECLARE @CurrentDbEndTime SMALLDATETIME = (SELECT EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = @ActivityID);
    DECLARE @EffectiveEndTime SMALLDATETIME = ISNULL(@EndTime, @CurrentDbEndTime);


    IF @EffectiveStartTime >= @EffectiveEndTime
    BEGIN
        RAISERROR(N'更新后的活动开始时间必须早于结束时间。', 16, 1);
        RETURN -5;
    END

    IF @RecruitmentCount IS NOT NULL AND @RecruitmentCount <= 0
    BEGIN
        RAISERROR(N'更新后的招募人数必须大于0。', 16, 1);
        RETURN -6;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivity
        SET ActivityName = ISNULL(@ActivityName, ActivityName),
            StartTime = ISNULL(@StartTime, StartTime),
            EndTime = ISNULL(@EndTime, EndTime),
            Location = ISNULL(@Location, Location),
            RecruitmentCount = ISNULL(@RecruitmentCount, RecruitmentCount),
            ContactPersonPhone = ISNULL(@ContactPersonPhone, ContactPersonPhone),
            ActivityStatus = N'待审核' 
        WHERE ActivityID = @ActivityID;

        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'更新志愿活动信息过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织更新志愿培训信息 (sp_OrgUpdateVolunteerTraining)
-- 描述: 组织更新已发布的志愿培训信息 (在特定条件下)
-- 参数:
--   @OperatingOrgID CHAR(15): 执行操作的组织ID
--   @TrainingID CHAR(15): 要更新的培训ID
--   @TrainingName NVARCHAR(20): 新的培训名称 (可选)
--   @Theme NVARCHAR(15): 新的主题 (可选)
--   @StartTime SMALLDATETIME: 新的开始时间 (可选)
--   @EndTime SMALLDATETIME: 新的结束时间 (可选)
--   @Location NVARCHAR(30): 新的地点 (可选)
--   @RecruitmentCount INT: 新的招募人数 (可选)
--   @ContactPersonPhone NVARCHAR(11): 新的联系电话 (可选)
-- 返回值:
--   0: 更新成功
--  -1: 操作组织ID无效
--  -2: 培训ID不存在
--  -3: 无权修改非本组织的培训
--  -4: 培训状态或时间不允许修改 (只允许修改'待审核'且未开始的培训)
--  -5: 更新后的时间逻辑错误
--  -6: 更新后的招募人数无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgUpdateVolunteerTraining', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgUpdateVolunteerTraining;
GO
CREATE PROCEDURE dbo.sp_OrgUpdateVolunteerTraining (
    @OperatingOrgID CHAR(15),
    @TrainingID CHAR(15),
    @TrainingName NVARCHAR(20) = NULL,
    @Theme NVARCHAR(15) = NULL,
    @StartTime SMALLDATETIME = NULL,
    @EndTime SMALLDATETIME = NULL,
    @Location NVARCHAR(30) = NULL,
    @RecruitmentCount INT = NULL,
    @ContactPersonPhone NVARCHAR(11) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentTrainingStatus NVARCHAR(10);
    DECLARE @TrainingOrgID CHAR(15);
    DECLARE @CurrentDbTrainingStartTime SMALLDATETIME;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -1;
    END

    SELECT @CurrentTrainingStatus = TrainingStatus,
           @TrainingOrgID = OrgID,
           @CurrentDbTrainingStartTime = StartTime
    FROM dbo.tbl_VolunteerTraining
    WHERE TrainingID = @TrainingID;

    IF @TrainingOrgID IS NULL
    BEGIN
        RAISERROR(N'培训ID "%s" 不存在。', 16, 1, @TrainingID);
        RETURN -2;
    END

    IF @TrainingOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权修改培训 "%s"，该培训不属于此组织。', 16, 1, @OperatingOrgID, @TrainingID);
        RETURN -3;
    END

    IF NOT (@CurrentTrainingStatus = N'待审核' AND @CurrentDbTrainingStartTime > GETDATE())
    BEGIN
        RAISERROR(N'培训 "%s" 当前状态为 "%s" 或已开始/已过开始时间，或非待审核状态，不允许修改。', 16, 1, @TrainingID, @CurrentTrainingStatus);
        RETURN -4;
    END
    
    DECLARE @EffectiveTrainingStartTime SMALLDATETIME = ISNULL(@StartTime, @CurrentDbTrainingStartTime);
    DECLARE @CurrentDbTrainingEndTime SMALLDATETIME = (SELECT EndTime FROM dbo.tbl_VolunteerTraining WHERE TrainingID = @TrainingID);
    DECLARE @EffectiveTrainingEndTime SMALLDATETIME = ISNULL(@EndTime, @CurrentDbTrainingEndTime);

    IF @EffectiveTrainingStartTime >= @EffectiveTrainingEndTime
    BEGIN
        RAISERROR(N'更新后的培训开始时间必须早于结束时间。', 16, 1);
        RETURN -5;
    END

    IF @RecruitmentCount IS NOT NULL AND @RecruitmentCount <= 0
    BEGIN
        RAISERROR(N'更新后的招募人数必须大于0。', 16, 1);
        RETURN -6;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerTraining
        SET TrainingName = ISNULL(@TrainingName, TrainingName),
            Theme = ISNULL(@Theme, Theme),
            StartTime = ISNULL(@StartTime, StartTime),
            EndTime = ISNULL(@EndTime, EndTime),
            Location = ISNULL(@Location, Location),
            RecruitmentCount = ISNULL(@RecruitmentCount, RecruitmentCount),
            ContactPersonPhone = ISNULL(@ContactPersonPhone, ContactPersonPhone),
            TrainingStatus = N'待审核'
        WHERE TrainingID = @TrainingID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'更新志愿培训信息过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织取消事件 (活动或培训) (sp_OrgCancelEvent)
-- 描述: 组织取消尚未开始的志愿活动或培训，将其状态设为'已停用'
--       如果取消的是活动，相关报名申请的状态也会更新。
-- 注意: 取消活动时，确保 tbl_VolunteerActivityApplication.ApplicationStatus 的 CHECK 约束包含 N'取消报名'
-- 参数:
--   @OperatingOrgID CHAR(15): 执行操作的组织ID
--   @EventType NVARCHAR(10): 事件类型 ('Activity' 或 'Training')
--   @EventID CHAR(15): 要取消的事件ID
-- 返回值:
--   0: 取消成功
--  -1: 操作组织ID无效
--  -2: 事件ID不存在
--  -3: 无权取消非本组织的事件
--  -4: 事件状态或时间不允许取消
--  -5: 无效的事件类型
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgCancelEvent', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgCancelEvent;
GO

CREATE PROCEDURE dbo.sp_OrgCancelEvent (
    @OperatingOrgID CHAR(15),
    @EventType NVARCHAR(10), -- 'Activity' 或 'Training'
    @EventID CHAR(15)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentEventStatus NVARCHAR(10);
    DECLARE @EventOrgID CHAR(15);
    DECLARE @EventStartTime SMALLDATETIME;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -1;
    END

    IF @EventType = N'Activity'
    BEGIN
        SELECT @CurrentEventStatus = ActivityStatus, @EventOrgID = OrgID, @EventStartTime = StartTime
        FROM dbo.tbl_VolunteerActivity
        WHERE ActivityID = @EventID;

        IF @EventOrgID IS NULL
        BEGIN
            RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @EventID);
            RETURN -2;
        END

        IF @EventOrgID <> @OperatingOrgID
        BEGIN
            RAISERROR(N'组织 "%s" 无权取消活动 "%s"，该活动不属于此组织。', 16, 1, @OperatingOrgID, @EventID);
            RETURN -3;
        END

        IF NOT (@CurrentEventStatus IN (N'待审核', N'审核通过') AND @EventStartTime > GETDATE())
        BEGIN
            RAISERROR(N'活动 "%s" 当前状态为 "%s" 或已开始/已过开始时间，不允许取消。', 16, 1, @EventID, @CurrentEventStatus);
            RETURN -4;
        END

        BEGIN TRANSACTION;
        BEGIN TRY
            UPDATE dbo.tbl_VolunteerActivity
            SET ActivityStatus = N'已停用'
            WHERE ActivityID = @EventID;

            UPDATE dbo.tbl_VolunteerActivityApplication
            SET ApplicationStatus = N'取消报名' -- 重要: 表CHECK约束需包含此值
            WHERE ActivityID = @EventID AND ApplicationStatus IN (N'待审核', N'已通过');
            
            COMMIT TRANSACTION;
            RETURN 0;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RAISERROR(N'取消志愿活动过程中发生未知错误。', 16, 1);
            RETURN -99;
        END CATCH
    END
    ELSE IF @EventType = N'Training'
    BEGIN
        SELECT @CurrentEventStatus = TrainingStatus, @EventOrgID = OrgID, @EventStartTime = StartTime
        FROM dbo.tbl_VolunteerTraining
        WHERE TrainingID = @EventID;

        IF @EventOrgID IS NULL
        BEGIN
            RAISERROR(N'培训ID "%s" 不存在。', 16, 1, @EventID);
            RETURN -2;
        END

        IF @EventOrgID <> @OperatingOrgID
        BEGIN
            RAISERROR(N'组织 "%s" 无权取消培训 "%s"，该培训不属于此组织。', 16, 1, @OperatingOrgID, @EventID);
            RETURN -3;
        END

        IF NOT (@CurrentEventStatus IN (N'待审核', N'审核通过', N'进行中') AND @EventStartTime > GETDATE()) -- 使用了 '进行中'
        BEGIN
            RAISERROR(N'培训 "%s" 当前状态为 "%s" 或已开始/已过开始时间，不允许取消。只允许取消尚未开始且状态为“待审核”、“审核通过”或“进行中”的培训。', 16, 1, @EventID, @CurrentEventStatus);
            RETURN -4;
        END

        BEGIN TRY
            UPDATE dbo.tbl_VolunteerTraining
            SET TrainingStatus = N'已停用'
            WHERE TrainingID = @EventID;
            RETURN 0;
        END TRY
        BEGIN CATCH
            RAISERROR(N'取消志愿培训过程中发生未知错误。', 16, 1);
            RETURN -99;
        END CATCH
    END
    ELSE
    BEGIN
        RAISERROR(N'无效的事件类型 "%s"。有效值为 "Activity" 或 "Training"。', 16, 1, @EventType);
        RETURN -5;
    END
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织对参与活动的志愿者进行评分 (sp_OrgRateVolunteerInActivity)
-- 描述: 组织对参与本组织活动的志愿者进行评分。
-- 参数:
--   @OperatingOrgID CHAR(15): 执行操作的组织ID
--   @VolunteerID CHAR(15): 被评分的志愿者ID
--   @ActivityID CHAR(15): 相关的活动ID
--   @ActualPositionID CHAR(15): 志愿者在该活动中实际担任的岗位ID
--   @Rating INT: 评分 (1-10)
-- 返回值:
--   0: 评分成功
--  -1: 操作组织ID无效
--  -2: 活动ID不存在
--  -3: 无权对此活动的参与者评分 (活动不属于本组织)
--  -4: 未找到指定的志愿者参与记录
--  -5: 活动尚未结束，无法评分
--  -6: 评分值无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgRateVolunteerInActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgRateVolunteerInActivity;
GO
CREATE PROCEDURE dbo.sp_OrgRateVolunteerInActivity (
    @OperatingOrgID CHAR(15),
    @VolunteerID CHAR(15),
    @ActivityID CHAR(15),
    @ActualPositionID CHAR(15),
    @Rating INT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActivityOrgID CHAR(15);
    DECLARE @ActivityStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -1;
    END

    SELECT @ActivityOrgID = OrgID, @ActivityStatus = ActivityStatus
    FROM dbo.tbl_VolunteerActivity WHERE ActivityID = @ActivityID;

    IF @ActivityOrgID IS NULL
    BEGIN
        RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @ActivityID);
        RETURN -2;
    END

    IF @ActivityOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权对此活动 "%s" 的参与者评分，该活动不属于此组织。', 16, 1, @OperatingOrgID, @ActivityID);
        RETURN -3;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityParticipation
                   WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @ActualPositionID)
    BEGIN
        RAISERROR(N'未找到志愿者 "%s" 在活动 "%s" 岗位 "%s" 上的参与记录。', 16, 1, @VolunteerID, @ActivityID, @ActualPositionID);
        RETURN -4;
    END

    IF @ActivityStatus <> N'已结束'
    BEGIN
        RAISERROR(N'活动 "%s" 尚未结束，暂时无法对参与者评分。', 16, 1, @ActivityID);
        RETURN -5;
    END

    IF @Rating < 1 OR @Rating > 10
    BEGIN
        RAISERROR(N'评分值 "%d" 无效，必须在1到10之间。', 16, 1, @Rating);
        RETURN -6;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivityParticipation
        SET OrgToVolunteerRating = @Rating
        WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @ActualPositionID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'组织对志愿者评分过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 组织对参与培训的志愿者进行评分 (sp_OrgRateVolunteerInTraining)
-- 描述: 组织对参与本组织培训的志愿者进行评分。
-- 参数:
--   @OperatingOrgID CHAR(15): 执行操作的组织ID
--   @VolunteerID CHAR(15): 被评分的志愿者ID
--   @TrainingID CHAR(15): 相关的培训ID
--   @Rating INT: 评分 (1-10)
-- 返回值:
--   0: 评分成功
--  -1: 操作组织ID无效
--  -2: 培训ID不存在
--  -3: 无权对此培训的参与者评分 (培训不属于本组织)
--  -4: 未找到指定的志愿者参与记录
--  -5: 培训尚未结束，无法评分
--  -6: 评分值无效
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_OrgRateVolunteerInTraining', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_OrgRateVolunteerInTraining;
GO
CREATE PROCEDURE dbo.sp_OrgRateVolunteerInTraining (
    @OperatingOrgID CHAR(15),
    @VolunteerID CHAR(15),
    @TrainingID CHAR(15),
    @Rating INT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TrainingOrgID CHAR(15);
    DECLARE @TrainingStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OperatingOrgID)
    BEGIN
        RAISERROR(N'操作的组织ID "%s" 无效。', 16, 1, @OperatingOrgID);
        RETURN -1;
    END

    SELECT @TrainingOrgID = OrgID, @TrainingStatus = TrainingStatus
    FROM dbo.tbl_VolunteerTraining WHERE TrainingID = @TrainingID;

    IF @TrainingOrgID IS NULL
    BEGIN
        RAISERROR(N'培训ID "%s" 不存在。', 16, 1, @TrainingID);
        RETURN -2;
    END

    IF @TrainingOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权对此培训 "%s" 的参与者评分，该培训不属于此组织。', 16, 1, @OperatingOrgID, @TrainingID);
        RETURN -3;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_VolunteerTrainingParticipation
                   WHERE VolunteerID = @VolunteerID AND TrainingID = @TrainingID)
    BEGIN
        RAISERROR(N'未找到志愿者 "%s" 在培训 "%s" 上的参与记录。', 16, 1, @VolunteerID, @TrainingID);
        RETURN -4;
    END

    IF @TrainingStatus <> N'已结束'
    BEGIN
        RAISERROR(N'培训 "%s" 尚未结束 (当前状态: %s)，暂时无法对参与者评分。', 16, 1, @TrainingID, @TrainingStatus);
        RETURN -5;
    END

    IF @Rating < 1 OR @Rating > 10
    BEGIN
        RAISERROR(N'评分值 "%d" 无效，必须在1到10之间。', 16, 1, @Rating);
        RETURN -6;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerTrainingParticipation
        SET OrgToVolunteerRating = @Rating
        WHERE VolunteerID = @VolunteerID AND TrainingID = @TrainingID;
        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'组织对志愿者培训评分过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 录入活动或培训时段 (sp_AddEventTimeslot)
-- 描述: 为指定的活动或培训录入一个新的时段信息。
-- 参数:
--   @TimeslotID CHAR(15): 新时段的唯一ID (应用生成)
--   @EventID CHAR(15): 关联的事件ID (例如: 'act_xxxx' 或 'trn_xxxx')
--   @StartTime SMALLDATETIME: 时段开始时间
--   @EndTime SMALLDATETIME: 时段结束时间
--   @OperatingOrgID CHAR(15): (可选) 执行操作的组织ID，用于权限校验
-- 返回值:
--   0: 成功
--  -1: 时段ID已存在
--  -2: 事件ID无效
--  -3: 开始时间晚于或等于结束时间
--  -4: (可选) 操作组织无权为该事件添加时段
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AddEventTimeslot', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddEventTimeslot;
GO

CREATE PROCEDURE dbo.sp_AddEventTimeslot (
    @TimeslotID CHAR(15),
    @EventID CHAR(15),
    @StartTime SMALLDATETIME,
    @EndTime SMALLDATETIME,
    @OperatingOrgID CHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.tbl_ActivityTimeslot WHERE TimeslotID = @TimeslotID)
    BEGIN
        RAISERROR(N'时段ID "%s" 已存在。', 16, 1, @TimeslotID);
        RETURN -1;
    END

    IF @StartTime >= @EndTime
    BEGIN
        RAISERROR(N'时段开始时间必须早于结束时间。', 16, 1);
        RETURN -3;
    END

    DECLARE @EventExists INT = 0;
    DECLARE @EventOrgID CHAR(15);

    IF LEFT(@EventID, 3) = 'act' -- 假设活动ID以 'act' 开头
    BEGIN
        SELECT @EventExists = 1, @EventOrgID = OrgID
        FROM dbo.tbl_VolunteerActivity
        WHERE ActivityID = @EventID;
    END
    ELSE IF LEFT(@EventID, 3) = 'trn' -- 假设培训ID以 'trn' 开头
    BEGIN
        SELECT @EventExists = 1, @EventOrgID = OrgID
        FROM dbo.tbl_VolunteerTraining
        WHERE TrainingID = @EventID;
    END

    IF @EventExists = 0
    BEGIN
        RAISERROR(N'事件ID "%s" 在活动表或培训表中均未找到，或ID格式不正确。', 16, 1, @EventID);
        RETURN -2;
    END

    IF @OperatingOrgID IS NOT NULL AND @EventOrgID <> @OperatingOrgID
    BEGIN
        RAISERROR(N'组织 "%s" 无权为事件 "%s" 添加时段，该事件不属于此组织。', 16, 1, @OperatingOrgID, @EventID);
        RETURN -4;
    END

    BEGIN TRY
        INSERT INTO dbo.tbl_ActivityTimeslot (TimeslotID, EventID, StartTime, EndTime)
        VALUES (@TimeslotID, @EventID, @StartTime, @EndTime);

        RETURN 0;
    END TRY
    BEGIN CATCH
        RAISERROR(N'录入活动/培训时段过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始创建组织综合评分计算相关存储过程 ---';
GO

--------------------------------------------------------------------------------
-- 阶段一：计算并存储单个活动/培训的平均分
-- 存储过程名称： sp_finalize_event_average_scores
-- 执行方式： 由数据库定时任务定期（例如，每日一次）调用。
-- 核心功能：
--   1. 识别评价窗口期已结束（例如，事件结束时间 + 7天 < 当前时间）的活动/培训。
--   2. 对每个此类事件，从其参与记录中收集志愿者提交的评分，计算平均分。
--   3. 将计算出的平均分更新到该活动记录的 ActivityRating 字段或培训记录的 TrainingRating 字段。
--   4. 更新事件的 IsRatingAggregated 标记为‘YES’，表示其评分已汇总，避免重复计算。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_finalize_event_average_scores', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_finalize_event_average_scores;
GO

CREATE PROCEDURE dbo.sp_finalize_event_average_scores
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'开始执行 sp_finalize_event_average_scores...';

    -- 更新活动的平均评分
    PRINT N'正在处理活动评分汇总...';
    DECLARE @ActivityID_Eval CHAR(15);
    DECLARE @AvgActivityRating DECIMAL(3,1); 

    DECLARE cur_activities CURSOR LOCAL FAST_FORWARD FOR
    SELECT ActivityID
    FROM dbo.tbl_VolunteerActivity
    WHERE EndTime < DATEADD(day, -7, GETDATE()) 
      AND (IsRatingAggregated = 'NO' OR IsRatingAggregated IS NULL); 

    OPEN cur_activities;
    FETCH NEXT FROM cur_activities INTO @ActivityID_Eval;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @AvgActivityRating = AVG(CONVERT(DECIMAL(3,1), VolunteerToOrgRating))
        FROM dbo.tbl_VolunteerActivityParticipation
        WHERE ActivityID = @ActivityID_Eval
          AND VolunteerToOrgRating IS NOT NULL; 

        IF @AvgActivityRating IS NOT NULL
        BEGIN
            UPDATE dbo.tbl_VolunteerActivity
            SET ActivityRating = @AvgActivityRating, 
                IsRatingAggregated = 'YES'
            WHERE ActivityID = @ActivityID_Eval;
            PRINT N'活动 ' + @ActivityID_Eval + N' 平均分已更新为: ' + ISNULL(CONVERT(NVARCHAR(10), @AvgActivityRating), 'N/A');
        END
        ELSE
        BEGIN
            UPDATE dbo.tbl_VolunteerActivity
            SET IsRatingAggregated = 'YES',
                ActivityRating = NULL 
            WHERE ActivityID = @ActivityID_Eval;
            PRINT N'活动 ' + @ActivityID_Eval + N' 没有有效评分进行汇总。';
        END

        FETCH NEXT FROM cur_activities INTO @ActivityID_Eval;
    END
    CLOSE cur_activities;
    DEALLOCATE cur_activities;
    PRINT N'活动评分汇总处理完毕。';

    -- 更新培训的平均评分
    PRINT N'正在处理培训评分汇总...';
    DECLARE @TrainingID_Eval CHAR(15);
    DECLARE @AvgTrainingRating DECIMAL(3,1); 

    DECLARE cur_trainings CURSOR LOCAL FAST_FORWARD FOR
    SELECT TrainingID
    FROM dbo.tbl_VolunteerTraining
    WHERE EndTime < DATEADD(day, -7, GETDATE())
      AND (IsRatingAggregated = 'NO' OR IsRatingAggregated IS NULL);

    OPEN cur_trainings;
    FETCH NEXT FROM cur_trainings INTO @TrainingID_Eval;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @AvgTrainingRating = AVG(CONVERT(DECIMAL(3,1), VolunteerToOrgRating))
        FROM dbo.tbl_VolunteerTrainingParticipation
        WHERE TrainingID = @TrainingID_Eval
          AND VolunteerToOrgRating IS NOT NULL;

        IF @AvgTrainingRating IS NOT NULL
        BEGIN
            UPDATE dbo.tbl_VolunteerTraining
            SET TrainingRating = @AvgTrainingRating, 
                IsRatingAggregated = 'YES'
            WHERE TrainingID = @TrainingID_Eval;
            PRINT N'培训 ' + @TrainingID_Eval + N' 平均分已更新为: ' + ISNULL(CONVERT(NVARCHAR(10), @AvgTrainingRating), 'N/A');
        END
        ELSE
        BEGIN
            UPDATE dbo.tbl_VolunteerTraining
            SET IsRatingAggregated = 'YES',
                TrainingRating = NULL
            WHERE TrainingID = @TrainingID_Eval;
            PRINT N'培训 ' + @TrainingID_Eval + N' 没有有效评分进行汇总。';
        END
        FETCH NEXT FROM cur_trainings INTO @TrainingID_Eval;
    END
    CLOSE cur_trainings;
    DEALLOCATE cur_trainings;
    PRINT N'培训评分汇总处理完毕。';

    PRINT N'sp_finalize_event_average_scores 执行完毕。';
END
GO

--------------------------------------------------------------------------------
-- 阶段二：计算并更新组织的最终综合评分
-- 存储过程名称： sp_calculate_organization_overall_ratings
-- 执行方式： 由数据库定时任务定期调用（例如，每日一次，应在 sp_finalize_event_average_scores 后运行）。
-- 核心功能：
--   1. 遍历所有“已认证”的组织。
--   2. 计算组织的“志愿活动平均分”（基于已汇总的活动评分）。
--   3. 计算组织的“培训平均分”（基于已汇总的培训评分）。
--   4. 获取组织的活动次数、培训次数、活动总时长。
--   5. 根据预设规则将次数和时长转换为对应的单项得分（1-10分制）。
--   6. 使用公式和权重计算最终的组织综合评分，并更新到 tbl_Organization.OrgRating。
-- 公式: 综合评分 = 0.3*活动平均分 + 0.2*培训平均分 + 0.2*活动次数分 + 0.1*培训次数分 + 0.2*活动总时长分
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_calculate_organization_overall_ratings', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_calculate_organization_overall_ratings;
GO

CREATE PROCEDURE dbo.sp_calculate_organization_overall_ratings
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'开始执行 sp_calculate_organization_overall_ratings... (已修改AVG计算和PRINT)';

    DECLARE @OrgID_Calc CHAR(15);
    DECLARE @AvgActivityRating_Org_Precise DECIMAL(10,2);
    DECLARE @AvgTrainingRating_Org_Precise DECIMAL(10,2);
    DECLARE @ActivityCount_Calc INT;
    DECLARE @TotalServiceHours_Calc INT;
    DECLARE @TrainingCount_Calc INT;
    
    DECLARE @Score_AvgActivityRating DECIMAL(3,1);
    DECLARE @Score_AvgTrainingRating DECIMAL(3,1);
    DECLARE @Score_ActivityCount DECIMAL(3,1);
    DECLARE @Score_TrainingCount DECIMAL(3,1);
    DECLARE @Score_TotalServiceHours DECIMAL(3,1);
    DECLARE @FinalOrgRating_Calc DECIMAL(10,4); 
    DECLARE @FinalOrgRating_Store DECIMAL(3,1);
    DECLARE @CurrentOrgRating_ForPrint NVARCHAR(10); -- 新增变量用于PRINT

    -- 定义权重
    DECLARE @Weight_AvgActivityRating DECIMAL(3,2) = 0.3;
    DECLARE @Weight_AvgTrainingRating DECIMAL(3,2) = 0.2;
    DECLARE @Weight_ActivityCount DECIMAL(3,2) = 0.2;
    DECLARE @Weight_TrainingCount DECIMAL(3,2) = 0.1;
    DECLARE @Weight_TotalServiceHours DECIMAL(3,2) = 0.2;

    DECLARE cur_organizations CURSOR LOCAL FAST_FORWARD FOR
    SELECT OrgID FROM dbo.tbl_Organization WHERE OrgAccountStatus = N'已认证'; 

    OPEN cur_organizations;
    FETCH NEXT FROM cur_organizations INTO @OrgID_Calc;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'正在为组织 ' + @OrgID_Calc + N' 计算综合评分...';

        -- 1. 计算组织的“志愿活动平均分”
        SELECT @AvgActivityRating_Org_Precise = AVG(CAST(ActivityRating AS DECIMAL(10,2)))
        FROM dbo.tbl_VolunteerActivity
        WHERE OrgID = @OrgID_Calc AND ActivityRating IS NOT NULL AND IsRatingAggregated = 'YES';
        SET @Score_AvgActivityRating = ISNULL(ROUND(@AvgActivityRating_Org_Precise, 1), 1.0);
        PRINT N'组织 ' + @OrgID_Calc + N': AvgActivityRating_Org_Precise = ' + ISNULL(CONVERT(NVARCHAR(20), @AvgActivityRating_Org_Precise), 'NULL') + N', Score_AvgActivityRating = ' + ISNULL(CONVERT(NVARCHAR(20), @Score_AvgActivityRating), 'NULL');

        -- 2. 计算组织的“培训平均分”
        SELECT @AvgTrainingRating_Org_Precise = AVG(CAST(TrainingRating AS DECIMAL(10,2)))
        FROM dbo.tbl_VolunteerTraining
        WHERE OrgID = @OrgID_Calc AND TrainingRating IS NOT NULL AND IsRatingAggregated = 'YES';
        SET @Score_AvgTrainingRating = ISNULL(ROUND(@AvgTrainingRating_Org_Precise, 1), 1.0);
        PRINT N'组织 ' + @OrgID_Calc + N': AvgTrainingRating_Org_Precise = ' + ISNULL(CONVERT(NVARCHAR(20), @AvgTrainingRating_Org_Precise), 'NULL') + N', Score_AvgTrainingRating = ' + ISNULL(CONVERT(NVARCHAR(20), @Score_AvgTrainingRating), 'NULL');

        -- 3. 获取组织的活动次数、培训次数、活动总时长
        SELECT @ActivityCount_Calc = ActivityCount,
               @TotalServiceHours_Calc = TotalServiceHours,
               @TrainingCount_Calc = TrainingCount
        FROM dbo.tbl_Organization
        WHERE OrgID = @OrgID_Calc;
        PRINT N'组织 ' + @OrgID_Calc + N': ActivityCount=' + ISNULL(CONVERT(NVARCHAR(10),@ActivityCount_Calc),'NULL') + N', TrainingCount=' + ISNULL(CONVERT(NVARCHAR(10),@TrainingCount_Calc),'NULL') + N', TotalServiceHours=' + ISNULL(CONVERT(NVARCHAR(10),@TotalServiceHours_Calc),'NULL');

        -- 4. 根据评分规则将次数和时长转换为对应的单项得分
        SET @Score_ActivityCount = 
            CASE 
                WHEN @ActivityCount_Calc >= 20 THEN 10.0 WHEN @ActivityCount_Calc >= 10 THEN 8.0
                WHEN @ActivityCount_Calc >= 5  THEN 6.0 WHEN @ActivityCount_Calc >= 1  THEN 4.0
                ELSE 1.0 END;
        PRINT N'组织 ' + @OrgID_Calc + N': Score_ActivityCount = ' + ISNULL(CONVERT(NVARCHAR(20), @Score_ActivityCount), 'NULL');

        SET @Score_TrainingCount = 
            CASE 
                WHEN @TrainingCount_Calc >= 10 THEN 10.0 WHEN @TrainingCount_Calc >= 5  THEN 8.0
                WHEN @TrainingCount_Calc >= 2  THEN 6.0 WHEN @TrainingCount_Calc >= 1  THEN 4.0
                ELSE 1.0 END;
        PRINT N'组织 ' + @OrgID_Calc + N': Score_TrainingCount = ' + ISNULL(CONVERT(NVARCHAR(20), @Score_TrainingCount), 'NULL');
        
        SET @Score_TotalServiceHours =  
            CASE 
                WHEN @TotalServiceHours_Calc >= 2000 THEN 10.0 WHEN @TotalServiceHours_Calc >= 1000 THEN 8.0
                WHEN @TotalServiceHours_Calc >= 500  THEN 6.0 WHEN @TotalServiceHours_Calc >= 100  THEN 4.0
                ELSE 1.0 END;
        PRINT N'组织 ' + @OrgID_Calc + N': Score_TotalServiceHours = ' + ISNULL(CONVERT(NVARCHAR(20), @Score_TotalServiceHours), 'NULL');
        
        -- 5. 使用公式和权重计算最终的组织综合评分
        SET @FinalOrgRating_Calc = (@Score_AvgActivityRating * @Weight_AvgActivityRating) +
                                   (@Score_AvgTrainingRating * @Weight_AvgTrainingRating) +
                                   (@Score_ActivityCount * @Weight_ActivityCount) +
                                   (@Score_TrainingCount * @Weight_TrainingCount) +
                                   (@Score_TotalServiceHours * @Weight_TotalServiceHours);
        PRINT N'组织 ' + @OrgID_Calc + N': FinalOrgRating_Calc (计算后，ROUND前) = ' + ISNULL(CONVERT(NVARCHAR(30), @FinalOrgRating_Calc, 2), 'NULL');

        -- 确保评分在1.0到10.0之间
        IF @FinalOrgRating_Calc > 10.0 SET @FinalOrgRating_Calc = 10.0;
        IF @FinalOrgRating_Calc < 1.0 SET @FinalOrgRating_Calc = 1.0;
        PRINT N'组织 ' + @OrgID_Calc + N': FinalOrgRating_Calc (调整范围后，ROUND前) = ' + ISNULL(CONVERT(NVARCHAR(30), @FinalOrgRating_Calc, 2), 'NULL');

        -- 四舍五入到一位小数
        SET @FinalOrgRating_Store = ROUND(@FinalOrgRating_Calc, 1);
        PRINT N'组织 ' + @OrgID_Calc + N': FinalOrgRating_Store (ROUND后，准备存入) = ' + ISNULL(CONVERT(NVARCHAR(20), @FinalOrgRating_Store), 'NULL');

        -- 更新组织的综合评分
        UPDATE dbo.tbl_Organization
        SET OrgRating = @FinalOrgRating_Store
        WHERE OrgID = @OrgID_Calc;
        
        -- **修正点**：先将查询结果存入变量，再用于PRINT
        SELECT @CurrentOrgRating_ForPrint = CONVERT(NVARCHAR(10), OrgRating)
        FROM dbo.tbl_Organization
        WHERE OrgID = @OrgID_Calc;

        PRINT N'组织 ' + @OrgID_Calc + N' 的新综合评分为 (从表中读取): ' + ISNULL(@CurrentOrgRating_ForPrint, 'NULL');

        FETCH NEXT FROM cur_organizations INTO @OrgID_Calc;
    END
    CLOSE cur_organizations;
    DEALLOCATE cur_organizations;

    PRINT N'sp_calculate_organization_overall_ratings 执行完毕。';
END
GO

PRINT N'--- 组织综合评分计算相关存储过程创建完毕 ---';
GO

PRINT N'组织机构相关存储过程已创建/更新完毕。';
PRINT N'重要：sp_OrgCancelEvent 用于取消活动时，请确保 tbl_VolunteerActivityApplication.ApplicationStatus 的 CHECK 约束包含 N''取消报名''。';
GO