USE volunteer_web_02
GO
select * from tbl_Volunteer;
select * from tbl_Organization;

-- 顺序 1: 创建 管理员表 (tbl_Administrator)
CREATE TABLE tbl_Administrator (
    AdminID CHAR(15) PRIMARY KEY,                                  -- 管理员唯一标识
    Name NVARCHAR(20) NOT NULL,                                   -- 真实姓名
    Gender NCHAR(1) NOT NULL CHECK (Gender IN (N'男', N'女')),     -- 性别
    IDCardNumber VARCHAR(18) NOT NULL UNIQUE,                      -- 身份证号, 标准处理
    PhoneNumber VARCHAR(11) NOT NULL UNIQUE,                       -- 标准手机号
    Password NVARCHAR(50) NOT NULL,                                -- 登录密码 (已修改为明文存储)
    ServiceArea NVARCHAR(100) NOT NULL,                            -- 管理员负责管辖的地区
    CurrentPosition NVARCHAR(20) NOT NULL DEFAULT N'普通管理员'
	CHECK (CurrentPosition IN (N'系统维护员', N'审核监督员', N'权限管理员', N'数据维护员', N'应急管理员', N'用户服务员',N'普通管理员')), -- 当前职务
    PermissionLevel NVARCHAR(8) NOT NULL CHECK (PermissionLevel IN (N'高', N'中', N'低')) -- 权限等级
);
GO
select * from tbl_Administrator;
-- 顺序 2: 创建 组织机构表 (tbl_Organization)
CREATE TABLE tbl_Organization (
    OrgID CHAR(15) PRIMARY KEY,                                    -- 唯一标识组织的编号
    OrgName NVARCHAR(20) NOT NULL,                                 -- 组织名称
    OrgLoginUserName NVARCHAR(20) NOT NULL UNIQUE,                 -- 组织登录凭证（组织登录用户名）
    OrgLoginPassword NVARCHAR(50) NOT NULL,                        -- 登陆密码 (已修改为明文存储)
    ContactPersonPhone NVARCHAR(11) NOT NULL,                      -- 标准手机号
    ServiceRegion NVARCHAR(50) NOT NULL
	CHECK(ServiceRegion IN('北京', '天津', '上海', '重庆', '河北', '山西', '辽宁', '吉林', '黑龙江','江苏', '浙江', '安徽', '福建', '江西',
	'山东', '河南', '湖北', '湖南','广东', '广西', '海南', '四川', '贵州', '云南', '西藏', '陕西', '甘肃','青海', '台湾', '香港', '澳门')),
	-- 服务区域
    OrgScale INT NOT NULL,                                         -- 组织人数
    OrgRating DECIMAL(3,1) NOT NULL DEFAULT 0.0 CHECK (OrgRating >= 0.0 AND OrgRating <= 10.0), -- 组织评分
    OrgAccountStatus NVARCHAR(10) NOT NULL DEFAULT N'待认证'
	CHECK (OrgAccountStatus IN (N'已认证', N'待认证', N'冻结',N'认证未通过')), -- 组织注册申请的当前审批状态
    TotalServiceHours INT NOT NULL DEFAULT 0,                      -- 反映组织活跃度与贡献度，可为组织评价标准之一
    ActivityCount INT NOT NULL DEFAULT 0,
    TrainingCount INT NOT NULL DEFAULT 0
);
GO
--例如，如果约束名是 'DF__tbl_Organ__OrgRa__3F466844' (这只是一个示例名称)
ALTER TABLE dbo.tbl_Organization
DROP CONSTRAINT CK__tbl_Organ__OrgRa__4222D4EF; -- 请替换为您的实际约束名
GO

ALTER TABLE dbo.tbl_Organization
ADD CONSTRAINT CK_tbl_Organization_OrgRating_0_to_10 CHECK (OrgRating >= 0.0 AND OrgRating <= 10.0);
GO

-- 顺序 3: 创建 志愿者表 (tbl_Volunteer)
CREATE TABLE tbl_Volunteer (
    VolunteerID CHAR(15) PRIMARY KEY,                                -- 唯一标识志愿者
    Username NVARCHAR(20) NOT NULL UNIQUE,                           -- 用户注册登录使用
    Name NVARCHAR(20) NOT NULL,                                      -- 真实姓名
    PhoneNumber VARCHAR(11)  NOT NULL UNIQUE,                         -- 标准手机号
    IDCardNumber VARCHAR(18) NOT NULL UNIQUE,                        -- 唯一认证证件
    Password NVARCHAR(50) NOT NULL,                                  -- 登录密码 (已修改为明文存储)
    Country NVARCHAR(10) DEFAULT N'中国',                             -- 国籍信息
    Gender NCHAR(1) NOT NULL CHECK (Gender IN (N'男', N'女')),       -- 真实性别筛选
    ServiceArea NVARCHAR(50) NOT NULL
	CHECK(ServiceArea IN('北京', '天津', '上海', '重庆', '河北', '山西', '辽宁', '吉林', '黑龙江','江苏', '浙江', '安徽', '福建', '江西',
	'山东', '河南', '湖北', '湖南','广东', '广西', '海南', '四川', '贵州', '云南', '西藏', '陕西', '甘肃','青海', '台湾', '香港', '澳门')),
 -- 服务区域
    Ethnicity NVARCHAR(10) DEFAULT N'汉族' CHECK (Ethnicity IN ('汉族', '蒙古族', '回族', '藏族', '维吾尔族', '苗族', '彝族', '壮族',
        '布依族', '朝鲜族', '满族', '侗族', '瑶族', '白族', '土家族',
        '哈尼族', '哈萨克族', '傣族', '黎族', '傈僳族', '佤族', '畲族',
        '高山族', '拉祜族', '水族', '东乡族', '纳西族', '景颇族',
        '柯尔克孜族', '土族', '达斡尔族', '仫佬族', '羌族', '布朗族',
        '撒拉族', '毛南族', '仡佬族', '锡伯族', '阿昌族', '普米族',
        '塔吉克族', '怒族', '乌孜别克族', '俄罗斯族', '鄂温克族',
        '德昂族', '保安族', '裕固族', '京族', '塔塔尔族', '独龙族',
        '鄂伦春族', '赫哲族', '门巴族', '珞巴族')), -- 民族身份
    PoliticalStatus NVARCHAR(20) DEFAULT N'群众'
	CHECK (PoliticalStatus IN ('中国共产党党员','中国共产党预备党员','中国共产主义青年团团员',
        '中国国民党革命委员会会员','中国民主同盟盟员','中国民主建国会会员',
        '中国民主促进会会员','中国农工民主党党员','中国致公党党员',
        '九三学社社员','台湾民主自治同盟盟员','无党派民主人士','群众')), -- 政治身份
    HighestEducation NVARCHAR(20)
	CHECK (HighestEducation IN ('博士研究生', '大学本科', '技工学校', '高中', '初中', '小学',
        '硕士研究生', '大学专科和专科学校', '幼儿园学龄前', '特殊教育',
        '文盲或半文盲', '未说明情况')), -- 教育背景
    EmploymentStatus NVARCHAR(20)
	CHECK (EmploymentStatus IN ('国家公务员', '职员', '企业管理人员', '工人', '学生', '现役军人',
        '自由职业', '个体经营者', '无业人员', '退(离)休人员', '医生',
        '司机', '律师', '教师', '农民','为说明情况')), -- 从业情况
    ServiceCategory NVARCHAR(20)
	CHECK (ServiceCategory IN ('助力复工复产志愿者', '扶贫济困志愿者', '社区志愿者',
        '青年志愿者', '文明志愿者', '文化志愿者', '医疗志愿者',
        '教育志愿者', '助残志愿者', '巾帼志愿者', '消防志愿者',
        '红十字志愿者', '税收志愿者', '疫情防控志愿者')), -- 志愿类别
    TotalVolunteerHours DECIMAL(10,2) DEFAULT 0.00,                  -- 总志愿时长
    VolunteerRating DECIMAL(10,2) DEFAULT 0.00,                      -- 志愿者综合评分
    AccountStatus NVARCHAR(10) NOT NULL DEFAULT N'未实名认证'
	CHECK (AccountStatus IN (N'未实名认证', N'已实名认证', N'已冻结',N'认证未通过'))
);
GO
select * from tbl_VolunteerActivity;

-- 顺序 4: 创建 志愿活动表 (tbl_VolunteerActivity)
CREATE TABLE tbl_VolunteerActivity (
    ActivityID CHAR(15) PRIMARY KEY,                                  -- 唯一标识活动
    OrgID CHAR(15) NOT NULL
	FOREIGN KEY REFERENCES tbl_Organization(OrgID),					  -- 关联志愿组织机构表
    ActivityName NVARCHAR(20) NOT NULL,                               -- 志愿活动名称
    StartTime SMALLDATETIME NOT NULL,                                       -- 志愿活动开始时间
    EndTime SMALLDATETIME NOT NULL,                                         -- 志愿活动结束时间
    Location NVARCHAR(30) NOT NULL,                                    -- 活动地点
    RecruitmentCount INT NOT NULL CHECK (RecruitmentCount > 0),        -- 招募人数
    AcceptedCount INT NOT NULL DEFAULT 0 , -- 录取人数
    ActivityStatus NVARCHAR(10) NOT NULL,DEFAULT N'待审核' ,
	CHECK (ActivityStatus IN (N'待审核', N'审核通过', N'审核不通过', N'进行中', N'已结束', N'已停用')), -- 志愿活动状态
    CreationTime DATETIME2(0) NOT NULL DEFAULT GETDATE(),                  -- 创建时间
    ReviewerAdminID CHAR(15) FOREIGN KEY REFERENCES tbl_Administrator(AdminID), -- 审核管理员ID, 关联管理员表 (可空)
    ContactPersonPhone NVARCHAR(11) NOT NULL,                         -- 负责人联系方式，标准手机号
    ActivityDurationHours INT CHECK (ActivityDurationHours >= 0),      -- 志愿活动总时长 (小时)
    ActivityRating INT CHECK (ActivityRating > 0 AND ActivityRating <= 10), -- 志愿活动评分 (假设1-10分)
    IsRatingAggregated CHAR(3) NOT NULL DEFAULT 'NO' CHECK (IsRatingAggregated IN ('YES', 'NO')), -- 标记一个活动或培训的评分是否已经被处理过
	CONSTRAINT CHK_AcceptedCount_Activity CHECK (AcceptedCount >= 0 AND AcceptedCount <= RecruitmentCount) -- 添加表级 CHECK 约束
);
GO

-- 顺序 5: 创建 志愿培训表 (tbl_VolunteerTraining)
CREATE TABLE tbl_VolunteerTraining (
    TrainingID CHAR(15) PRIMARY KEY,                                  -- 唯一标识培训
    OrgID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Organization(OrgID), -- 关联组织表
    TrainingName NVARCHAR(20) NOT NULL,                               -- 培训名称
    Theme NVARCHAR(15) NOT NULL ,                                     -- 主题（组织内部培训，活动培训，特定岗位培训）
    StartTime SMALLDATETIME NOT NULL,                                  -- 培训开始时间
    EndTime SMALLDATETIME NOT NULL,                                    -- 培训结束时间
    Location NVARCHAR(30) NOT NULL,                                    -- 培训地点
    RecruitmentCount INT NOT NULL CHECK (RecruitmentCount > 0),        -- 招募人数
    TrainingStatus NVARCHAR(10) NOT NULL 
	CHECK (TrainingStatus IN (N'待审核', N'审核通过', N'审核不通过', N'进行中', N'已结束', N'已停用')), -- << 修改点：添加 N'审核不通过'
    CreationTime SMALLDATETIME NOT NULL DEFAULT GETDATE(),             -- 创建时间
    ReviewerAdminID CHAR(15) FOREIGN KEY REFERENCES tbl_Administrator(AdminID), -- 审核管理员ID, 关联管理员表 (可空)
    ContactPersonPhone NVARCHAR(11) NOT NULL,                         -- 负责人联系方式，标准手机号
    TrainingRating INT CHECK (TrainingRating > 0 AND TrainingRating <= 10), -- 培训评分 (假设1-10分)
    IsRatingAggregated CHAR(3) NOT NULL DEFAULT 'NO' CHECK (IsRatingAggregated IN ('YES', 'NO')) -- 标记一个活动或培训的评分是否已经被处理过
);
GO

-- 顺序 6: 创建 志愿者组织机构参与表 (tbl_VolunteerOrganizationJoin)
CREATE TABLE tbl_VolunteerOrganizationJoin (
    VolunteerID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Volunteer(VolunteerID), -- 关联志愿者表
    OrgID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Organization(OrgID),       -- 关联组织机构表
    JoinTime DATETIME NOT NULL DEFAULT GETDATE(),                                 -- 志愿者加入组织的时间
    MemberStatus NVARCHAR(3) NOT NULL CHECK (MemberStatus IN (N'申请中', N'已加入', N'已退出')), -- 成员状态
    PRIMARY KEY (VolunteerID, OrgID)                                              -- 联合主键
);
GO

-- 顺序 7: 创建 岗位表 (tbl_Position)
CREATE TABLE tbl_Position (
    PositionID CHAR(15) PRIMARY KEY,                                 -- 岗位ID, 主键 (CHAR类型的唯一性需应用层面确保)
    PositionName NVARCHAR(50) NOT NULL,                              -- 岗位名称
    ActivityID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_VolunteerActivity(ActivityID), -- 活动ID, 外键, 关联志愿活动表
    PositionServiceHours INT NOT NULL CHECK (PositionServiceHours > 0), -- 岗位服务时长 (指在该活动中任职岗位可获得的服务时长)
    RequiredVolunteers INT NOT NULL,                                  -- 需求人数
    RecruitedVolunteers INT NOT NULL DEFAULT 0, -- 已招募人数 (小于等于需求人数, 且大于等于0)
	CONSTRAINT CHK_RecruitedVolunteers_Position CHECK (RecruitedVolunteers <= RequiredVolunteers AND RecruitedVolunteers >= 0) -- 添加表级 CHECK 约束
);
GO

-- 顺序 8: 创建 活动时段表 (tbl_ActivityTimeslot)
CREATE TABLE tbl_ActivityTimeslot (
    TimeslotID CHAR(15) PRIMARY KEY,                                  -- 时段ID, 主键
    EventID CHAR(15) NOT NULL,                                       -- 事件ID (例如: 'activity_xxxx' 或 'training_xxxx')
    StartTime SMALLDATETIME NOT NULL,                                     -- 时段开始时间
    EndTime SMALLDATETIME NOT NULL,                                       -- 时段结束时间
    CONSTRAINT CHK_ActivityTimeslot_EndTimeAfterStart CHECK (EndTime > StartTime) -- 确保结束时间在开始时间之后
);
GO

-- 顺序 9: 创建 志愿者活动报名表 (tbl_VolunteerActivityApplication)
CREATE TABLE tbl_VolunteerActivityApplication (
    ApplicationID CHAR(15) PRIMARY KEY,                                -- 报名申请的唯一标识 (CHAR类型的唯一性需应用层面确保)
    VolunteerID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Volunteer(VolunteerID), -- 关联申请的志愿者
    ActivityID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_VolunteerActivity(ActivityID), -- 志愿活动ID
    IntendedPositionID CHAR(15) NULL FOREIGN KEY REFERENCES tbl_Position(PositionID), -- 外键到岗位表
    ApplicationTime DATETIME NOT NULL DEFAULT GETDATE(),               -- 志愿者提交申请的具体时间
    ApplicationStatus NVARCHAR(10) NOT NULL DEFAULT N'待审核'
	CHECK (ApplicationStatus IN (N'待审核', N'已通过', N'已拒绝',N'取消报名')) -- 申请的当前状态
);
GO

-- 顺序 10: 创建 志愿者活动参与表 (tbl_VolunteerActivityParticipation)
CREATE TABLE tbl_VolunteerActivityParticipation (
    VolunteerID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Volunteer(VolunteerID),       -- 关联志愿者表
    ActivityID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_VolunteerActivity(ActivityID), -- 关联志愿活动表
    ActualPositionID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Position(PositionID), -- 外键到岗位表
    IsCheckedIn NCHAR(1) NOT NULL DEFAULT N'否' CHECK (IsCheckedIn IN (N'是', N'否')),     -- 志愿者是否进行签到
    VolunteerToOrgRating INT CHECK (VolunteerToOrgRating >= 1 AND VolunteerToOrgRating <= 10), -- 志愿者给组织评分
    OrgToVolunteerRating INT CHECK (OrgToVolunteerRating >= 1 AND OrgToVolunteerRating <= 10), -- 组织给志愿者评分
    PRIMARY KEY (VolunteerID, ActualPositionID) -- 主键：活动ID+实际岗位ID
);
GO

-- 顺序 11: 创建 志愿者培训参与表 (tbl_VolunteerTrainingParticipation)
CREATE TABLE tbl_VolunteerTrainingParticipation (
    VolunteerID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_Volunteer(VolunteerID),       -- 关联志愿者表的唯一标志
    TrainingID CHAR(15) NOT NULL FOREIGN KEY REFERENCES tbl_VolunteerTraining(TrainingID),   -- 关联志愿培训表的唯一标志
    IsCheckedIn NCHAR(1) NOT NULL DEFAULT N'否' CHECK (IsCheckedIn IN (N'是', N'否')),     -- 志愿者是否进行签到
    OrgToVolunteerRating INT CHECK (OrgToVolunteerRating >= 1 AND OrgToVolunteerRating <= 10), -- 组织给志愿者评分
    VolunteerToOrgRating INT CHECK (VolunteerToOrgRating >= 1 AND VolunteerToOrgRating <= 10), -- 志愿者给组织评分
    PRIMARY KEY (VolunteerID, TrainingID)                                                  -- 联合主键
);
GO

-- 顺序 12: 创建 投诉表 (tbl_Complaint)
CREATE TABLE tbl_Complaint (
    ComplaintID CHAR(15) PRIMARY KEY,                                 -- 投诉ID, 主键 (CHAR类型的唯一性需应用层面确保)
    ComplaintTime DATETIME NOT NULL DEFAULT GETDATE(),                -- 投诉时间
    ComplainantID CHAR(15) NOT NULL,                                  -- 发起人对象ID (ID带前缀，应用层面处理引用完整性)
    ComplaintTargetID CHAR(15) NOT NULL,                              -- 投诉对象ID (ID带前缀，应用层面处理引用完整性)
    ComplaintType NVARCHAR(10) NOT NULL DEFAULT N'其他'
        CHECK (ComplaintType IN (
            N'服务质量', N'行为不当', N'信息虚假', N'活动违规', N'其他'
        )),
    ComplaintContent NVARCHAR(MAX) NOT NULL,                          -- 投诉内容
    EvidenceLink NVARCHAR(255),                                       -- 证据链接
    ProcessingStatus NVARCHAR(10) NOT NULL DEFAULT N'未处理'
        CHECK (ProcessingStatus IN (
            N'未处理', N'转应诉', N'处理中', N'已应诉', N'仲裁中', N'已仲裁', N'已退回'
        )),
    ProcessingResult NVARCHAR(MAX),                                   -- 处理结果
    LatestProcessingTime DATETIME,                                    -- 最新处理时间
    HandlerAdminID CHAR(15) FOREIGN KEY REFERENCES tbl_Administrator(AdminID), -- 处理人ID (可空)
    VisitTime DATETIME,                                               -- 回访时间
    VisitResult NVARCHAR(20) NOT NULL DEFAULT N'满意'
        CHECK (VisitResult IN (N'满意', N'不满意')),
    ArbitrationRound INT CHECK (ArbitrationRound BETWEEN 1 AND 2),    -- 仲裁轮次
    ReviewAdminID CHAR(15) FOREIGN KEY REFERENCES tbl_Administrator(AdminID) -- 复审管理员ID (可空)
);
GO