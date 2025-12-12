-- ========================================
-- 调试 admin_id=5 的数据问题
-- ========================================

-- 1. 检查管理员是否存在
SELECT * FROM admins WHERE admin_id = 5;

-- 2. 检查管理员的角色分配
SELECT 
    ar.admin_id,
    ar.role_id,
    r.role_name,
    r.description
FROM admin_roles ar
LEFT JOIN roles r ON ar.role_id = r.role_id
WHERE ar.admin_id = 5;

-- 3. 检查角色的权限分配
SELECT 
    r.role_id,
    r.role_name,
    rp.permission_id,
    p.permission_name,
    p.description
FROM roles r
INNER JOIN admin_roles ar ON r.role_id = ar.role_id
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
WHERE ar.admin_id = 5
ORDER BY r.role_id, p.permission_id;

-- 4. 完整的权限查询（模拟后端查询）
SELECT DISTINCT
    p.permission_name
FROM admins a
INNER JOIN admin_roles ar ON a.admin_id = ar.admin_id
INNER JOIN roles r ON ar.role_id = r.role_id
INNER JOIN role_permissions rp ON r.role_id = rp.role_id
INNER JOIN permissions p ON rp.permission_id = p.permission_id
WHERE a.admin_id = 5
ORDER BY p.permission_name;

-- 5. 检查所有表的数据
SELECT '=== admins 表 ===' AS info;
SELECT * FROM admins WHERE admin_id = 5;

SELECT '=== admin_roles 表 ===' AS info;
SELECT * FROM admin_roles WHERE admin_id = 5;

SELECT '=== roles 表 ===' AS info;
SELECT * FROM roles WHERE role_id IN (
    SELECT role_id FROM admin_roles WHERE admin_id = 5
);

SELECT '=== role_permissions 表 ===' AS info;
SELECT * FROM role_permissions WHERE role_id IN (
    SELECT role_id FROM admin_roles WHERE admin_id = 5
);

SELECT '=== permissions 表 ===' AS info;
SELECT * FROM permissions WHERE permission_id IN (
    SELECT permission_id FROM role_permissions WHERE role_id IN (
        SELECT role_id FROM admin_roles WHERE admin_id = 5
    )
);
