--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员登录 (sp_AdminLogin)
-- 描述: 验证管理员登录凭据。
-- 参数:
--   @AdminIdentifier: 管理员ID
--   @Password: 明文密码
-- 返回值:
--   0: 登录成功 (并返回管理员基本信息)
--  -1: 用户不存在
--  -2: 密码错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AdminLogin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AdminLogin;
GO

CREATE PROCEDURE dbo.sp_AdminLogin (
    @AdminIdentifier CHAR(15), -- Changed from NVARCHAR(20) to match AdminID type
    @Password NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CorrectPassword NVARCHAR(50);
    DECLARE @AdminID_found CHAR(15);

    -- 尝试通过AdminID查找管理员
    SELECT @CorrectPassword = Password, @AdminID_found = AdminID
    FROM dbo.tbl_Administrator
    WHERE AdminID = @AdminIdentifier;

    IF @AdminID_found IS NULL
    BEGIN
        RAISERROR(N'管理员ID "%s" 不存在。', 16, 1, @AdminIdentifier); -- Clarified error message
        RETURN -1; -- 用户不存在
    END

    IF @CorrectPassword = @Password
    BEGIN
        SELECT AdminID, Name, CurrentPosition, PermissionLevel FROM dbo.tbl_Administrator WHERE AdminID = @AdminID_found;
        RETURN 0; -- 登录成功
    END
    ELSE
    BEGIN
        RAISERROR(N'管理员ID "%s" 密码错误。', 16, 1, @AdminIdentifier); -- Clarified error message
        RETURN -2; -- 密码错误
    END
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员修改自己的密码 (sp_ChangeAdminPassword)
-- 描述: 管理员修改自己的登录密码。
-- 参数:
--   @AdminID: 管理员ID
--   @OldPassword: 旧的明文密码
--   @NewPassword: 新的明文密码
-- 返回值:
--   0: 修改成功
--  -1: 管理员不存在
--  -2: 旧密码错误
--  -3: 新密码与旧密码相同
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ChangeAdminPassword', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ChangeAdminPassword;
GO

CREATE PROCEDURE dbo.sp_ChangeAdminPassword (
    @AdminID CHAR(15),
    @OldPassword NVARCHAR(50),
    @NewPassword NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StoredPassword NVARCHAR(50);

    SELECT @StoredPassword = Password FROM dbo.tbl_Administrator WHERE AdminID = @AdminID;

    IF @StoredPassword IS NULL
    BEGIN
        RAISERROR(N'管理员ID "%s" 不存在。', 16, 1, @AdminID);
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

    -- 可以在此添加新密码复杂度校验逻辑 (例如长度、字符类型等)

    BEGIN TRY
        UPDATE dbo.tbl_Administrator
        SET Password = @NewPassword
        WHERE AdminID = @AdminID;
        RETURN 0; -- 修改成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'修改密码过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员审核组织机构注册申请 (sp_ReviewOrganizationRegistration)
-- 描述: 管理员审核组织机构的注册申请，更新其账户状态。
-- 参数:
--   @ReviewingAdminID: 执行审核的管理员ID
--   @OrgID: 被审核的组织ID
--   @NewStatus: 新的账户状态 (例如: N'已认证', N'认证未通过', N'冻结')
-- 返回值:
--   0: 操作成功
--  -1: 组织ID不存在
--  -2: 当前组织状态不是'待认证'
--  -3: 无效的新状态值
--  -4: 无效的审核员ID
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ReviewOrganizationRegistration', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReviewOrganizationRegistration;
GO

CREATE PROCEDURE dbo.sp_ReviewOrganizationRegistration (
    @ReviewingAdminID CHAR(15),
    @OrgID CHAR(15),
    @NewStatus NVARCHAR(10)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentOrgStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @ReviewingAdminID)
    BEGIN
        RAISERROR(N'审核操作的管理员ID "%s" 无效。', 16, 1, @ReviewingAdminID);
        RETURN -4;
    END

    SELECT @CurrentOrgStatus = OrgAccountStatus FROM dbo.tbl_Organization WHERE OrgID = @OrgID;

    IF @CurrentOrgStatus IS NULL
    BEGIN
        RAISERROR(N'组织ID "%s" 不存在。', 16, 1, @OrgID);
        RETURN -1;
    END

    IF @CurrentOrgStatus <> N'待认证'
    BEGIN
        RAISERROR(N'组织 "%s" 当前状态为 "%s"，并非“待认证”，无法执行此审核操作。', 16, 1, @OrgID, @CurrentOrgStatus);
        RETURN -2;
    END

    IF @NewStatus NOT IN (N'已认证', N'认证未通过', N'冻结') -- Added '认证未通过'
    BEGIN
        RAISERROR(N'无效的新账户状态 "%s"。允许的状态为 "已认证", "认证未通过" 或 "冻结"。', 16, 1, @NewStatus); -- Updated message
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Organization
        SET OrgAccountStatus = @NewStatus
        -- 假设您的 tbl_Organization 表中添加了 ReviewerAdminID, ReviewTime 字段
        -- , ReviewerAdminID = @ReviewingAdminID
        -- , ReviewTime = GETDATE() -- 如果是 SMALLDATETIME，会自动舍入
        WHERE OrgID = @OrgID;
        RETURN 0; -- 操作成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'审核组织注册申请过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员审核志愿活动 (sp_ReviewVolunteerActivityByAdmin)
-- 描述: 管理员审核组织发布的志愿活动。
-- 参数:
--   @ReviewingAdminID: 执行审核的管理员ID
--   @ActivityID: 被审核的活动ID
--   @NewStatus: 新的活动状态 (例如: N'审核通过', N'审核不通过')
-- 返回值:
--   0: 操作成功
--  -1: 活动ID不存在
--  -2: 当前活动状态不是'待审核'
--  -3: 无效的新状态值
--  -4: 无效的审核员ID
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ReviewVolunteerActivityByAdmin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReviewVolunteerActivityByAdmin;
GO

CREATE PROCEDURE dbo.sp_ReviewVolunteerActivityByAdmin (
    @ReviewingAdminID CHAR(15),
    @ActivityID CHAR(15),
    @NewStatus NVARCHAR(10))
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentActivityStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @ReviewingAdminID)
    BEGIN
        RAISERROR(N'审核操作的管理员ID "%s" 无效。', 16, 1, @ReviewingAdminID);
        RETURN -4;
    END

    SELECT @CurrentActivityStatus = ActivityStatus FROM dbo.tbl_VolunteerActivity WHERE ActivityID = @ActivityID;

    IF @CurrentActivityStatus IS NULL
    BEGIN
        RAISERROR(N'活动ID "%s" 不存在。', 16, 1, @ActivityID);
        RETURN -1;
    END

    IF @CurrentActivityStatus <> N'待审核'
    BEGIN
        RAISERROR(N'活动 "%s" 当前状态为 "%s"，并非“待审核”，无法执行此审核操作。', 16, 1, @ActivityID, @CurrentActivityStatus);
        RETURN -2;
    END

    IF @NewStatus NOT IN (N'审核通过', N'审核不通过')
    BEGIN
        RAISERROR(N'无效的新活动状态 "%s"。允许的状态为 "审核通过" 或 "审核不通过"。', 16, 1, @NewStatus);
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerActivity
        SET ActivityStatus = @NewStatus,
            ReviewerAdminID = @ReviewingAdminID -- 记录审核的管理员
            -- 假设您的 tbl_VolunteerActivity 表中添加了 ReviewTime 字段
            -- , ReviewTime = GETDATE() -- 如果是 SMALLDATETIME，会自动舍入
        WHERE ActivityID = @ActivityID;
        RETURN 0; -- 操作成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'审核志愿活动过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员审核志愿培训 (sp_ReviewVolunteerTrainingByAdmin)
-- 描述: 管理员审核组织发布的志愿培训。
-- 参数:
--   @ReviewingAdminID: 执行审核的管理员ID
--   @TrainingID: 被审核的培训ID
--   @NewStatus: 新的培训状态 (例如: N'审核通过', N'审核不通过', N'已停用')
-- 返回值:
--   0: 操作成功
--  -1: 培训ID不存在
--  -2: 当前培训状态不是'待审核'
--  -3: 无效的新状态值
--  -4: 无效的审核员ID
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ReviewVolunteerTrainingByAdmin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReviewVolunteerTrainingByAdmin;
GO

CREATE PROCEDURE dbo.sp_ReviewVolunteerTrainingByAdmin (
    @ReviewingAdminID CHAR(15),
    @TrainingID CHAR(15),
    @NewStatus NVARCHAR(10) -- 确保此长度与 tbl_VolunteerTraining.TrainingStatus 一致
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentTrainingStatus NVARCHAR(10); -- 确保此长度与 tbl_VolunteerTraining.TrainingStatus 一致

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @ReviewingAdminID)
    BEGIN
        RAISERROR(N'审核操作的管理员ID "%s" 无效。', 16, 1, @ReviewingAdminID);
        RETURN -4;
    END

    SELECT @CurrentTrainingStatus = TrainingStatus FROM dbo.tbl_VolunteerTraining WHERE TrainingID = @TrainingID;

    IF @CurrentTrainingStatus IS NULL
    BEGIN
        RAISERROR(N'培训ID "%s" 不存在。', 16, 1, @TrainingID);
        RETURN -1;
    END

    IF @CurrentTrainingStatus <> N'待审核'
    BEGIN
        RAISERROR(N'培训 "%s" 当前状态为 "%s"，并非“待审核”，无法执行此审核操作。', 16, 1, @TrainingID, @CurrentTrainingStatus);
        RETURN -2;
    END

    IF @NewStatus NOT IN (N'审核通过', N'审核不通过', N'已停用') -- Changed N'运行中' to N'审核通过'
    BEGIN
        RAISERROR(N'无效的新培训状态 "%s"。允许的审核后状态为 "审核通过", "审核不通过" 或 "已停用"。', 16, 1, @NewStatus); -- Updated message
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_VolunteerTraining
        SET TrainingStatus = @NewStatus,
            ReviewerAdminID = @ReviewingAdminID
            -- 假设您的 tbl_VolunteerTraining 表中添加了 ReviewTime 字段
            -- , ReviewTime = GETDATE() -- 如果是 SMALLDATETIME，会自动舍入
        WHERE TrainingID = @TrainingID;
        RETURN 0; -- 操作成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'审核志愿培训过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员处理投诉 (sp_AdminHandleComplaint)
-- 描述: 管理员更新投诉的处理状态和结果。
-- 参数:
--   @HandlingAdminID: 执行处理的管理员ID
--   @ComplaintID: 被处理的投诉ID
--   @NewProcessingStatus: 新的处理状态
--   @ProcessingResult: 处理结果描述 (可为空)
-- 返回值:
--   0: 操作成功
--  -1: 投诉ID不存在
--  -2: 无效的新处理状态值 (假设由表CHECK约束处理)
--  -3: 无效的处理管理员ID
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AdminHandleComplaint', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AdminHandleComplaint;
GO

CREATE PROCEDURE dbo.sp_AdminHandleComplaint (
    @HandlingAdminID CHAR(15),
    @ComplaintID CHAR(15),
    @NewProcessingStatus NVARCHAR(10),
    @ProcessingResult NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @HandlingAdminID)
    BEGIN
        RAISERROR(N'处理操作的管理员ID "%s" 无效。', 16, 1, @HandlingAdminID);
        RETURN -3;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Complaint WHERE ComplaintID = @ComplaintID)
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    -- NewProcessingStatus 的有效性将由 tbl_Complaint 的 CHECK 约束来保证
    -- 如果 CHECK 约束不存在或不完整，则应在此处添加校验

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET ProcessingStatus = @NewProcessingStatus,
            ProcessingResult = @ProcessingResult,
            HandlerAdminID = @HandlingAdminID,
            LatestProcessingTime = GETDATE() -- 如果是 SMALLDATETIME，会自动舍入
        WHERE ComplaintID = @ComplaintID;
        RETURN 0; -- 操作成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'处理投诉过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员审核志愿者身份 (sp_ReviewVolunteerIdentity)
-- 描述: 管理员审核志愿者的身份信息，并更新其账户状态。
-- 参数:
--   @ReviewingAdminID: 执行审核的管理员ID
--   @VolunteerID: 被审核的志愿者ID
--   @NewAccountStatus: 新的账户状态 (例如: N'已实名认证', N'认证未通过', N'已冻结')
-- 返回值:
--   0: 操作成功
--  -1: 志愿者ID不存在
--  -2: 当前志愿者账户状态不适合进行此审核 (例如已经是'已实名认证')
--  -3: 无效的新账户状态值
--  -4: 无效的审核员ID
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ReviewVolunteerIdentity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReviewVolunteerIdentity;
GO

CREATE PROCEDURE dbo.sp_ReviewVolunteerIdentity (
    @ReviewingAdminID CHAR(15),
    @VolunteerID CHAR(15),
    @NewAccountStatus NVARCHAR(10) -- 确保此长度与 tbl_Volunteer.AccountStatus 一致
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentAccountStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @ReviewingAdminID)
    BEGIN
        RAISERROR(N'审核操作的管理员ID "%s" 无效。', 16, 1, @ReviewingAdminID);
        RETURN -4;
    END

    SELECT @CurrentAccountStatus = AccountStatus FROM dbo.tbl_Volunteer WHERE VolunteerID = @VolunteerID;

    IF @CurrentAccountStatus IS NULL
    BEGIN
        RAISERROR(N'志愿者ID "%s" 不存在。', 16, 1, @VolunteerID);
        RETURN -1;
    END

    -- 通常，身份审核针对的是'未实名认证'的志愿者
    -- 根据业务逻辑，也可以允许对 '认证未通过' 的状态再次审核
    IF @CurrentAccountStatus NOT IN (N'未实名认证', N'认证未通过')
    BEGIN
        -- 使用级别10作为信息性提示或警告，除非严格禁止对其他状态操作
        RAISERROR(N'志愿者 "%s" 当前账户状态为 "%s"，可能不适合进行此审核操作。审核通常针对“未实名认证”或“认证未通过”的账户。', 10, 1, @VolunteerID, @CurrentAccountStatus);
        -- 如果业务严格要求，此处可以 RETURN -2;
    END

    -- tbl_Volunteer.AccountStatus 的 CHECK 约束是 (N'未实名认证', N'已实名认证', N'已冻结', N'认证未通过')
    -- 管理员审核后，可设置的状态
    IF @NewAccountStatus NOT IN (N'已实名认证', N'认证未通过', N'已冻结') -- Removed N'未实名认证' as a direct SET target post-review; admin might just leave it if info is missing, but explicit "fail" or "pass" is cleaner. Can be re-added if needed.
    BEGIN
        RAISERROR(N'无效的新账户状态 "%s"。允许的审核后状态为 "已实名认证", "认证未通过" 或 "已冻结"。', 16, 1, @NewAccountStatus); -- Updated message
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Volunteer
        SET AccountStatus = @NewAccountStatus
            -- 假设您的 tbl_Volunteer 表中添加了 ReviewerAdminID, ReviewTime 字段用于记录身份审核信息
            -- , IdentityReviewerAdminID = @ReviewingAdminID
            -- , IdentityReviewTime = GETDATE() -- 如果是 SMALLDATETIME，会自动舍入
        WHERE VolunteerID = @VolunteerID;

        PRINT N'志愿者ID "%s" 账户状态已成功更新为 "%s"。'; -- Consider removing PRINT for production
        RETURN 0; -- 操作成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'审核志愿者身份过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO