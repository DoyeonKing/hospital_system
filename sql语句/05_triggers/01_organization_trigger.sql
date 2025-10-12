--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO
PRINT N'开始创建或更新数据库触发器...';
GO

--------------------------------------------------------------------------------
-- 触发器 0.1: trg_update_parent_event_overall_times
-- 监控表：dbo.tbl_ActivityTimeslot (活动/培训时段表)
-- 触发事件：AFTER INSERT, UPDATE, DELETE (在时段记录被插入、更新或删除之后)
-- 核心功能：当某个活动或培训的详细时段发生变化时，自动重新计算并更新其父活动
--            (在 tbl_VolunteerActivity 表中) 或父培训 (在 tbl_VolunteerTraining 表中)
--            的总体开始时间 (StartTime) 和总体结束时间 (EndTime)。
--            这是为了确保父级事件记录的总体时间范围始终反映其所有子时段的最早开始和最晚结束。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_update_parent_event_overall_times', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_parent_event_overall_times;
GO

CREATE TRIGGER dbo.trg_update_parent_event_overall_times
ON dbo.tbl_ActivityTimeslot
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AffectedEventIDs TABLE (EventID CHAR(15) PRIMARY KEY);

    INSERT INTO @AffectedEventIDs (EventID)
    SELECT DISTINCT EventID FROM inserted WHERE EventID IS NOT NULL
    UNION 
    SELECT DISTINCT EventID FROM deleted WHERE EventID IS NOT NULL;

    DECLARE @CurrentEventID CHAR(15);
    DECLARE @MinStartTime SMALLDATETIME;
    DECLARE @MaxEndTime SMALLDATETIME;

    DECLARE event_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT EventID FROM @AffectedEventIDs;

    OPEN event_cursor;
    FETCH NEXT FROM event_cursor INTO @CurrentEventID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @MinStartTime = MIN(StartTime), @MaxEndTime = MAX(EndTime)
        FROM dbo.tbl_ActivityTimeslot
        WHERE EventID = @CurrentEventID;

        IF LEFT(@CurrentEventID, 3) = 'act' 
        BEGIN
            UPDATE dbo.tbl_VolunteerActivity
            SET StartTime = @MinStartTime, 
                EndTime = @MaxEndTime    
            WHERE ActivityID = @CurrentEventID;
        END
        ELSE IF LEFT(@CurrentEventID, 3) = 'trn' 
        BEGIN
            UPDATE dbo.tbl_VolunteerTraining
            SET StartTime = @MinStartTime, 
                EndTime = @MaxEndTime     
            WHERE TrainingID = @CurrentEventID;
        END

        FETCH NEXT FROM event_cursor INTO @CurrentEventID;
    END
    CLOSE event_cursor;
    DEALLOCATE event_cursor;
END;
GO
PRINT N'触发器 [trg_update_parent_event_overall_times] 已创建/更新。';
GO

--------------------------------------------------------------------------------
-- 触发器 1.1: trg_update_org_activity_stats
-- 监控表：dbo.tbl_VolunteerActivity (志愿活动表)
-- 触发事件：AFTER UPDATE (在活动记录被更新之后)
-- 核心功能：当志愿活动的 ActivityStatus 字段从任何其他状态更新为“已结束”时：
--            1. 对应组织的 ActivityCount (活动总数) 字段在 tbl_Organization 表中加 1。
--            2. 将该已结束活动的 ActivityDurationHours (活动时长) 累加到对应组织的
--               TotalServiceHours (总服务时长) 字段。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_update_org_activity_stats', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_org_activity_stats;
GO

CREATE TRIGGER dbo.trg_update_org_activity_stats
ON dbo.tbl_VolunteerActivity
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(ActivityStatus) 
    BEGIN
        DECLARE @OrgStatsUpdates TABLE (
            OrgID CHAR(15),
            ActivityCountChange INT,
            ServiceHoursChange INT
        );

        INSERT INTO @OrgStatsUpdates (OrgID, ActivityCountChange, ServiceHoursChange)
        SELECT 
            i.OrgID,
            1, 
            ISNULL(i.ActivityDurationHours, 0) 
        FROM inserted i
        JOIN deleted d ON i.ActivityID = d.ActivityID
        WHERE i.ActivityStatus = N'已结束' AND d.ActivityStatus <> N'已结束';

        DECLARE @AggregatedOrgStats TABLE (
            OrgID CHAR(15) PRIMARY KEY,
            TotalActivityCountChange INT,
            TotalServiceHoursChange INT
        );

        INSERT INTO @AggregatedOrgStats (OrgID, TotalActivityCountChange, TotalServiceHoursChange)
        SELECT OrgID, SUM(ActivityCountChange), SUM(ServiceHoursChange)
        FROM @OrgStatsUpdates
        GROUP BY OrgID;

        DECLARE @CurrentOrgID CHAR(15);
        DECLARE @ActivityCountDelta INT;
        DECLARE @ServiceHoursDelta INT;

        DECLARE org_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT OrgID, TotalActivityCountChange, TotalServiceHoursChange FROM @AggregatedOrgStats;

        OPEN org_cursor;
        FETCH NEXT FROM org_cursor INTO @CurrentOrgID, @ActivityCountDelta, @ServiceHoursDelta;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @CurrentOrgID IS NOT NULL
            BEGIN
                BEGIN TRY
                    UPDATE dbo.tbl_Organization
                    SET ActivityCount = ActivityCount + @ActivityCountDelta,
                        TotalServiceHours = TotalServiceHours + @ServiceHoursDelta
                    WHERE OrgID = @CurrentOrgID;
                END TRY
                BEGIN CATCH
                    PRINT N'错误：更新组织 ' + @CurrentOrgID + N' 的活动统计时发生错误。详情: ' + ERROR_MESSAGE();
                END CATCH
            END
            FETCH NEXT FROM org_cursor INTO @CurrentOrgID, @ActivityCountDelta, @ServiceHoursDelta;
        END
        CLOSE org_cursor;
        DEALLOCATE org_cursor;
    END
END;
GO
PRINT N'触发器 [trg_update_org_activity_stats] 已创建/更新。';
GO

-- 触发器 1.2: trg_update_org_training_count
-- 监控表：dbo.tbl_VolunteerTraining (志愿培训表)
-- 触发事件：AFTER UPDATE (在培训记录被更新之后)
-- 核心功能：当志愿培训的 TrainingStatus 字段从任何其他状态更新为“已结束”时，
--            自动将对应组织的 TrainingCount (培训总数) 字段在 tbl_Organization 表中加 1。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_update_org_training_count', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_org_training_count;
GO

CREATE TRIGGER dbo.trg_update_org_training_count
ON dbo.tbl_VolunteerTraining
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(TrainingStatus)
    BEGIN
        DECLARE @OrgTrainingUpdates TABLE (OrgID CHAR(15), TrainingCountChange INT);

        INSERT INTO @OrgTrainingUpdates (OrgID, TrainingCountChange)
        SELECT i.OrgID, 1
        FROM inserted i
        JOIN deleted d ON i.TrainingID = d.TrainingID
        WHERE i.TrainingStatus = N'已结束' AND d.TrainingStatus <> N'已结束';

        DECLARE @AggregatedOrgTrainingStats TABLE (
            OrgID CHAR(15) PRIMARY KEY,
            TotalTrainingCountChange INT
        );
        INSERT INTO @AggregatedOrgTrainingStats(OrgID, TotalTrainingCountChange)
        SELECT OrgID, SUM(TrainingCountChange)
        FROM @OrgTrainingUpdates
        GROUP BY OrgID;

        DECLARE @CurrentOrgID CHAR(15);
        DECLARE @TrainingCountDelta INT;

        DECLARE org_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT OrgID, TotalTrainingCountChange FROM @AggregatedOrgTrainingStats;

        OPEN org_cursor;
        FETCH NEXT FROM org_cursor INTO @CurrentOrgID, @TrainingCountDelta;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @CurrentOrgID IS NOT NULL
            BEGIN
                BEGIN TRY
                    UPDATE dbo.tbl_Organization
                    SET TrainingCount = TrainingCount + @TrainingCountDelta
                    WHERE OrgID = @CurrentOrgID;
                END TRY
                BEGIN CATCH
                    PRINT N'错误：更新组织 ' + @CurrentOrgID + N' 的培训次数时发生错误。详情: ' + ERROR_MESSAGE();
                END CATCH
            END
            FETCH NEXT FROM org_cursor INTO @CurrentOrgID, @TrainingCountDelta;
        END
        CLOSE org_cursor;
        DEALLOCATE org_cursor;
    END
END;
GO
PRINT N'触发器 [trg_update_org_training_count] 已创建/更新。';
GO

-- 触发器 2.1: trg_prevent_delete_last_timeslot_and_update_parent
-- 监控表：dbo.tbl_ActivityTimeslot (活动/培训时段表)
-- 触发事件：INSTEAD OF DELETE (在时段记录被删除之前)
-- 核心功能：当某活动的详细时段发生变化时，自动重新计算并更新该活动在 
--            tbl_VolunteerActivity 表中的 ActivityDurationHours (计划总时长) 字段。
--            (此触发器仅针对活动，不处理培训的总时长)
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_prevent_delete_last_timeslot_and_update_parent', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_prevent_delete_last_timeslot_and_update_parent;
GO

CREATE TRIGGER dbo.trg_prevent_delete_last_timeslot_and_update_parent
ON dbo.tbl_ActivityTimeslot
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventID_ToProcess CHAR(15);
    DECLARE @TimeslotID_ToProcess CHAR(15);
    DECLARE @RemainingTimeslotsForEvent INT;
    DECLARE @ErrorMessage NVARCHAR(255);

    -- 通常 INSTEAD OF DELETE 触发器一次处理一行，但最好还是用游标处理多行删除的可能
    DECLARE cur_deleted CURSOR LOCAL FAST_FORWARD FOR
    SELECT EventID, TimeslotID FROM deleted;

    OPEN cur_deleted;
    FETCH NEXT FROM cur_deleted INTO @EventID_ToProcess, @TimeslotID_ToProcess;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 检查如果删除了这个时段，该事件是否还有其他时段
        SELECT @RemainingTimeslotsForEvent = COUNT(*)
        FROM dbo.tbl_ActivityTimeslot
        WHERE EventID = @EventID_ToProcess AND TimeslotID <> @TimeslotID_ToProcess; -- 排除当前正要删除的时段

        IF @RemainingTimeslotsForEvent = 0
        BEGIN
            SET @ErrorMessage = N'操作失败：事件 ' + @EventID_ToProcess + N' 至少需要一个时段。不能删除其最后一个时段 (' + @TimeslotID_ToProcess + N')。';
            RAISERROR(@ErrorMessage, 16, 1);
            -- 因为是 INSTEAD OF DELETE，所以不执行任何操作就等于阻止了删除
        END
        ELSE
        BEGIN
            -- 如果删除后仍有其他时段，则执行删除
            DELETE FROM dbo.tbl_ActivityTimeslot
            WHERE TimeslotID = @TimeslotID_ToProcess AND EventID = @EventID_ToProcess;

            -- 然后更新父事件的时间（这里的逻辑与之前的 trg_update_parent_event_overall_times 类似）
            DECLARE @NewStartTime SMALLDATETIME, @NewEndTime SMALLDATETIME;
            SELECT
                @NewStartTime = MIN(ts.StartTime),
                @NewEndTime = MAX(ts.EndTime)
            FROM dbo.tbl_ActivityTimeslot ts
            WHERE ts.EventID = @EventID_ToProcess;

            IF LEFT(@EventID_ToProcess, 3) = 'act'
                UPDATE dbo.tbl_VolunteerActivity SET StartTime = @NewStartTime, EndTime = @NewEndTime WHERE ActivityID = @EventID_ToProcess;
            ELSE IF LEFT(@EventID_ToProcess, 3) = 'trn'
                UPDATE dbo.tbl_VolunteerTraining SET StartTime = @NewStartTime, EndTime = @NewEndTime WHERE TrainingID = @EventID_ToProcess;

            PRINT N'时段 ' + @TimeslotID_ToProcess + N' 已删除，父事件 ' + @EventID_ToProcess + N' 时间已更新。';
        END

        FETCH NEXT FROM cur_deleted INTO @EventID_ToProcess, @TimeslotID_ToProcess;
    END
    CLOSE cur_deleted;
    DEALLOCATE cur_deleted;
END
GO

-- 触发器 3.1: trg_update_activity_accepted_count
-- 监控表：dbo.tbl_VolunteerActivityApplication (志愿者活动报名表)
-- 触发事件：AFTER INSERT, UPDATE, DELETE (在报名记录被插入、更新或删除之后)
-- 核心功能：当活动报名申请的状态（ApplicationStatus）改变，或有新的报名产生/删除时，
--            自动更新 tbl_VolunteerActivity 表中对应活动的 AcceptedCount (实际录取人数)。
--            如果计算出的新录取人数超过了活动的 RecruitmentCount (计划招募人数)，
--            则回滚当前操作并报错，以防止超额录取。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_update_activity_accepted_count', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_activity_accepted_count;
GO

CREATE TRIGGER dbo.trg_update_activity_accepted_count
ON dbo.tbl_VolunteerActivityApplication
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    PRINT N'触发器 trg_update_activity_accepted_count 已触发。';

    DECLARE @AffectedActivityIDs TABLE (ActivityID CHAR(15) PRIMARY KEY);

    -- 收集所有受本次操作影响的 ActivityID
    INSERT INTO @AffectedActivityIDs (ActivityID)
    SELECT DISTINCT ActivityID FROM inserted WHERE ActivityID IS NOT NULL
    UNION -- 使用 UNION 去重，因为 UPDATE 操作时 ActivityID 会同时存在于 inserted 和 deleted
    SELECT DISTINCT ActivityID FROM deleted WHERE ActivityID IS NOT NULL;

    DECLARE @CurrentActivityID CHAR(15);
    DECLARE @NewAcceptedCount INT;
    DECLARE @RecruitmentCount INT;
    DECLARE @ErrorMessage NVARCHAR(300);

    DECLARE activity_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ActivityID FROM @AffectedActivityIDs;

    OPEN activity_cursor;
    FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'处理 ActivityID: ' + @CurrentActivityID;

        -- 获取该活动的招募人数
        SELECT @RecruitmentCount = RecruitmentCount
        FROM dbo.tbl_VolunteerActivity
        WHERE ActivityID = @CurrentActivityID;
        PRINT N'ActivityID: ' + @CurrentActivityID + N', RecruitmentCount: ' + ISNULL(CONVERT(VARCHAR(10), @RecruitmentCount), 'NULL');

        -- 重新计算该活动的“已通过”报名总数
        SELECT @NewAcceptedCount = COUNT(*)
        FROM dbo.tbl_VolunteerActivityApplication
        WHERE ActivityID = @CurrentActivityID AND ApplicationStatus = N'已通过';
        PRINT N'ActivityID: ' + @CurrentActivityID + N', 新计算的 NewAcceptedCount: ' + ISNULL(CONVERT(VARCHAR(10), @NewAcceptedCount), 'NULL');

        -- 检查计算出的新录取人数是否会超过招募人数
        IF @NewAcceptedCount > @RecruitmentCount -- 假设 RecruitmentCount 始终 NOT NULL (根据表结构)
        BEGIN
            SET @ErrorMessage = N'活动 "' + @CurrentActivityID + N'" 的新录取人数 (' + CONVERT(VARCHAR(10), @NewAcceptedCount) + N') 将超过其招募人数 (' + CONVERT(VARCHAR(10), @RecruitmentCount) + N')。操作将回滚。';
            PRINT @ErrorMessage; -- 打印错误信息以供调试
            RAISERROR (@ErrorMessage, 16, 1); -- 抛出错误
            IF @@TRANCOUNT > 0
            BEGIN
                PRINT N'回滚事务...';
                ROLLBACK TRANSACTION;
            END
            CLOSE activity_cursor;
            DEALLOCATE activity_cursor;
            RETURN; -- 关键：一旦发生错误并回滚，立即退出触发器，不再处理其他ActivityID（如果有的话）
        END

        -- 更新父表 tbl_VolunteerActivity 中的 AcceptedCount
        PRINT N'准备更新 ActivityID: ' + @CurrentActivityID + N' 的 AcceptedCount 为 ' + CONVERT(VARCHAR(10), @NewAcceptedCount);
        UPDATE dbo.tbl_VolunteerActivity
        SET AcceptedCount = @NewAcceptedCount
        WHERE ActivityID = @CurrentActivityID;
        PRINT N'ActivityID: ' + @CurrentActivityID + N' 的 AcceptedCount 已更新。';

        FETCH NEXT FROM activity_cursor INTO @CurrentActivityID;
    END
    CLOSE activity_cursor;
    DEALLOCATE activity_cursor;
    PRINT N'触发器 trg_update_activity_accepted_count 执行完毕。';
END;
GO
PRINT N'触发器 [trg_update_activity_accepted_count] 已创建/更新。';
GO

-- 触发器 3.2: trg_update_position_recruited_count
-- 监控表：dbo.tbl_VolunteerActivityParticipation (志愿者活动参与表)
-- 触发事件：AFTER INSERT, DELETE, UPDATE (在参与记录被插入、删除或更新之后)
-- 核心功能：当志愿者被实际分配到某活动的某个岗位，或从岗位移除时（即参与记录发生变化），
--            自动更新 tbl_Position 表中对应岗位的 RecruitedVolunteers (已招募人数)。
--            如果计算出的新已招募人数超过了岗位的 RequiredVolunteers (需求人数)，
--            则回滚当前操作并报错，以防止岗位超额招募。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_update_position_recruited_count', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_update_position_recruited_count;
GO

CREATE TRIGGER dbo.trg_update_position_recruited_count
ON dbo.tbl_VolunteerActivityParticipation
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AffectedPositions TABLE (PositionID CHAR(15), ActivityID CHAR(15), PRIMARY KEY (PositionID, ActivityID));

    INSERT INTO @AffectedPositions (PositionID, ActivityID)
    SELECT DISTINCT ActualPositionID, ActivityID FROM inserted WHERE ActualPositionID IS NOT NULL AND ActivityID IS NOT NULL
    UNION
    SELECT DISTINCT ActualPositionID, ActivityID FROM deleted WHERE ActualPositionID IS NOT NULL AND ActivityID IS NOT NULL;

    DECLARE @CurrentPositionID CHAR(15);
    DECLARE @CurrentActivityID_Pos CHAR(15); 
    DECLARE @NewRecruitedCount INT;
    DECLARE @RequiredVolunteers INT;

    DECLARE position_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT PositionID, ActivityID FROM @AffectedPositions;

    OPEN position_cursor;
    FETCH NEXT FROM position_cursor INTO @CurrentPositionID, @CurrentActivityID_Pos;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @RequiredVolunteers = RequiredVolunteers
        FROM dbo.tbl_Position
        WHERE PositionID = @CurrentPositionID AND ActivityID = @CurrentActivityID_Pos;

        SELECT @NewRecruitedCount = COUNT(DISTINCT VolunteerID) 
        FROM dbo.tbl_VolunteerActivityParticipation
        WHERE ActualPositionID = @CurrentPositionID AND ActivityID = @CurrentActivityID_Pos;

        IF @NewRecruitedCount > @RequiredVolunteers AND @RequiredVolunteers IS NOT NULL
        BEGIN
            RAISERROR (N'岗位 "%s" (活动 "%s") 的已招募人数 (%d) 不能超过需求人数 (%d)。操作已回滚。', 16, 1, @CurrentPositionID, @CurrentActivityID_Pos, @NewRecruitedCount, @RequiredVolunteers);
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            CLOSE position_cursor; DEALLOCATE position_cursor;
            RETURN;
        END

        UPDATE dbo.tbl_Position
        SET RecruitedVolunteers = @NewRecruitedCount
        WHERE PositionID = @CurrentPositionID AND ActivityID = @CurrentActivityID_Pos;

        FETCH NEXT FROM position_cursor INTO @CurrentPositionID, @CurrentActivityID_Pos;
    END
    CLOSE position_cursor;
    DEALLOCATE position_cursor;
END;
GO
PRINT N'触发器 [trg_update_position_recruited_count] 已创建/更新。';
GO

--------------------------------------------------------------------------------
-- 第二部分：流程控制与冲突检测触发器
--------------------------------------------------------------------------------

-- 触发器 4.1: trg_check_activity_application_time_conflict
-- 监控表：dbo.tbl_VolunteerActivityApplication (志愿者活动报名表)
-- 触发事件：INSTEAD OF INSERT (在尝试插入新的活动报名记录之前)
-- 核心功能：在志愿者提交新的活动报名时，阻止插入操作，并检查新报名活动的总体时间
--            是否与该志愿者已确认参与的其他活动（tbl_VolunteerActivityParticipation）
--            或已报名且有效的培训（tbl_VolunteerTrainingParticipation 和 tbl_VolunteerTraining）
--            的总体时间存在重叠。如果存在时间冲突，则报错并不执行插入；否则，执行原插入操作。
--------------------------------------------------------------------------------
-- THIS TRIGGER IS REDUNDANT AND CONFLICTS WITH trg_InsteadInsert_Application IN 07_id_generation_triggers.sql
-- IT SHOULD BE REMOVED FROM THIS FILE.
-- IF OBJECT_ID('dbo.trg_check_activity_application_time_conflict', 'TR') IS NOT NULL
--     DROP TRIGGER dbo.trg_check_activity_application_time_conflict;
-- GO
-- CREATE TRIGGER dbo.trg_check_activity_application_time_conflict
-- ON dbo.tbl_VolunteerActivityApplication
-- INSTEAD OF INSERT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @VolunteerID CHAR(15);
--     DECLARE @NewActivityID CHAR(15);
--     DECLARE @NewActivityStartTime SMALLDATETIME;
--     DECLARE @NewActivityEndTime SMALLDATETIME;
--     DECLARE @ConflictEventID CHAR(15);
--     DECLARE @ConflictEventType NVARCHAR(20);

--     SELECT @VolunteerID = i.VolunteerID, @NewActivityID = i.ActivityID FROM inserted i;

--     SELECT @NewActivityStartTime = va.StartTime, @NewActivityEndTime = va.EndTime
--     FROM dbo.tbl_VolunteerActivity va WHERE va.ActivityID = @NewActivityID;

--     IF @NewActivityStartTime IS NULL OR @NewActivityEndTime IS NULL
--     BEGIN
--         RAISERROR(N'无法获取新报名活动 "%s" 的有效时间范围。报名失败。', 16, 1, @NewActivityID);
--         RETURN;
--     END

--     -- 检查与已确认参加的活动的时间冲突
--     SELECT TOP 1 @ConflictEventID = vap.ActivityID, @ConflictEventType = N'活动'
--     FROM dbo.tbl_VolunteerActivityParticipation vap
--     JOIN dbo.tbl_VolunteerActivity va_existing ON vap.ActivityID = va_existing.ActivityID
--     WHERE vap.VolunteerID = @VolunteerID
--       AND NOT (@NewActivityEndTime <= va_existing.StartTime OR @NewActivityStartTime >= va_existing.EndTime); 

--     IF @ConflictEventID IS NOT NULL
--     BEGIN
--         RAISERROR(N'报名失败：新活动与您已确认参加的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
--         RETURN;
--     END

--     -- 检查与已确认参加的、且有效的（非已结束/已停用/审核不通过）培训的时间冲突
--     SET @ConflictEventID = NULL; 
--     SELECT TOP 1 @ConflictEventID = vtp.TrainingID, @ConflictEventType = N'培训'
--     FROM dbo.tbl_VolunteerTrainingParticipation vtp
--     JOIN dbo.tbl_VolunteerTraining vt_existing ON vtp.TrainingID = vt_existing.TrainingID
--     WHERE vtp.VolunteerID = @VolunteerID
--       AND vt_existing.TrainingStatus NOT IN (N'已结束', N'已停用', N'审核不通过') 
--       AND NOT (@NewActivityEndTime <= vt_existing.StartTime OR @NewActivityStartTime >= vt_existing.EndTime); 

--     IF @ConflictEventID IS NOT NULL
--     BEGIN
--         RAISERROR(N'报名失败：新活动与您已报名且有效的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
--         RETURN;
--     END

--     INSERT INTO dbo.tbl_VolunteerActivityApplication (ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus)
--     SELECT ApplicationID, VolunteerID, ActivityID, IntendedPositionID, ApplicationTime, ApplicationStatus FROM inserted;
-- END;
-- GO
-- PRINT N'触发器 [trg_check_activity_application_time_conflict] 已创建/更新。';
-- GO


-- 触发器 4.2: trg_check_training_participation_time_conflict
-- 监控表：dbo.tbl_VolunteerTrainingParticipation (志愿者培训参与表)
-- 触发事件：INSTEAD OF INSERT (在尝试插入新的培训参与记录之前)
-- 核心功能：当为某培训添加参与志愿者时（即插入参与记录），阻止插入操作，并检查该培训的总体时间
--            是否与该志愿者已确认参加的其他活动（tbl_VolunteerActivityParticipation）
--            或其他已报名且有效的培训（tbl_VolunteerTrainingParticipation 和 tbl_VolunteerTraining）
--            的总体时间存在重叠。如果存在时间冲突，则报错并不执行插入；否则，执行原插入操作。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_check_training_participation_time_conflict', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_check_training_participation_time_conflict;
GO
CREATE TRIGGER dbo.trg_check_training_participation_time_conflict
ON dbo.tbl_VolunteerTrainingParticipation
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @VolunteerID CHAR(15);
    DECLARE @NewTrainingID CHAR(15);
    DECLARE @NewTrainingStartTime SMALLDATETIME;
    DECLARE @NewTrainingEndTime SMALLDATETIME;
    DECLARE @ConflictEventID CHAR(15);
    DECLARE @ConflictEventType NVARCHAR(20);

    SELECT @VolunteerID = i.VolunteerID, @NewTrainingID = i.TrainingID FROM inserted i;

    SELECT @NewTrainingStartTime = vt.StartTime, @NewTrainingEndTime = vt.EndTime
    FROM dbo.tbl_VolunteerTraining vt WHERE vt.TrainingID = @NewTrainingID;

    IF @NewTrainingStartTime IS NULL OR @NewTrainingEndTime IS NULL
    BEGIN
        RAISERROR(N'无法获取新培训 "%s" 的有效时间范围。添加参与失败。', 16, 1, @NewTrainingID);
        RETURN;
    END

    -- 检查与已确认参加的活动的时间冲突
    SELECT TOP 1 @ConflictEventID = vap.ActivityID, @ConflictEventType = N'活动'
    FROM dbo.tbl_VolunteerActivityParticipation vap
    JOIN dbo.tbl_VolunteerActivity va_existing ON vap.ActivityID = va_existing.ActivityID
    WHERE vap.VolunteerID = @VolunteerID
      AND NOT (@NewTrainingEndTime <= va_existing.StartTime OR @NewTrainingStartTime >= va_existing.EndTime);

    IF @ConflictEventID IS NOT NULL
    BEGIN
        RAISERROR(N'添加培训参与失败：该培训与志愿者已确认参加的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
        RETURN;
    END

    -- 检查与已确认参加的其他、且有效的（非已结束/已停用/审核不通过）培训的时间冲突
    SET @ConflictEventID = NULL; 
    SELECT TOP 1 @ConflictEventID = vtp.TrainingID, @ConflictEventType = N'培训'
    FROM dbo.tbl_VolunteerTrainingParticipation vtp
    JOIN dbo.tbl_VolunteerTraining vt_existing ON vtp.TrainingID = vt_existing.TrainingID
    WHERE vtp.VolunteerID = @VolunteerID
      AND vt_existing.TrainingID <> @NewTrainingID 
      AND vt_existing.TrainingStatus NOT IN (N'已结束', N'已停用', N'审核不通过') 
      AND NOT (@NewTrainingEndTime <= vt_existing.StartTime OR @NewTrainingStartTime >= vt_existing.EndTime);

    IF @ConflictEventID IS NOT NULL
    BEGIN
        RAISERROR(N'添加培训参与失败：该培训与志愿者已报名且有效的%s "%s" 存在时间冲突。', 16, 1, @ConflictEventType, @ConflictEventID);
        RETURN;
    END

    INSERT INTO dbo.tbl_VolunteerTrainingParticipation (VolunteerID, TrainingID, IsCheckedIn, OrgToVolunteerRating, VolunteerToOrgRating) 
    SELECT VolunteerID, TrainingID, IsCheckedIn, OrgToVolunteerRating, VolunteerToOrgRating FROM inserted;
END;
GO
PRINT N'触发器 [trg_check_training_participation_time_conflict] 已创建/更新。';
GO


-- 触发器 5.1: trg_manage_volunteer_org_membership
-- 监控表：dbo.tbl_VolunteerOrganizationJoin (志愿者组织加入表)
-- 触发事件：AFTER UPDATE (在加入记录被更新之后)
-- 核心功能： 当志愿者在组织中的 MemberStatus 字段从“已加入”更新为“已退出”时，
--            系统自动将其在该组织名下所有尚未开始的、且状态为“待审核”或“已通过”的
--            活动报名（tbl_VolunteerActivityApplication）的状态更新为“取消报名”。
--            （重要：确保 '取消报名' 是 tbl_VolunteerActivityApplication.ApplicationStatus 的有效状态）
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_manage_volunteer_org_membership', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_manage_volunteer_org_membership;
GO

CREATE TRIGGER dbo.trg_manage_volunteer_org_membership
ON dbo.tbl_VolunteerOrganizationJoin
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(MemberStatus) 
    BEGIN
        DECLARE @ExitedMemberships TABLE (VolunteerID CHAR(15), OrgID CHAR(15));
        INSERT INTO @ExitedMemberships (VolunteerID, OrgID)
        SELECT i.VolunteerID, i.OrgID
        FROM inserted i
        JOIN deleted d ON i.VolunteerID = d.VolunteerID AND i.OrgID = d.OrgID
        WHERE d.MemberStatus = N'已加入' AND i.MemberStatus = N'已退出';

        IF EXISTS (SELECT 1 FROM @ExitedMemberships)
        BEGIN
            BEGIN TRY
                UPDATE vaa
                SET vaa.ApplicationStatus = N'取消报名' 
                FROM dbo.tbl_VolunteerActivityApplication vaa
                JOIN dbo.tbl_VolunteerActivity va ON vaa.ActivityID = va.ActivityID
                JOIN @ExitedMemberships em ON vaa.VolunteerID = em.VolunteerID AND va.OrgID = em.OrgID
                WHERE va.StartTime > GETDATE()          
                  AND vaa.ApplicationStatus IN (N'待审核', N'已通过'); 
            END TRY
            BEGIN CATCH
                 PRINT N'错误：在处理志愿者退出组织后的报名状态时发生错误。详情: ' + ERROR_MESSAGE();
            END CATCH
        END
    END
END;
GO
PRINT N'触发器 [trg_manage_volunteer_org_membership] 已创建/更新。';
GO

--------------------------------------------------------------------------------
-- 第三部分：评价管理与组织综合评分机制 (合并后的触发器)
--------------------------------------------------------------------------------

-- 触发器 6.1 (合并版): trg_instead_update_activity_participation
-- 监控表：dbo.tbl_VolunteerActivityParticipation (志愿者活动参与表)
-- 触发事件：INSTEAD OF UPDATE (在尝试更新活动参与记录之前)
-- 核心功能：阻止直接更新，并根据业务规则执行更新。
--            主要用于控制志愿者（VolunteerToOrgRating）和组织（OrgToVolunteerRating）
--            对活动参与情况的评分提交，确保评分在活动结束后7天的窗口期内进行。
--            同时，允许对其他字段（如 IsCheckedIn）进行常规更新。
--            如果评分更新不符合窗口期规则，则该评分更新将被阻止，并报错。
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_instead_update_activity_participation', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_instead_update_activity_participation;
GO

CREATE TRIGGER dbo.trg_instead_update_activity_participation
ON dbo.tbl_VolunteerActivityParticipation
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    PRINT N'触发器 trg_instead_update_activity_participation 已触发。';

    -- 使用表变量来存储 inserted 表中的数据，以便迭代处理
    DECLARE @UpdatedParticipations TABLE (
        VolunteerID CHAR(15),
        ActivityID CHAR(15),
        ActualPositionID CHAR(15),
        NewIsCheckedIn NCHAR(1),
        OldIsCheckedIn NCHAR(1),
        IsIsCheckedInUpdated BIT,
        NewVolunteerToOrgRating INT,
        OldVolunteerToOrgRating INT,
        IsVolunteerToOrgRatingUpdated BIT,
        NewOrgToVolunteerRating INT,
        OldOrgToVolunteerRating INT,
        IsOrgToVolunteerRatingUpdated BIT,
        PRIMARY KEY (VolunteerID, ActivityID, ActualPositionID) -- 确保唯一性
    );

    -- 将 inserted 和 deleted 表的数据填充到表变量中
    -- 并标记哪些列被尝试更新
    INSERT INTO @UpdatedParticipations (
        VolunteerID, ActivityID, ActualPositionID,
        NewIsCheckedIn, OldIsCheckedIn, IsIsCheckedInUpdated,
        NewVolunteerToOrgRating, OldVolunteerToOrgRating, IsVolunteerToOrgRatingUpdated,
        NewOrgToVolunteerRating, OldOrgToVolunteerRating, IsOrgToVolunteerRatingUpdated
    )
    SELECT
        i.VolunteerID, i.ActivityID, i.ActualPositionID,
        i.IsCheckedIn, d.IsCheckedIn, CASE WHEN UPDATE(IsCheckedIn) THEN 1 ELSE 0 END,
        i.VolunteerToOrgRating, d.VolunteerToOrgRating, CASE WHEN UPDATE(VolunteerToOrgRating) THEN 1 ELSE 0 END,
        i.OrgToVolunteerRating, d.OrgToVolunteerRating, CASE WHEN UPDATE(OrgToVolunteerRating) THEN 1 ELSE 0 END
    FROM
        inserted i
    INNER JOIN
        deleted d ON i.VolunteerID = d.VolunteerID AND i.ActivityID = d.ActivityID AND i.ActualPositionID = d.ActualPositionID;

    -- 声明用于迭代的变量
    DECLARE @CurrentVolunteerID CHAR(15);
    DECLARE @CurrentActivityID CHAR(15);
    DECLARE @CurrentActualPositionID CHAR(15);
    DECLARE @CurrentNewIsCheckedIn NCHAR(1);
    DECLARE @CurrentIsIsCheckedInUpdated BIT;
    DECLARE @CurrentNewVolunteerToOrgRating INT;
    DECLARE @CurrentIsVolunteerToOrgRatingUpdated BIT;
    DECLARE @CurrentNewOrgToVolunteerRating INT;
    DECLARE @CurrentIsOrgToVolunteerRatingUpdated BIT;

    DECLARE @ActivityOverallEndTime SMALLDATETIME;
    DECLARE @ErrorMessage NVARCHAR(512);

    -- 创建游标遍历所有被尝试更新的行
    DECLARE participation_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT VolunteerID, ActivityID, ActualPositionID,
           NewIsCheckedIn, IsIsCheckedInUpdated,
           NewVolunteerToOrgRating, IsVolunteerToOrgRatingUpdated,
           NewOrgToVolunteerRating, IsOrgToVolunteerRatingUpdated
    FROM @UpdatedParticipations;

    OPEN participation_cursor;
    FETCH NEXT FROM participation_cursor INTO
        @CurrentVolunteerID, @CurrentActivityID, @CurrentActualPositionID,
        @CurrentNewIsCheckedIn, @CurrentIsIsCheckedInUpdated,
        @CurrentNewVolunteerToOrgRating, @CurrentIsVolunteerToOrgRatingUpdated,
        @CurrentNewOrgToVolunteerRating, @CurrentIsOrgToVolunteerRatingUpdated;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'正在处理 VolunteerID: ' + @CurrentVolunteerID + N', ActivityID: ' + @CurrentActivityID + N', PositionID: ' + @CurrentActualPositionID;

        -- 获取当前处理行的活动结束时间
        SELECT @ActivityOverallEndTime = va.EndTime
        FROM dbo.tbl_VolunteerActivity va
        WHERE va.ActivityID = @CurrentActivityID;

        IF @ActivityOverallEndTime IS NULL
        BEGIN
            SET @ErrorMessage = N'更新评分失败：无法获取活动 "' + @CurrentActivityID + N'" 的结束时间。跳过此行更新。';
            PRINT @ErrorMessage;
            -- 可以选择RAISERROR并回滚，或者仅跳过此行。为避免单行失败导致整个批量失败，这里仅打印并跳过。
            -- 如果需要严格的原子性，则应 RAISERROR 并 RETURN。
            FETCH NEXT FROM participation_cursor INTO
                @CurrentVolunteerID, @CurrentActivityID, @CurrentActualPositionID,
                @CurrentNewIsCheckedIn, @CurrentIsIsCheckedInUpdated,
                @CurrentNewVolunteerToOrgRating, @CurrentIsVolunteerToOrgRatingUpdated,
                @CurrentNewOrgToVolunteerRating, @CurrentIsOrgToVolunteerRatingUpdated;
            CONTINUE; -- 继续处理下一行
        END

        -- 校验 VolunteerToOrgRating 更新的时间窗口
        IF @CurrentIsVolunteerToOrgRatingUpdated = 1
        BEGIN
            PRINT N'检测到 VolunteerToOrgRating 正在被更新。';
            IF NOT (GETDATE() > @ActivityOverallEndTime AND GETDATE() <= DATEADD(day, 7, @ActivityOverallEndTime))
            BEGIN
                SET @ErrorMessage = N'志愿者评分失败：当前不在活动 "' + @CurrentActivityID + N'" ("' + CONVERT(VARCHAR(19), @ActivityOverallEndTime, 120) + N'") 结束后7天的评价窗口期内，或者活动尚未结束。将不会更新 VolunteerToOrgRating。';
                PRINT @ErrorMessage;
                -- RAISERROR(@ErrorMessage, 16, 1); -- 如果需要严格失败并回滚整个操作，取消此行注释
                -- RETURN; -- 并取消此行注释
                SET @CurrentIsVolunteerToOrgRatingUpdated = 0; -- 标记此列不应被更新
            END
            ELSE
            BEGIN
                 PRINT N'VolunteerToOrgRating 的评价窗口期校验通过。';
            END
        END

        -- 校验 OrgToVolunteerRating 更新的时间窗口
        IF @CurrentIsOrgToVolunteerRatingUpdated = 1
        BEGIN
            PRINT N'检测到 OrgToVolunteerRating 正在被更新。';
            IF NOT (GETDATE() > @ActivityOverallEndTime AND GETDATE() <= DATEADD(day, 7, @ActivityOverallEndTime))
            BEGIN
                SET @ErrorMessage = N'组织评分失败：当前不在活动 "' + @CurrentActivityID + N'" ("' + CONVERT(VARCHAR(19), @ActivityOverallEndTime, 120) + N'") 结束后7天的评价窗口期内，或者活动尚未结束。将不会更新 OrgToVolunteerRating。';
                PRINT @ErrorMessage;
                -- RAISERROR(@ErrorMessage, 16, 1); -- 如果需要严格失败并回滚整个操作，取消此行注释
                -- RETURN; -- 并取消此行注释
                SET @CurrentIsOrgToVolunteerRatingUpdated = 0; -- 标记此列不应被更新
            END
             ELSE
            BEGIN
                 PRINT N'OrgToVolunteerRating 的评价窗口期校验通过。';
            END
        END

        -- 执行实际的更新操作 (只更新那些通过校验的列或非评分列)
        PRINT N'准备对 VolunteerID: ' + @CurrentVolunteerID + N', ActivityID: ' + @CurrentActivityID + N' 执行更新。';
        UPDATE dbo.tbl_VolunteerActivityParticipation
        SET
            -- IsCheckedIn 总是可以更新 (如果被尝试更新)
            IsCheckedIn = CASE WHEN @CurrentIsIsCheckedInUpdated = 1 THEN @CurrentNewIsCheckedIn ELSE IsCheckedIn END,
            -- VolunteerToOrgRating 只有在被尝试更新且校验通过时才更新
            VolunteerToOrgRating = CASE WHEN @CurrentIsVolunteerToOrgRatingUpdated = 1 THEN @CurrentNewVolunteerToOrgRating ELSE VolunteerToOrgRating END,
            -- OrgToVolunteerRating 只有在被尝试更新且校验通过时才更新
            OrgToVolunteerRating = CASE WHEN @CurrentIsOrgToVolunteerRatingUpdated = 1 THEN @CurrentNewOrgToVolunteerRating ELSE OrgToVolunteerRating END
        WHERE
            VolunteerID = @CurrentVolunteerID
            AND ActivityID = @CurrentActivityID
            AND ActualPositionID = @CurrentActualPositionID;

        PRINT N'VolunteerID: ' + @CurrentVolunteerID + N', ActivityID: ' + @CurrentActivityID + N' 更新完毕。';

        FETCH NEXT FROM participation_cursor INTO
            @CurrentVolunteerID, @CurrentActivityID, @CurrentActualPositionID,
            @CurrentNewIsCheckedIn, @CurrentIsIsCheckedInUpdated,
            @CurrentNewVolunteerToOrgRating, @CurrentIsVolunteerToOrgRatingUpdated,
            @CurrentNewOrgToVolunteerRating, @CurrentIsOrgToVolunteerRatingUpdated;
    END

    CLOSE participation_cursor;
    DEALLOCATE participation_cursor;

    PRINT N'触发器 trg_instead_update_activity_participation 执行完毕。';
END;
GO
PRINT N'触发器 [trg_instead_update_activity_participation] 已创建/更新。';
GO

-- 触发器 6.2 (合并版): trg_instead_update_training_participation
-- 监控表：dbo.tbl_VolunteerTrainingParticipation (志愿者培训参与表)
-- 触发事件：INSTEAD OF UPDATE (在尝试更新培训参与记录之前)
-- 核心功能：阻止直接更新，并根据业务规则执行更新。
--            主要用于控制志愿者（VolunteerToOrgRating）和组织（OrgToVolunteerRating）
--            对培训参与情况的评分提交，确保评分在培训结束后7天的窗口期内进行。
--            同时，允许对其他字段（如 IsCheckedIn）进行常规更新。
--            如果评分更新不符合窗口期规则，则该评分更新将被阻止，并报错。
--------------------------------------------------------------------------------

GO
PRINT N'触发器 [trg_instead_update_training_participation] 已创建/更新。';
GO

PRINT N'所有触发器创建/更新完毕。';
GO

IF OBJECT_ID('dbo.trg_instead_update_training_participation', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_instead_update_training_participation;
GO

CREATE TRIGGER dbo.trg_instead_update_training_participation
ON dbo.tbl_VolunteerTrainingParticipation
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'触发器 trg_instead_update_training_participation 已触发。';

    -- 使用表变量存储需要处理的更新数据
    DECLARE @UpdatedParticipations TABLE (
        VolunteerID CHAR(15),
        TrainingID CHAR(15),
        NewIsCheckedIn NCHAR(1),
        IsIsCheckedInUpdated BIT,
        NewVolunteerToOrgRating INT,
        IsVolunteerToOrgRatingUpdated BIT,
        NewOrgToVolunteerRating INT,
        IsOrgToVolunteerRatingUpdated BIT,
        PRIMARY KEY (VolunteerID, TrainingID)
    );

    INSERT INTO @UpdatedParticipations (
        VolunteerID, TrainingID,
        NewIsCheckedIn, IsIsCheckedInUpdated,
        NewVolunteerToOrgRating, IsVolunteerToOrgRatingUpdated,
        NewOrgToVolunteerRating, IsOrgToVolunteerRatingUpdated
    )
    SELECT
        i.VolunteerID, i.TrainingID,
        i.IsCheckedIn, CASE WHEN UPDATE(IsCheckedIn) THEN 1 ELSE 0 END,
        i.VolunteerToOrgRating, CASE WHEN UPDATE(VolunteerToOrgRating) THEN 1 ELSE 0 END,
        i.OrgToVolunteerRating, CASE WHEN UPDATE(OrgToVolunteerRating) THEN 1 ELSE 0 END
    FROM
        inserted i;
        -- 注意：为了获取旧值进行比较或在CASE ELSE中使用，通常还需要JOIN deleted d
        -- 但在这个INSTEAD OF UPDATE中，我们是完全重构更新逻辑，所以主要依赖inserted的新值
        -- 和UPDATE()函数来判断哪些列被尝试更新。

    DECLARE @CurrentVolunteerID CHAR(15),
            @CurrentTrainingID CHAR(15),
            @CurrentNewIsCheckedIn NCHAR(1),
            @CurrentIsIsCheckedInUpdated BIT,
            @CurrentNewVolToOrgRating INT,
            @CurrentIsVolToOrgRatingUpdated BIT,
            @CurrentNewOrgToVolRating INT,
            @CurrentIsOrgToVolRatingUpdated BIT;

    DECLARE @TrainingOverallEndTime SMALLDATETIME;
    DECLARE @ErrorMessage NVARCHAR(512);

    DECLARE training_participation_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT VolunteerID, TrainingID, NewIsCheckedIn, IsIsCheckedInUpdated,
           NewVolunteerToOrgRating, IsVolunteerToOrgRatingUpdated,
           NewOrgToVolunteerRating, IsOrgToVolunteerRatingUpdated
    FROM @UpdatedParticipations;

    OPEN training_participation_cursor;
    FETCH NEXT FROM training_participation_cursor INTO
        @CurrentVolunteerID, @CurrentTrainingID, @CurrentNewIsCheckedIn, @CurrentIsIsCheckedInUpdated,
        @CurrentNewVolToOrgRating, @CurrentIsVolToOrgRatingUpdated,
        @CurrentNewOrgToVolRating, @CurrentIsOrgToVolRatingUpdated;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'处理更新 VolunteerID: ' + @CurrentVolunteerID + N', TrainingID: ' + @CurrentTrainingID;

        SELECT @TrainingOverallEndTime = vt.EndTime
        FROM dbo.tbl_VolunteerTraining vt
        WHERE vt.TrainingID = @CurrentTrainingID;

        IF @TrainingOverallEndTime IS NULL
        BEGIN
            SET @ErrorMessage = N'更新评分失败：无法获取培训 "' + @CurrentTrainingID + N'" 的结束时间。跳过此行更新。';
            PRINT @ErrorMessage;
            -- 如果希望单行校验失败导致整个批量操作失败，则应 RAISERROR 并 RETURN
            -- RAISERROR(@ErrorMessage, 16, 1); RETURN;
            GOTO NextIteration; -- 跳到下一次循环迭代
        END

        -- 校验 VolunteerToOrgRating 更新的时间窗口
        IF @CurrentIsVolToOrgRatingUpdated = 1
        BEGIN
            PRINT N'检测到 VolunteerToOrgRating 正在被更新。';
            IF NOT (GETDATE() > @TrainingOverallEndTime AND GETDATE() <= DATEADD(day, 7, @TrainingOverallEndTime))
            BEGIN
                SET @ErrorMessage = N'志愿者评分失败：当前不在培训 "' + @CurrentTrainingID + N'" (结束于 ' + CONVERT(VARCHAR(19), @TrainingOverallEndTime, 120) + N') 结束后7天的评价窗口期内，或者培训尚未结束。将不会更新 VolunteerToOrgRating。';
                PRINT @ErrorMessage;
                SET @CurrentIsVolToOrgRatingUpdated = 0; -- 标记此列不应被更新
                -- 如果希望严格失败，则 RAISERROR 和 RETURN
            END
            ELSE
            BEGIN
                PRINT N'VolunteerToOrgRating 的评价窗口期校验通过。';
            END
        END

        -- 校验 OrgToVolunteerRating 更新的时间窗口
        IF @CurrentIsOrgToVolRatingUpdated = 1
        BEGIN
            PRINT N'检测到 OrgToVolunteerRating 正在被更新。';
            IF NOT (GETDATE() > @TrainingOverallEndTime AND GETDATE() <= DATEADD(day, 7, @TrainingOverallEndTime))
            BEGIN
                SET @ErrorMessage = N'组织评分失败：当前不在培训 "' + @CurrentTrainingID + N'" (结束于 ' + CONVERT(VARCHAR(19), @TrainingOverallEndTime, 120) + N') 结束后7天的评价窗口期内，或者培训尚未结束。将不会更新 OrgToVolunteerRating。';
                PRINT @ErrorMessage;
                SET @CurrentIsOrgToVolRatingUpdated = 0; -- 标记此列不应被更新
                -- 如果希望严格失败，则 RAISERROR 和 RETURN
            END
            ELSE
            BEGIN
                PRINT N'OrgToVolunteerRating 的评价窗口期校验通过。';
            END
        END

        -- 执行实际的更新操作
        UPDATE dbo.tbl_VolunteerTrainingParticipation
        SET
            IsCheckedIn = CASE WHEN @CurrentIsIsCheckedInUpdated = 1 THEN @CurrentNewIsCheckedIn ELSE IsCheckedIn END,
            VolunteerToOrgRating = CASE WHEN @CurrentIsVolToOrgRatingUpdated = 1 THEN @CurrentNewVolToOrgRating ELSE VolunteerToOrgRating END,
            OrgToVolunteerRating = CASE WHEN @CurrentIsOrgToVolRatingUpdated = 1 THEN @CurrentNewOrgToVolRating ELSE OrgToVolunteerRating END
        WHERE
            VolunteerID = @CurrentVolunteerID AND TrainingID = @CurrentTrainingID;

        PRINT N'VolunteerID: ' + @CurrentVolunteerID + N', TrainingID: ' + @CurrentTrainingID + N' 的记录已按条件更新。';

        NextIteration: -- GOTO 标签
        FETCH NEXT FROM training_participation_cursor INTO
            @CurrentVolunteerID, @CurrentTrainingID, @CurrentNewIsCheckedIn, @CurrentIsIsCheckedInUpdated,
            @CurrentNewVolToOrgRating, @CurrentIsVolToOrgRatingUpdated,
            @CurrentNewOrgToVolRating, @CurrentIsOrgToVolRatingUpdated;
    END

    CLOSE training_participation_cursor;
    DEALLOCATE training_participation_cursor;

    PRINT N'触发器 trg_instead_update_training_participation 执行完毕。';
END;
GO
PRINT N'触发器 [dbo.trg_instead_update_training_participation] (已修改为迭代处理) 已创建/更新。';
GO