-- ========================================
-- 修复 admin_id=5 的权限配置
-- ========================================

-- 1. 查看当前 admin_id=5 的信息
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    a.status,
    GROUP_CONCAT(DISTINCT r.role_name) AS roles,
    GROUP_CONCAT(DISTINCT p.permission_name) AS permissions
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
GROUP BY a.admin_id, a.username, a.full_name, a.status;

-- 2. 查看所有管理员的角色分配情况
SELECT 
    admin_id,
    role_id
FROM admin_roles
ORDER BY admin_id, role_id;

-- 3. 为 admin_id=5 分配角色
-- 根据实际数据库配置，admin_id=5 应该拥有 role_id=2 (医务管理员) 和 role_id=3 (财务管理员)

-- 先删除可能存在的旧配置
DELETE FROM admin_roles WHERE admin_id = 5;

-- 重新分配角色
INSERT INTO admin_roles (admin_id, role_id) VALUES
(5, 2),  -- 医务管理员
(5, 3);  -- 财务管理员

-- 4. 验证修复结果
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

-- 预期结果：
-- admin_id=5 应该拥有以下权限：
-- doctor_manage, schedule_manage, appointment_manage, audit_log_view, financial_manage, report_generate
