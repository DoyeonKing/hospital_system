/*
 Navicat Premium Dump SQL

 Source Server         : hospital-system
 Source Server Type    : MySQL
 Source Server Version : 80044 (8.0.44)
 Source Host           : localhost:3306
 Source Schema         : hospital_db

 Target Server Type    : MySQL
 Target Server Version : 80044 (8.0.44)
 File Encoding         : 65001

 Date: 08/12/2025 13:53:13
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for admin_roles
-- ----------------------------
DROP TABLE IF EXISTS `admin_roles`;
CREATE TABLE `admin_roles`  (
  `admin_id` int NOT NULL COMMENT '管理员ID',
  `role_id` int NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`admin_id`, `role_id`) USING BTREE,
  INDEX `fk_admin_roles_role`(`role_id` ASC) USING BTREE,
  CONSTRAINT `fk_admin_roles_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`admin_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_admin_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '管理员-角色映射表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for admins
-- ----------------------------
DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins`  (
  `admin_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '管理员登录用户名',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '管理员真实姓名',
  `status` enum('active','inactive','locked') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  PRIMARY KEY (`admin_id`) USING BTREE,
  UNIQUE INDEX `uk_admins_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '管理员表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for appointments
-- ----------------------------
DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments`  (
  `appointment_id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL COMMENT '患者ID',
  `schedule_id` int NOT NULL COMMENT '排班ID',
  `appointment_number` int NOT NULL COMMENT '就诊序号',
  `status` enum('PENDING_PAYMENT','scheduled','CHECKED_IN','completed','cancelled','NO_SHOW') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'scheduled' COMMENT '预约状态',
  `payment_status` enum('unpaid','paid','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unpaid' COMMENT '支付状态',
  `payment_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '支付方式',
  `transaction_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '支付流水号',
  `check_in_time` datetime NULL DEFAULT NULL COMMENT '现场签到时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '预约生成时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '最后更新时间（status变为completed时由触发器更新）',
  `called_at` datetime NULL DEFAULT NULL COMMENT '叫号时间（NULL表示未叫号）',
  `is_on_time` tinyint(1) NULL DEFAULT 0 COMMENT '是否按时签到（预约时段开始后20分钟内）',
  `missed_call_count` int NULL DEFAULT 0 COMMENT '过号次数',
  `recheck_in_time` datetime NULL DEFAULT NULL COMMENT '过号后重新签到时间',
  `is_walk_in` tinyint(1) NULL DEFAULT 0 COMMENT '是否现场挂号（0=预约，1=现场挂号）',
  `real_time_queue_number` int NULL DEFAULT NULL COMMENT '实时候诊序号（在时段内按签到时间分配）',
  `is_late` tinyint(1) NULL DEFAULT 0 COMMENT '是否迟到（超过时段结束时间+软关门时间）',
  `appointment_type` enum('APPOINTMENT','WALK_IN','SAME_DAY_FOLLOW_UP','ADD_ON') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'APPOINTMENT' COMMENT '预约类型',
  `original_appointment_id` int NULL DEFAULT NULL COMMENT '原始预约ID（用于复诊号关联，复诊号关联到原始预约）',
  `is_add_on` tinyint(1) NULL DEFAULT 0 COMMENT '是否加号（0=否，1=是）',
  `payment_deadline` datetime NULL DEFAULT NULL COMMENT '支付截止时间（加号专用，参考候补的notification_sent_at+15分钟模式）',
  PRIMARY KEY (`appointment_id`) USING BTREE,
  INDEX `idx_patient_id`(`patient_id` ASC) USING BTREE,
  INDEX `idx_schedule_id`(`schedule_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_check_in_time`(`check_in_time` ASC) USING BTREE,
  INDEX `idx_called_at`(`called_at` ASC) USING BTREE,
  INDEX `idx_is_on_time`(`is_on_time` ASC) USING BTREE,
  INDEX `idx_recheck_in_time`(`recheck_in_time` ASC) USING BTREE,
  INDEX `idx_is_walk_in`(`is_walk_in` ASC) USING BTREE,
  INDEX `idx_real_time_queue_number`(`real_time_queue_number` ASC) USING BTREE,
  INDEX `idx_is_late`(`is_late` ASC) USING BTREE,
  INDEX `idx_appointment_type`(`appointment_type` ASC) USING BTREE,
  INDEX `idx_original_appointment_id`(`original_appointment_id` ASC) USING BTREE,
  INDEX `idx_is_add_on`(`is_add_on` ASC) USING BTREE,
  INDEX `idx_payment_deadline`(`payment_deadline` ASC) USING BTREE,
  CONSTRAINT `fk_appointments_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_appointments_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_original_appointment` FOREIGN KEY (`original_appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE SET NULL ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 30 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '预约挂号表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for audit_logs
-- ----------------------------
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs`  (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `actor_id` int NOT NULL COMMENT '操作者ID',
  `actor_type` enum('patient','doctor','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '操作者类型',
  `action` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '操作行为描述',
  `target_entity` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '被操作对象所在的表名',
  `target_id` int NOT NULL COMMENT '被操作对象的ID',
  `details` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '操作详细信息',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作发生时间',
  PRIMARY KEY (`log_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '审计日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for departments
-- ----------------------------
DROP TABLE IF EXISTS `departments`;
CREATE TABLE `departments`  (
  `department_id` int NOT NULL AUTO_INCREMENT,
  `parent_id` int NOT NULL COMMENT '父科室ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '子科室名称',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '科室职能描述',
  PRIMARY KEY (`department_id`) USING BTREE,
  INDEX `fk_departments_parent`(`parent_id` ASC) USING BTREE,
  CONSTRAINT `fk_departments_parent` FOREIGN KEY (`parent_id`) REFERENCES `parent_departments` (`parent_department_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1001 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '子科室表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for doctors
-- ----------------------------
DROP TABLE IF EXISTS `doctors`;
CREATE TABLE `doctors`  (
  `doctor_id` int NOT NULL AUTO_INCREMENT,
  `department_id` int NOT NULL COMMENT '所属科室',
  `identifier` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '医生的工号',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '真实姓名',
  `id_card_number` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '身份证号, 建议加密',
  `phone_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '存储E.164标准格式',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '职称',
  `title_level` tinyint UNSIGNED NULL DEFAULT NULL COMMENT '职称等级：0-主任医师，1-副主任医师，2-主治医师',
  `specialty` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '擅长领域描述',
  `bio` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '个人简介',
  `photo_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '头像照片URL',
  `status` enum('active','inactive','locked','deleted') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '信息最后更新时间',
  PRIMARY KEY (`doctor_id`) USING BTREE,
  UNIQUE INDEX `uk_doctors_identifier`(`identifier` ASC) USING BTREE,
  UNIQUE INDEX `uk_doctors_id_card`(`id_card_number` ASC) USING BTREE,
  UNIQUE INDEX `uk_doctors_phone`(`phone_number` ASC) USING BTREE,
  INDEX `fk_doctors_department`(`department_id` ASC) USING BTREE,
  CONSTRAINT `fk_doctors_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '医生表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for leave_requests
-- ----------------------------
DROP TABLE IF EXISTS `leave_requests`;
CREATE TABLE `leave_requests`  (
  `request_id` int NOT NULL AUTO_INCREMENT,
  `doctor_id` int NOT NULL COMMENT '申请人医生ID',
  `request_type` enum('leave','schedule_change') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '申请类型',
  `start_time` datetime NOT NULL COMMENT '申请开始时间',
  `end_time` datetime NOT NULL COMMENT '申请结束时间',
  `reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '申请事由',
  `proof_document_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '请假证明文件URL（图片或PDF）',
  `status` enum('PENDING','APPROVED','REJECTED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approver_id` int NULL DEFAULT NULL COMMENT '审批人管理员ID',
  `approver_comments` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '审批人员的意见或备注',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '申请更新时间',
  PRIMARY KEY (`request_id`) USING BTREE,
  INDEX `fk_leave_requests_doctor`(`doctor_id` ASC) USING BTREE,
  INDEX `fk_leave_requests_approver`(`approver_id` ASC) USING BTREE,
  CONSTRAINT `fk_leave_requests_approver` FOREIGN KEY (`approver_id`) REFERENCES `admins` (`admin_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_leave_requests_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '调班/休假申请表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for locations
-- ----------------------------
DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations`  (
  `location_id` int NOT NULL AUTO_INCREMENT,
  `location_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '诊室名称，如：门诊楼201室',
  `department_id` int NULL DEFAULT NULL COMMENT '所属科室',
  `floor_level` int NULL DEFAULT NULL COMMENT '楼层',
  `building` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '楼栋',
  `room_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '房间号',
  `capacity` int NULL DEFAULT NULL COMMENT '容纳人数',
  `map_node_id` int NULL DEFAULT NULL COMMENT '对应的地图节点',
  PRIMARY KEY (`location_id`) USING BTREE,
  INDEX `fk_locations_department`(`department_id` ASC) USING BTREE,
  INDEX `fk_locations_map_node`(`map_node_id` ASC) USING BTREE,
  CONSTRAINT `fk_locations_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_locations_map_node` FOREIGN KEY (`map_node_id`) REFERENCES `map_nodes` (`node_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '诊室表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for map_edges
-- ----------------------------
DROP TABLE IF EXISTS `map_edges`;
CREATE TABLE `map_edges`  (
  `edge_id` int NOT NULL AUTO_INCREMENT,
  `start_node_id` int NOT NULL COMMENT '起始节点',
  `end_node_id` int NOT NULL COMMENT '结束节点',
  `distance` decimal(10, 2) NOT NULL COMMENT '距离(米)',
  `walk_time` int NOT NULL COMMENT '步行时间(秒)',
  `is_bidirectional` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否双向通行',
  `accessibility_info` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '无障碍设施信息',
  PRIMARY KEY (`edge_id`) USING BTREE,
  INDEX `fk_edges_start_node`(`start_node_id` ASC) USING BTREE,
  INDEX `fk_edges_end_node`(`end_node_id` ASC) USING BTREE,
  CONSTRAINT `fk_edges_end_node` FOREIGN KEY (`end_node_id`) REFERENCES `map_nodes` (`node_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_edges_start_node` FOREIGN KEY (`start_node_id`) REFERENCES `map_nodes` (`node_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '地图路径表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for map_nodes
-- ----------------------------
DROP TABLE IF EXISTS `map_nodes`;
CREATE TABLE `map_nodes`  (
  `node_id` int NOT NULL AUTO_INCREMENT,
  `node_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '节点名称',
  `node_type` enum('room','hallway','elevator','stairs','entrance') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '节点类型',
  `coordinates_x` decimal(10, 2) NOT NULL COMMENT 'X坐标',
  `coordinates_y` decimal(10, 2) NOT NULL COMMENT 'Y坐标',
  `floor_level` int NOT NULL COMMENT '楼层',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '节点描述',
  `is_accessible` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否无障碍通行',
  `qrcode_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '二维码内容（格式：HOSPITAL_NODE_{nodeId}），用于扫码定位',
  `qrcode_image_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '二维码图片存储路径',
  `qrcode_generated_at` timestamp NULL DEFAULT NULL COMMENT '二维码生成时间',
  `qrcode_status` enum('active','inactive','pending') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending' COMMENT '二维码状态：active=已激活，inactive=已停用，pending=待生成',
  PRIMARY KEY (`node_id`) USING BTREE,
  INDEX `idx_qrcode_content`(`qrcode_content` ASC) USING BTREE,
  INDEX `idx_qrcode_status`(`qrcode_status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '地图节点表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for medical_guidelines
-- ----------------------------
DROP TABLE IF EXISTS `medical_guidelines`;
CREATE TABLE `medical_guidelines`  (
  `guideline_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规范标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规范内容',
  `category` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '规范分类',
  `status` enum('active','inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '状态',
  `created_by` int NOT NULL COMMENT '创建人管理员ID',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`guideline_id`) USING BTREE,
  INDEX `fk_guidelines_created_by`(`created_by` ASC) USING BTREE,
  CONSTRAINT `fk_guidelines_created_by` FOREIGN KEY (`created_by`) REFERENCES `admins` (`admin_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '就医规范表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for notifications
-- ----------------------------
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications`  (
  `notification_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT '接收用户ID',
  `user_type` enum('patient','doctor','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户类型',
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知类型: appointment_reminder, cancellation, waitlist_available, schedule_change, system_notice等',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '通知内容',
  `related_entity` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '相关实体类型 (如: appointment, schedule)',
  `related_id` int NULL DEFAULT NULL COMMENT '相关实体ID',
  `status` enum('unread','read','deleted') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unread' COMMENT '通知状态',
  `priority` enum('low','normal','high','urgent') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal' COMMENT '优先级',
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  `read_at` datetime NULL DEFAULT NULL COMMENT '阅读时间',
  PRIMARY KEY (`notification_id`) USING BTREE,
  INDEX `idx_user`(`user_id` ASC, `user_type` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_sent_at`(`sent_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 69 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '通知消息表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for parent_departments
-- ----------------------------
DROP TABLE IF EXISTS `parent_departments`;
CREATE TABLE `parent_departments`  (
  `parent_department_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '父科室名称',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '科室职能描述',
  PRIMARY KEY (`parent_department_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1000 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '父科室表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for patient_profiles
-- ----------------------------
DROP TABLE IF EXISTS `patient_profiles`;
CREATE TABLE `patient_profiles`  (
  `patient_id` int NOT NULL COMMENT '患者ID',
  `id_card_number` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '身份证号, 建议加密存储',
  `allergies` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '过敏史, 建议加密存储',
  `medical_history` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '基础病史, 建议加密存储',
  `no_show_count` int NOT NULL DEFAULT 0 COMMENT '爽约次数',
  `blacklist_status` enum('normal','blacklisted') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal' COMMENT '黑名单状态',
  `birth_date` date NULL DEFAULT NULL COMMENT '出生日期',
  `gender` enum('male','female','other') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '性别',
  `home_address` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '家庭地址',
  `emergency_contact_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '紧急联系人姓名',
  `emergency_contact_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '紧急联系人电话',
  `height` decimal(5,2) NULL DEFAULT NULL COMMENT '身高(cm)',
  `weight` decimal(5,2) NULL DEFAULT NULL COMMENT '体重(kg)',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`patient_id`) USING BTREE,
  CONSTRAINT `fk_patient_profiles_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '患者信息扩展表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for patients
-- ----------------------------
DROP TABLE IF EXISTS `patients`;
CREATE TABLE `patients`  (
  `patient_id` int NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '学号或工号',
  `patient_type` enum('student','teacher','staff') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '患者类型',
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '真实姓名',
  `phone_number` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '存储E.164标准格式',
  `status` enum('active','inactive','locked','deleted') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '信息最后更新时间',
  PRIMARY KEY (`patient_id`) USING BTREE,
  UNIQUE INDEX `uk_patients_identifier`(`identifier` ASC) USING BTREE,
  UNIQUE INDEX `uk_patients_phone`(`phone_number` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '患者表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions`  (
  `permission_id` int NOT NULL AUTO_INCREMENT,
  `permission_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '权限名称',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '权限详细描述',
  PRIMARY KEY (`permission_id`) USING BTREE,
  UNIQUE INDEX `uk_permissions_name`(`permission_name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '权限表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for role_permissions
-- ----------------------------
DROP TABLE IF EXISTS `role_permissions`;
CREATE TABLE `role_permissions`  (
  `role_id` int NOT NULL COMMENT '角色ID',
  `permission_id` int NOT NULL COMMENT '权限ID',
  PRIMARY KEY (`role_id`, `permission_id`) USING BTREE,
  INDEX `fk_role_permissions_permission`(`permission_id` ASC) USING BTREE,
  CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`permission_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色-权限映射表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
  `role_id` int NOT NULL AUTO_INCREMENT,
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色名称',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '角色职责描述',
  PRIMARY KEY (`role_id`) USING BTREE,
  UNIQUE INDEX `uk_roles_name`(`role_name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '角色表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for schedules
-- ----------------------------
DROP TABLE IF EXISTS `schedules`;
CREATE TABLE `schedules`  (
  `schedule_id` int NOT NULL AUTO_INCREMENT,
  `doctor_id` int NOT NULL COMMENT '医生ID',
  `schedule_date` date NOT NULL COMMENT '出诊日期',
  `slot_id` int NOT NULL COMMENT '时间段ID',
  `location_id` int NOT NULL COMMENT '就诊地点ID',
  `total_slots` int NOT NULL COMMENT '总号源数',
  `booked_slots` int NOT NULL DEFAULT 0 COMMENT '已预约数',
  `fee` decimal(10, 2) NOT NULL DEFAULT 5.00 COMMENT '挂号费用',
  `status` enum('available','full','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'available' COMMENT '排班状态',
  `remarks` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '排班要求或备注信息',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_add_on_slot` tinyint(1) NULL DEFAULT 0 COMMENT '是否为加号虚拟号源（0=否，1=是）',
  `reserved_for_patient_id` bigint NULL DEFAULT NULL COMMENT '预留给指定患者ID（加号专用，锁定该号源）',
  `slot_application_id` int NULL DEFAULT NULL COMMENT '关联的加号申请ID（追溯来源）',
  PRIMARY KEY (`schedule_id`) USING BTREE,
  UNIQUE INDEX `uk_schedules_doctor_date_slot`(`doctor_id` ASC, `schedule_date` ASC, `slot_id` ASC) USING BTREE,
  INDEX `fk_schedules_slot`(`slot_id` ASC) USING BTREE,
  INDEX `fk_schedules_location`(`location_id` ASC) USING BTREE,
  INDEX `idx_reserved_patient`(`reserved_for_patient_id` ASC) USING BTREE,
  INDEX `idx_slot_application`(`slot_application_id` ASC) USING BTREE,
  CONSTRAINT `fk_schedule_slot_application` FOREIGN KEY (`slot_application_id`) REFERENCES `slot_application` (`application_id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_schedules_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_schedules_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_schedules_slot` FOREIGN KEY (`slot_id`) REFERENCES `time_slots` (`slot_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 322 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '医生排班表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for slot_application
-- ----------------------------
DROP TABLE IF EXISTS `slot_application`;
CREATE TABLE `slot_application`  (
  `application_id` int NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `doctor_id` int NOT NULL COMMENT '申请医生ID',
  `schedule_id` int NOT NULL COMMENT '关联的排班ID（必填，从医生排班中选择）',
  `added_slots` int NOT NULL COMMENT '加号数量',
  `patient_id` int NOT NULL COMMENT '指定患者ID（必填）',
  `urgency_level` enum('LOW','MEDIUM','HIGH','CRITICAL') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MEDIUM' COMMENT '紧急程度',
  `reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '申请理由',
  `status` enum('PENDING','APPROVED','REJECTED','CANCELLED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING' COMMENT '审批状态',
  `approver_id` int NULL DEFAULT NULL COMMENT '审批人ID',
  `approver_comments` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '审批意见',
  `approved_at` timestamp NULL DEFAULT NULL COMMENT '审批时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `appointment_id` int NULL DEFAULT NULL COMMENT '关联生成的预约ID（审批通过后自动创建）',
  PRIMARY KEY (`application_id`) USING BTREE,
  INDEX `idx_doctor_id`(`doctor_id` ASC) USING BTREE,
  INDEX `idx_schedule_id`(`schedule_id` ASC) USING BTREE,
  INDEX `idx_patient_id`(`patient_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_created_at`(`created_at` ASC) USING BTREE,
  INDEX `fk_slot_application_approver`(`approver_id` ASC) USING BTREE,
  INDEX `idx_appointment`(`appointment_id` ASC) USING BTREE,
  CONSTRAINT `fk_slot_application_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments` (`appointment_id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_slot_application_approver` FOREIGN KEY (`approver_id`) REFERENCES `admins` (`admin_id`) ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT `fk_slot_application_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_slot_application_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_slot_application_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `chk_added_slots` CHECK ((`added_slots` >= 1) and (`added_slots` <= 20))
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '加号申请表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for symptom_department_mapping
-- ----------------------------
DROP TABLE IF EXISTS `symptom_department_mapping`;
CREATE TABLE `symptom_department_mapping`  (
  `mapping_id` int NOT NULL AUTO_INCREMENT,
  `symptom_keywords` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '症状关键词',
  `department_id` int NOT NULL COMMENT '推荐科室',
  `priority` int NOT NULL DEFAULT 1 COMMENT '推荐优先级',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`mapping_id`) USING BTREE,
  INDEX `fk_symptom_mapping_department`(`department_id` ASC) USING BTREE,
  CONSTRAINT `fk_symptom_mapping_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '症状-科室映射表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for symptom_synonyms
-- ----------------------------
DROP TABLE IF EXISTS `symptom_synonyms`;
CREATE TABLE `symptom_synonyms`  (
  `synonym_id` int NOT NULL AUTO_INCREMENT,
  `symptom_keyword` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '症状关键词',
  `synonym` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '同义词',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`synonym_id`) USING BTREE,
  INDEX `idx_symptom_keyword`(`symptom_keyword` ASC) USING BTREE,
  INDEX `idx_synonym`(`synonym` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '症状同义词表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for time_slots
-- ----------------------------
DROP TABLE IF EXISTS `time_slots`;
CREATE TABLE `time_slots`  (
  `slot_id` int NOT NULL AUTO_INCREMENT,
  `slot_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '时段名称',
  `start_time` time NOT NULL COMMENT '开始时间',
  `end_time` time NOT NULL COMMENT '结束时间',
  PRIMARY KEY (`slot_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '固定时间段表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for waitlist
-- ----------------------------
DROP TABLE IF EXISTS `waitlist`;
CREATE TABLE `waitlist`  (
  `waitlist_id` int NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL COMMENT '患者ID',
  `schedule_id` int NOT NULL COMMENT '排班ID',
  `status` enum('waiting','notified','expired','booked') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'waiting' COMMENT '候补状态',
  `notification_sent_at` datetime NULL DEFAULT NULL COMMENT '系统发送通知的时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入队列的时间',
  PRIMARY KEY (`waitlist_id`) USING BTREE,
  INDEX `fk_waitlist_patient`(`patient_id` ASC) USING BTREE,
  INDEX `fk_waitlist_schedule`(`schedule_id` ASC) USING BTREE,
  CONSTRAINT `fk_waitlist_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_waitlist_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '候补表' ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
