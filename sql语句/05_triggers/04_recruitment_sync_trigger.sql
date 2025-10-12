USE volunteer_db_test;
GO

--------------------------------------------------------------------------------
-- Trigger: trg_sync_recruitment_count_from_positions
-- Target table: dbo.tbl_Position (Position table)
-- Trigger event: AFTER INSERT, UPDATE, DELETE
-- Function: When activity positions change, automatically calculate and update
--           RecruitmentCount field in activity table based on total required volunteers
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

    -- Collect all potentially affected activity IDs
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
        -- Calculate total required volunteers for this activity
        SELECT @TotalRecruitmentCount = ISNULL(SUM(RequiredVolunteers), 0)
        FROM dbo.tbl_Position
        WHERE ActivityID = @CurrentActivityID;

        -- Update RecruitmentCount field in activity table
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

PRINT 'Trigger [trg_sync_recruitment_count_from_positions] created successfully.';
GO 