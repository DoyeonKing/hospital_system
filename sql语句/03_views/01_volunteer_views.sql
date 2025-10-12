--USE volunteer_db_test
USE volunteer_web_05;
GO

IF OBJECT_ID('dbo.v_VolunteerAuxiliaryRating', 'V') IS NOT NULL
    DROP VIEW dbo.v_VolunteerAuxiliaryRating;
GO

--------------------------------------------------------------------------------
-- 视图名称: v_VolunteerAuxiliaryRating
-- 目的:     提供一个基于志愿者累计志愿服务时长转换的星级评分。
--           此星级评分可作为志愿者综合评分的一个计算维度。
-- 核心功能: 根据 tbl_Volunteer 表中的 TotalVolunteerHours，按照预设规则计算星级。
--           规则 (志愿时长 TotalVolunteerHours):
--             >= 1500 小时 THEN 5 星
--             >= 1000 小时 THEN 4 星
--             >= 600  小时 THEN 3 星
--             >= 300  小时 THEN 2 星
--             >= 100  小时 THEN 1 星
--             < 100  小时 THEN 0 星 (或不返回记录/返回特定值，根据需求调整)
-- 输出列:
--   VolunteerID CHAR(15): 志愿者ID
--   StarRatingValue DECIMAL(3,1): 计算出的星级评分 (例如 0.0 到 5.0)
--------------------------------------------------------------------------------
CREATE VIEW Volunteer_Stars AS
SELECT
    VolunteerID,                     -- 对应 tbl_Volunteer 表中的 VolunteerID
    TotalVolunteerHours,             -- 对应 tbl_Volunteer 表中的 TotalVolunteerHours
    CASE
        WHEN TotalVolunteerHours >= 1500 THEN 5
        WHEN TotalVolunteerHours >= 1000 THEN 4
        WHEN TotalVolunteerHours >= 600  THEN 3
        WHEN TotalVolunteerHours >= 300  THEN 2
        WHEN TotalVolunteerHours >= 100  THEN 1
        ELSE 0
    END AS StarLevel                 -- 视图中计算出的星级列
FROM
    tbl_Volunteer;                   -- 您的志愿者表名

GO





CREATE VIEW dbo.v_VolunteerAuxiliaryRating
AS
SELECT
    VolunteerID,
    CAST( -- 将CASE表达式的结果转换为DECIMAL(3,1)以确保数据类型一致
        CASE
            WHEN TotalVolunteerHours >= 1500 THEN 5.0
            WHEN TotalVolunteerHours >= 1000 THEN 4.0
            WHEN TotalVolunteerHours >= 600  THEN 3.0
            WHEN TotalVolunteerHours >= 300  THEN 2.0
            WHEN TotalVolunteerHours >= 100  THEN 1.0
            ELSE 0.0 -- 如果志愿时长少于100小时，则为0星 (或者可以设为 NULL 或其他基础值)
        END
    AS DECIMAL(3,1)) AS StarRatingValue
FROM
    dbo.tbl_Volunteer;
GO



-- 查询视图示例 (用于验证)
-- SELECT * FROM dbo.v_VolunteerAuxiliaryRating ORDER BY StarRatingValue DESC;