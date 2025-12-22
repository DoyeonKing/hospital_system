-- ========================================
-- 测试管理员权限功能的SQL查询
-- ========================================

-- 1. 查看所有管理员及其角色
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    GROUP_CONCAT(r.role_name) AS roles
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
GROUP BY a.admin_id, a.username, a.full_name
ORDER BY a.admin_id;

-- 2. 查看每个管理员拥有的权限
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    GROUP_CONCAT(DISTINCT p.permission_name ORDER BY p.permission_name) AS permissions
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
GROUP BY a.admin_id, a.username, a.full_name
ORDER BY a.admin_id;

-- 3. 查看 admin_id=1 的权限（超级管理员）
SELECT 
    a.admin_id,
    a.username,
    r.role_name,
    p.permission_name,
    p.description
FROM admins a
JOIN admin_roles ar ON a.admin_id = ar.admin_id
JOIN roles r ON ar.role_id = r.role_id
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 1
ORDER BY p.permission_name;

-- 4. 查看 admin_id=2 的权限（患者管理员）
SELECT 
    a.admin_id,
    a.username,
    r.role_name,
    p.permission_name,
    p.description
FROM admins a
JOIN admin_roles ar ON a.admin_id = ar.admin_id
JOIN roles r ON ar.role_id = r.role_id
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 2
ORDER BY p.permission_name;

-- 5. 查看 admin_id=3 的权限（系统操作员）
SELECT 
    a.admin_id,
    a.username,
    r.role_name,
    p.permission_name,
    p.description
FROM admins a
JOIN admin_roles ar ON a.admin_id = ar.admin_id
JOIN roles r ON ar.role_id = r.role_id
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 3
ORDER BY p.permission_name;

-- 6. 查看 admin_id=5 的权限（医务管理员 + 财务管理员）
SELECT 
    a.admin_id,
    a.username,
    r.role_name,
    p.permission_name,
    p.description
FROM admins a
JOIN admin_roles ar ON a.admin_id = ar.admin_id
JOIN roles r ON ar.role_id = r.role_id
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
ORDER BY r.role_name, p.permission_name;

-- 7. 查看所有角色及其权限
SELECT 
    r.role_id,
    r.role_name,
    r.description,
    GROUP_CONCAT(p.permission_name ORDER BY p.permission_name) AS permissions
FROM roles r
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
GROUP BY r.role_id, r.role_name, r.description
ORDER BY r.role_id;

-- 8. 检查是否有管理员没有分配角色
SELECT 
    a.admin_id,
    a.username,
    a.full_name
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
WHERE ar.role_id IS NULL;

-- 9. 检查是否有角色没有分配权限
SELECT 
    r.role_id,
    r.role_name,
    r.description
FROM roles r
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
WHERE rp.permission_id IS NULL;

-- ========================================
-- 预期测试结果
-- ========================================

/*
admin_id=1 应该拥有的权限（10个）:
- user_manage
- doctor_manage
- patient_manage
- schedule_manage
- appointment_manage
- financial_manage
- medical_guide_manage
- system_config
- audit_log_view
- report_generate

admin_id=2 应该拥有的权限（3个）:
- patient_manage
- appointment_manage
- audit_log_view

admin_id=3 应该拥有的权限（3个）:
- schedule_manage
- appointment_manage
- audit_log_view

admin_id=5 应该拥有的权限（6个）:
- doctor_manage
- schedule_manage
- appointment_manage
- audit_log_view
- financial_manage
- report_generate
*/
