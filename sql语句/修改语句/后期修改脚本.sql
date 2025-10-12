-- 为志愿活动表添加临时存储字段
-- 用于在审核前保存岗位和时段信息的JSON格式数据

USE volunteer_web_05;  -- 请根据你的实际数据库名称修改
GO

-- 添加两个新字段用于临时存储岗位和时段信息
ALTER TABLE tbl_VolunteerActivity 
ADD PendingPositionsJson NVARCHAR(MAX) NULL,  -- 待审核的岗位信息（JSON格式）
    PendingTimeslotsJson NVARCHAR(MAX) NULL;  -- 待审核的时段信息（JSON格式）
GO

-- 验证字段是否添加成功
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'tbl_VolunteerActivity' 
  AND COLUMN_NAME IN ('PendingPositionsJson', 'PendingTimeslotsJson');
GO

PRINT N'已成功为 tbl_VolunteerActivity 表添加 PendingPositionsJson 和 PendingTimeslotsJson 字段';
GO 

/* 更新概述
为实现基本信息中"开始时间"、"结束时间"、"活动时长"与"招募人数"的自动同步计算，新增了2个数据库触发器。

## 新增触发器列表

### 1. 活动时长自动计算触发器

**触发器名称**: `trg_sync_activity_duration_from_timeslots`

**作用表**: `dbo.tbl_ActivityTimeslot` (活动时段表)

**触发事件**: `AFTER INSERT, UPDATE, DELETE`

**功能描述**: 
- 当活动时段发生变化时，自动计算该活动所有时段的总时长
- 将计算结果更新到 `tbl_VolunteerActivity.ActivityDurationHours` 字段
- 确保活动时长始终与时段安排保持同步

**业务场景**:
- 添加新时段 → 自动增加活动总时长
- 修改时段时间 → 自动重新计算活动总时长  
- 删除时段 → 自动减少活动总时长

### 2. 招募人数自动计算触发器

**触发器名称**: `trg_sync_recruitment_count_from_positions`

**作用表**: `dbo.tbl_Position` (岗位表)

**触发事件**: `AFTER INSERT, UPDATE, DELETE`

**功能描述**:
- 当活动岗位信息发生变化时，自动计算该活动所有岗位的需求人数总和
- 将计算结果更新到 `tbl_VolunteerActivity.RecruitmentCount` 字段
- 确保招募人数始终与岗位需求保持同步

**业务场景**:
- 添加新岗位 → 自动增加活动招募人数
- 修改岗位需求人数 → 自动重新计算活动招募人数
- 删除岗位 → 自动减少活动招募人数

## 触发器创建SQL语句*/

-- 触发器1: 活动时长自动计算

USE volunteer_db_test;
GO

--------------------------------------------------------------------------------
-- 触发器: trg_sync_activity_duration_from_timeslots
-- 作用表: dbo.tbl_ActivityTimeslot (活动时段表)
-- 触发事件: AFTER INSERT, UPDATE, DELETE
-- 功能: 当活动时段发生变化时，自动计算并更新活动表中的 ActivityDurationHours
--       字段，使其等于该活动所有时段的总时长（小时数）
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

        PRINT 'Activity ' + @CurrentActivityID + ' duration updated to: ' + CONVERT(VARCHAR(10), @TotalDurationHours) + ' hours';

        FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;
    END
    
    CLOSE activity_cursor;
    DEALLOCATE activity_cursor;
END;
GO


-- 触发器2: 招募人数自动计算

USE volunteer_db_test;
GO

--------------------------------------------------------------------------------
-- 触发器: trg_sync_recruitment_count_from_positions
-- 作用表: dbo.tbl_Position (岗位表)
-- 触发事件: AFTER INSERT, UPDATE, DELETE
-- 功能: 当活动岗位信息发生变化时，自动计算并更新活动表中的 RecruitmentCount
--       字段，使其等于该活动所有岗位的需求人数总和
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

        PRINT 'Activity ' + @CurrentActivityID + ' recruitment count updated to: ' + CONVERT(VARCHAR(10), @TotalRecruitmentCount) + ' people';

        FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;
    END
    
    CLOSE activity_cursor;
    DEALLOCATE activity_cursor;
END;
GO
