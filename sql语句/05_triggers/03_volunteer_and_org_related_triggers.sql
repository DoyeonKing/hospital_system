--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始创建志愿者及组织规模相关触发器 ---';
GO

--------------------------------------------------------------------------------
-- 触发器 3.1: trg_UpdateVolunteerComprehensiveScore_Activity
-- 监控表：   dbo.tbl_VolunteerActivityParticipation (志愿者志愿活动参与表)
-- 触发事件： AFTER UPDATE
-- 核心功能： 当 tbl_VolunteerActivityParticipation 表中记录的 OrgToVolunteerRating 
--            被有效更新时，重新计算并更新对应志愿者的综合评分。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_UpdateVolunteerComprehensiveScore_Activity', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_UpdateVolunteerComprehensiveScore_Activity;
GO

CREATE TRIGGER dbo.trg_UpdateVolunteerComprehensiveScore_Activity
ON dbo.tbl_VolunteerActivityParticipation
AFTER UPDATE -- 确保是 AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'触发器 trg_UpdateVolunteerComprehensiveScore_Activity 已触发。';

    -- 仅当 OrgToVolunteerRating 列被更新且实际值发生变化时才执行
    IF UPDATE(OrgToVolunteerRating)
    BEGIN
        DECLARE @AffectedVolunteers TABLE (VolunteerID CHAR(15) PRIMARY KEY);

        INSERT INTO @AffectedVolunteers (VolunteerID)
        SELECT DISTINCT i.VolunteerID
        FROM inserted i
        JOIN deleted d ON i.VolunteerID = d.VolunteerID
                      AND i.ActivityID = d.ActivityID
                      AND i.ActualPositionID = d.ActualPositionID
        WHERE i.OrgToVolunteerRating IS NOT NULL -- 新的评分必须有效
          AND (d.OrgToVolunteerRating IS NULL OR i.OrgToVolunteerRating <> d.OrgToVolunteerRating); -- 确保评分值实际改变了

        IF NOT EXISTS (SELECT 1 FROM @AffectedVolunteers)
        BEGIN
            PRINT N'没有志愿者因为活动评分变化需要更新综合评分。';
            RETURN;
        END

        DECLARE @VolunteerID_Update CHAR(15);
        DECLARE @AvgActivityScore DECIMAL(10,2);
        DECLARE @AvgTrainingScore DECIMAL(10,2);
        DECLARE @StarRatingValue DECIMAL(10,2); -- 从视图获取的原始星级评分值
        DECLARE @AdjustedStarRatingScore DECIMAL(10,2); -- 调整后用于计算的星级得分 (星级 * 2)
        DECLARE @ComprehensiveScore DECIMAL(10,2);

        -- 定义权重 (根据新公式调整)
        DECLARE @WeightActivityAvg DECIMAL(3,2) = 0.4;
        DECLARE @WeightTrainingAvg DECIMAL(3,2) = 0.3;
        DECLARE @WeightStarComponent DECIMAL(3,2) = 0.3; -- 这是星级评分部分的总权重因子
                                                      -- 星级本身乘以2后再乘以这个权重

        DECLARE vol_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT VolunteerID FROM @AffectedVolunteers;

        OPEN vol_cursor;
        FETCH NEXT FROM vol_cursor INTO @VolunteerID_Update;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT N'正在为志愿者处理活动评分更新: ' + @VolunteerID_Update;

            EXEC dbo.proc_CalculateAvgActivityScoreForVolunteer
                @TargetVolunteerID = @VolunteerID_Update,
                @CalculatedAvgScore = @AvgActivityScore OUTPUT;

            EXEC dbo.proc_CalculateAvgTrainingScoreForVolunteer
                @TargetVolunteerID = @VolunteerID_Update,
                @CalculatedAvgScore = @AvgTrainingScore OUTPUT;

            SET @StarRatingValue = NULL;
            IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'v_VolunteerAuxiliaryRating')
            BEGIN
                 SELECT @StarRatingValue = ISNULL(StarRatingValue, 0.0)
                 FROM dbo.v_VolunteerAuxiliaryRating
                 WHERE VolunteerID = @VolunteerID_Update;
            END
            ELSE
            BEGIN
                PRINT N'警告：视图 dbo.v_VolunteerAuxiliaryRating 不存在，星级评分值将按0处理。';
                SET @StarRatingValue = 0.0;
            END

            -- 处理可能的NULL值，并赋予默认基础分 (0.0)
            SET @AvgActivityScore = ISNULL(@AvgActivityScore, 0.0);
            SET @AvgTrainingScore = ISNULL(@AvgTrainingScore, 0.0);
            -- @StarRatingValue 已在上面用 ISNULL 处理

            -- 根据新公式计算调整后的星级得分 (星级 * 2)
            SET @AdjustedStarRatingScore = @StarRatingValue * 2.0;
            -- （可选）如果调整后的星级得分有上限（例如10分制），可以在此添加约束
            -- IF @AdjustedStarRatingScore > 10.0 SET @AdjustedStarRatingScore = 10.0;

            PRINT N'志愿者 ' + @VolunteerID_Update + N': AvgActivityScore=' + CONVERT(NVARCHAR(10),@AvgActivityScore) +
                  N', AvgTrainingScore=' + CONVERT(NVARCHAR(10),@AvgTrainingScore) +
                  N', StarRatingValue=' + CONVERT(NVARCHAR(10),@StarRatingValue) +
                  N', AdjustedStarRatingScore (Star*2)=' + CONVERT(NVARCHAR(10),@AdjustedStarRatingScore);

            -- 计算综合评分 (使用新公式)
            SET @ComprehensiveScore = (@AvgActivityScore * @WeightActivityAvg) +
                                      (@AvgTrainingScore * @WeightTrainingAvg) +
                                      (@AdjustedStarRatingScore * @WeightStarComponent); -- 星级部分 (StarRatingValue*2) * 0.3

            -- （可选）确保最终综合评分在合理范围内，例如 1.0 到 10.0
            -- IF @ComprehensiveScore < 1.0 AND (@AvgActivityScore > 0 OR @AvgTrainingScore > 0 OR @StarRatingValue > 0) SET @ComprehensiveScore = 1.0; -- 如果有任何评分项，最低为1
            -- IF @ComprehensiveScore > 10.0 SET @ComprehensiveScore = 10.0;
            -- 此处简单处理，如果需要更复杂的边界逻辑，请添加

            UPDATE dbo.tbl_Volunteer
            SET VolunteerRating = ROUND(@ComprehensiveScore, 2)
            WHERE VolunteerID = @VolunteerID_Update;

            PRINT N'已更新志愿者 ' + @VolunteerID_Update + N' 的综合评分为 (因活动评分变化): ' + CONVERT(NVARCHAR(20), ROUND(@ComprehensiveScore, 2));

            FETCH NEXT FROM vol_cursor INTO @VolunteerID_Update;
        END
        CLOSE vol_cursor;
        DEALLOCATE vol_cursor;
    END
    ELSE
    BEGIN
        PRINT N'活动参与的 OrgToVolunteerRating 列未发生实际变化，不执行综合评分更新。';
    END
    PRINT N'触发器 trg_UpdateVolunteerComprehensiveScore_Activity 执行完毕。';
END;
GO
PRINT N'触发器 [dbo.trg_UpdateVolunteerComprehensiveScore_Activity] (已更新评分公式) 已创建/更新。';
GO
--------------------------------------------------------------------------------
-- 触发器 3.2: trg_UpdateVolunteerComprehensiveScore_Training
-- 监控表：   dbo.tbl_VolunteerTrainingParticipation (志愿者培训参与表)
-- 触发事件： AFTER UPDATE
-- 核心功能： 当 tbl_VolunteerTrainingParticipation 表中记录的 OrgToVolunteerRating 
--            被有效更新时，重新计算并更新对应志愿者的综合评分。逻辑与活动评分触发器相同。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_UpdateVolunteerComprehensiveScore_Training', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_UpdateVolunteerComprehensiveScore_Training;
GO

CREATE TRIGGER dbo.trg_UpdateVolunteerComprehensiveScore_Training
ON dbo.tbl_VolunteerTrainingParticipation
AFTER UPDATE -- 确保是 AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'触发器 trg_UpdateVolunteerComprehensiveScore_Training 已触发。';

    -- 仅当 OrgToVolunteerRating 列被更新且实际值发生变化时才执行
    IF UPDATE(OrgToVolunteerRating)
    BEGIN
        DECLARE @AffectedVolunteers TABLE (VolunteerID CHAR(15) PRIMARY KEY);

        INSERT INTO @AffectedVolunteers (VolunteerID)
        SELECT DISTINCT i.VolunteerID
        FROM inserted i
        JOIN deleted d ON i.VolunteerID = d.VolunteerID AND i.TrainingID = d.TrainingID
        WHERE i.OrgToVolunteerRating IS NOT NULL -- 新的评分必须有效
          AND (d.OrgToVolunteerRating IS NULL OR i.OrgToVolunteerRating <> d.OrgToVolunteerRating); -- 确保评分值实际改变了

        IF NOT EXISTS (SELECT 1 FROM @AffectedVolunteers)
        BEGIN
            PRINT N'没有志愿者因为培训评分变化需要更新综合评分。';
            RETURN;
        END

        DECLARE @VolunteerID_Update CHAR(15);
        DECLARE @AvgActivityScore DECIMAL(10,2);
        DECLARE @AvgTrainingScore DECIMAL(10,2);
        DECLARE @StarRatingValue DECIMAL(10,2); -- 从视图获取的原始星级评分值
        DECLARE @AdjustedStarRatingScore DECIMAL(10,2); -- 调整后用于计算的星级得分 (星级 * 2)
        DECLARE @ComprehensiveScore DECIMAL(10,2);

        -- 定义权重 (根据新公式调整)
        DECLARE @WeightActivityAvg DECIMAL(3,2) = 0.4;
        DECLARE @WeightTrainingAvg DECIMAL(3,2) = 0.3;
        DECLARE @WeightStarComponent DECIMAL(3,2) = 0.3; -- 这是星级评分部分的总权重因子

        DECLARE vol_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT VolunteerID FROM @AffectedVolunteers;

        OPEN vol_cursor;
        FETCH NEXT FROM vol_cursor INTO @VolunteerID_Update;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT N'正在为志愿者处理培训评分更新: ' + @VolunteerID_Update;

            EXEC dbo.proc_CalculateAvgActivityScoreForVolunteer
                @TargetVolunteerID = @VolunteerID_Update,
                @CalculatedAvgScore = @AvgActivityScore OUTPUT;

            EXEC dbo.proc_CalculateAvgTrainingScoreForVolunteer
                @TargetVolunteerID = @VolunteerID_Update,
                @CalculatedAvgScore = @AvgTrainingScore OUTPUT;

            SET @StarRatingValue = NULL;
            IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'v_VolunteerAuxiliaryRating')
            BEGIN
                 SELECT @StarRatingValue = ISNULL(StarRatingValue, 0.0)
                 FROM dbo.v_VolunteerAuxiliaryRating
                 WHERE VolunteerID = @VolunteerID_Update;
            END
            ELSE
            BEGIN
                PRINT N'警告：视图 dbo.v_VolunteerAuxiliaryRating 不存在，星级评分值将按0处理。';
                SET @StarRatingValue = 0.0;
            END

            SET @AvgActivityScore = ISNULL(@AvgActivityScore, 0.0);
            SET @AvgTrainingScore = ISNULL(@AvgTrainingScore, 0.0);

            SET @AdjustedStarRatingScore = @StarRatingValue * 2.0;
            -- （可选）如果调整后的星级得分有上限（例如10分制），可以在此添加约束
            -- IF @AdjustedStarRatingScore > 10.0 SET @AdjustedStarRatingScore = 10.0;

            PRINT N'志愿者 ' + @VolunteerID_Update + N': AvgActivityScore=' + CONVERT(NVARCHAR(10),@AvgActivityScore) +
                  N', AvgTrainingScore=' + CONVERT(NVARCHAR(10),@AvgTrainingScore) +
                  N', StarRatingValue=' + CONVERT(NVARCHAR(10),@StarRatingValue) +
                  N', AdjustedStarRatingScore (Star*2)=' + CONVERT(NVARCHAR(10),@AdjustedStarRatingScore);

            SET @ComprehensiveScore = (@AvgActivityScore * @WeightActivityAvg) +
                                      (@AvgTrainingScore * @WeightTrainingAvg) +
                                      (@AdjustedStarRatingScore * @WeightStarComponent);

            -- （可选）确保最终综合评分在合理范围内

            UPDATE dbo.tbl_Volunteer
            SET VolunteerRating = ROUND(@ComprehensiveScore, 2)
            WHERE VolunteerID = @VolunteerID_Update;

            PRINT N'已更新志愿者 ' + @VolunteerID_Update + N' 的综合评分为 (因培训评分变化): ' + CONVERT(NVARCHAR(20), ROUND(@ComprehensiveScore, 2));

            FETCH NEXT FROM vol_cursor INTO @VolunteerID_Update;
        END
        CLOSE vol_cursor;
        DEALLOCATE vol_cursor;
    END
    ELSE
    BEGIN
        PRINT N'培训参与的 OrgToVolunteerRating 列未发生实际变化，不执行综合评分更新。';
    END
    PRINT N'触发器 trg_UpdateVolunteerComprehensiveScore_Training 执行完毕。';
END;
GO
PRINT N'触发器 [dbo.trg_UpdateVolunteerComprehensiveScore_Training] (已更新评分公式) 已创建/更新。';
GO
--------------------------------------------------------------------------------
-- 触发器 3.3: trg_CalculateActivityServiceDuration
-- 监控表：   dbo.tbl_VolunteerActivity (志愿活动表)
-- 触发事件： AFTER UPDATE
-- 核心功能： 当活动的 ActivityStatus 从非“已结束”更新为“已结束”时，
--            为所有已签到的参与志愿者累加该活动的岗位服务时长到其个人总服务时长。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_CalculateActivityServiceDuration', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_CalculateActivityServiceDuration;
GO

CREATE TRIGGER dbo.trg_CalculateActivityServiceDuration
ON dbo.tbl_VolunteerActivity
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(ActivityStatus)
    BEGIN
        DECLARE @FinishedActivities TABLE (ActivityID CHAR(15) PRIMARY KEY);

        INSERT INTO @FinishedActivities (ActivityID)
        SELECT i.ActivityID
        FROM inserted i
        JOIN deleted d ON i.ActivityID = d.ActivityID
        WHERE i.ActivityStatus = N'已结束' AND d.ActivityStatus <> N'已结束'; -- 修改为 N'已结束'

        IF EXISTS (SELECT 1 FROM @FinishedActivities)
        BEGIN
            UPDATE vol
            SET vol.TotalVolunteerHours = ISNULL(vol.TotalVolunteerHours, 0) + Durations.TotalHoursForVolunteer
            FROM dbo.tbl_Volunteer vol
            INNER JOIN (
                SELECT 
                    vap.VolunteerID, 
                    SUM(ISNULL(p.PositionServiceHours, 0)) AS TotalHoursForVolunteer
                FROM dbo.tbl_VolunteerActivityParticipation vap
                JOIN dbo.tbl_Position p ON vap.ActualPositionID = p.PositionID AND vap.ActivityID = p.ActivityID
                JOIN @FinishedActivities fa ON vap.ActivityID = fa.ActivityID
                WHERE vap.IsCheckedIn = N'是' AND p.PositionServiceHours > 0 
                GROUP BY vap.VolunteerID
            ) AS Durations ON vol.VolunteerID = Durations.VolunteerID
            WHERE Durations.TotalHoursForVolunteer > 0; -- 只有当有服务时长时才更新

            PRINT N'已为状态变更为“已结束”的活动参与者更新了志愿总时长。';
        END
    END
END;
GO
PRINT N'触发器 [trg_CalculateActivityServiceDuration] 已创建/更新 (活动状态为 "已结束")。';
GO

--------------------------------------------------------------------------------
-- 触发器 V.1: trg_UpdateOrgSizeOnMembershipChange (原名 trg_UpdateOrgSizeAndMembership)
-- 监控表：   dbo.tbl_VolunteerOrganizationJoin (志愿者组织机构参与表)
-- 触发事件： AFTER INSERT, UPDATE, DELETE
-- 核心功能： 当志愿者与组织的成员关系发生变化时，自动更新对应组织的 OrgScale (组织规模/活跃成员数)。
--            活跃成员状态定义为 MemberStatus = N'已加入'。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_UpdateOrgSizeOnMembershipChange', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_UpdateOrgSizeOnMembershipChange;
GO

CREATE TRIGGER dbo.trg_UpdateOrgSizeOnMembershipChange
ON dbo.tbl_VolunteerOrganizationJoin
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AffectedOrgs TABLE (OrgID CHAR(15) PRIMARY KEY);

    INSERT INTO @AffectedOrgs (OrgID)
    SELECT DISTINCT OrgID FROM inserted WHERE OrgID IS NOT NULL
    UNION
    SELECT DISTINCT OrgID FROM deleted WHERE OrgID IS NOT NULL;

    DECLARE @CurrentOrgID CHAR(15);
    DECLARE @NewOrgScale INT;

    DECLARE org_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT OrgID FROM @AffectedOrgs;

    OPEN org_cursor;
    FETCH NEXT FROM org_cursor INTO @CurrentOrgID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @NewOrgScale = COUNT(DISTINCT VolunteerID)
        FROM dbo.tbl_VolunteerOrganizationJoin
        WHERE OrgID = @CurrentOrgID AND MemberStatus = N'已加入';

        UPDATE dbo.tbl_Organization
        SET OrgScale = ISNULL(@NewOrgScale, 0)
        WHERE OrgID = @CurrentOrgID;
        
        PRINT N'组织 ' + @CurrentOrgID + N' 的规模已更新为: ' + CONVERT(NVARCHAR(10), ISNULL(@NewOrgScale, 0));

        FETCH NEXT FROM org_cursor INTO @CurrentOrgID;
    END
    CLOSE org_cursor;
    DEALLOCATE org_cursor;
END;
GO
PRINT N'触发器 [trg_UpdateOrgSizeOnMembershipChange] 已创建/更新。';
GO

PRINT N'--- 所有志愿者及组织规模相关触发器创建/更新完毕 ---';
GO