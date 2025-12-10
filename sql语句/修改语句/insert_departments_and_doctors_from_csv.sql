-- =====================================================
-- 第一部分：插入父科室
-- =====================================================

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(100, '肿瘤科', '肿瘤科相关疾病诊疗');

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(101, '外科', '外科相关疾病诊疗');

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(102, '儿科', '儿科相关疾病诊疗');

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(103, '妇产科', '妇产科相关疾病诊疗');

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(104, '内科', '内科相关疾病诊疗');

INSERT IGNORE INTO `parent_departments` (`parent_department_id`, `name`, `description`) VALUES
(105, '男科', '男科相关疾病诊疗');

-- =====================================================
-- 第二部分：插入子科室
-- =====================================================

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(100, 100, '甲状腺癌', '甲状腺癌主要诊治甲状腺癌、甲状腺结节、甲状腺功能亢进、甲状腺功能减退、甲状腺炎、甲状腺肿大、甲状腺囊肿等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(101, 100, '结肠癌', '结肠癌主要诊治结肠癌、结肠息肉、结肠炎、结肠溃疡、肠易激综合征、结肠出血、结肠梗阻等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(102, 100, '肺癌', '肺癌主要诊治肺癌、肺结节、肺炎、肺结核、肺气肿、支气管炎、哮喘等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(103, 100, '乳腺癌', '乳腺癌主要诊治乳腺癌、乳腺增生、乳腺炎、乳腺纤维瘤、乳腺囊肿、乳腺疼痛、乳头溢液等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(104, 100, '宫颈癌', '宫颈癌主要诊治宫颈癌、宫颈炎、宫颈糜烂、宫颈息肉、宫颈囊肿、宫颈肥大、宫颈病变等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(105, 100, '骨癌', '骨癌主要诊治骨癌、骨肿瘤、骨转移、骨痛、病理性骨折、骨破坏、骨增生等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(106, 100, '胃癌', '胃癌主要诊治胃癌、胃溃疡、胃炎、胃息肉、胃出血、胃穿孔、胃肿瘤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(107, 100, '肝癌', '肝癌主要诊治肝癌、肝炎、肝硬化、肝囊肿、肝血管瘤、肝腹水、肝功能异常等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(108, 100, '食管癌', '食管癌主要诊治食管癌、食管炎、食管溃疡、食管狭窄、食管息肉、食管出血、食管肿瘤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(109, 100, '淋巴瘤', '淋巴瘤主要诊治淋巴瘤、淋巴结肿大、淋巴系统疾病、霍奇金淋巴瘤、非霍奇金淋巴瘤、淋巴癌、淋巴系统肿瘤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(110, 101, '肛肠', '肛肠是外科的一个分支，主要诊治痔疮、肛裂、肛瘘、肛周脓肿、直肠脱垂、便秘、便血等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(111, 101, '普通外科', '普通外科是外科的一个分支，主要诊治阑尾炎、疝气、胆囊炎、胆结石、胰腺炎、腹膜炎、肠梗阻等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(112, 101, '肝胆', '肝胆是外科的一个分支，主要诊治肝炎、肝硬化、肝癌、胆囊炎、胆结石、肝囊肿、肝血管瘤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(113, 101, '骨科', '骨科是外科的一个分支，主要诊治骨折、关节炎、骨质疏松、腰椎间盘突出、颈椎病、骨刺、关节损伤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(114, 101, '泌尿外科', '泌尿外科是外科的一个分支，主要诊治肾结石、输尿管结石、膀胱结石、前列腺增生、肾肿瘤、膀胱肿瘤、泌尿系统肿瘤等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(115, 102, '营养发育科', '营养发育科主要诊治儿童肥胖、营养不良、生长发育迟缓、佝偻病、缺铁性贫血、维生素缺乏、生长激素缺乏等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(116, 102, '耳鼻喉科', '耳鼻喉科主要诊治儿童鼻炎、儿童中耳炎、儿童扁桃体炎、儿童腺样体肥大、儿童听力障碍、儿童鼻窦炎、儿童咽喉炎等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(117, 103, '妇科', '妇科主要诊治月经不调、痛经、子宫肌瘤、卵巢囊肿、盆腔炎、阴道炎、宫颈炎等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(118, 103, '生殖医学', '生殖医学主要诊治不孕不育、多囊卵巢综合征、输卵管堵塞、排卵障碍、习惯性流产、子宫内膜异位、卵巢早衰等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(119, 103, '计划生育', '计划生育主要诊治人工流产、药物流产、避孕咨询、节育环、避孕药、紧急避孕、绝育手术等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(120, 103, '产科', '产科主要诊治妊娠高血压、妊娠糖尿病、先兆流产、早产、胎位不正、羊水异常、产前检查等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(121, 104, '心血管科', '心血管科是内科的一个分支，主要诊治高血压、冠心病、心绞痛、心律失常、心力衰竭、心肌梗死、动脉硬化等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(122, 104, '内分泌科', '内分泌科是内科的一个分支，主要诊治糖尿病、甲状腺功能亢进、甲状腺功能减退、肥胖症、高血脂、痛风、骨质疏松等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(123, 104, '消化科', '消化科是内科的一个分支，主要诊治胃炎、胃溃疡、胃食管反流、肝炎、肝硬化、肠炎、胰腺炎等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(124, 104, '神经科', '神经科是内科的一个分支，主要诊治头痛、偏头痛、脑血管疾病、癫痫、帕金森病、阿尔茨海默病、周围神经病变等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(125, 104, '呼吸科', '呼吸科是内科的一个分支，主要诊治慢性阻塞性肺疾病、支气管哮喘、肺炎、肺结核、过敏性鼻炎、支气管炎、肺气肿等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(126, 105, '早泄', '早泄主要诊治早泄、射精过快、性功能障碍、勃起功能障碍、性欲减退、性心理障碍、性交疼痛等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(127, 105, '前列腺炎', '前列腺炎主要诊治前列腺炎、前列腺增生、前列腺癌、尿频、尿急、尿痛、排尿困难等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(128, 105, '泌尿系统感染', '泌尿系统感染主要诊治尿道炎、膀胱炎、肾盂肾炎、尿路感染、尿路结石、血尿、蛋白尿等疾病。');

INSERT IGNORE INTO `departments` (`department_id`, `parent_id`, `name`, `description`) VALUES
(129, 105, '勃起功能障碍', '勃起功能障碍主要诊治勃起功能障碍、阳痿、性功能障碍、性欲减退、早泄、射精障碍、性心理问题等疾病。');

-- =====================================================
-- 第三部分：插入医生（每个子科室2-3个医生）
-- =====================================================

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(100, 100, 'D10001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '张伟', '110101198010255178', '+8613846879745', '主任医师', '擅长甲状腺癌、甲状腺结节、甲状腺炎的诊治。', '从事甲状腺癌临床工作多年，经验丰富', '/images/doctors/张伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(101, 100, 'D10002', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '王芳', '110101199501038890', '+8613835624552', '副主任医师', '擅长甲状腺功能减退、甲状腺结节的诊治。', '从事甲状腺癌临床工作多年，经验丰富', '/images/doctors/王芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(102, 100, 'D10003', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '李强', '110101198702119660', '+8613845012857', '主治医师', '擅长甲状腺囊肿、甲状腺结节、甲状腺功能亢进的诊治。', '从事甲状腺癌临床工作多年，经验丰富', '/images/doctors/李强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(103, 101, 'D10101', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '刘敏', '110101199101099016', '+8613898266422', '主任医师', '擅长结肠息肉、结肠出血、肠易激综合征的诊治。', '从事结肠癌临床工作多年，经验丰富', '/images/doctors/刘敏.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(104, 101, 'D10102', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '陈静', '110101199411156642', '+8613815081191', '副主任医师', '擅长结肠出血、结肠炎的诊治。', '从事结肠癌临床工作多年，经验丰富', '/images/doctors/陈静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(105, 101, 'D10103', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '杨洋', '110101198502111212', '+8613835359621', '主治医师', '擅长结肠炎、结肠出血、肠易激综合征的诊治。', '从事结肠癌临床工作多年，经验丰富', '/images/doctors/杨洋.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(106, 102, 'D10201', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '赵磊', '110101198902117690', '+8613879857307', '主任医师', '擅长肺气肿、肺炎的诊治。', '从事肺癌临床工作多年，经验丰富', '/images/doctors/赵磊.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(107, 102, 'D10202', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '黄丽', '110101198212026244', '+8613880097260', '副主任医师', '擅长肺气肿、肺结核、肺癌的诊治。', '从事肺癌临床工作多年，经验丰富', '/images/doctors/黄丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(108, 102, 'D10203', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '周杰', '110101198609201391', '+8613833796140', '主治医师', '擅长肺结核、肺癌的诊治。', '从事肺癌临床工作多年，经验丰富', '/images/doctors/周杰.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(109, 103, 'D10301', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '吴娟', '110101198706258981', '+8613824478320', '主任医师', '擅长乳腺疼痛、乳腺纤维瘤、乳腺囊肿的诊治。', '从事乳腺癌临床工作多年，经验丰富', '/images/doctors/吴娟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(110, 103, 'D10302', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '徐明', '110101198012288031', '+8613865744171', '副主任医师', '擅长乳腺炎、乳腺纤维瘤的诊治。', '从事乳腺癌临床工作多年，经验丰富', '/images/doctors/徐明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(111, 104, 'D10401', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '孙丽', '110101199104202911', '+8613888444988', '主任医师', '擅长宫颈癌、宫颈炎的诊治。', '从事宫颈癌临床工作多年，经验丰富', '/images/doctors/孙丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(112, 104, 'D10402', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '马强', '110101198303055946', '+8613838675530', '副主任医师', '擅长宫颈囊肿、宫颈癌的诊治。', '从事宫颈癌临床工作多年，经验丰富', '/images/doctors/马强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(113, 104, 'D10403', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '朱红', '110101199411158176', '+8613889332224', '主治医师', '擅长宫颈糜烂、宫颈肥大、宫颈病变的诊治。', '从事宫颈癌临床工作多年，经验丰富', '/images/doctors/朱红.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(114, 105, 'D10501', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '胡军', '110101199205201357', '+8613851420487', '主任医师', '擅长骨转移、骨肿瘤、病理性骨折的诊治。', '从事骨癌临床工作多年，经验丰富', '/images/doctors/胡军.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(115, 105, 'D10502', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '林芳', '110101198102128778', '+8613832454340', '副主任医师', '擅长骨增生、骨癌的诊治。', '从事骨癌临床工作多年，经验丰富', '/images/doctors/林芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(116, 105, 'D10503', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '郭伟', '110101198812048506', '+8613856175210', '主治医师', '擅长骨增生、骨破坏、骨痛的诊治。', '从事骨癌临床工作多年，经验丰富', '/images/doctors/郭伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(117, 106, 'D10601', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '何静', '110101198512115183', '+8613825624735', '主任医师', '擅长胃溃疡、胃息肉的诊治。', '从事胃癌临床工作多年，经验丰富', '/images/doctors/何静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(118, 106, 'D10602', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '罗明', '110101198312016339', '+8613834005236', '副主任医师', '擅长胃肿瘤、胃癌的诊治。', '从事胃癌临床工作多年，经验丰富', '/images/doctors/罗明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(119, 107, 'D10701', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '高丽', '110101198603037972', '+8613868405099', '主任医师', '擅长肝炎、肝囊肿、肝腹水的诊治。', '从事肝癌临床工作多年，经验丰富', '/images/doctors/高丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(120, 107, 'D10702', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '梁强', '110101199502037969', '+8613899478101', '副主任医师', '擅长肝腹水、肝炎、肝癌的诊治。', '从事肝癌临床工作多年，经验丰富', '/images/doctors/梁强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(121, 107, 'D10703', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '韩敏', '110101199207075065', '+8613853676350', '主治医师', '擅长肝癌、肝硬化的诊治。', '从事肝癌临床工作多年，经验丰富', '/images/doctors/韩敏.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(122, 108, 'D10801', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '唐伟', '110101198906199147', '+8613858176925', '主任医师', '擅长食管癌、食管息肉、食管溃疡的诊治。', '从事食管癌临床工作多年，经验丰富', '/images/doctors/唐伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(123, 108, 'D10802', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '冯静', '110101198401031645', '+8613843978215', '副主任医师', '擅长食管癌、食管狭窄的诊治。', '从事食管癌临床工作多年，经验丰富', '/images/doctors/冯静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(124, 108, 'D10803', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '于明', '110101198412156847', '+8613827367046', '主治医师', '擅长食管癌、食管息肉、食管炎的诊治。', '从事食管癌临床工作多年，经验丰富', '/images/doctors/于明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(125, 109, 'D10901', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '董丽', '110101198007268004', '+8613879923134', '主任医师', '擅长淋巴系统肿瘤、淋巴结肿大、淋巴系统疾病的诊治。', '从事淋巴瘤临床工作多年，经验丰富', '/images/doctors/董丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(126, 109, 'D10902', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '袁强', '110101198204038728', '+8613881434733', '副主任医师', '擅长淋巴系统肿瘤、淋巴瘤、霍奇金淋巴瘤的诊治。', '从事淋巴瘤临床工作多年，经验丰富', '/images/doctors/袁强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(127, 110, 'D11001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '邓芳', '110101198102133146', '+8613849001375', '主任医师', '擅长痔疮、便血、肛裂的诊治。', '从事肛肠临床工作多年，经验丰富', '/images/doctors/邓芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(128, 110, 'D11002', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '许伟', '110101198312247230', '+8613840917119', '副主任医师', '擅长便秘、肛瘘的诊治。', '从事肛肠临床工作多年，经验丰富', '/images/doctors/许伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(129, 111, 'D11101', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '潘静', '110101198509269695', '+8613889232901', '主任医师', '擅长阑尾炎、胆囊炎的诊治。', '从事普通外科临床工作多年，经验丰富', '/images/doctors/潘静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(130, 111, 'D11102', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '宋明', '110101198305078538', '+8613824747426', '副主任医师', '擅长腹膜炎、胆结石的诊治。', '从事普通外科临床工作多年，经验丰富', '/images/doctors/宋明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(131, 112, 'D11201', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '郑丽', '110101198102194142', '+8613895256461', '主任医师', '擅长胆结石、肝炎、肝硬化的诊治。', '从事肝胆临床工作多年，经验丰富', '/images/doctors/郑丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(132, 112, 'D11202', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '谢强', '110101199101022731', '+8613892136275', '副主任医师', '擅长肝炎、肝癌的诊治。', '从事肝胆临床工作多年，经验丰富', '/images/doctors/谢强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(133, 113, 'D11301', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '曹芳', '110101198402228722', '+8613884226716', '主任医师', '擅长腰椎间盘突出、关节损伤、关节炎的诊治。', '从事骨科临床工作多年，经验丰富', '/images/doctors/曹芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(134, 113, 'D11302', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '魏伟', '110101199412051475', '+8613846492205', '副主任医师', '擅长关节炎、骨折、腰椎间盘突出的诊治。', '从事骨科临床工作多年，经验丰富', '/images/doctors/魏伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(135, 113, 'D11303', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '薛静', '110101198709096536', '+8613861820477', '主治医师', '擅长骨刺、腰椎间盘突出、关节炎的诊治。', '从事骨科临床工作多年，经验丰富', '/images/doctors/薛静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(136, 114, 'D11401', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '叶明', '110101198012276461', '+8613817173324', '主任医师', '擅长膀胱肿瘤、膀胱结石的诊治。', '从事泌尿外科临床工作多年，经验丰富', '/images/doctors/叶明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(137, 114, 'D11402', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '卢丽', '110101198404186530', '+8613834464618', '副主任医师', '擅长肾肿瘤、输尿管结石、膀胱肿瘤的诊治。', '从事泌尿外科临床工作多年，经验丰富', '/images/doctors/卢丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(138, 115, 'D11501', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '蒋强', '110101198101119896', '+8613815099747', '主任医师', '擅长维生素缺乏、缺铁性贫血、营养不良的诊治。', '从事营养发育科临床工作多年，经验丰富', '/images/doctors/蒋强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(139, 115, 'D11502', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '蔡芳', '110101199501098917', '+8613887705147', '副主任医师', '擅长佝偻病、生长发育迟缓的诊治。', '从事营养发育科临床工作多年，经验丰富', '/images/doctors/蔡芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(140, 115, 'D11503', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '张伟', '110101198105116070', '+8613830349018', '主治医师', '擅长缺铁性贫血、生长激素缺乏的诊治。', '从事营养发育科临床工作多年，经验丰富', '/images/doctors/张伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(141, 116, 'D11601', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '王芳', '110101198802283443', '+8613816126022', '主任医师', '擅长儿童扁桃体炎、儿童咽喉炎、儿童鼻窦炎的诊治。', '从事耳鼻喉科临床工作多年，经验丰富', '/images/doctors/王芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(142, 116, 'D11602', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '李强', '110101199203062167', '+8613835297684', '副主任医师', '擅长儿童咽喉炎、儿童鼻炎的诊治。', '从事耳鼻喉科临床工作多年，经验丰富', '/images/doctors/李强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(143, 117, 'D11701', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '刘敏', '110101198705039499', '+8613889315871', '主任医师', '擅长宫颈炎、月经不调、卵巢囊肿的诊治。', '从事妇科临床工作多年，经验丰富', '/images/doctors/刘敏.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(144, 117, 'D11702', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '陈静', '110101199203019211', '+8613831233101', '副主任医师', '擅长阴道炎、痛经、子宫肌瘤的诊治。', '从事妇科临床工作多年，经验丰富', '/images/doctors/陈静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(145, 118, 'D11801', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '杨洋', '110101199104193831', '+8613842078532', '主任医师', '擅长卵巢早衰、不孕不育、排卵障碍的诊治。', '从事生殖医学临床工作多年，经验丰富', '/images/doctors/杨洋.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(146, 118, 'D11802', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '赵磊', '110101198407238153', '+8613896457806', '副主任医师', '擅长卵巢早衰、输卵管堵塞的诊治。', '从事生殖医学临床工作多年，经验丰富', '/images/doctors/赵磊.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(147, 118, 'D11803', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '黄丽', '110101199510281633', '+8613870129373', '主治医师', '擅长子宫内膜异位、习惯性流产的诊治。', '从事生殖医学临床工作多年，经验丰富', '/images/doctors/黄丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(148, 119, 'D11901', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '周杰', '110101198812189828', '+8613893577877', '主任医师', '擅长绝育手术、人工流产、药物流产的诊治。', '从事计划生育临床工作多年，经验丰富', '/images/doctors/周杰.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(149, 119, 'D11902', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '吴娟', '110101199012105570', '+8613861150255', '副主任医师', '擅长避孕咨询、人工流产的诊治。', '从事计划生育临床工作多年，经验丰富', '/images/doctors/吴娟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(150, 120, 'D12001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '徐明', '110101199005247306', '+8613874209950', '主任医师', '擅长产前检查、妊娠高血压的诊治。', '从事产科临床工作多年，经验丰富', '/images/doctors/徐明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(151, 120, 'D12002', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '孙丽', '110101198604219064', '+8613888824885', '副主任医师', '擅长妊娠糖尿病、羊水异常的诊治。', '从事产科临床工作多年，经验丰富', '/images/doctors/孙丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(152, 121, 'D12101', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '马强', '110101199006232016', '+8613834528051', '主任医师', '擅长动脉硬化、心绞痛的诊治。', '从事心血管科临床工作多年，经验丰富', '/images/doctors/马强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(153, 121, 'D12102', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '朱红', '110101198106263356', '+8613834796086', '副主任医师', '擅长动脉硬化、心律失常、心力衰竭的诊治。', '从事心血管科临床工作多年，经验丰富', '/images/doctors/朱红.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(154, 121, 'D12103', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '胡军', '110101199407074051', '+8613863569810', '主治医师', '擅长心肌梗死、心力衰竭、冠心病的诊治。', '从事心血管科临床工作多年，经验丰富', '/images/doctors/胡军.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(155, 122, 'D12201', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '林芳', '110101199308079992', '+8613858426870', '主任医师', '擅长甲状腺功能亢进、高血脂的诊治。', '从事内分泌科临床工作多年，经验丰富', '/images/doctors/林芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(156, 122, 'D12202', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '郭伟', '110101199109214148', '+8613814555446', '副主任医师', '擅长甲状腺功能减退、糖尿病的诊治。', '从事内分泌科临床工作多年，经验丰富', '/images/doctors/郭伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(157, 123, 'D12301', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '何静', '110101198612222448', '+8613852140864', '主任医师', '擅长胃食管反流、胰腺炎的诊治。', '从事消化科临床工作多年，经验丰富', '/images/doctors/何静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(158, 123, 'D12302', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '罗明', '110101198812161165', '+8613865278915', '副主任医师', '擅长胃炎、肝硬化的诊治。', '从事消化科临床工作多年，经验丰富', '/images/doctors/罗明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(159, 124, 'D12401', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '高丽', '110101198112273461', '+8613883675269', '主任医师', '擅长头痛、帕金森病的诊治。', '从事神经科临床工作多年，经验丰富', '/images/doctors/高丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(160, 124, 'D12402', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '梁强', '110101199304066187', '+8613893304196', '副主任医师', '擅长头痛、阿尔茨海默病、癫痫的诊治。', '从事神经科临床工作多年，经验丰富', '/images/doctors/梁强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(161, 125, 'D12501', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '韩敏', '110101199311284360', '+8613851745425', '主任医师', '擅长过敏性鼻炎、肺炎、支气管炎的诊治。', '从事呼吸科临床工作多年，经验丰富', '/images/doctors/韩敏.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(162, 125, 'D12502', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '唐伟', '110101198801148410', '+8613892721929', '副主任医师', '擅长支气管哮喘、肺气肿的诊治。', '从事呼吸科临床工作多年，经验丰富', '/images/doctors/唐伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(163, 126, 'D12601', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '冯静', '110101198504103494', '+8613882774346', '主任医师', '擅长早泄、射精过快的诊治。', '从事早泄临床工作多年，经验丰富', '/images/doctors/冯静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(164, 126, 'D12602', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '于明', '110101199212191638', '+8613849439475', '副主任医师', '擅长性功能障碍、性欲减退、性交疼痛的诊治。', '从事早泄临床工作多年，经验丰富', '/images/doctors/于明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(165, 126, 'D12603', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '董丽', '110101199206146116', '+8613852712652', '主治医师', '擅长性心理障碍、射精过快、勃起功能障碍的诊治。', '从事早泄临床工作多年，经验丰富', '/images/doctors/董丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(166, 127, 'D12701', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '袁强', '110101198112014317', '+8613840448676', '主任医师', '擅长尿痛、前列腺增生、尿急的诊治。', '从事前列腺炎临床工作多年，经验丰富', '/images/doctors/袁强.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(167, 127, 'D12702', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '邓芳', '110101198809277451', '+8613836886212', '副主任医师', '擅长前列腺炎、前列腺增生的诊治。', '从事前列腺炎临床工作多年，经验丰富', '/images/doctors/邓芳.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(168, 127, 'D12703', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '许伟', '110101198104182200', '+8613895440279', '主治医师', '擅长排尿困难、尿频、前列腺炎的诊治。', '从事前列腺炎临床工作多年，经验丰富', '/images/doctors/许伟.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(169, 128, 'D12801', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '潘静', '110101198009159192', '+8613852045444', '主任医师', '擅长肾盂肾炎、尿道炎的诊治。', '从事泌尿系统感染临床工作多年，经验丰富', '/images/doctors/潘静.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(170, 128, 'D12802', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '宋明', '110101198112211546', '+8613892878656', '副主任医师', '擅长蛋白尿、尿路感染的诊治。', '从事泌尿系统感染临床工作多年，经验丰富', '/images/doctors/宋明.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(171, 129, 'D12901', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '郑丽', '110101199305253335', '+8613849404998', '主任医师', '擅长性欲减退、早泄的诊治。', '从事勃起功能障碍临床工作多年，经验丰富', '/images/doctors/郑丽.jpg', 'active');

INSERT IGNORE INTO `doctors` (`doctor_id`, `department_id`, `identifier`, `password_hash`, `full_name`, `id_card_number`, `phone_number`, `title`, `specialty`, `bio`, `photo_url`, `status`) VALUES
(172, 129, 'D12902', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '谢强', '110101199310023591', '+8613830460326', '副主任医师', '擅长早泄、性欲减退、勃起功能障碍的诊治。', '从事勃起功能障碍临床工作多年，经验丰富', '/images/doctors/谢强.jpg', 'active');
