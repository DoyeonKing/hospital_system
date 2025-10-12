USE volunteer_db_test;
GO

PRINT N'--- 开始测试志愿者相关存储过程 ---';
GO

--------------------------------------------------------------------------------
-- 测试 sp_RegisterVolunteer (志愿者注册)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_RegisterVolunteer ---';
-- 1.1 注册一个新志愿者 (成功)
PRINT N'尝试注册新志愿者 "vol_test_005":';
EXEC dbo.sp_RegisterVolunteer
    @VolunteerID = 'vol_test_005',
    @Username = N'new_volunteer_user',
    @Password = N'volTestPass123',
    @Name = N'刘新宇',
    @PhoneNumber = '13456789012',
    @IDCardNumber = '330101199801010055',
    @Gender = N'男',
    @ServiceArea = N'浙江',
    @AccountStatus = N'未实名认证';
GO
-- 期望：返回 0。
-- 验证：
SELECT * FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_test_005';
GO

-- 1.2 尝试注册一个已存在的用户名 (失败)
PRINT N'尝试注册已存在的用户名 "zhang_wei_01":';
EXEC dbo.sp_RegisterVolunteer
    @VolunteerID = 'vol_test_006',
    @Username = N'zhang_wei_01', -- 这个用户名已在初始数据中存在
    @Password = N'anyPass',
    @Name = N'测试重名',
    @PhoneNumber = '13123456789',
    @IDCardNumber = '340101199001010066',
    @Gender = N'女',
    @ServiceArea = N'安徽';
GO
-- 期望：返回 -1，并提示用户名已存在。

-- 1.3 尝试注册一个已存在的手机号 (失败)
PRINT N'尝试注册已存在的手机号 "13671098821":';
EXEC dbo.sp_RegisterVolunteer
    @VolunteerID = 'vol_test_007',
    @Username = N'another_new_user',
    @Password = N'anyPass',
    @Name = N'测试重手机',
    @PhoneNumber = '13671098821', -- 这个手机号已在初始数据中存在 (vol_001)
    @IDCardNumber = '350101199101010077',
    @Gender = N'男',
    @ServiceArea = N'福建';
GO
-- 期望：返回 -2，并提示手机号已存在。

--------------------------------------------------------------------------------
-- 测试 sp_VolunteerLogin (志愿者登录)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_VolunteerLogin ---';
-- 2.1 成功登录
PRINT N'尝试志愿者 "zhang_wei_01" 使用正确密码 "volPassZhang" 登录:';
EXEC dbo.sp_VolunteerLogin @Username = N'zhang_wei_01', @Password = N'volPassZhang';
GO
-- 期望：返回 0，并显示志愿者信息。

-- 2.2 用户名不存在
PRINT N'尝试使用不存在的用户名 "non_exist_volunteer" 登录:';
EXEC dbo.sp_VolunteerLogin @Username = N'non_exist_volunteer', @Password = N'anyPass';
GO
-- 期望：返回 -1。

-- 2.3 密码错误
PRINT N'尝试志愿者 "zhang_wei_01" 使用错误密码 "wrongPass" 登录:';
EXEC dbo.sp_VolunteerLogin @Username = N'zhang_wei_01', @Password = N'wrongPass';
GO
-- 期望：返回 -2。

-- 2.4 账户被冻结 (假设 vol_003 后续被管理员冻结)
-- 首先，模拟管理员冻结一个账户 (需要先执行管理员审核存储过程)
 EXEC dbo.sp_ReviewVolunteerIdentity @ReviewingAdminID = 'adm_001', @VolunteerID = 'vol_003', @NewAccountStatus = N'已冻结';
 PRINT N'尝试登录已被冻结的志愿者 "wang_feng_gz" (vol_003):';
 EXEC dbo.sp_VolunteerLogin @Username = N'wang_feng_gz', @Password = N'volPassWang';
 GO
-- 期望：返回 -3。 (执行此测试前需确保 vol_003 状态为 '已冻结')

--------------------------------------------------------------------------------
-- 测试 sp_UpdateVolunteerProfile (志愿者更新个人信息)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_UpdateVolunteerProfile ---';
-- 查看 vol_002 更新前的信息
PRINT N'志愿者 "vol_002" (李娜) 更新前信息:';
SELECT VolunteerID, Name, PhoneNumber, ServiceArea, ServiceCategory FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_002';
GO

-- 3.1 更新部分信息
PRINT N'更新志愿者 "vol_002" 的服务区域和服务类别:';
EXEC dbo.sp_UpdateVolunteerProfile
    @VolunteerID = 'vol_002',
    @ServiceArea = N'江苏',
    @ServiceCategory = N'社区志愿者';
GO
-- 期望：返回 0。
PRINT N'志愿者 "vol_002" 更新后信息:';
SELECT VolunteerID, Name, PhoneNumber, ServiceArea, ServiceCategory FROM dbo.tbl_Volunteer WHERE VolunteerID = 'vol_002';
GO

-- 3.2 尝试更新手机号为一个已存在的号码 (失败)
PRINT N'志愿者 "vol_002" 尝试将其手机号更新为 "vol_001" 的手机号 "13671098821":';
EXEC dbo.sp_UpdateVolunteerProfile
    @VolunteerID = 'vol_002',
    @PhoneNumber = '13671098821';
GO
-- 期望：返回 -2。

-- 3.3 更新不存在的志愿者
PRINT N'尝试更新不存在的志愿者 "vol_999":';
EXEC dbo.sp_UpdateVolunteerProfile @VolunteerID = 'vol_999', @Name = N'不存在的人';
GO
-- 期望：返回 -1。

--------------------------------------------------------------------------------
-- 测试 sp_ChangeVolunteerPassword (志愿者修改自己的登录密码)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ChangeVolunteerPassword ---';
-- 4.1 修改密码成功 (vol_002, 初始密码 volPassLi)
PRINT N'志愿者 "vol_002" 尝试修改密码:';
EXEC dbo.sp_ChangeVolunteerPassword @VolunteerID = 'vol_002', @OldPassword = 'volPassLi', @NewPassword = 'newVolPass456';
GO
-- 期望：返回 0。
-- 验证：
PRINT N'验证志愿者 "vol_002" 新密码登录:';
EXEC dbo.sp_VolunteerLogin @Username = N'li_na_sh', @Password = N'newVolPass456';
GO

--------------------------------------------------------------------------------
-- 测试 sp_VolunteerApplyToJoinOrganization (志愿者申请加入组织)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_VolunteerApplyToJoinOrganization ---';
-- 5.1 志愿者 vol_002 申请加入组织 org_003 (成功)
PRINT N'志愿者 "vol_002" 申请加入组织 "org_003":';
EXEC dbo.sp_VolunteerApplyToJoinOrganization @VolunteerID = 'vol_002', @OrgID = 'org_003';
GO
-- 期望：返回 0。
-- 验证：
SELECT * FROM dbo.tbl_VolunteerOrganizationJoin WHERE VolunteerID = 'vol_002' AND OrgID = 'org_003';
GO

-- 5.2 志愿者 vol_001 尝试再次申请加入已加入的组织 org_001 (提示已申请/加入)
PRINT N'志愿者 "vol_001" 再次申请加入已加入的组织 "org_001":';
EXEC dbo.sp_VolunteerApplyToJoinOrganization @VolunteerID = 'vol_001', @OrgID = 'org_001';
GO
-- 期望：返回 1 (或RAISERROR级别10的消息)。

--------------------------------------------------------------------------------
-- 测试 sp_ApplyForVolunteerActivity (志愿者报名参加志愿活动)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_ApplyForVolunteerActivity ---';
-- 6.1 志愿者 vol_003 报名活动 act_002 (城市公园垃圾清理)，意向岗位 pos_004 (宣传引导员)
-- (假设 act_002 状态为 '审核通过' 或 '进行中')
PRINT N'志愿者 "vol_003" 报名活动 "act_002"，意向岗位 "pos_004":';
EXEC dbo.sp_ApplyForVolunteerActivity
    @ApplicationID = 'app_test_010', -- 新的唯一报名ID
    @VolunteerID = 'vol_003',
    @ActivityID = 'act_002',
    @IntendedPositionID = 'pos_004';
GO
-- 期望：返回 0。
-- 验证：
SELECT * FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_test_010';
GO

-- 6.2 志愿者 vol_001 尝试再次报名已申请过的活动 act_002 (提示已报名)
PRINT N'志愿者 "vol_001" 再次报名活动 "act_002":';
EXEC dbo.sp_ApplyForVolunteerActivity
    @ApplicationID = 'app_test_011',
    @VolunteerID = 'vol_001',
    @ActivityID = 'act_002',
    @IntendedPositionID = NULL;
GO
-- 期望：返回 1 (或RAISERROR级别10的消息)。(因为初始数据中 vol_001 已有对 act_002 的申请 app_004)

-- 6.3 尝试报名一个状态为 '已结束' 的活动 (失败)
-- 活动 act_004 状态为 '已结束'
PRINT N'志愿者 "vol_002" 尝试报名已结束的活动 "act_004":';
EXEC dbo.sp_ApplyForVolunteerActivity
    @ApplicationID = 'app_test_012',
    @VolunteerID = 'vol_002',
    @ActivityID = 'act_004',
    @IntendedPositionID = 'pos_005';
GO
-- 期望：返回 -4。

--------------------------------------------------------------------------------
-- 测试 sp_WithdrawActivityApplication (志愿者取消活动报名)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_WithdrawActivityApplication ---';
-- 假设 vol_003 对 act_001 的报名 app_007 状态为 '待审核'
PRINT N'查看报名 "app_007" (vol_003 对 act_001) 状态 (取消前):';
SELECT ApplicationID, ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007';
GO

-- 7.1 志愿者 vol_003 取消报名 app_007 (成功)
PRINT N'志愿者 "vol_003" 取消报名 "app_007":';
EXEC dbo.sp_WithdrawActivityApplication @VolunteerID = 'vol_003', @ApplicationID = 'app_007';
GO
-- 期望：返回 0。
PRINT N'查看报名 "app_007" 状态 (取消后):';
SELECT ApplicationID, ApplicationStatus FROM dbo.tbl_VolunteerActivityApplication WHERE ApplicationID = 'app_007';
GO

-- 7.2 尝试取消一个已通过且活动即将开始的报名 (根据您的SP逻辑，目前只允许取消'待审核')
-- 假设 app_001 (vol_001 对 act_001) 状态为 '已通过'
-- 如果您的SP只允许取消'待审核'，则此测试会失败
PRINT N'志愿者 "vol_001" 尝试取消已通过的报名 "app_001":';
EXEC dbo.sp_WithdrawActivityApplication @VolunteerID = 'vol_001', @ApplicationID = 'app_001';
GO
-- 期望：返回 -3 (如果SP只允许取消'待审核')。

--------------------------------------------------------------------------------
-- 测试 sp_VolunteerCheckInActivity (志愿者活动签到)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_VolunteerCheckInActivity ---';
-- 假设 vol_001 在 act_001 的 pos_001 岗位参与记录存在且 IsCheckedIn = '否'
-- (初始数据中 vol_001, act_001, pos_001 的 IsCheckedIn 是 '是'，我们先找一个未签到的或手动改一个)
-- 为了测试，我们假设 vol_002 在 act_001 的 pos_001 岗位，初始 IsCheckedIn 是 '是'，我们将其改为 '否'
UPDATE tbl_VolunteerActivityParticipation SET IsCheckedIn = N'否' WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
PRINT N'志愿者 "vol_002" 在活动 "act_001" 岗位 "pos_001" 签到前状态:';
SELECT IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_002' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
GO

-- 8.1 签到成功 (需要一个真实的未签到参与记录)
-- 假设 vol_004 参与 act_001 的 pos_002，且报名已通过，参与记录已生成，IsCheckedIn = '否'
-- (基于初始数据，app_003 是 vol_004 对 act_001 岗位 pos_002 的申请，状态是'已通过')
-- (基于初始数据，tbl_VolunteerActivityParticipation 中 vol_004, act_001, pos_002 参与记录的 IsCheckedIn 是 '是')
-- 为确保测试，我们手动插入一条未签到的参与记录或修改现有记录
-- 假设我们用 vol_004 参与 act_001 的 pos_002，并确保其 IsCheckedIn = '否'
IF EXISTS (SELECT 1 FROM tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_004' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_002')
    UPDATE tbl_VolunteerActivityParticipation SET IsCheckedIn = N'否' WHERE VolunteerID = 'vol_004' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_002';
ELSE
    INSERT INTO tbl_VolunteerActivityParticipation (VolunteerID, ActivityID, ActualPositionID, IsCheckedIn) VALUES ('vol_004', 'act_001', 'pos_002', N'否');
GO
PRINT N'志愿者 "vol_004" 在活动 "act_001" 岗位 "pos_002" 签到前状态:';
SELECT IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_004' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_002';
GO
PRINT N'志愿者 "vol_004" 尝试在活动 "act_001" 岗位 "pos_002" 签到:';
EXEC dbo.sp_VolunteerCheckInActivity @VolunteerID = 'vol_004', @ActivityID = 'act_001', @ActualPositionID = 'pos_002';
GO
-- 期望：返回 0。
PRINT N'志愿者 "vol_004" 在活动 "act_001" 岗位 "pos_002" 签到后状态:';
SELECT IsCheckedIn FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_004' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_002';
GO

-- 8.2 尝试重复签到 (失败)
PRINT N'志愿者 "vol_001" 尝试在活动 "act_001" 岗位 "pos_001" 重复签到:';
EXEC dbo.sp_VolunteerCheckInActivity @VolunteerID = 'vol_001', @ActivityID = 'act_001', @ActualPositionID = 'pos_001';
GO
-- 期望：返回 1 (或RAISERROR级别10的消息)。

-- 8.3 尝试为已结束的活动签到 (失败)
-- 活动 act_004 状态为 '已结束'
PRINT N'志愿者 "vol_001" 尝试为已结束的活动 "act_004" 签到:';
EXEC dbo.sp_VolunteerCheckInActivity @VolunteerID = 'vol_001', @ActivityID = 'act_004', @ActualPositionID = 'pos_005';
GO
-- 期望：返回 -2。

--------------------------------------------------------------------------------
-- 测试 sp_VolunteerRateOrganizationAfterActivity (志愿者对活动/组织评分)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_VolunteerRateOrganizationAfterActivity ---';

-- 准备：确认活动 act_004 已结束，志愿者 vol_004 参与了 pos_005
-- 初始数据中：
-- 活动 'act_004' ('长者智能手机教学') 状态为 '已结束', EndTime 为 '2025-05-10 12:00'
-- 志愿者 'vol_004' ('陈燕') 参与了活动 'act_004' 的岗位 'pos_005' ('智能设备助教')
-- 初始时，vol_004 对该活动的 VolunteerToOrgRating 为 NULL, OrgToVolunteerRating 为 NULL (根据初始数据脚本的参与记录)

PRINT N'--- 场景 9.1: 志愿者首次成功评分 ---';
PRINT N'步骤 9.1.1: 查看志愿者 "vol_004" 对活动 "act_004" (岗位 "pos_005") 的评分情况 (评分前):';
SELECT
    v.Name AS '志愿者姓名',
    va.ActivityName AS '活动名称',
    p.PositionName AS '参与岗位',
    vap.VolunteerToOrgRating AS '志愿者给组织的评分',
    vap.OrgToVolunteerRating AS '组织给志愿者的评分'
FROM
    dbo.tbl_VolunteerActivityParticipation vap
JOIN
    dbo.tbl_Volunteer v ON vap.VolunteerID = v.VolunteerID
JOIN
    dbo.tbl_VolunteerActivity va ON vap.ActivityID = va.ActivityID
JOIN
    dbo.tbl_Position p ON vap.ActualPositionID = p.PositionID
WHERE
    vap.VolunteerID = 'vol_004' AND vap.ActivityID = 'act_004' AND vap.ActualPositionID = 'pos_005';
GO

PRINT N'步骤 9.1.2: 志愿者 "vol_004" 对活动 "act_004" (岗位 "pos_005") 评分为 8:';
DECLARE @ReturnCode_9_1 INT;
EXEC @ReturnCode_9_1 = dbo.sp_VolunteerRateOrganizationAfterActivity
    @VolunteerID = 'vol_004',
    @ActivityID = 'act_004',
    @ActualPositionID = 'pos_005',
    @Rating = 8;
SELECT @ReturnCode_9_1 AS '存储过程返回值';
GO
-- 期望：存储过程返回值应为 0 (成功)。

PRINT N'步骤 9.1.3: 查看志愿者 "vol_004" 对活动 "act_004" (岗位 "pos_005") 的评分情况 (评分后):';
SELECT
    v.Name AS '志愿者姓名',
    va.ActivityName AS '活动名称',
    p.PositionName AS '参与岗位',
    vap.VolunteerToOrgRating AS '志愿者给组织的评分',
    vap.OrgToVolunteerRating AS '组织给志愿者的评分'
FROM
    dbo.tbl_VolunteerActivityParticipation vap
JOIN
    dbo.tbl_Volunteer v ON vap.VolunteerID = v.VolunteerID
JOIN
    dbo.tbl_VolunteerActivity va ON vap.ActivityID = va.ActivityID
JOIN
    dbo.tbl_Position p ON vap.ActualPositionID = p.PositionID
WHERE
    vap.VolunteerID = 'vol_004' AND vap.ActivityID = 'act_004' AND vap.ActualPositionID = 'pos_005';
GO
-- 期望：'志愿者给组织的评分' 列应显示为 8。

--------------------------------------------------------------------------------
PRINT N'--- 场景 9.2: 尝试对未结束的活动评分 (失败) ---';
-- 活动 act_001 ('周末爱心书屋辅导') 在初始数据中状态为 '进行中', EndTime 为 '2025-06-10 12:00'
-- 假设当前日期在活动结束之前 (如果不是，此测试可能不按预期失败)
PRINT N'步骤 9.2.1: 查看活动 "act_001" 的状态和结束时间:';
SELECT ActivityID, ActivityName, ActivityStatus, EndTime FROM dbo.tbl_VolunteerActivity WHERE ActivityID = 'act_001';
GO

PRINT N'步骤 9.2.2: 志愿者 "vol_001" 尝试对进行中的活动 "act_001" (岗位 "pos_001") 评分为 7:';
DECLARE @ReturnCode_9_2 INT;
EXEC @ReturnCode_9_2 = dbo.sp_VolunteerRateOrganizationAfterActivity
    @VolunteerID = 'vol_001',
    @ActivityID = 'act_001',
    @ActualPositionID = 'pos_001',
    @Rating = 7;
SELECT @ReturnCode_9_2 AS '存储过程返回值';
GO
-- 期望：存储过程返回值应为 -2 (活动尚未结束或不处于可评分状态)，并有 RAISERROR 信息。
-- 验证评分未改变：
PRINT N'步骤 9.2.3: 查看志愿者 "vol_001" 对活动 "act_001" (岗位 "pos_001") 的评分情况 (应未改变):';
SELECT VolunteerToOrgRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_001' AND ActualPositionID = 'pos_001';
GO

--------------------------------------------------------------------------------
PRINT N'--- 场景 9.3: 尝试重复评分 (提示已评分) ---';
-- 志愿者 vol_001 对活动 act_004 (岗位 pos_005) 在初始数据中已由组织评分为8，自己评分为8
PRINT N'步骤 9.3.1: 查看志愿者 "vol_001" 对活动 "act_004" (岗位 "pos_005") 的当前评分 (应为8):';
SELECT VolunteerToOrgRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005';
GO

PRINT N'步骤 9.3.2: 志愿者 "vol_001" 尝试对活动 "act_004" (岗位 "pos_005") 重复评分为 6:';
DECLARE @ReturnCode_9_3 INT;
EXEC @ReturnCode_9_3 = dbo.sp_VolunteerRateOrganizationAfterActivity
    @VolunteerID = 'vol_001',
    @ActivityID = 'act_004',
    @ActualPositionID = 'pos_005',
    @Rating = 6;
SELECT @ReturnCode_9_3 AS '存储过程返回值';
GO
-- 期望：存储过程返回值应为 1 (已评分)，并有 RAISERROR 信息 (级别10)。
-- 验证评分未改变：
PRINT N'步骤 9.3.3: 查看志愿者 "vol_001" 对活动 "act_004" (岗位 "pos_005") 的评分情况 (应仍为8):';
SELECT VolunteerToOrgRating FROM dbo.tbl_VolunteerActivityParticipation WHERE VolunteerID = 'vol_001' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005';
GO

--------------------------------------------------------------------------------
PRINT N'--- 场景 9.4: 尝试对不存在的参与记录评分 (失败) ---';
PRINT N'步骤 9.4.1: 志愿者 "vol_002" 尝试对活动 "act_004" (一个他未参与的岗位 "pos_005") 评分:';
DECLARE @ReturnCode_9_4 INT;
EXEC @ReturnCode_9_4 = dbo.sp_VolunteerRateOrganizationAfterActivity
    @VolunteerID = 'vol_002',      -- 李娜
    @ActivityID = 'act_004',      -- 长者智能手机教学
    @ActualPositionID = 'pos_005', -- 智能设备助教 (李娜未参与此活动此岗位)
    @Rating = 5;
SELECT @ReturnCode_9_4 AS '存储过程返回值';
GO
-- 期望：存储过程返回值应为 -1 (未找到参与记录)。

--------------------------------------------------------------------------------
PRINT N'--- 场景 9.5: 尝试使用无效的评分值 (失败) ---';
PRINT N'步骤 9.5.1: 志愿者 "vol_004" 对活动 "act_004" (岗位 "pos_005") 评分为 11 (无效):';
-- 先确保 vol_004 对 act_004 的评分为 NULL 以便测试此场景
UPDATE dbo.tbl_VolunteerActivityParticipation SET VolunteerToOrgRating = NULL WHERE VolunteerID = 'vol_004' AND ActivityID = 'act_004' AND ActualPositionID = 'pos_005';
DECLARE @ReturnCode_9_5 INT;
EXEC @ReturnCode_9_5 = dbo.sp_VolunteerRateOrganizationAfterActivity
    @VolunteerID = 'vol_004',
    @ActivityID = 'act_004',
    @ActualPositionID = 'pos_005',
    @Rating = 11; -- 无效评分
SELECT @ReturnCode_9_5 AS '存储过程返回值';
GO
-- 期望：存储过程返回值应为 -3 (评分值无效)。

PRINT N'--- sp_VolunteerRateOrganizationAfterActivity 存储过程测试结束 ---';
GO
--------------------------------------------------------------------------------
-- 测试 sp_SubmitComplaintByVolunteer (志愿者提交投诉)
--------------------------------------------------------------------------------
PRINT N'--- 测试 sp_SubmitComplaintByVolunteer ---';
-- 10.1 提交新投诉 (成功)
PRINT N'志愿者 "vol_002" 提交新投诉 "cmpl_test_003":';
EXEC dbo.sp_SubmitComplaintByVolunteer
    @ComplaintID = 'cmpl_test_003',
    @ComplainantVolunteerID = 'vol_002',
    @ComplaintTargetID = 'org_001', -- 投诉对象为组织
    @ComplaintType = N'服务质量',
    @ComplaintContent = N'组织 org_001 在活动 act_001 期间的物资发放不及时。',
    @EvidenceLink = NULL;
GO
-- 期望：返回 0。
-- 验证：
SELECT * FROM dbo.tbl_Complaint WHERE ComplaintID = 'cmpl_test_003';
GO

-- 10.2 尝试使用不存在的志愿者ID提交投诉 (失败)
PRINT N'尝试使用不存在的志愿者ID "vol_999" 提交投诉:';
EXEC dbo.sp_SubmitComplaintByVolunteer
    @ComplaintID = 'cmpl_test_004',
    @ComplainantVolunteerID = 'vol_999',
    @ComplaintTargetID = 'org_001',
    @ComplaintType = N'其他',
    @ComplaintContent = N'无效投诉测试。',
    @EvidenceLink = NULL;
GO
-- 期望：返回 -1。

PRINT N'--- 志愿者相关存储过程测试结束 ---';
GO
