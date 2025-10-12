--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 存储过程: 投诉人补充投诉信息 (sp_ComplainantAddInfoToComplaint)
-- 描述: 允许投诉人向已提交的、特定状态的投诉补充内容或证据链接。
-- 参数:
--   @ComplainantID CHAR(15): 执行操作的投诉人ID (应与投诉记录中的ComplainantID一致)
--   @ComplaintID CHAR(15): 要补充信息的投诉ID
--   @AdditionalContent NVARCHAR(MAX): 补充的投诉内容 (可选)
--   @NewEvidenceLink NVARCHAR(255): 新的或更新的证据链接 (可选)
-- 返回值:
--   0: 成功
--  -1: 投诉ID不存在
--  -2: 操作人不是该投诉的发起人
--  -3: 当前投诉状态不允许补充信息 (例如已处理完毕)
--  -4: 未提供任何补充信息
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_ComplainantAddInfoToComplaint', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ComplainantAddInfoToComplaint;
GO

CREATE PROCEDURE dbo.sp_ComplainantAddInfoToComplaint (
    @ComplainantID CHAR(15),
    @ComplaintID CHAR(15),
    @AdditionalContent NVARCHAR(MAX) = NULL,
    @NewEvidenceLink NVARCHAR(255) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentComplainantID CHAR(15);
    DECLARE @CurrentProcessingStatus NVARCHAR(10);

    IF @AdditionalContent IS NULL AND @NewEvidenceLink IS NULL
    BEGIN
        RAISERROR(N'没有提供任何要补充的内容或证据链接。', 16, 1);
        RETURN -4; -- 无信息提供
    END

    SELECT @CurrentComplainantID = ComplainantID, @CurrentProcessingStatus = ProcessingStatus
    FROM dbo.tbl_Complaint
    WHERE ComplaintID = @ComplaintID;

    IF @CurrentComplainantID IS NULL
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    IF @CurrentComplainantID <> @ComplainantID
    BEGIN
        RAISERROR(N'用户 "%s" 不是投诉 "%s" 的发起人，无权补充信息。', 16, 1, @ComplainantID, @ComplaintID);
        RETURN -2;
    END

    -- 假设只允许在 '未处理', '转应诉', '处理中' 状态下补充信息
    IF @CurrentProcessingStatus NOT IN (N'未处理', N'转应诉', N'处理中')
    BEGIN
        RAISERROR(N'投诉 "%s" 当前状态为 "%s"，不允许补充信息。', 16, 1, @ComplaintID, @CurrentProcessingStatus);
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET ComplaintContent = CASE
                                 WHEN @AdditionalContent IS NOT NULL THEN ISNULL(ComplaintContent, N'') + NCHAR(13) + NCHAR(10) + N'---补充内容 (' + CONVERT(NVARCHAR(20), GETDATE(), 120) + N')---' + NCHAR(13) + NCHAR(10) + @AdditionalContent
                                 ELSE ComplaintContent
                               END,
            EvidenceLink = ISNULL(@NewEvidenceLink, EvidenceLink),
            LatestProcessingTime = GETDATE()
        WHERE ComplaintID = @ComplaintID;

        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'补充投诉信息过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 被投诉方回应投诉 (sp_TargetRespondToComplaint)
-- 描述: 允许被投诉方对特定状态的投诉进行回应。
-- 参数:
--   @RespondingTargetID CHAR(15): 执行操作的被投诉方ID (应与投诉记录中的ComplaintTargetID一致)
--   @ComplaintID CHAR(15): 要回应的投诉ID
--   @ResponseContent NVARCHAR(MAX): 回应内容
-- 返回值:
--   0: 成功
--  -1: 投诉ID不存在
--  -2: 操作人不是该投诉的被投诉对象
--  -3: 当前投诉状态不允许回应 (例如已处理完毕或未转应诉)
--  -4: 回应内容为空
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_TargetRespondToComplaint', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TargetRespondToComplaint;
GO

CREATE PROCEDURE dbo.sp_TargetRespondToComplaint (
    @RespondingTargetID CHAR(15),
    @ComplaintID CHAR(15),
    @ResponseContent NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentTargetID CHAR(15);
    DECLARE @CurrentProcessingStatus NVARCHAR(10);

    IF @ResponseContent IS NULL OR LTRIM(RTRIM(@ResponseContent)) = ''
    BEGIN
        RAISERROR(N'回应内容不能为空。', 16, 1);
        RETURN -4; -- 回应内容为空
    END

    SELECT @CurrentTargetID = ComplaintTargetID, @CurrentProcessingStatus = ProcessingStatus
    FROM dbo.tbl_Complaint
    WHERE ComplaintID = @ComplaintID;

    IF @CurrentTargetID IS NULL
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    IF @CurrentTargetID <> @RespondingTargetID
    BEGIN
        RAISERROR(N'用户/组织 "%s" 不是投诉 "%s" 的被投诉对象，无权回应。', 16, 1, @RespondingTargetID, @ComplaintID);
        RETURN -2;
    END

    IF @CurrentProcessingStatus <> N'转应诉'
    BEGIN
        RAISERROR(N'投诉 "%s" 当前状态为 "%s"，不允许回应。请等待管理员将其状态转为“转应诉”。', 16, 1, @ComplaintID, @CurrentProcessingStatus);
        RETURN -3;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET ProcessingResult = ISNULL(ProcessingResult, N'') + NCHAR(13) + NCHAR(10) + N'---被投诉方回应 (' + CONVERT(NVARCHAR(20), GETDATE(), 120) + N')---' + NCHAR(13) + NCHAR(10) + @ResponseContent,
            ProcessingStatus = N'已应诉', 
            LatestProcessingTime = GETDATE()
        WHERE ComplaintID = @ComplaintID;

        RETURN 0; -- 成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'回应投诉过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员指派投诉处理人 (sp_AdminAssignComplaintHandler)
-- 描述: 管理员将一个投诉指派给另一个（或自己）管理员进行处理。
-- 参数:
--   @AssigningAdminID CHAR(15): 执行指派操作的管理员ID (需要有权限)
--   @ComplaintID CHAR(15): 被指派的投诉ID
--   @NewHandlerAdminID CHAR(15): 新的处理人管理员ID
-- 返回值:
--   0: 指派成功
--  -1: 投诉ID不存在
--  -2: 指派的管理员ID无效
--  -3: 新的处理人管理员ID无效
--  -4: 投诉当前状态不适合指派 (例如已关闭)
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AdminAssignComplaintHandler', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AdminAssignComplaintHandler;
GO

CREATE PROCEDURE dbo.sp_AdminAssignComplaintHandler (
    @AssigningAdminID CHAR(15),
    @ComplaintID CHAR(15),
    @NewHandlerAdminID CHAR(15)
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentProcessingStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @AssigningAdminID)
    BEGIN
        RAISERROR(N'执行指派操作的管理员ID "%s" 无效。', 16, 1, @AssigningAdminID);
        RETURN -2;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @NewHandlerAdminID)
    BEGIN
        RAISERROR(N'指派的新处理人管理员ID "%s" 无效。', 16, 1, @NewHandlerAdminID);
        RETURN -3;
    END

    SELECT @CurrentProcessingStatus = ProcessingStatus
    FROM dbo.tbl_Complaint
    WHERE ComplaintID = @ComplaintID;

    IF @CurrentProcessingStatus IS NULL
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    IF @CurrentProcessingStatus IN (N'已仲裁', N'已退回')
    BEGIN
        RAISERROR(N'投诉 "%s" 当前状态为 "%s"，不适合重新指派处理人。', 16, 1, @ComplaintID, @CurrentProcessingStatus);
        RETURN -4;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET HandlerAdminID = @NewHandlerAdminID,
            ProcessingStatus = CASE 
                                WHEN @CurrentProcessingStatus = N'未处理' THEN N'处理中' 
                                ELSE @CurrentProcessingStatus 
                             END,
            LatestProcessingTime = GETDATE()
        WHERE ComplaintID = @ComplaintID;

        RETURN 0; -- 指派成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'指派投诉处理人过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员记录投诉回访结果 (sp_AdminRecordComplaintVisit)
-- 描述: 管理员记录对投诉处理结果的回访情况。
-- 参数:
--   @OperatingAdminID CHAR(15): 执行操作的管理员ID
--   @ComplaintID CHAR(15): 相关的投诉ID
--   @VisitResult NVARCHAR(20): 回访结果 ('满意', '不满意')
-- 返回值:
--   0: 记录成功
--  -1: 投诉ID不存在
--  -2: 操作的管理员ID无效
--  -3: 投诉状态不适合进行回访
--  -4: 无效的回访结果值
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AdminRecordComplaintVisit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AdminRecordComplaintVisit;
GO

CREATE PROCEDURE dbo.sp_AdminRecordComplaintVisit (
    @OperatingAdminID CHAR(15),
    @ComplaintID CHAR(15),
    @VisitResult NVARCHAR(20)
    -- @VisitNotes NVARCHAR(MAX) = NULL -- 如果表中增加了回访备注字段
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentProcessingStatus NVARCHAR(10);

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @OperatingAdminID)
    BEGIN
        RAISERROR(N'执行操作的管理员ID "%s" 无效。', 16, 1, @OperatingAdminID);
        RETURN -2;
    END

    SELECT @CurrentProcessingStatus = ProcessingStatus
    FROM dbo.tbl_Complaint
    WHERE ComplaintID = @ComplaintID;

    IF @CurrentProcessingStatus IS NULL
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    -- 允许在 '已应诉', '已仲裁', '已退回' 状态后进行回访。
    -- '已处理' 或 '已解决' 如果是您系统中的状态，也应加入。
    IF @CurrentProcessingStatus NOT IN (N'已应诉', N'已仲裁', N'已退回') 
    BEGIN
        RAISERROR(N'投诉 "%s" 当前状态为 "%s"，不适合进行回访。通常在“已应诉”、“已仲裁”或“已退回”后进行。', 16, 1, @ComplaintID, @CurrentProcessingStatus);
        RETURN -3;
    END

    IF @VisitResult NOT IN (N'满意', N'不满意')
    BEGIN
        RAISERROR(N'无效的回访结果 "%s"。允许值为 "满意" 或 "不满意"。', 16, 1, @VisitResult);
        RETURN -4;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET VisitTime = GETDATE(),
            VisitResult = @VisitResult,
            -- , VisitNotes = @VisitNotes 
            LatestProcessingTime = GETDATE() -- 回访也算一次处理时间更新
        WHERE ComplaintID = @ComplaintID;

        IF @VisitResult = N'不满意'
        BEGIN
            PRINT N'提示：投诉人对处理结果不满意，投诉 "%s" 可能需要进一步处理。'; -- Informational
        END

        RETURN 0; -- 记录成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'记录投诉回访结果过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

--------------------------------------------------------------------------------
-- 存储过程: 管理员升级投诉进行仲裁/复审 (sp_AdminEscalateComplaint)
-- 描述: 当投诉处理后用户不满意，管理员将投诉升级给更高级别管理员进行仲裁或复审。
-- 参数:
--   @EscalatingAdminID CHAR(15): 执行升级操作的管理员ID
--   @ComplaintID CHAR(15): 要升级的投诉ID
--   @NewReviewAdminID CHAR(15): 指派的新的复审/仲裁管理员ID
--   @NewArbitrationRound INT: 新的仲裁轮次 (通常是上一轮次+1)
-- 返回值:
--   0: 升级成功
--  -1: 投诉ID不存在
--  -2: 升级操作的管理员ID无效
--  -3: 指派的复审管理员ID无效
--  -4: 当前投诉状态不适合升级
--  -5: 仲裁轮次无效或超出限制
--  -99: 其他错误
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_AdminEscalateComplaint', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AdminEscalateComplaint;
GO

CREATE PROCEDURE dbo.sp_AdminEscalateComplaint (
    @EscalatingAdminID CHAR(15),
    @ComplaintID CHAR(15),
    @NewReviewAdminID CHAR(15),
    @NewArbitrationRound INT
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentProcessingStatus NVARCHAR(10);
    DECLARE @CurrentVisitResult NVARCHAR(20);
    DECLARE @CurrentArbitrationRound INT;

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @EscalatingAdminID)
    BEGIN
        RAISERROR(N'执行升级操作的管理员ID "%s" 无效。', 16, 1, @EscalatingAdminID);
        RETURN -2;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Administrator WHERE AdminID = @NewReviewAdminID)
    BEGIN
        RAISERROR(N'指派的新的复审管理员ID "%s" 无效。', 16, 1, @NewReviewAdminID);
        RETURN -3;
    END

    SELECT @CurrentProcessingStatus = ProcessingStatus, 
           @CurrentVisitResult = VisitResult,
           @CurrentArbitrationRound = ISNULL(ArbitrationRound, 0)
    FROM dbo.tbl_Complaint
    WHERE ComplaintID = @ComplaintID;

    IF @CurrentProcessingStatus IS NULL
    BEGIN
        RAISERROR(N'投诉ID "%s" 不存在。', 16, 1, @ComplaintID);
        RETURN -1;
    END

    IF @CurrentVisitResult <> N'不满意'
    BEGIN
        RAISERROR(N'投诉 "%s" 的回访结果为 "%s"，通常无需升级。仅当回访结果为“不满意”时才考虑升级。', 10, 1, @ComplaintID, @CurrentVisitResult);
        RETURN 1; 
    END

    IF @NewArbitrationRound <= @CurrentArbitrationRound OR @NewArbitrationRound > 2 
    BEGIN
        RAISERROR(N'新的仲裁轮次 "%d" 无效。当前轮次 %d，最多允许2轮。', 16, 1, @NewArbitrationRound, @CurrentArbitrationRound);
        RETURN -5;
    END
    
    -- 允许从 '已应诉', '处理中'(若回访后仍是处理中) 或上一轮 '已仲裁' (然后回访不满意) 的状态进行升级
    IF @CurrentProcessingStatus IN (N'未处理', N'已退回') OR (@CurrentProcessingStatus = N'仲裁中' AND @NewArbitrationRound <= @CurrentArbitrationRound)
    BEGIN
        RAISERROR(N'投诉 "%s" 当前状态为 "%s"，不适合进行升级仲裁。', 16, 1, @ComplaintID, @CurrentProcessingStatus);
        RETURN -4;
    END

    BEGIN TRY
        UPDATE dbo.tbl_Complaint
        SET ProcessingStatus = N'仲裁中', 
            ReviewAdminID = @NewReviewAdminID,
            ArbitrationRound = @NewArbitrationRound,
            HandlerAdminID = @NewReviewAdminID, 
            LatestProcessingTime = GETDATE()
        WHERE ComplaintID = @ComplaintID;

        RETURN 0; -- 升级成功
    END TRY
    BEGIN CATCH
        RAISERROR(N'升级投诉进行仲裁过程中发生未知错误。', 16, 1);
        RETURN -99;
    END CATCH
END
GO

PRINT N'投诉处理相关存储过程已创建/更新完毕。';
GO