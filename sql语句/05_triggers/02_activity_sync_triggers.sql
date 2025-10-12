USE volunteer_db_test;
GO
PRINT N'开始创建活动同步触发器...';
GO

--------------------------------------------------------------------------------
-- 触发器 1: trg_sync_activity_duration_from_timeslots
-- 作用表：  dbo.tbl_ActivityTimeslot (活动时段表)
-- 触发事件：AFTER INSERT, UPDATE, DELETE (在时段记录增加、修改或删除之后)
-- 主要功能：当某个活动的时段发生变化时，自动计算并更新活动表中的 ActivityDurationHours
--          字段，使其等于该活动所有时段的总时长（小时数）
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_sync_activity_duration_from_timeslots', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_sync_activity_duration_from_timeslots;
GO

CREATE TRIGGER dbo.trg_sync_activity_duration_from_timeslots
ON dbo.tbl_ActivityTimeslot
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedActivityIDs TABLE (ActivityID CHAR(15) PRIMARY KEY);

    -- 收集所有可能被影响的活动ID
    INSERT INTO @AffectedActivityIDs (ActivityID)
    SELECT DISTINCT EventID FROM inserted WHERE EventID IS NOT NULL AND LEFT(EventID, 3) = 'act'
    UNION 
    SELECT DISTINCT EventID FROM deleted WHERE EventID IS NOT NULL AND LEFT(EventID, 3) = 'act';

    DECLARE @CurrentActivityID CHAR(15);
    DECLARE @TotalDurationHours INT;

    DECLARE activity_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ActivityID FROM @AffectedActivityIDs;

    OPEN activity_cursor;
    FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 计算该活动所有时段的总时长（小时）
        SELECT @TotalDurationHours = ISNULL(SUM(DATEDIFF(HOUR, StartTime, EndTime)), 0)
        FROM dbo.tbl_ActivityTimeslot
        WHERE EventID = @CurrentActivityID;

        -- 更新活动表中的 ActivityDurationHours 字段
        UPDATE dbo.tbl_VolunteerActivity
        SET ActivityDurationHours = @TotalDurationHours
        WHERE ActivityID = @CurrentActivityID;

        PRINT N'活动 ' + @CurrentActivityID + N' 的时长已更新为: ' + CONVERT(NVARCHAR(10), @TotalDurationHours) + N' 小时';

        FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;
    END
    
    CLOSE activity_cursor;
    DEALLOCATE activity_cursor;
END;
GO
PRINT N'触发器 [trg_sync_activity_duration_from_timeslots] 已创建/更新。';
GO

--------------------------------------------------------------------------------
-- 触发器 2: trg_sync_recruitment_count_from_positions
-- 作用表：  dbo.tbl_Position (岗位表)
-- 触发事件：AFTER INSERT, UPDATE, DELETE (在岗位记录增加、修改或删除之后)
-- 主要功能：当某个活动的岗位信息发生变化时，自动计算并更新活动表中的 RecruitmentCount
--          字段，使其等于该活动所有岗位的需求人数总和
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_sync_recruitment_count_from_positions', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_sync_recruitment_count_from_positions;
GO

CREATE TRIGGER dbo.trg_sync_recruitment_count_from_positions
ON dbo.tbl_Position
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AffectedActivityIDs TABLE (ActivityID CHAR(15) PRIMARY KEY);

    -- 收集所有可能被影响的活动ID
    INSERT INTO @AffectedActivityIDs (ActivityID)
    SELECT DISTINCT ActivityID FROM inserted WHERE ActivityID IS NOT NULL
    UNION 
    SELECT DISTINCT ActivityID FROM deleted WHERE ActivityID IS NOT NULL;

    DECLARE @CurrentActivityID CHAR(15);
    DECLARE @TotalRecruitmentCount INT;

    DECLARE activity_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ActivityID FROM @AffectedActivityIDs;

    OPEN activity_cursor;
    FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 计算该活动所有岗位的需求人数总和
        SELECT @TotalRecruitmentCount = ISNULL(SUM(RequiredVolunteers), 0)
        FROM dbo.tbl_Position
        WHERE ActivityID = @CurrentActivityID;

        -- 更新活动表中的 RecruitmentCount 字段
        UPDATE dbo.tbl_VolunteerActivity
        SET RecruitmentCount = @TotalRecruitmentCount
        WHERE ActivityID = @CurrentActivityID;

        PRINT N'活动 ' + @CurrentActivityID + N' 的招募人数已更新为: ' + CONVERT(NVARCHAR(10), @TotalRecruitmentCount) + N' 人';

        FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;
    END
    
    CLOSE activity_cursor;
    DEALLOCATE activity_cursor;
END;
GO
PRINT N'触发器 [trg_sync_recruitment_count_from_positions] 已创建/更新。';
GO

PRINT N'活动同步触发器创建完成！';
GO 