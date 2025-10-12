--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者注册 (sp_RegisterVolunteer)
-- 描述: 处理新志愿者的注册请求。
-- 参数: (与您之前脚本中的定义一致)
--   @VolunteerID, @Username, @Password, @Name, @PhoneNumber, @IDCardNumber,
--   @Gender, @ServiceArea, @Country, @Ethnicity, @PoliticalStatus,
--   @HighestEducation, @EmploymentStatus, @ServiceCategory, @AccountStatus
-- 返回值:
--   0: 成功
--  -1: 用户名已存在
--  -2: 手机号已存在
--  -3: 身份证号已存在
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RegisterVolunteer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegisterVolunteer;
GO

CREATE PROCEDURE dbo.sp_RegisterVolunteer (
    -- @VolunteerID CHAR(15), -- 此参数已移除，ID由触发器生成
    @Username NVARCHAR(20),
    @Password NVARCHAR(50),
    @Name NVARCHAR(20),
    @PhoneNumber VARCHAR(11),
    @IDCardNumber VARCHAR(18),
    @Gender NCHAR(1),
    @ServiceArea NVARCHAR(50),
    @Country NVARCHAR(10) = N'中国',
    @Ethnicity NVARCHAR(10) = N'汉族',
    @PoliticalStatus NVARCHAR(20) = N'群众',
    @HighestEducation NVARCHAR(20) = NULL,
    @EmploymentStatus NVARCHAR(20) = NULL,
    @ServiceCategory NVARCHAR(20) = NULL,
    @AccountStatus NVARCHAR(10) = N'未实名认证'
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @GeneratedVolunteerID CHAR(15);

    IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE Username = @Username)
    BEGIN
        RAISERROR(N'用户名 "%s" 已存在。', 16, 1, @Username);
        RETURN -1; -- 用户名已存在
    END

    IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE PhoneNumber = @PhoneNumber)
    BEGIN
        RAISERROR(N'手机号码 "%s" 已被注册。', 16, 1, @PhoneNumber);
        RETURN -2; -- 手机号已存在
    END

    IF EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE IDCardNumber = @IDCardNumber)
    BEGIN
        RAISERROR(N'身份证号码 "%s" 已被注册。', 16, 1, @IDCardNumber);
        RETURN -3; -- 身份证号已存在
    END

    BEGIN TRY
        -- 注意：INSERT语句中不再包含VolunteerID列，其值将由触发器 trg_GenerateVolunteerID 自动填充
        INSERT INTO dbo.tbl_Volunteer (
            Username, Name, PhoneNumber, IDCardNumber, Password,
            Country, Gender, ServiceArea, Ethnicity, PoliticalStatus,
            HighestEducation, EmploymentStatus, ServiceCategory, AccountStatus,
            TotalVolunteerHours, VolunteerRating
        )
        VALUES (
            @Username, @Name, @PhoneNumber, @IDCardNumber, @Password,
            @Country, @Gender, @ServiceArea, @Ethnicity, @PoliticalStatus,
            @HighestEducation, @EmploymentStatus, @ServiceCategory, @AccountStatus,
            0.00, 0.00 -- 初始总时长和评分
        );

        -- 获取由触发器生成的新VolunteerID
        SELECT @GeneratedVolunteerID = VolunteerID 
        FROM dbo.tbl_Volunteer 
        WHERE Username = @Username;

        -- 返回新生成的VolunteerID给调用者
        SELECT @GeneratedVolunteerID AS GeneratedVolunteerID;

        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        -- 简化了错误处理，您可以根据需要保留或扩展原有的详细错误捕获逻辑
        RAISERROR(N'志愿者注册过程中发生未知错误。', 16, 1);
        RETURN -99; -- 其他错误
    END CATCH
END
GO
PRINT N'存储过程 [sp_RegisterVolunteer] 已修改。';
GO

PRINT N'--- 注册存储过程修改完毕 ---';
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者登录 (sp_VolunteerLogin)
-- 描述: 验证志愿者登录凭据。
-- 参数:
--   @Username: 志愿者登录用户名
--   @Password: 明文密码
-- 返回值:
--   0: 登录成功 (并返回志愿者基本信息)
--  -1: 用户名不存在
--  -2: 密码错误
--  -3: 账户被冻结
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_VolunteerLogin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_VolunteerLogin;
GO

CREATE PROCEDURE dbo.sp_VolunteerLogin (
    @Username NVARCHAR(20),
    @Password NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CorrectPassword NVARCHAR(50);
    DECLARE @VolunteerID_found CHAR(15);
    DECLARE @VolunteerName NVARCHAR(20);
    DECLARE @AccountStatus NVARCHAR(10);

    SELECT @CorrectPassword = Password, @VolunteerID_found = VolunteerID, @VolunteerName = Name, @AccountStatus = AccountStatus
    FROM dbo.tbl_Volunteer
    WHERE Username = @Username;

    IF @VolunteerID_found IS NULL
    BEGIN
        RAISERROR(N'志愿者用户名 "%s" 不存在。', 16, 1, @Username);
        RETURN -1; -- 用户名不存在
    END

    IF @AccountStatus = N'已冻结'
    BEGIN
        RAISERROR(N'志愿者账户 "%s" 已被冻结，无法登录。', 16, 1, @Username);
        RETURN -3; -- 账户被冻结
    END

    IF @CorrectPassword = @Password
    BEGIN
        SELECT VolunteerID, Username, Name, AccountStatus FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID_found; -- 返回一些志愿者信息
        RETURN 0; -- 登录成功
    END
    ELSE
    BEGIN
        RAISERROR(N'志愿者用户名 "%s" 密码错误。', 16, 1, @Username);
        RETURN -2; -- 密码错误
    END
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者更新个人信息 (sp_UpdateVolunteerProfile)
-- 描述: 志愿者更新自己的个人信息 (部分可选更新)。
-- 参数:
--   @VolunteerID CHAR(15): 要更新的志愿者ID
--   @Name NVARCHAR(20): 新的姓名 (可选)
--   @PhoneNumber VARCHAR(11): 新的手机号 (可选, 如果提供会检查唯一性)
--   @Gender NCHAR(1): 新的性别 (可选)
--   @ServiceArea NVARCHAR(50): 新的服务区域 (可选)
--   @Country, @Ethnicity, @PoliticalStatus, @HighestEducation, @EmploymentStatus, @ServiceCategory (均为可选)
-- 返回值:
--   0: 更新成功
--  -1: 志愿者ID不存在
--  -2: 新的手机号已被其他用户注册
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_UpdateVolunteerProfile', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateVolunteerProfile;
GO

CREATE PROCEDURE dbo.sp_UpdateVolunteerProfile (
    @VolunteerID CHAR(15),
    @Name NVARCHAR(20) = NULL,
    @PhoneNumber VARCHAR(11) = NULL,
    @Gender NCHAR(1) = NULL,
    @ServiceArea NVARCHAR(50) = NULL,
    @Country NVARCHAR(10) = NULL,
    @Ethnicity NVARCHAR(10) = NULL,
    @PoliticalStatus NVARCHAR(20) = NULL,
    @HighestEducation NVARCHAR(20) = NULL,
    @EmploymentStatus NVARCHAR(20) = NULL,
    @ServiceCategory NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID)
    BEGIN
        RAISERROR(N'志愿者ID "%s" 不存在，无法更新。', 16, 1, @VolunteerID);
        RETURN -1;
    END

    IF @PhoneNumber IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE PhoneNumber = @PhoneNumber AND VolunteerID <> @VolunteerID)
    BEGIN
        RAISERROR(N'新的手机号码 "%s" 已被其他用户注册。', 16, 1, @PhoneNumber);
        RETURN -2;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Volunteer
        SET Name = ISNULL(@Name, Name),
            PhoneNumber = ISNULL(@PhoneNumber, PhoneNumber),
            Gender = ISNULL(@Gender, Gender),
            ServiceArea = ISNULL(@ServiceArea, ServiceArea),
            Country = ISNULL(@Country, Country),
            Ethnicity = ISNULL(@Ethnicity, Ethnicity),
            PoliticalStatus = ISNULL(@PoliticalStatus, PoliticalStatus),
            HighestEducation = ISNULL(@HighestEducation, HighestEducation),
            EmploymentStatus = ISNULL(@EmploymentStatus, EmploymentStatus),
            ServiceCategory = ISNULL(@ServiceCategory, ServiceCategory)
        WHERE VolunteerID = @VolunteerID;

        RETURN 0; -- 更新成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'更新志愿者信息过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者修改自己的登录密码 (sp_ChangeVolunteerPassword)
-- 描述: 志愿者修改自己的登录密码。
-- 参数:
--   @VolunteerID CHAR(15): 志愿者ID
--   @OldPassword NVARCHAR(50): 旧的明文密码
--   @NewPassword NVARCHAR(50): 新的明文密码
-- 返回值:
--   0: 修改成功
--  -1: 志愿者不存在
--  -2: 旧密码错误
--  -3: 新密码与旧密码相同
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ChangeVolunteerPassword', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ChangeVolunteerPassword;
GO

CREATE PROCEDURE dbo.sp_ChangeVolunteerPassword (
    @VolunteerID CHAR(15),
    @OldPassword NVARCHAR(50),
    @NewPassword NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StoredPassword NVARCHAR(50);

    SELECT @StoredPassword = Password FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID;

    IF @StoredPassword IS NULL
    BEGIN
        RAISERROR(N'志愿者ID "%s" 不存在。', 16, 1, @VolunteerID);
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
        UPDATE dbo.tbl_Volunteer
        SET Password = @NewPassword
        WHERE VolunteerID = @VolunteerID;
        RETURN 0; -- 修改成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'修改志愿者密码过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者申请加入组织 (sp_VolunteerApplyToJoinOrganization)
-- (此存储过程已在 organization_procedures.sql 文件中提供过类似版本，为保持完整性此处也包含)
-- 描述: 志愿者向某个组织提交加入申请。
-- 参数:
--   @VolunteerID CHAR(15): 申请的志愿者ID
--   @OrgID CHAR(15): 申请加入的组织ID
-- 返回值:
--   0: 申请成功
--   1: 已申请或已加入，无需重复
--  -1: 志愿者ID不存在
--  -2: 组织ID不存在
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_VolunteerApplyToJoinOrganization', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_VolunteerApplyToJoinOrganization;
GO

CREATE PROCEDURE dbo.sp_VolunteerApplyToJoinOrganization (
    @VolunteerID CHAR(15),
    @OrgID CHAR(15)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID)
    BEGIN
        RAISERROR(N'志愿者ID "%s" 不存在。', 16, 1, @VolunteerID);
        RETURN -1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Organization WHERE OrgID = @OrgID)
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在。', 16, 1, @OrgID);
        RETURN -2;
    END

    IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerOrganizationJoin WHERE VolunteerID = @VolunteerID AND OrgID = @OrgID)
    BEGIN
        DECLARE @CurrentStatus NVARCHAR(3);
        SELECT @CurrentStatus = MemberStatus FROM dbo.tbl_VolunteerOrganizationJoin WHERE VolunteerID = @VolunteerID AND OrgID = @OrgID;
        RAISERROR(N'您已申请或已加入该组织，当前状态为: %s。无需重复申请。', 10, 1, @CurrentStatus);
        RETURN 1;
    END

    BEGIN TRY
        INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, JoinTime, MemberStatus)
        VALUES (@VolunteerID, @OrgID, GETDATE(), N'申请中');
        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'申请加入组织过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者报名参加志愿活动 (sp_ApplyForVolunteerActivity)
-- (此存储过程已在 organization_procedures.sql 文件中提供过类似版本，为保持完整性此处也包含)
-- 描述: 志愿者报名参加某个志愿活动。
-- 参数:
--   @ApplicationID CHAR(15): 报名申请ID (应用生成)
--   @VolunteerID CHAR(15): 报名的志愿者ID
--   @ActivityID CHAR(15): 报名的活动ID
--   @IntendedPositionID CHAR(15): 意向岗位ID (可选)
-- 返回值:
--   0: 成功
--   1: 已报名/申请
--  -1: 志愿者ID不存在
--  -2: 活动ID不存在
--  -3: 意向岗位ID在活动中不存在
--  -4: 活动状态不可报名
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ApplyForVolunteerActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ApplyForVolunteerActivity;
GO

CREATE PROCEDURE dbo.sp_ApplyForVolunteerActivity (
    @ApplicationID CHAR(15),
    @VolunteerID CHAR(15),
    @ActivityID CHAR(15),
    @IntendedPositionID CHAR(15) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActivityStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID)
    BEGIN
        RAISERROR(N'志愿者ID "%s" 不存在。', 16, 1, @VolunteerID);
        RETURN -1;
    END

    SELECT @ActivityStatus = ActivityStatus FROM dbo.tbl_VolunteerActivity WHERE ActivityID = @ActivityID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @ActivityID);
        RETURN -2;
    END

    IF @IntendedPositionID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.tbl_Position WHERE PositionID = @IntendedPositionID AND ActivityID = @ActivityID)
    BEGIN
        RAISERROR(N'意向岗位ID "%s" 在活动 "%s" 中不存在。', 16, 1, @IntendedPositionID, @ActivityID);
        RETURN -3;
    END

    IF @ActivityStatus NOT IN (N'审核通过', N'进行中') -- 假设只有这两种状态可以报名
    BEGIN
        RAISERROR(N'活动 "%s" 当前状态为 "%s"，不可报名。', 16, 1, @ActivityID, @ActivityStatus);
        RETURN -4;
    END

    IF EXISTS (SELECT 1 FROM dbo.tbl_VolunteerActivityApplication WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID)
    BEGIN
        RAISERROR(N'志愿者 "%s" 已报名或申请过活动 "%s"。', 10, 1, @VolunteerID, @ActivityID);
        RETURN 1;
    END

    BEGIN TRY
        INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus)
        VALUES (@ApplicationID, @VolunteerID, @ActivityID, @IntendedPositionID, GETDATE(), N'待审核');
        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'报名活动过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者取消活动报名 (sp_WithdrawActivityApplication)
-- 描述: 志愿者取消尚未被处理或在允许条件下的活动报名。
-- 参数:
--   @VolunteerID CHAR(15): 志愿者ID
--   @ApplicationID CHAR(15): 要取消的报名申请ID
-- 返回值:
--   0: 取消成功
--  -1: 报名申请ID不存在
--  -2: 此志愿者无权取消该报名
--  -3: 报名状态不允许取消 (例如已通过且活动即将开始)
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_WithdrawActivityApplication', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_WithdrawActivityApplication;
GO

CREATE PROCEDURE dbo.sp_WithdrawActivityApplication (
    @VolunteerID CHAR(15),
    @ApplicationID CHAR(15)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentApplicationStatus NVARCHAR(10);
    DECLARE @AppVolunteerID CHAR(15);
    DECLARE @ActivityID CHAR(15);
    DECLARE @ActivityStartTime SMALLDATETIME;

    SELECT @CurrentApplicationStatus = vaa.ApplicationStatus, 
           @AppVolunteerID = vaa.VolunteerID,
           @ActivityID = vaa.ActivityID,
           @ActivityStartTime = va.StartTime
    FROM dbo.tbl_VolunteerActivityApplication vaa
    JOIN dbo.tbl_VolunteerActivity va ON vaa.ActivityID = va.ActivityID
    WHERE vaa.ApplicationID = @ApplicationID;

    IF @AppVolunteerID IS NULL
    BEGIN
        RAISERROR(N'报名申请ID "%s" 不存在。', 16, 1, @ApplicationID);
        RETURN -1;
    END

    IF @AppVolunteerID <> @VolunteerID
    BEGIN
        RAISERROR(N'您无权取消不属于您的报名申请。', 16, 1);
        RETURN -2;
    END

    -- 业务规则：例如只允许在 '待审核' 状态取消，或者活动开始前一段时间内取消 '已通过' 的报名
    IF @CurrentApplicationStatus NOT IN (N'待审核') -- , N'已通过' -- 如果允许取消已通过的，需加上
    -- AND (DATEDIFF(hour, GETDATE(), @ActivityStartTime) < 24) -- 示例：活动开始前24小时内不能取消已通过的
    BEGIN
        RAISERROR(N'报名申请当前状态为 "%s"，不允许取消。', 16, 1, @CurrentApplicationStatus);
        RETURN -3;
    END

    BEGIN TRY
        -- 如果取消的是 '已通过' 的报名，可能需要将被占用的名额释放
        -- 此处简化，直接更新状态，复杂逻辑需应用层或触发器处理 AcceptedCount 和 RecruitedVolunteers
        UPDATE dbo.tbl_VolunteerActivityApplication
        SET ApplicationStatus = N'取消报名' -- 确保 CHECK 约束中有此状态
        WHERE ApplicationID = @ApplicationID;
        
        -- 如果是从'已通过'状态取消，需要对应减少活动和岗位的录取人数/已招募人数
        -- 这部分逻辑较为复杂，涉及查找参与记录等，为保持此SP相对简单，可考虑在应用层或触发器中处理
        -- 或者，如果业务不允许取消已通过的报名，则上面IF条件会更严格

        RETURN 0; -- 取消成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'取消活动报名过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者活动签到 (sp_VolunteerCheckInActivity)
-- 描述: 志愿者在活动现场进行签到。
-- 参数:
--   @VolunteerID CHAR(15): 签到的志愿者ID
--   @ActivityID CHAR(15): 签到的活动ID
--   @ActualPositionID CHAR(15): 签到时确认的实际岗位ID
-- 返回值:
--   0: 签到成功
--  -1: 未找到该志愿者在此活动此岗位的参与记录 (可能报名未通过或岗位不符)
--  -2: 活动尚未开始或已结束，无法签到
--  -3: 已签到，无需重复
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_VolunteerCheckInActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_VolunteerCheckInActivity;
GO

CREATE PROCEDURE dbo.sp_VolunteerCheckInActivity (
    @VolunteerID CHAR(15),
    @ActivityID CHAR(15),
    @ActualPositionID CHAR(15)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsCheckedIn NCHAR(1);
    DECLARE @ActivityStartTime SMALLDATETIME;
    DECLARE @ActivityEndTime SMALLDATETIME;
    DECLARE @ActivityStatus NVARCHAR(10);

    SELECT @ActivityStartTime = StartTime, @ActivityEndTime = EndTime, @ActivityStatus = ActivityStatus
    FROM dbo.tbl_VolunteerActivity
    WHERE ActivityID = @ActivityID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @ActivityID);
        RETURN -4; -- 活动不存在，放在参与记录检查前
    END

    SELECT @IsCheckedIn = IsCheckedIn
    FROM dbo.tbl_VolunteerActivityParticipation
    WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @ActualPositionID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'未找到志愿者 "%s" 在活动 "%s" 岗位 "%s" 的有效参与记录。请确认报名已通过且岗位正确。', 16, 1, @VolunteerID, @ActivityID, @ActualPositionID);
        RETURN -1;
    END

    -- 业务规则：例如，只允许在活动状态为“进行中”或活动开始后一段时间内签到
    IF @ActivityStatus <> N'进行中' -- 或者更灵活的时间窗口判断: GETDATE() < @ActivityStartTime OR GETDATE() > @ActivityEndTime
    BEGIN
        RAISERROR(N'活动 "%s" 当前状态为 "%s"，不在可签到时间范围内。', 16, 1, @ActivityID, @ActivityStatus);
        RETURN -2;
    END

    IF @IsCheckedIn = N'是'
    BEGIN
        RAISERROR(N'您已签到过活动 "%s"，无需重复签到。', 10, 1, @ActivityID);
        RETURN 1; -- 已签到
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivityParticipation
        SET IsCheckedIn = N'是'
        WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @ActualPositionID;
        RETURN 0; -- 签到成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'活动签到过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者对活动/组织评分 (sp_VolunteerRateOrganizationAfterActivity)
-- 描述: 志愿者在活动结束后对组织或活动进行评分。
-- 参数:
--   @VolunteerID CHAR(15): 评分的志愿者ID
--   @ActivityID CHAR(15): 相关的活动ID
--   @ActualPositionID CHAR(15): 志愿者在该活动中实际担任的岗位ID
--   @Rating INT: 评分 (1-10)
-- 返回值:
--   0: 评分成功
--  -1: 未找到参与记录
--  -2: 活动尚未结束或不处于可评分状态
--  -3: 评分值无效
--  -4: 此活动您已评过分
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_VolunteerRateOrganizationAfterActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_VolunteerRateOrganizationAfterActivity;
GO

CREATE PROCEDURE dbo.sp_VolunteerRateOrganizationAfterActivity (
    @VolunteerID CHAR(15),
    @ActivityID CHAR(15),
    @ActualPositionID CHAR(15),
    @Rating INT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ActivityStatus NVARCHAR(10);
    DECLARE @ExistingRating INT;

    SELECT @ActivityStatus = va.ActivityStatus, @ExistingRating = vap.VolunteerToOrgRating
    FROM dbo.tbl_VolunteerActivityParticipation vap
    JOIN dbo.tbl_VolunteerActivity va ON vap.ActivityID = va.ActivityID
    WHERE vap.VolunteerID = @VolunteerID AND vap.ActivityID = @ActivityID AND vap.ActualPositionID = @ActualPositionID;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'未找到您在活动 "%s" 岗位 "%s" 上的参与记录。', 16, 1, @ActivityID, @ActualPositionID);
        RETURN -1;
    END

    -- 业务规则：通常只允许对已结束的活动进行评分
    IF @ActivityStatus <> N'已结束'
    BEGIN
        RAISERROR(N'活动 "%s" 尚未结束或不处于可评分状态，暂时无法评分。', 16, 1, @ActivityID);
        RETURN -2;
    END

    IF @Rating < 1 OR @Rating > 10
    BEGIN
        RAISERROR(N'评分值 "%d" 无效，必须在1到10之间。', 16, 1, @Rating);
        RETURN -3;
    END
    
    IF @ExistingRating IS NOT NULL
    BEGIN
        RAISERROR(N'您已对活动 "%s" 进行过评分。', 10, 1, @ActivityID);
        RETURN 1; -- 已评分
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivityParticipation
        SET VolunteerToOrgRating = @Rating
        WHERE VolunteerID = @VolunteerID AND ActivityID = @ActivityID AND ActualPositionID = @ActualPositionID;
        
        -- 可以在此触发更新活动总评分或组织总评分的逻辑 (如果需要)
        -- 例如，更新 tbl_VolunteerActivity 的 ActivityRating (如果该评分是汇总所有志愿者评分的平均值)
        -- 或者更新 tbl_Organization 的 OrgRating
        
        RETURN 0; -- 评分成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'志愿者对活动评分过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 志愿者提交投诉 (sp_SubmitComplaintByVolunteer)
-- 描述: 志愿者提交一个新的投诉。
-- 参数:
--   @ComplaintID CHAR(15): 投诉ID (应用生成)
--   @ComplainantVolunteerID CHAR(15): 发起投诉的志愿者ID
--   @ComplaintTargetID CHAR(15): 被投诉的对象ID (带前缀)
--   @ComplaintType NVARCHAR(10): 投诉类型
--   @ComplaintContent NVARCHAR(MAX): 投诉内容
--   @EvidenceLink NVARCHAR(255): 证据链接 (可选)
-- 返回值:
--   0: 提交成功
--  -1: 发起投诉的志愿者ID不存在
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_SubmitComplaintByVolunteer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SubmitComplaintByVolunteer;
GO

CREATE PROCEDURE dbo.sp_SubmitComplaintByVolunteer (
    @ComplaintID CHAR(15),
    @ComplainantVolunteerID CHAR(15),
    @ComplaintTargetID CHAR(15),
    @ComplaintType NVARCHAR(10),
    @ComplaintContent NVARCHAR(MAX),
    @EvidenceLink NVARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @ComplainantVolunteerID)
    BEGIN
        RAISERROR(N'发起投诉的志愿者ID "%s" 不存在。', 16, 1, @ComplainantVolunteerID);
        RETURN -1;
    END

    -- ComplaintTargetID 的存在性校验应在应用层根据其前缀进行，或在此SP中增加TargetType参数进行判断

    BEGIN TRY
        INSERT INTO dbo.tbl_Complaint (
            ComplaintID, ComplaintTime, ComplainantID, ComplaintTargetID,
            ComplaintType, ComplaintContent, EvidenceLink, ProcessingStatus,
            VisitResult -- 其他字段会有默认值或在处理时更新
        )
        VALUES (
            @ComplaintID, GETDATE(), @ComplainantVolunteerID, @ComplaintTargetID,
            @ComplaintType, @ComplaintContent, @EvidenceLink, N'未处理',
            N'满意' -- 假设 VisitResult 默认为满意，或根据业务设为NULL
        );
        RETURN 0; -- 提交成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'提交投诉过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

-- 注意：
-- 1. 评分和时长相关的更新 (如更新tbl_Volunteer.TotalVolunteerHours, tbl_Organization.TotalServiceHours, tbl_Organization.OrgRating)
--    可以考虑在对应的参与表（tbl_VolunteerActivityParticipation, tbl_VolunteerTrainingParticipation）上创建触发器来自动计算和更新，
--    或者创建单独的存储过程（例如 sp_UpdateVolunteerTotalHours）由应用层在适当的时候调用。
--    为保持单个存储过程的职责单一，我没有在上述评分或签到过程中直接更新这些总计/平均值。
-- 2. sp_WithdrawActivityApplication 中，如果取消的是已通过的报名，也需要更新 tbl_Position.RecruitedVolunteers 和 tbl_VolunteerActivity.AcceptedCount，
--    这部分逻辑可以添加到该存储过程中，或者也通过触发器实现。
