--USE volunteer_db_test; -- 确保在正确的数据库上下文中执行
USE volunteer_web_05;
GO

SET NOCOUNT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    -- 清理旧数据
    PRINT N'--- 开始清理所有相关表中的旧数据 ---';
    -- 按照从依赖到被依赖的顺序删除数据，避免外键约束问题
    DELETE FROM dbo.tbl_Complaint;
    DELETE FROM dbo.tbl_VolunteerActivityParticipation;
    DELETE FROM dbo.tbl_VolunteerTrainingParticipation;
    DELETE FROM dbo.tbl_VolunteerActivityApplication;
    DELETE FROM dbo.tbl_Position;
    DELETE FROM dbo.tbl_ActivityTimeslot;
    DELETE FROM dbo.tbl_VolunteerActivity;
    DELETE FROM dbo.tbl_VolunteerTraining;
    DELETE FROM dbo.tbl_VolunteerOrganizationJoin;
    DELETE FROM dbo.tbl_Organization;
    DELETE FROM dbo.tbl_Volunteer;
    DELETE FROM dbo.tbl_Administrator;
    PRINT N'--- 旧数据清理完毕 ---';

    -- 1. 插入管理员数据
    PRINT N'--- 1. 正在插入管理员数据 ---';
    -- AdminID 由 trg_GenerateAdministratorID 触发器自动生成
    INSERT INTO dbo.tbl_Administrator (Name, Gender, IDCardNumber, PhoneNumber, Password, ServiceArea, CurrentPosition, PermissionLevel) VALUES
    (N'张伟', N'男', '11010119850510351X', '13910856214', 'adminPass1', N'全国', N'系统维护员', N'高'),
    (N'李静', N'女', '310101199008152424', '13818695302', 'adminPass2', N'华东区', N'审核监督员', N'中'),
	(N'金陶然', N'女', '22062320050528004X', '13894037809', '23301153', N'华东区', N'审核监督员', N'中'),
    (N'刘洋', N'男', '440103198812017838', '13715982401', 'adminPass3', N'华南区', N'普通管理员', N'低');

    -- 获取刚刚生成的管理员ID，以便后续关联
    DECLARE @adm_001_id CHAR(15) = (SELECT AdminID FROM dbo.tbl_Administrator WHERE IDCardNumber = '11010119850510351X');
    DECLARE @adm_002_id CHAR(15) = (SELECT AdminID FROM dbo.tbl_Administrator WHERE IDCardNumber = '310101199008152424');
	DECLARE @adm_003_id CHAR(15) = (SELECT AdminID FROM dbo.tbl_Administrator WHERE IDCardNumber = '22062320050528004X');
    DECLARE @adm_004_id CHAR(15) = (SELECT AdminID FROM dbo.tbl_Administrator WHERE IDCardNumber = '440103198812017838');


    -- 2. 插入组织机构数据
    PRINT N'--- 2. 正在插入组织机构数据 ---';
    -- OrgID 由 trg_GenerateOrganizationID 触发器自动生成
    INSERT INTO dbo.tbl_Organization (OrgName, OrgLoginUserName, OrgLoginPassword, ContactPersonPhone, ServiceRegion, OrgScale, OrgAccountStatus, TotalServiceHours, ActivityCount, TrainingCount, OrgRating) VALUES
    (N'晨曦社区服务社', 'chenxishequ', 'orgPassChenxi', '13810294817', N'北京', 0, N'已认证', 1250, 15, 5, 8.5),
    (N'绿芽环保联盟', 'lvyahuanbao', 'orgPassLvya', '13918519374', N'上海', 0, N'已认证', 880, 8, 3, 7.8),
    (N'启航助学基金', 'qihangzhuxue', 'orgPassQihang', '17702076591', N'广东', 0, N'待认证', 0, 0, 0, 1.0),
    (N'蓝天救援预备队', 'lskyrescue', 'orgPassLantian', '13612847590', N'四川', 0, N'冻结', 2500, 25, 10, 9.5),
    (N'夕阳红老年服务中心', 'xiyanghong', 'orgPassXiyang', '13501258493', N'北京', 0, N'认证未通过', 300, 5, 1, 1.0),
	(N'小金刀刀集团志愿服务中心','jintaoran','23301153','13894037809',N'北京',0,N'已认证',300,5,1,1.0),
    (N'文津图书社', 'wenjinshe', 'orgPassWenjin', '18611593857', N'北京', 0, N'已认证', 450, 6, 2, 8.2);

    -- 获取刚刚生成的组织ID，以便后续关联
    DECLARE @org_001_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'晨曦社区服务社');
    DECLARE @org_002_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'绿芽环保联盟');
    DECLARE @org_003_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'启航助学基金');
    DECLARE @org_004_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'蓝天救援预备队');
    DECLARE @org_005_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'夕阳红老年服务中心');
    DECLARE @org_006_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'小金刀刀集团志愿服务中心');
    DECLARE @org_007_id CHAR(15) = (SELECT OrgID FROM dbo.tbl_Organization WHERE OrgName = N'文津图书社');


    -- 3. 插入志愿者数据
    PRINT N'--- 3. 正在插入志愿者数据 ---';
    -- VolunteerID 由 trg_GenerateVolunteerID 触发器自动生成
    -- 确保提供所有 NOT NULL 且没有 DEFAULT 的列，以及需要设置特定值的列
    -- 触发器会为 Country, Ethnicity, PoliticalStatus, HighestEducation, EmploymentStatus, ServiceCategory
    -- 提供默认值或从 inserted 表中读取（如果提供了的话）
    INSERT INTO dbo.tbl_Volunteer (Username, Name, PhoneNumber, IDCardNumber, Password, Gender, ServiceArea, AccountStatus, TotalVolunteerHours, VolunteerRating) VALUES
    (N'wang_wei_v', N'王伟', '13671098821', '110102199503154212', 'volPassWang', N'男', N'北京', N'已实名认证', 120.5, 8.8),
    (N'li_na_sh', N'李娜', '13918273645', '31010419981120172X', 'volPassLi', N'女', N'上海', N'已实名认证', 250.0, 9.2),
    (N'chen_hao_gz', N'陈浩', '13570384421', '440106199307073135', 'volPassChen', N'男', N'广东', N'已实名认证', 55.0, 7.5),
    (N'zhang_min_pending', N'张敏', '18622749158', '120101199901305946', 'volPassZhang', N'女', N'天津', N'未实名认证', 0, 1.0),
    (N'liu_yang_frozen', N'刘洋', '15045098762', '230102199605253859', 'volPassLiu', N'男', N'黑龙江', N'已冻结', 30.0, 6.0),
    (N'wu_jing_failed', N'吴静', '13388514936', '510107199709182763', 'volPassWu', N'女', N'四川', N'认证未通过', 0, 1.0),
    (N'zhao_lei_conflict', N'赵磊', '13901287654', '110108199402116178', 'volPassZhao', N'男', N'北京', N'已实名认证', 80.0, 8.0),
    (N'qian_sun_new', N'孙倩', '18516982475', '310115199704223129', 'volPassSun', N'女', N'上海', N'已实名认证', 15.0, 6.5),
    (N'li_qiang_member', N'李强', '13764218903', '310107199210051211', 'volPassLiQ', N'男', N'上海', N'已实名认证', 310.0, 8.9),
    (N'zhou_fang_member', N'周芳', '13621859941', '31010519930614532X', 'volPassZhou', N'女', N'上海', N'已实名认证', 180.0, 8.2),
    (N'wu_lei_new_app', N'吴磊', '13916337582', '310110199508284618', 'volPassWuL', N'男', N'上海', N'已实名认证', 25.5, 7.0),
    (N'zhao_qian_new', N'赵倩', '18601214358', '110105199803082221', 'volPassZhaoQ', N'女', N'北京', N'未实名认证', 0, 1.0),
	(N'jtr_02', N'金陶然', '13894037809', '22062320050528004X', '23301153', N'女', N'北京', N'已实名认证', 0, 1.0);

    -- 获取刚刚生成的志愿者ID，以便后续关联
    DECLARE @vol_001_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'wang_wei_v');
    DECLARE @vol_002_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'li_na_sh');
    DECLARE @vol_003_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'chen_hao_gz');
    DECLARE @vol_004_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'zhang_min_pending');
    DECLARE @vol_005_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'liu_yang_frozen');
    DECLARE @vol_006_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'wu_jing_failed');
    DECLARE @vol_007_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'zhao_lei_conflict');
    DECLARE @vol_008_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'qian_sun_new');
    DECLARE @vol_009_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'li_qiang_member');
    DECLARE @vol_010_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'zhou_fang_member');
    DECLARE @vol_011_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'wu_lei_new_app');
    DECLARE @vol_012_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'zhao_qian_new');
	DECLARE @vol_013_id CHAR(15) = (SELECT VolunteerID FROM dbo.tbl_Volunteer WHERE Username = N'jtr_02');


    -- 4. 插入志愿者与组织关系数据 (丰富成员)
    PRINT N'--- 4. 正在插入丰富的成员关系数据 ---';
    INSERT INTO dbo.tbl_VolunteerOrganizationJoin (VolunteerID, OrgID, JoinTime, MemberStatus) VALUES
    (@vol_001_id, @org_001_id, DATEADD(year, -1, GETDATE()), N'已加入'),
    (@vol_007_id, @org_001_id, DATEADD(month, -8, GETDATE()), N'已加入'),
    (@vol_012_id, @org_001_id, DATEADD(day, -5, GETDATE()), N'申请中'),
    (@vol_002_id, @org_002_id, DATEADD(month, -6, GETDATE()), N'已加入'),
    (@vol_009_id, @org_002_id, DATEADD(month, -5, GETDATE()), N'已加入'),
    (@vol_010_id, @org_002_id, DATEADD(month, -4, GETDATE()), N'已加入'),
    (@vol_011_id, @org_002_id, DATEADD(day, -20, GETDATE()), N'申请中'),
    (@vol_003_id, @org_006_id, DATEADD(day, -1, GETDATE()), N'申请中');

    -- 执行触发器，更新初始OrgScale (如果存在相关触发器的话)
    -- 注意: 如果 OrgScale 是由 tbl_VolunteerOrganizationJoin 上的触发器更新的，
    -- 那么 UPDATE dbo.tbl_VolunteerOrganizationJoin SET JoinTime = JoinTime;
    -- 这样的语句可以触发更新。
    PRINT N'--- 执行触发器以更新初始组织规模 ---';
    UPDATE dbo.tbl_VolunteerOrganizationJoin SET JoinTime = JoinTime WHERE OrgID IN (@org_001_id, @org_002_id);


    -- 5. 插入活动、培训、岗位、时段数据 (丰富内容)
    PRINT N'--- 5. 正在插入丰富的活动、培训、岗位、时段数据 ---';
    
    -- 为活动定义名称，以便之后查询其自动生成的 ID
    DECLARE @act_001_name NVARCHAR(200) = N'周末爱心书屋辅导';
    DECLARE @act_002_name NVARCHAR(200) = N'城市公园垃圾清理';
    DECLARE @act_003_name NVARCHAR(200) = N'社区嘉年华协助';
    DECLARE @act_004_name NVARCHAR(200) = N'湿地生态调研';
    DECLARE @act_cfl_005_name NVARCHAR(200) = N'时间冲突测试活动';
    DECLARE @act_rate_test_name NVARCHAR(200) = N'评价窗口期测试活动';

    -- 插入活动，ActivityID 由 trg_GenerateActivityID 触发器自动生成
    -- ReviewerAdminID 可以在这里指定，或者在触发器中设置为 NULL
    INSERT INTO dbo.tbl_VolunteerActivity (OrgID, ActivityName, StartTime, EndTime, Location, RecruitmentCount, ActivityStatus, ContactPersonPhone, ActivityDurationHours, ReviewerAdminID) VALUES
    (@org_001_id, @act_001_name, '2025-05-10 09:00:00', '2025-05-11 17:00:00', N'晨曦社区书屋', 10, N'已结束', '13810294817', 16, @adm_001_id),
    (@org_002_id, @act_002_name, DATEADD(hour, -2, GETDATE()), DATEADD(hour, 2, GETDATE()), N'世纪公园', 20, N'进行中', '13918519374', 4, @adm_002_id),
    (@org_001_id, @act_003_name, DATEADD(day, 10, GETDATE()), DATEADD(day, 10, DATEADD(hour, 8, GETDATE())), N'晨曦社区广场', 30, N'审核通过', '13810294817', 8, @adm_001_id),
    (@org_002_id, @act_004_name, DATEADD(day, 20, GETDATE()), DATEADD(day, 21, GETDATE()), N'东滩湿地公园', 15, N'待审核', '13918519374', NULL, NULL), -- ActivityDurationHours 可空
    (@org_002_id, @act_cfl_005_name, DATEADD(day, 15, GETDATE()), DATEADD(day, 15, DATEADD(hour, 4, GETDATE())), N'科技馆', 10, N'审核通过', '13918519374', NULL, @adm_002_id),
    (@org_001_id, @act_rate_test_name, DATEADD(day, -4, GETDATE()), DATEADD(day, -3, GETDATE()), N'市图书馆', 10, N'已结束', '13810294817', 6, @adm_001_id);

    -- 获取刚刚生成的活动ID，以便插入 Position 和 Timeslot
    DECLARE @act_001_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_001_name AND OrgID = @org_001_id);
    DECLARE @act_002_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_002_name AND OrgID = @org_002_id);
    DECLARE @act_003_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_003_name AND OrgID = @org_001_id);
    DECLARE @act_004_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_004_name AND OrgID = @org_002_id);
    DECLARE @act_cfl_005_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_cfl_005_name AND OrgID = @org_002_id);
    DECLARE @act_rate_test_id CHAR(15) = (SELECT ActivityID FROM dbo.tbl_VolunteerActivity WHERE ActivityName = @act_rate_test_name AND OrgID = @org_001_id);

    -- 插入岗位，PositionID 由 trg_GeneratePositionID 触发器自动生成
    INSERT INTO dbo.tbl_Position(PositionName, ActivityID, PositionServiceHours, RequiredVolunteers) VALUES
    (N'故事讲解员(周六)', @act_001_id, 8, 5),
    (N'故事讲解员(周日)', @act_001_id, 8, 5),
    (N'垃圾分类督导', @act_002_id, 4, 10),
    (N'环保宣传员', @act_002_id, 4, 10),
    (N'游戏摊位协助', @act_003_id, 8, 15),
    (N'秩序维护', @act_003_id, 8, 15),
    (N'冲突活动岗位', @act_cfl_005_id, 4, 10),
    (N'图书整理员', @act_rate_test_id, 6, 10);

    -- 获取刚刚生成的 PositionID，以便插入参与记录和报名记录
    DECLARE @pos_001a_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_001_id AND PositionName = N'故事讲解员(周六)');
    DECLARE @pos_001b_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_001_id AND PositionName = N'故事讲解员(周日)');
    DECLARE @pos_002a_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_002_id AND PositionName = N'垃圾分类督导');
    DECLARE @pos_002b_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_002_id AND PositionName = N'环保宣传员');
    DECLARE @pos_003a_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_003_id AND PositionName = N'游戏摊位协助');
    DECLARE @pos_003b_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_003_id AND PositionName = N'秩序维护');
    DECLARE @pos_cfl_001_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_cfl_005_id AND PositionName = N'冲突活动岗位');
    DECLARE @pos_rate_test_id CHAR(15) = (SELECT PositionID FROM dbo.tbl_Position WHERE ActivityID = @act_rate_test_id AND PositionName = N'图书整理员');

    -- 插入活动时段，TimeslotID 由 trg_GenerateTimeslotID 触发器自动生成
    INSERT INTO dbo.tbl_ActivityTimeslot(EventID, StartTime, EndTime) VALUES
    (@act_001_id, '2025-05-10 09:00:00', '2025-05-10 17:00:00'),
    (@act_001_id, '2025-05-11 09:00:00', '2025-05-11 17:00:00'),
    (@act_002_id, DATEADD(hour, -2, GETDATE()), DATEADD(hour, 2, GETDATE())),
    (@act_003_id, DATEADD(day, 10, GETDATE()), DATEADD(day, 10, DATEADD(hour, 8, GETDATE()))),
    (@act_004_id, DATEADD(day, 20, GETDATE()), DATEADD(day, 21, GETDATE())),
    (@act_cfl_005_id, DATEADD(day, 15, GETDATE()), DATEADD(day, 15, DATEADD(hour, 4, GETDATE())));


    -- 为培训定义名称，以便之后查询其自动生成的 ID
    DECLARE @trn_001_name NVARCHAR(200) = N'基础急救知识培训';
    DECLARE @trn_cfl_002_name NVARCHAR(200) = N'时间冲突测试培训';

	-- 插入培训，TrainingID 由 trg_GenerateTrainingID 触发器自动生成
    INSERT INTO dbo.tbl_VolunteerTraining(OrgID, TrainingName, Theme, StartTime, EndTime, Location, RecruitmentCount, TrainingStatus, ContactPersonPhone, ReviewerAdminID) VALUES
    (@org_001_id, @trn_001_name, N'应急救护', '2025-04-20 09:00:00', '2025-04-20 13:00:00', N'社区活动中心', 30, N'已结束', '13810294817', @adm_001_id),
    (@org_001_id, @trn_cfl_002_name, N'沟通技巧', DATEADD(day, 15, DATEADD(hour, 1, GETDATE())), DATEADD(day, 15, DATEADD(hour, 3, GETDATE())), N'总部会议室', 20, N'审核通过', '13810294817', @adm_001_id);

    -- 获取刚刚生成的培训ID，以便插入参与记录和时段
    DECLARE @trn_001_id CHAR(15) = (SELECT TrainingID FROM dbo.tbl_VolunteerTraining WHERE TrainingName = @trn_001_name AND OrgID = @org_001_id);
    DECLARE @trn_cfl_002_id CHAR(15) = (SELECT TrainingID FROM dbo.tbl_VolunteerTraining WHERE TrainingName = @trn_cfl_002_name AND OrgID = @org_001_id);

    -- 插入培训时段，TimeslotID 由 trg_GenerateTimeslotID 触发器自动生成
    INSERT INTO dbo.tbl_ActivityTimeslot(EventID, StartTime, EndTime) VALUES
    (@trn_001_id, '2025-04-20 09:00:00', '2025-04-20 13:00:00'),
    (@trn_cfl_002_id, DATEADD(day, 15, DATEADD(hour, 1, GETDATE())), DATEADD(day, 15, DATEADD(hour, 3, GETDATE())));


    -- 6. 插入报名和参与数据
    PRINT N'--- 6. 正在插入丰富的报名和参与数据 ---';
    -- 活动参与记录
    INSERT INTO dbo.tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating) VALUES
    (@vol_001_id, @act_001_id, @pos_001a_id, N'是', 8, 9),
    (@vol_007_id, @act_001_id, @pos_001b_id, N'是', 9, 9),
    (@vol_002_id, @act_002_id, @pos_002a_id, N'否', NULL, NULL), -- 进行中活动，尚未签到或评分
    (@vol_009_id, @act_002_id, @pos_002b_id, N'否', NULL, NULL), -- 进行中活动，尚未签到或评分
    (@vol_007_id, @act_cfl_005_id, @pos_cfl_001_id, N'否', NULL, NULL), -- 将来活动，尚未签到或评分
    (@vol_001_id, @act_rate_test_id, @pos_rate_test_id, N'是', NULL, NULL); -- 已结束活动，但未评价

    -- 报名记录
    -- ApplicationID 由 trg_InsteadInsert_Application 触发器自动生成
    INSERT INTO dbo.tbl_VolunteerActivityApplication(VolunteerID, ActivityID, IntendedPositionID, ApplicationStatus) VALUES
    (@vol_001_id, @act_003_id, @pos_003a_id, N'待审核'),
    (@vol_008_id, @act_003_id, @pos_003a_id, N'待审核'),
    (@vol_007_id, @act_003_id, @pos_003b_id, N'已通过');

    -- 培训参与记录
    INSERT INTO dbo.tbl_VolunteerTrainingParticipation(VolunteerID, TrainingID, IsCheckedIn, VolunteerToOrgRating, OrgToVolunteerRating) VALUES
    (@vol_001_id, @trn_001_id, N'是', 9, 8),
    (@vol_002_id, @trn_001_id, N'是', 8, 8),
    (@vol_007_id, @trn_001_id, N'是', 10, 9);

    -- 7. 插入投诉数据
    PRINT N'--- 7. 正在插入投诉数据 ---';
    -- ComplaintID 由 trg_GenerateComplaintID 触发器自动生成
    -- ComplainantID 和 ComplaintTargetID 没有外键约束，需要提供带前缀的 ID
    INSERT INTO dbo.tbl_Complaint (ComplainantID, ComplaintTargetID, ComplaintType, ComplaintContent, ProcessingStatus, VisitResult) VALUES
    (@vol_002_id, @org_001_id, N'活动违规', N'活动`' + @act_001_id + '`的实际服务时长与宣传不符。', N'未处理', N'满意'),
    (@vol_001_id, @vol_003_id, N'行为不当', N'志愿者' + N'陈浩' + '在活动中言语不当。', N'已应诉', N'不满意');


    -- 重新计算并更新所有活动、岗位的录取人数等 (如果有 AFTER 触发器，这些更新操作会触发它们)
    PRINT N'--- 触发器数据同步：正在更新所有活动和岗位的统计数据 ---';
    -- 强制触发 UPDATE 触发器，以同步相关统计数据（例如 AcceptedCount, RecruitedVolunteers等）
    -- 这是一个常见的技巧，用于在批量插入后触发依赖于 UPDATE 事件的聚合逻辑。
    -- 如果有更精细的聚合存储过程或函数，则应调用它们。
    UPDATE dbo.tbl_VolunteerActivity SET ActivityName = ActivityName WHERE ActivityID IN (@act_001_id, @act_002_id, @act_003_id, @act_cfl_005_id, @act_rate_test_id);
    UPDATE dbo.tbl_VolunteerActivityApplication SET ApplicationStatus = ApplicationStatus WHERE ActivityID IN (@act_003_id);
    UPDATE dbo.tbl_VolunteerActivityParticipation SET IsCheckedIn = IsCheckedIn WHERE ActivityID IN (@act_001_id, @act_002_id, @act_cfl_005_id, @act_rate_test_id);
    UPDATE dbo.tbl_VolunteerTrainingParticipation SET IsCheckedIn = IsCheckedIn WHERE TrainingID IN (@trn_001_id, @trn_cfl_002_id);
    
    COMMIT TRANSACTION;
    PRINT N'--- 所有初始数据插入完毕 ---';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorProcedure NVARCHAR(200) = ISNULL(ERROR_PROCEDURE(), '-');

    PRINT N'--- 数据插入失败，事务已回滚 ---';
    RAISERROR ('错误发生在过程 %s 的第 %d 行: %s', @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);
END CATCH;
GO