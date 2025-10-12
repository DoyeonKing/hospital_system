--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

--------------------------------------------------------------------------------
-- 触发器 1: TRG_Complaint_Audit_LatestProcessingTime
-- 描述: 确保存储在投诉处理相关的关键字段被修改时，'LatestProcessingTime' 得以更新。
--       此触发器作为一道保障，补充存储过程中已有的更新逻辑。
-- 触发时机:    UPDATE
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.TRG_Complaint_Audit_LatestProcessingTime', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_Complaint_Audit_LatestProcessingTime;
GO

CREATE TRIGGER TRG_Complaint_Audit_LatestProcessingTime
ON dbo.tbl_Complaint
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 检查是否有任何指示处理活动的相关字段被更新。
    -- 存储过程应该已经处理了 LatestProcessingTime 的更新。
    -- 此触发器确保即使是通过直接的 UPDATE 语句（而非存储过程）修改了这些列，时间戳也能被更新。
    IF UPDATE(ProcessingStatus) OR
       UPDATE(ProcessingResult) OR
       UPDATE(HandlerAdminID) OR
       UPDATE(ReviewAdminID) OR
       UPDATE(VisitResult) OR
       UPDATE(ComplaintContent) OR -- (通过 sp_ComplainantAddInfoToComplaint)
       UPDATE(EvidenceLink)        -- (通过 sp_ComplainantAddInfoToComplaint)
    BEGIN
        UPDATE C
        SET LatestProcessingTime = GETDATE()
        FROM dbo.tbl_Complaint C
        INNER JOIN inserted I ON C.ComplaintID = I.ComplaintID
        -- 仅当该行确实是触发更新语句影响的行时才更新
        WHERE EXISTS (SELECT 1 FROM deleted d WHERE d.ComplaintID = I.ComplaintID);
    END
END
GO

PRINT N'触发器 TRG_Complaint_Audit_LatestProcessingTime 已创建。';
GO

--------------------------------------------------------------------------------
-- 触发器 2: TRG_Complaint_AutoEscalateOnDissatisfaction
-- 描述: 实现流程图逻辑：如果回访结果记录为“不满意”，并且投诉尚未处于
--       最终复审状态或仲裁轮次已达上限，则此触发器会自动将“ProcessingStatus”更改为“仲裁中”，
--       从而提示管理员需要使用 sp_AdminEscalateComplaint 来指派复审员和轮次。
-- 触发时机:    UPDATE
--------------------------------------------------------------------------------
IF OBJECT_ID('dbo.TRG_Complaint_AutoEscalateOnDissatisfaction', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_Complaint_AutoEscalateOnDissatisfaction;
GO

CREATE TRIGGER TRG_Complaint_AutoEscalateOnDissatisfaction
ON dbo.tbl_Complaint
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 检查 VisitResult 列是否被更新
    IF UPDATE(VisitResult)
    BEGIN
        UPDATE C
        SET
            ProcessingStatus = N'仲裁中', -- 根据流程图“进入复审”的指示，将状态设置为“仲裁中”
            LatestProcessingTime = GETDATE()  -- 因状态变更而更新处理时间
        FROM dbo.tbl_Complaint C
        INNER JOIN inserted I ON C.ComplaintID = I.ComplaintID
        INNER JOIN deleted D ON I.ComplaintID = D.ComplaintID
        WHERE I.VisitResult = N'不满意'                         -- 当前回访结果为“不满意”
          AND ISNULL(D.VisitResult, N'') <> N'不满意'           -- 并且它是*变为*“不满意”（之前不是“不满意”）
          AND ISNULL(C.ArbitrationRound, 0) < 2                -- 并且仲裁轮次未达到上限（最多2轮意味着 < 2 允许进行第1轮或第2轮）
          AND C.ProcessingStatus NOT IN (N'仲裁中', N'未处理', N'已退回'); -- 并且投诉当前并非已处于“仲裁中”状态，或不应由此触发器自动升级的初始/最终状态。
                                                                  -- 合适的前置状态可能包括“已应诉”，或来自先前轮次的“已仲裁”。
                                                                  -- 'sp_AdminRecordComplaintVisit' 允许在“已应诉”、“已仲裁”、“已退回”状态下记录回访。
                                                                  -- 如果“已退回”状态的投诉在回访后变为“不满意”，则意味着它需要重新进入仲裁流程。
                                                                  -- 如果“已仲裁”（例如第1轮已完成）状态的投诉在回访后变为“不满意”，则会升级到下一轮并标记为“仲裁中”。
                                                                  -- 添加 NOT IN (N'仲裁中') 以防止在状态已被设置的情况下可能出现的递归问题。
    END
END
GO

PRINT N'触发器 TRG_Complaint_AutoEscalateOnDissatisfaction 已创建。';
GO