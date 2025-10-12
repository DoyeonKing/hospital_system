--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

PRINT N'--- 开始测试ID自动生成触发器 ---';
GO

-- 清理可能存在的旧测试数据 (如果脚本可重复执行)
DELETE FROM dbo.tbl_Volunteer WHERE Username LIKE 'test_vol_trigger%';
DELETE FROM dbo.tbl_Organization WHERE OrgLoginUserName LIKE 'test_org_trigger%';
DELETE FROM dbo.tbl_Administrator WHERE Name LIKE '测试管理员Trigger%';
GO

--------------------------------------------------------------------------------
-- 测试 trg_GenerateVolunteerID
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_GenerateVolunteerID ---';

-- 测试1.1: 单行插入志愿者 (不提供VolunteerID)
PRINT N'测试1.1: 单行插入志愿者';
INSERT INTO dbo.tbl_Volunteer (
    Username, Name, PhoneNumber, IDCardNumber, Password, Gender, ServiceArea 
    -- VolunteerID 将由触发器生成
    -- Country, Ethnicity, PoliticalStatus, AccountStatus 将使用触发器中处理的默认值
    -- TotalVolunteerHours, VolunteerRating 将使用触发器中处理的默认值
) VALUES (
    N'test_vol_trigger1', N'测试志愿者1号', '13000000001', '110101200101010011', 'pass1', N'男', N'北京'
);
GO
DECLARE @GeneratedVolID1 CHAR(15);
SELECT TOP 1 @GeneratedVolID1 = VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'test_vol_trigger1' ORDER BY VolunteerID DESC; -- 获取最新生成的ID
PRINT N'生成的志愿者ID 1: ' + ISNULL(@GeneratedVolID1, '未找到或生成失败');
SELECT * FROM dbo.tbl_Volunteer WHERE VolunteerID = @GeneratedVolID1;
GO

-- 测试1.2: 再次单行插入志愿者，验证ID序列递增
PRINT N'测试1.2: 再次单行插入志愿者以验证序列';
INSERT INTO dbo.tbl_Volunteer (
    Username, Name, PhoneNumber, IDCardNumber, Password, Gender, ServiceArea, AccountStatus
) VALUES (
    N'test_vol_trigger2', N'测试志愿者2号', '13000000002', '110101200202020022', 'pass2', N'女', N'上海', N'已实名认证'
);
GO
DECLARE @GeneratedVolID2 CHAR(15);
SELECT TOP 1 @GeneratedVolID2 = VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'test_vol_trigger2' ORDER BY VolunteerID DESC;
PRINT N'生成的志愿者ID 2: ' + ISNULL(@GeneratedVolID2, '未找到或生成失败');
SELECT * FROM dbo.tbl_Volunteer WHERE VolunteerID = @GeneratedVolID2;
GO
-- 验证ID格式和序列 (目视检查 @GeneratedVolID1 和 @GeneratedVolID2)
-- @GeneratedVolID2 的数字部分应该比 @GeneratedVolID1 大1

-- 测试1.3: 多行插入志愿者
PRINT N'测试1.3: 多行插入志愿者';
INSERT INTO dbo.tbl_Volunteer (Username, Name, PhoneNumber, IDCardNumber, Password, Gender, ServiceArea)
VALUES
(N'test_vol_trigger3', N'测试志愿者3号', '13000000003', '110101200303030033', 'pass3', N'男', N'广东'),
(N'test_vol_trigger4', N'测试志愿者4号', '13000000004', '110101200404040044', 'pass4', N'女', N'江苏');
GO
PRINT N'多行插入后生成的志愿者信息:';
SELECT * FROM dbo.tbl_Volunteer WHERE Username LIKE 'test_vol_trigger[34]';
GO -- ID应唯一且符合格式

--------------------------------------------------------------------------------
-- 测试 trg_GenerateOrganizationID
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_GenerateOrganizationID ---';
-- 测试2.1: 单行插入组织
PRINT N'测试2.1: 单行插入组织';
INSERT INTO dbo.tbl_Organization (
    OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone, ServiceRegion, OrgScale
    -- OrgID, OrgRating, OrgAccountStatus, TotalServiceHours, ActivityCount, TrainingCount 由触发器或默认值处理
) VALUES (
    N'测试触发器组织A', N'test_org_triggerA', 'orgPassA', '13100000011', N'北京', 50
);
GO
DECLARE @GeneratedOrgID1 CHAR(15);
SELECT TOP 1 @GeneratedOrgID1 = OrgID FROM dbo.tbl_Organization WHERE OrgLoginUserName = N'test_org_triggerA' ORDER BY OrgID DESC;
PRINT N'生成的组织ID 1: ' + ISNULL(@GeneratedOrgID1, '未找到或生成失败');
SELECT * FROM dbo.tbl_Organization WHERE OrgID = @GeneratedOrgID1;
GO

-- 测试2.2: 多行插入组织
PRINT N'测试2.2: 多行插入组织';
INSERT INTO dbo.tbl_Organization (OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone, ServiceRegion, OrgScale)
VALUES
(N'测试触发器组织B', N'test_org_triggerB', 'orgPassB', '13100000012', N'上海', 30),
(N'测试触发器组织C', N'test_org_triggerC', 'orgPassC', '13100000013', N'广东', 70);
GO
PRINT N'多行插入后生成的组织信息:';
SELECT * FROM dbo.tbl_Organization WHERE OrgLoginUserName LIKE 'test_org_trigger[BC]';
GO

--------------------------------------------------------------------------------
-- 测试 trg_GenerateAdministratorID
--------------------------------------------------------------------------------
PRINT N'--- 测试 trg_GenerateAdministratorID ---';
-- 测试3.1: 单行插入管理员
PRINT N'测试3.1: 单行插入管理员';
INSERT INTO dbo.tbl_Administrator (
    Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, PermissionLevel
    -- AdminID, CurrentPosition 由触发器或默认值处理
) VALUES (
    N'测试管理员TriggerX', N'男', '12010119900101001X', '13200000021', 'adminPassX', N'全国', N'高'
);
GO
DECLARE @GeneratedAdminID1 CHAR(15);
SELECT TOP 1 @GeneratedAdminID1 = AdminID FROM dbo.tbl_Administrator WHERE Name = N'测试管理员TriggerX' ORDER BY AdminID DESC;
PRINT N'生成的管理员ID 1: ' + ISNULL(@GeneratedAdminID1, '未找到或生成失败');
SELECT * FROM dbo.tbl_Administrator WHERE AdminID = @GeneratedAdminID1;
GO

-- 测试3.2: 多行插入管理员
PRINT N'测试3.2: 多行插入管理员';
INSERT INTO dbo.tbl_Administrator (Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, PermissionLevel, CurrentPosition)
VALUES
(N'测试管理员TriggerY', N'女', '12010119910202002Y', '13200000022', 'adminPassY', N'上海市', N'中', N'审核监督员'),
(N'测试管理员TriggerZ', N'男', '12010119920303003Z', '13200000023', 'adminPassZ', N'广州市', N'低', N'普通管理员');
GO
PRINT N'多行插入后生成的管理员信息:';
SELECT * FROM dbo.tbl_Administrator WHERE Name LIKE '测试管理员Trigger[YZ]';
GO

PRINT N'--- ID自动生成触发器测试结束 ---';
GO

-- 最终清理测试数据 (可选)
/*
DELETE FROM dbo.tbl_Volunteer WHERE Username LIKE 'test_vol_trigger%';
DELETE FROM dbo.tbl_Organization WHERE OrgLoginUserName LIKE 'test_org_trigger%';
DELETE FROM dbo.tbl_Administrator WHERE Name LIKE '测试管理员Trigger%';
PRINT N'测试数据已清理。';
*/