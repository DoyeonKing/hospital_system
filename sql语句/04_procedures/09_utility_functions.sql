--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO
IF OBJECT_ID('dbo.proc_CalculateAvgActivityScoreForVolunteer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.proc_CalculateAvgActivityScoreForVolunteer;
GO

--------------------------------------------------------------------------------
-- 存储过程名称: proc_CalculateAvgActivityScoreForVolunteer
-- 描述:
--   计算指定志愿者的所有已参与且被组织评分的志愿活动的平均得分。
--   此平均分将通过 OUTPUT 参数返回。
--   如果志愿者没有有效的活动评分记录，则返回一个预设的默认平均分。
--   此存储过程通常由更新志愿者综合评分的触发器调用。
--
-- 参数:
--   @TargetVolunteerID CHAR(15):         需要计算平均活动得分的志愿者ID。
--   @CalculatedAvgScore DECIMAL(10,2) OUTPUT: 计算出的平均活动得分。
--                                         如果志愿者没有有效评分，则返回预设的默认值。
--
-- 返回值 (存储过程本身的 RETURN 值, 非 OUTPUT 参数):
--   0: 成功计算并获取了平均分（无论是实际计算还是默认值）。
--  -1: 未找到指定的志愿者ID。
--  -2: 志愿者有参与记录但均未被有效评分 (虽然此时也会返回默认分给OUTPUT)。
--
-- 注意:
--   - 仅考虑 tbl_VolunteerActivityParticipation表中 OrgToVolunteerRating 不为 NULL 的评分。
--   - 返回的 @CalculatedAvgScore 的评分范围会调整在1.0到10.0之间（如果实际计算值超出）。
--   - 无评分记录时的默认平均分当前设置为 5.0。
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.proc_CalculateAvgActivityScoreForVolunteer
    @TargetVolunteerID CHAR(15),
    @CalculatedAvgScore DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'proc_CalculateAvgActivityScoreForVolunteer: 开始为志愿者 ' + @TargetVolunteerID + N' 计算活动平均得分...';

    -- 检查目标志愿者是否存在
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TargetVolunteerID)
    BEGIN
        PRINT N'错误：在 tbl_Volunteer 表中未找到志愿者ID: ' + @TargetVolunteerID;
        SET @CalculatedAvgScore = 5.0; -- 即使志愿者不存在，也设定一个默认值，但调用方应检查RETURN值
        RAISERROR(N'未找到指定的志愿者ID "%s"。', 16, 1, @TargetVolunteerID);
        RETURN -1; -- 指示未找到志愿者
    END

    DECLARE @NumberOfRatedActivities INT;
    DECLARE @DefaultScoreIfNoRatings DECIMAL(10,2) = 5.0; -- 定义当志愿者无任何有效活动评分时的默认平均分

    -- 计算指定志愿者所有已评分活动的平均 OrgToVolunteerRating
    SELECT
        @CalculatedAvgScore = AVG(CONVERT(DECIMAL(10,2), OrgToVolunteerRating)),
        @NumberOfRatedActivities = COUNT(OrgToVolunteerRating) -- 计算有多少条有效的评分记录
    FROM
        dbo.tbl_VolunteerActivityParticipation
    WHERE
        VolunteerID = @TargetVolunteerID
        AND OrgToVolunteerRating IS NOT NULL; -- 确保只统计有评分的参与记录

    PRINT N'志愿者 ' + @TargetVolunteerID + N' 有 ' + CONVERT(VARCHAR(10), ISNULL(@NumberOfRatedActivities, 0)) + N' 条有效活动评分记录。';

    IF @NumberOfRatedActivities > 0
    BEGIN
        -- 如果有有效的评分记录，对计算出的平均分进行范围调整
        IF @CalculatedAvgScore < 1.0 SET @CalculatedAvgScore = 1.0;
        IF @CalculatedAvgScore > 10.0 SET @CalculatedAvgScore = 10.0; -- 假设评分上限是10
        PRINT N'计算出的实际平均活动得分为: ' + ISNULL(CONVERT(VARCHAR(20), @CalculatedAvgScore), 'NULL');
        RETURN 0; -- 成功计算实际平均分
    END
    ELSE
    BEGIN
        -- 如果志愿者没有任何有效的活动评分记录，则使用默认得分
        PRINT N'警告：志愿者 ' + @TargetVolunteerID + N' 没有有效的活动评分记录，将使用默认平均得分: ' + CONVERT(VARCHAR(20), @DefaultScoreIfNoRatings);
        SET @CalculatedAvgScore = @DefaultScoreIfNoRatings;
        RETURN -2; -- 表示没有实际评分记录，返回了默认分
    END
END
GO
PRINT N'存储过程 [dbo.proc_CalculateAvgActivityScoreForVolunteer] (OUTPUT参数版, 无评分时默认5.0) 已创建/更新。';
GO

IF OBJECT_ID('dbo.proc_CalculateAvgTrainingScoreForVolunteer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.proc_CalculateAvgTrainingScoreForVolunteer;
GO

--------------------------------------------------------------------------------
-- 存储过程名称: proc_CalculateAvgTrainingScoreForVolunteer
-- 描述:
--   计算指定志愿者的所有已参与且被组织评分的志愿培训的平均得分。
--   此平均分将通过 OUTPUT 参数返回。
--   如果志愿者没有有效的培训评分记录，则返回一个预设的默认平均分。
--   此存储过程通常由更新志愿者综合评分的触发器调用。
--
-- 参数:
--   @TargetVolunteerID CHAR(15):         需要计算平均培训得分的志愿者ID。
--   @CalculatedAvgScore DECIMAL(10,2) OUTPUT: 计算出的平均培训得分。
--                                         如果志愿者没有有效评分，则返回预设的默认值。
--
-- 返回值 (存储过程本身的 RETURN 值, 非 OUTPUT 参数):
--   0: 成功计算并获取了平均分（无论是实际计算还是默认值）。
--  -1: 未找到指定的志愿者ID。
--  -2: 志愿者有参与记录但均未被有效评分 (虽然此时也会返回默认分给OUTPUT)。
--
-- 注意:
--   - 假设在 tbl_VolunteerTrainingParticipation 表中，组织给志愿者的评分存储在 OrgToVolunteerRating 列。
--     如果列名不同 (例如 VolunteerToOrgRating)，请务必修改本存储过程中的对应列名。
--   - 返回的 @CalculatedAvgScore 的评分范围会调整在1.0到10.0之间（如果实际计算值超出）。
--   - 无评分记录时的默认平均分当前设置为 5.0。
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.proc_CalculateAvgTrainingScoreForVolunteer
    @TargetVolunteerID CHAR(15),
    @CalculatedAvgScore DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'proc_CalculateAvgTrainingScoreForVolunteer: 开始为志愿者 ' + @TargetVolunteerID + N' 计算培训平均得分...';

    -- 检查目标志愿者是否存在
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Volunteer WHERE VolunteerID = @TargetVolunteerID)
    BEGIN
        PRINT N'错误：在 tbl_Volunteer 表中未找到志愿者ID: ' + @TargetVolunteerID;
        SET @CalculatedAvgScore = 5.0; -- 即使志愿者不存在，也设定一个默认值
        RAISERROR(N'未找到指定的志愿者ID "%s"。', 16, 1, @TargetVolunteerID);
        RETURN -1; -- 指示未找到志愿者
    END

    DECLARE @NumberOfRatedTrainings INT;
    DECLARE @DefaultScoreIfNoRatings DECIMAL(10,2) = 5.0; -- 定义当志愿者无任何有效培训评分时的默认平均分

    -- 计算指定志愿者所有已评分培训的平均 OrgToVolunteerRating
    -- !!! 重要：请确认 tbl_VolunteerTrainingParticipation 中组织给志愿者的评分列名 !!!
    -- !!! 这里假设是 OrgToVolunteerRating。如果是 VolunteerToOrgRating，请修改下面的 AVG 和 COUNT !!!
    SELECT
        @CalculatedAvgScore = AVG(CONVERT(DECIMAL(10,2), OrgToVolunteerRating)), -- 假设是 OrgToVolunteerRating
        @NumberOfRatedTrainings = COUNT(OrgToVolunteerRating)                   -- 假设是 OrgToVolunteerRating
    FROM
        dbo.tbl_VolunteerTrainingParticipation
    WHERE
        VolunteerID = @TargetVolunteerID
        AND OrgToVolunteerRating IS NOT NULL; -- 假设是 OrgToVolunteerRating

    PRINT N'志愿者 ' + @TargetVolunteerID + N' 有 ' + CONVERT(VARCHAR(10), ISNULL(@NumberOfRatedTrainings, 0)) + N' 条有效培训评分记录。';

    IF @NumberOfRatedTrainings > 0
    BEGIN
        -- 如果有有效的评分记录，对计算出的平均分进行范围调整
        IF @CalculatedAvgScore < 1.0 SET @CalculatedAvgScore = 1.0;
        IF @CalculatedAvgScore > 10.0 SET @CalculatedAvgScore = 10.0; -- 假设评分上限是10
        PRINT N'计算出的实际平均培训得分为: ' + ISNULL(CONVERT(VARCHAR(20), @CalculatedAvgScore), 'NULL');
        RETURN 0; -- 成功计算实际平均分
    END
    ELSE
    BEGIN
        -- 如果志愿者没有任何有效的培训评分记录，则使用默认得分
        PRINT N'警告：志愿者 ' + @TargetVolunteerID + N' 没有有效的培训评分记录，将使用默认平均得分: ' + CONVERT(VARCHAR(20), @DefaultScoreIfNoRatings);
        SET @CalculatedAvgScore = @DefaultScoreIfNoRatings;
        RETURN -2; -- 表示没有实际评分记录，返回了默认分
    END
END
GO
PRINT N'存储过程 [dbo.proc_CalculateAvgTrainingScoreForVolunteer] (OUTPUT参数版, 无评分时默认5.0) 已创建/更新。';
GO