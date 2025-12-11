-- ========================================
-- 验证管理员权限配置
-- ========================================

-- 1. 查看所有管理员及其角色和权限
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    a.status,
    GROUP_CONCAT(DISTINCT r.role_name ORDER BY r.role_name SEPARATOR ', ') AS roles,
    GROUP_CONCAT(DISTINCT p.permission_name ORDER BY p.permission_name SEPARATOR ', ') AS permissions
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
GROUP BY a.admin_id, a.username, a.full_name, a.status
ORDER BY a.admin_id;

-- 2. 查看 admin_id=5 的详细信息
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    a.status,
    r.role_id,
    r.role_name,
    p.permission_id,
    p.permission_name
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
ORDER BY r.role_id, p.permission_id;

-- 3. 检查 admin_roles 表中的数据
SELECT * FROM admin_roles WHERE admin_id = 5;

-- 4. 检查所有角色及其权限
SELECT 
    r.role_id,
    r.role_name,
    GROUP_CONCAT(p.permission_name ORDER BY p.permission_name SEPARATOR ', ') AS permissions
FROM roles r
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
GROUP BY r.role_id, r.role_name
ORDER BY r.role_id;

-- 5. 检查所有权限
SELECT * FROM permissions ORDER BY permission_id;
