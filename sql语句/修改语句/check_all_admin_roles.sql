-- 检查所有管理员的角色分配情况

-- 1. 查看所有管理员
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    a.status
FROM admins a
ORDER BY a.admin_id;

-- 2. 查看所有管理员的角色分配
SELECT 
    a.admin_id,
    a.username,
    a.full_name,
    GROUP_CONCAT(r.role_name) AS roles,
    COUNT(ar.role_id) AS role_count
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
GROUP BY a.admin_id, a.username, a.full_name
ORDER BY a.admin_id;

-- 3. 查看 admin_roles 表的所有数据
SELECT * FROM admin_roles ORDER BY admin_id;

-- 4. 为没有角色的管理员分配默认角色（系统操作员）
-- 注意：这只是示例，请根据实际需求修改

-- 查看哪些管理员没有角色
SELECT a.admin_id, a.username, a.full_name
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
WHERE ar.role_id IS NULL;

-- 为所有没有角色的管理员分配"系统操作员"角色（role_id=5）
INSERT INTO admin_roles (admin_id, role_id)
SELECT a.admin_id, 5
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
WHERE ar.role_id IS NULL;

-- 验证结果
SELECT 
    a.admin_id,
    a.username,
    GROUP_CONCAT(r.role_name) AS roles
FROM admins a
LEFT JOIN admin_roles ar ON a.admin_id = ar.admin_id
LEFT JOIN roles r ON ar.role_id = r.role_id
GROUP BY a.admin_id, a.username
ORDER BY a.admin_id;
