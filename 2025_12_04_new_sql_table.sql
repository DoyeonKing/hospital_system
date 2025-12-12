SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. Table structure for parent_departments (父科室表)
-- ----------------------------
DROP TABLE IF EXISTS `parent_departments`;
CREATE TABLE `parent_departments` (
  `parent_department_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '父科室名称',
  `description` text COMMENT '科室职能描述',
  PRIMARY KEY (`parent_department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='一级/父级科室表';

-- ----------------------------
-- 2. Table structure for departments (子科室表)
-- ----------------------------
DROP TABLE IF EXISTS `departments`;
CREATE TABLE `departments` (
  `department_id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL COMMENT '父科室ID',
  `name` varchar(100) NOT NULL COMMENT '子科室名称',
  `description` text COMMENT '科室职能描述',
  PRIMARY KEY (`department_id`),
  KEY `fk_departments_parent` (`parent_id`),
  CONSTRAINT `fk_departments_parent` FOREIGN KEY (`parent_id`) REFERENCES `parent_departments` (`parent_department_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='具体科室表';

-- ----------------------------
-- 3. Table structure for admins (管理员表)
-- ----------------------------
DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins` (
  `admin_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL COMMENT '管理员登录用户名',
  `password_hash` varchar(255) NOT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) DEFAULT NULL COMMENT '管理员真实姓名',
  `status` enum('active','inactive','locked') DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  PRIMARY KEY (`admin_id`),
  UNIQUE KEY `uk_admins_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

-- ----------------------------
-- 4. Table structure for roles (角色表)
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(50) NOT NULL COMMENT '角色名称',
  `description` text COMMENT '角色职责描述',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_roles_name` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

-- ----------------------------
-- 5. Table structure for admin_roles (管理员-角色关联表)
-- ----------------------------
DROP TABLE IF EXISTS `admin_roles`;
CREATE TABLE `admin_roles` (
  `admin_id` int(11) NOT NULL COMMENT '管理员ID',
  `role_id` int(11) NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`admin_id`, `role_id`),
  KEY `fk_admin_roles_role` (`role_id`),
  CONSTRAINT `fk_admin_roles_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`admin_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_admin_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员角色关联表';

-- ----------------------------
-- 6. Table structure for permissions (权限表)
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
  `permission_id` int(11) NOT NULL AUTO_INCREMENT,
  `permission_name` varchar(100) NOT NULL COMMENT '权限名称',
  `description` text COMMENT '权限详细描述',
  PRIMARY KEY (`permission_id`),
  UNIQUE KEY `uk_permissions_name` (`permission_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限表';

-- ----------------------------
-- 7. Table structure for role_permissions (角色-权限关联表)
-- ----------------------------
DROP TABLE IF EXISTS `role_permissions`;
CREATE TABLE `role_permissions` (
  `role_id` int(11) NOT NULL COMMENT '角色ID',
  `permission_id` int(11) NOT NULL COMMENT '权限ID',
  PRIMARY KEY (`role_id`, `permission_id`),
  KEY `fk_role_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_role_permissions_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_role_permissions_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`permission_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';

-- ----------------------------
-- 8. Table structure for patients (患者表)
-- ----------------------------
DROP TABLE IF EXISTS `patients`;
CREATE TABLE `patients` (
  `patient_id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL COMMENT '学号或工号',
  `patient_type` enum('student','teacher','staff') NOT NULL COMMENT '患者类型',
  `password_hash` varchar(255) DEFAULT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) NOT NULL COMMENT '真实姓名',
  `phone_number` varchar(20) DEFAULT NULL COMMENT '存储E.164标准格式',
  `status` enum('active','inactive','locked','deleted') DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '信息最后更新时间',
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `uk_patients_identifier` (`identifier`),
  UNIQUE KEY `uk_patients_phone` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='患者基本信息表';

-- ----------------------------
-- 9. Table structure for patient_profiles (患者健康档案表)
-- ----------------------------
DROP TABLE IF EXISTS `patient_profiles`;
CREATE TABLE `patient_profiles` (
  `patient_id` int(11) NOT NULL COMMENT '患者ID',
  `id_card_number` varchar(18) DEFAULT NULL COMMENT '身份证号,建议加密存储',
  `allergies` text COMMENT '过敏史,建议加密存储',
  `medical_history` text COMMENT '基础病史,建议加密存储',
  `no_show_count` int(11) DEFAULT '0' COMMENT '爽约次数',
  `blacklist_status` enum('normal','blacklisted') DEFAULT 'normal' COMMENT '黑名单状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`patient_id`),
  CONSTRAINT `fk_profiles_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='患者健康档案扩展表';

-- ----------------------------
-- 10. Table structure for doctors (医生表)
-- ----------------------------
DROP TABLE IF EXISTS `doctors`;
CREATE TABLE `doctors` (
  `doctor_id` int(11) NOT NULL AUTO_INCREMENT,
  `department_id` int(11) NOT NULL COMMENT '所属科室',
  `identifier` varchar(100) NOT NULL COMMENT '医生的工号',
  `password_hash` varchar(255) DEFAULT NULL COMMENT '哈希加盐后的密码',
  `full_name` varchar(100) NOT NULL COMMENT '真实姓名',
  `id_card_number` varchar(18) DEFAULT NULL COMMENT '身份证号,建议加密',
  `phone_number` varchar(20) DEFAULT NULL COMMENT '存储E.164标准格式',
  `title` varchar(100) DEFAULT NULL COMMENT '职称',
  `title_level` tinyint(3) unsigned DEFAULT NULL COMMENT '职称等级:0-主任医师,1-副主任医师,2-主治医师',
  `specialty` tinytext COMMENT '擅长领域',
  `bio` tinytext COMMENT '简介',
  `photo_url` varchar(255) DEFAULT NULL COMMENT '头像照片URL',
  `status` enum('active','inactive','locked','deleted') DEFAULT 'active' COMMENT '账户状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账户创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '信息最后更新时间',
  PRIMARY KEY (`doctor_id`),
  UNIQUE KEY `uk_doctors_identifier` (`identifier`),
  UNIQUE KEY `uk_doctors_id_card` (`id_card_number`),
  UNIQUE KEY `uk_doctors_phone` (`phone_number`),
  KEY `fk_doctors_department` (`department_id`),
  CONSTRAINT `fk_doctors_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='医生信息表';

-- ----------------------------
-- 11. Table structure for map_nodes (地图节点表)
-- ----------------------------
DROP TABLE IF EXISTS `map_nodes`;
CREATE TABLE `map_nodes` (
  `node_id` int(11) NOT NULL AUTO_INCREMENT,
  `node_name` varchar(100) DEFAULT NULL COMMENT '节点名称',
  `node_type` enum('room','hallway','elevator','stairs','entrance') DEFAULT NULL COMMENT '节点类型',
  `coordinates_x` decimal(10,2) DEFAULT NULL COMMENT 'x坐标',
  `coordinates_y` decimal(10,2) DEFAULT NULL COMMENT 'y坐标',
  `floor_level` int(11) DEFAULT NULL COMMENT '楼层',
  `description` text COMMENT '节点描述',
  `is_accessible` tinyint(1) DEFAULT '0' COMMENT '是否无障碍通行',
  `qrcode_content` varchar(255) DEFAULT NULL COMMENT '二维码内容(格式:HOSPITAL_NODE_{nodeId})',
  `qrcode_image_path` varchar(500) DEFAULT NULL COMMENT '二维码图片存储路径',
  `qrcode_generated_at` timestamp NULL DEFAULT NULL COMMENT '二维码生成时间',
  `qrcode_status` enum('active','inactive','pending') DEFAULT 'active' COMMENT '二维码状态',
  PRIMARY KEY (`node_id`),
  KEY `idx_qrcode_content` (`qrcode_content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地图节点表';

-- ----------------------------
-- 12. Table structure for map_edges (地图路径边表)
-- ----------------------------
DROP TABLE IF EXISTS `map_edges`;
CREATE TABLE `map_edges` (
  `edge_id` int(11) NOT NULL AUTO_INCREMENT,
  `start_node_id` int(11) NOT NULL COMMENT '起始节点',
  `end_node_id` int(11) NOT NULL COMMENT '结束节点',
  `distance` decimal(10,2) DEFAULT NULL COMMENT '距离(米)',
  `walk_time` int(11) DEFAULT NULL COMMENT '步行时间(秒)',
  `is_bidirectional` tinyint(1) DEFAULT '1' COMMENT '是否双向通行',
  `accessibility_info` text COMMENT '无障碍设施信息',
  PRIMARY KEY (`edge_id`),
  KEY `fk_edges_start_node` (`start_node_id`),
  KEY `fk_edges_end_node` (`end_node_id`),
  CONSTRAINT `fk_edges_end_node` FOREIGN KEY (`end_node_id`) REFERENCES `map_nodes` (`node_id`),
  CONSTRAINT `fk_edges_start_node` FOREIGN KEY (`start_node_id`) REFERENCES `map_nodes` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地图路径/边表';

-- ----------------------------
-- 13. Table structure for locations (诊室地点表)
-- ----------------------------
DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
  `location_id` int(11) NOT NULL AUTO_INCREMENT,
  `location_name` varchar(100) NOT NULL COMMENT '诊室名称,如:门诊楼201室',
  `department_id` int(11) NOT NULL COMMENT '所属科室',
  `floor_level` int(11) DEFAULT NULL COMMENT '楼层',
  `building` varchar(50) DEFAULT NULL COMMENT '楼栋',
  `room_number` varchar(20) DEFAULT NULL COMMENT '房间号',
  `capacity` int(11) DEFAULT NULL COMMENT '容纳人数',
  `map_node_id` int(11) DEFAULT NULL COMMENT '对应的地图节点',
  PRIMARY KEY (`location_id`),
  KEY `fk_locations_department` (`department_id`),
  KEY `fk_locations_map_node` (`map_node_id`),
  CONSTRAINT `fk_locations_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`),
  CONSTRAINT `fk_locations_map_node` FOREIGN KEY (`map_node_id`) REFERENCES `map_nodes` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='诊室/地点表';

-- ----------------------------
-- 14. Table structure for time_slots (时间段字典表)
-- ----------------------------
DROP TABLE IF EXISTS `time_slots`;
CREATE TABLE `time_slots` (
  `slot_id` int(11) NOT NULL AUTO_INCREMENT,
  `slot_name` varchar(100) DEFAULT NULL COMMENT '时段名称',
  `start_time` time NOT NULL COMMENT '开始时间',
  `end_time` time NOT NULL COMMENT '结束时间',
  PRIMARY KEY (`slot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排班时间段字典表';

-- ----------------------------
-- 15. Table structure for schedules (排班表)
-- ----------------------------
DROP TABLE IF EXISTS `schedules`;
CREATE TABLE `schedules` (
  `schedule_id` int(11) NOT NULL AUTO_INCREMENT,
  `doctor_id` int(11) NOT NULL COMMENT '医生ID',
  `schedule_date` date NOT NULL COMMENT '出诊日期',
  `slot_id` int(11) NOT NULL COMMENT '时间段ID',
  `location_id` int(11) NOT NULL COMMENT '就诊地点ID',
  `total_slots` int(11) NOT NULL COMMENT '总号源数',
  `booked_slots` int(11) DEFAULT '0' COMMENT '已预约数',
  `fee` decimal(10,2) NOT NULL COMMENT '挂号费用',
  `status` enum('available','full','cancelled') DEFAULT 'available' COMMENT '排班状态',
  `remarks` text COMMENT '排班要求或备注信息',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`schedule_id`),
  UNIQUE KEY `uk_schedules_doctor_date_slot` (`doctor_id`,`schedule_date`,`slot_id`),
  KEY `fk_schedules_slot` (`slot_id`),
  KEY `fk_schedules_location` (`location_id`),
  CONSTRAINT `fk_schedules_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`),
  CONSTRAINT `fk_schedules_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`),
  CONSTRAINT `fk_schedules_slot` FOREIGN KEY (`slot_id`) REFERENCES `time_slots` (`slot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排班表';

-- ----------------------------
-- 16. Table structure for appointments (预约/挂号表)
-- ----------------------------
DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments` (
  `appointment_id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_id` int(11) NOT NULL COMMENT '患者ID',
  `schedule_id` int(11) NOT NULL COMMENT '排班ID',
  `appointment_number` int(11) NOT NULL COMMENT '就诊序号',
  `status` enum('PENDING PAYMENT','scheduled','CHECKED IN','completed','cancelled','NC') DEFAULT 'PENDING PAYMENT',
  `payment_status` enum('unpaid','paid','refunded') DEFAULT 'unpaid' COMMENT '支付状态',
  `payment_method` varchar(50) DEFAULT NULL COMMENT '支付方式',
  `transaction_id` varchar(255) DEFAULT NULL COMMENT '支付流水号',
  `check_in_time` datetime DEFAULT NULL COMMENT '现场签到时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '预约生成时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '最后更新时间(status变为completed时由触发器更新)',
  `called_at` datetime DEFAULT NULL COMMENT '叫号时间(NULL表示未叫号)',
  `is_on_time` tinyint(1) DEFAULT NULL COMMENT '是否按时签到(预约时段开始后20分钟内)',
  `missed_call_count` int(11) DEFAULT '0' COMMENT '过号次数',
  `recheck_in_time` datetime DEFAULT NULL COMMENT '过号后重新签到时间',
  `is_walk_in` tinyint(1) DEFAULT '0' COMMENT '是否现场挂号(0=预约,1=现场挂号)',
  `real_time_queue_number` int(11) DEFAULT NULL COMMENT '实时候诊序号(在时段内按签到时间分配)',
  `is_late` tinyint(1) DEFAULT '0' COMMENT '是否迟到(超过时段结束时间+软关门时间)',
  `appointment_type` enum('APPOINTMENT','WALK IN','SAME DAY FOLLOW UP','ADD ON') DEFAULT 'APPOINTMENT' COMMENT '预约类型',
  `original_appointment_id` int(11) DEFAULT NULL COMMENT '原始预约ID(用于复诊号关联,复诊号关联到原始预约)',
  `is_add_on` tinyint(1) DEFAULT '0' COMMENT '是否加号',
  `payment_deadline` datetime DEFAULT NULL COMMENT '支付截止时间(加号专用)',
  PRIMARY KEY (`appointment_id`),
  KEY `fk_appointments_patient` (`patient_id`),
  KEY `fk_appointments_schedule` (`schedule_id`),
  KEY `idx_is_on_time` (`is_on_time`),
  KEY `idx_recheck_in_time` (`recheck_in_time`),
  KEY `idx_is_walk_in` (`is_walk_in`),
  KEY `idx_real_time_queue_number` (`real_time_queue_number`),
  KEY `idx_appointment_type` (`appointment_type`),
  KEY `idx_original_appointment_id` (`original_appointment_id`),
  KEY `idx_payment_deadline` (`payment_deadline`),
  CONSTRAINT `fk_appointments_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`),
  CONSTRAINT `fk_appointments_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预约记录表';

-- ----------------------------
-- 17. Table structure for waitlist (候补队列表)
-- ----------------------------
DROP TABLE IF EXISTS `waitlist`;
CREATE TABLE `waitlist` (
  `waitlist_id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_id` int(11) NOT NULL COMMENT '患者ID',
  `schedule_id` int(11) NOT NULL COMMENT '排班ID',
  `status` enum('waiting','notified','expired','booked') DEFAULT 'waiting' COMMENT '候补状态',
  `notification_sent_at` datetime DEFAULT NULL COMMENT '系统发送通知的时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入队列的时间',
  PRIMARY KEY (`waitlist_id`),
  KEY `fk_waitlist_patient` (`patient_id`),
  KEY `fk_waitlist_schedule` (`schedule_id`),
  CONSTRAINT `fk_waitlist_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`),
  CONSTRAINT `fk_waitlist_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='候补队列表';

-- ----------------------------
-- 18. Table structure for leave_requests (医生请假表)
-- ----------------------------
DROP TABLE IF EXISTS `leave_requests`;
CREATE TABLE `leave_requests` (
  `request_id` int(11) NOT NULL AUTO_INCREMENT,
  `doctor_id` int(11) NOT NULL COMMENT '申请人医生ID',
  `request_type` enum('leave','schedule_change') NOT NULL COMMENT '申请类型',
  `start_time` datetime NOT NULL COMMENT '申请开始时间',
  `end_time` datetime NOT NULL COMMENT '申请结束时间',
  `reason` text COMMENT '申请事由',
  `proof_document_url` varchar(500) DEFAULT NULL COMMENT '证明文件URL',
  `status` enum('pending','approved','rejected') DEFAULT 'pending' COMMENT '审批状态',
  `approver_id` int(11) DEFAULT NULL COMMENT '审批人管理员ID',
  `approver_comments` text COMMENT '审批人员的意见或备注',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '申请更新时间',
  PRIMARY KEY (`request_id`),
  KEY `fk_leave_requests_doctor` (`doctor_id`),
  KEY `fk_leave_requests_approver` (`approver_id`),
  CONSTRAINT `fk_leave_requests_approver` FOREIGN KEY (`approver_id`) REFERENCES `admins` (`admin_id`),
  CONSTRAINT `fk_leave_requests_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`doctor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='医生请假申请表';

-- ----------------------------
-- 19. Table structure for medical_guidelines (医疗规范表)
-- ----------------------------
DROP TABLE IF EXISTS `medical_guidelines`;
CREATE TABLE `medical_guidelines` (
  `guideline_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL COMMENT '规范标题',
  `content` mediumtext COMMENT '规范内容',
  `category` varchar(100) DEFAULT NULL COMMENT '规范分类',
  `status` enum('active','inactive') DEFAULT 'active' COMMENT '状态',
  `created_by` int(11) DEFAULT NULL COMMENT '创建人管理员ID',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`guideline_id`),
  KEY `fk_guidelines_created_by` (`created_by`),
  CONSTRAINT `fk_guidelines_created_by` FOREIGN KEY (`created_by`) REFERENCES `admins` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='医疗规范表';

-- ----------------------------
-- 20. Table structure for audit_logs (审计日志表)
-- ----------------------------
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `actor_id` int(11) NOT NULL COMMENT '操作者ID',
  `actor_type` enum('patient','doctor','admin') NOT NULL COMMENT '操作者类型',
  `action` varchar(255) NOT NULL COMMENT '操作行为描述',
  `target_entity` varchar(100) DEFAULT NULL COMMENT '被操作对象所在的表名',
  `target_id` int(11) DEFAULT NULL COMMENT '被操作对象的ID',
  `details` text COMMENT '操作详细信息',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作发生时间',
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统审计日志表';

-- ----------------------------
-- 21. Table structure for notifications (系统通知表)
-- ----------------------------
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `notification_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '接收用户ID',
  `user_type` enum('patient','doctor','admin') NOT NULL COMMENT '用户类型',
  `type` varchar(50) DEFAULT NULL COMMENT '通知类型: appointment_reminder, cancellation, waitlist_available',
  `title` varchar(200) DEFAULT NULL COMMENT '通知标题',
  `content` text COMMENT '通知内容',
  `related_entity` varchar(50) DEFAULT NULL COMMENT '相关实体类型(如:appointment, schedule)',
  `related_id` int(11) DEFAULT NULL COMMENT '相关实体ID',
  `status` enum('unread','read','deleted') DEFAULT 'unread' COMMENT '通知状态',
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal' COMMENT '优先级',
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  `read_at` datetime DEFAULT NULL COMMENT '阅读时间',
  PRIMARY KEY (`notification_id`),
  KEY `idx_user` (`user_id`,`user_type`),
  KEY `idx_status` (`status`),
  KEY `idx_sent_at` (`sent_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统通知表';

-- ----------------------------
-- 22. Table structure for symptom_department_mapping (症状-科室映射表)
-- ----------------------------
DROP TABLE IF EXISTS `symptom_department_mapping`;
CREATE TABLE `symptom_department_mapping` (
  `mapping_id` int(11) NOT NULL AUTO_INCREMENT,
  `symptom_keywords` varchar(255) NOT NULL COMMENT '症状关键词',
  `department_id` int(11) NOT NULL COMMENT '推荐科室',
  `priority` int(11) DEFAULT '0' COMMENT '推荐优先级',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`mapping_id`),
  KEY `fk_symptom_mapping_department` (`department_id`),
  CONSTRAINT `fk_symptom_mapping_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能导诊症状映射表';


SET FOREIGN_KEY_CHECKS = 1;








