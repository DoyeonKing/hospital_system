-- ========================================
-- 完整修复 admin_id=5 的角色和权限配置
-- ========================================

-- 步骤1: 检查当前状态
SELECT '=== 修复前的状态 ===' AS step;
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    GROUP_CONCAT(DISTINCT r.role_name ORDER BY r.role_name) AS current_roles,
    GROUP_CONCAT(DISTINCT p.permission_name ORDER BY p.permission_name) AS current_permissions
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
GROUP BY a.admin_id, a.username, a.full_name;

-- 步骤2: 清除现有的角色分配
SELECT '=== 清除现有角色分配 ===' AS step;
DELETE FROM admin_roles WHERE admin_id = 5;

-- 步骤3: 检查角色是否存在
SELECT '=== 检查角色 ===' AS step;
SELECT role_id, role_name, description FROM roles WHERE role_id IN (2, 3);

-- 步骤4: 如果角色不存在，创建它们
INSERT IGNORE INTO roles (role_id, role_name, description) VALUES
(2, 'medical_admin', '医务管理员，负责医生和排班管理'),
(3, 'financial_admin', '财务管理员，负责财务和报表管理');

-- 步骤5: 检查权限是否存在
SELECT '=== 检查权限 ===' AS step;
SELECT permission_id, permission_name, description FROM permissions 
WHERE permission_id IN (2, 4, 5, 6, 9, 10);

-- 步骤6: 如果权限不存在，创建它们
INSERT IGNORE INTO permissions (permission_id, permission_name, description) VALUES
(2, 'doctor_manage', '医生管理权限'),
(4, 'schedule_manage', '排班管理权限'),
(5, 'appointment_manage', '预约管理权限'),
(6, 'financial_manage', '财务管理权限'),
(9, 'audit_log_view', '审计日志查看权限'),
(10, 'report_generate', '报表生成权限');

-- 步骤7: 配置角色权限映射
SELECT '=== 配置角色权限 ===' AS step;
-- 医务管理员的权限
INSERT IGNORE INTO role_permissions (role_id, permission_id) VALUES
(2, 2),  -- doctor_manage
(2, 4),  -- schedule_manage
(2, 5),  -- appointment_manage
(2, 9);  -- audit_log_view

-- 财务管理员的权限
INSERT IGNORE INTO role_permissions (role_id, permission_id) VALUES
(3, 6),  -- financial_manage
(3, 10); -- report_generate

-- 步骤8: 为 admin_id=5 分配角色
SELECT '=== 分配角色给管理员 ===' AS step;
INSERT INTO admin_roles (admin_id, role_id) VALUES
(5, 2),  -- 医务管理员
(5, 3);  -- 财务管理员

-- 步骤9: 验证修复结果
SELECT '=== 修复后的状态 ===' AS step;
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    GROUP_CONCAT(DISTINCT r.role_name ORDER BY r.role_name) AS roles,
    GROUP_CONCAT(DISTINCT p.permission_name ORDER BY p.permission_name) AS permissions
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
GROUP BY a.admin_id, a.username, a.full_name;

-- 步骤10: 详细验证每个角色的权限
SELECT '=== 详细权限列表 ===' AS step;
SELECT 
    a.admin_id,
    a.username,
    r.role_name,
    p.permission_name,
    p.description
FROM admins a
INNER JOIN admin_roles ar ON a.admin_id = ar.admin_id
INNER JOIN roles r ON ar.role_id = r.role_id
INNER JOIN role_permissions rp ON r.role_id = rp.role_id
INNER JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
ORDER BY r.role_name, p.permission_name;

-- 预期结果：
-- admin_id=5 应该拥有以下权限：
-- 1. appointment_manage (预约管理)
-- 2. audit_log_view (审计日志查看)
-- 3. doctor_manage (医生管理)
-- 4. financial_manage (财务管理)
-- 5. report_generate (报表生成)
-- 6. schedule_manage (排班管理)
