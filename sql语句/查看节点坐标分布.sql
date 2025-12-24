-- ============================================
-- 查看所有地图节点的坐标分布
-- 用于分析节点位置，调整地图布局
-- ============================================

-- 1. 按楼层统计节点坐标范围
SELECT 
    floor_level AS '楼层',
    COUNT(*) AS '节点数量',
    MIN(coordinates_x) AS '最小X坐标',
    MAX(coordinates_x) AS '最大X坐标',
    MIN(coordinates_y) AS '最小Y坐标',
    MAX(coordinates_y) AS '最大Y坐标',
    AVG(coordinates_x) AS '平均X坐标',
    AVG(coordinates_y) AS '平均Y坐标',
    CONCAT('X范围: ', MIN(coordinates_x), ' ~ ', MAX(coordinates_x), 
           ', Y范围: ', MIN(coordinates_y), ' ~ ', MAX(coordinates_y)) AS '坐标范围'
FROM map_nodes
GROUP BY floor_level
ORDER BY floor_level;

-- 2. 按节点类型统计
SELECT 
    node_type AS '节点类型',
    COUNT(*) AS '数量',
    MIN(coordinates_x) AS '最小X',
    MAX(coordinates_x) AS '最大X',
    MIN(coordinates_y) AS '最小Y',
    MAX(coordinates_y) AS '最大Y'
FROM map_nodes
GROUP BY node_type
ORDER BY COUNT(*) DESC;

-- 3. 详细节点列表（按楼层和坐标排序）
SELECT 
    node_id AS '节点ID',
    node_name AS '节点名称',
    node_type AS '类型',
    floor_level AS '楼层',
    coordinates_x AS 'X坐标',
    coordinates_y AS 'Y坐标',
    CASE 
        WHEN node_type = 'entrance' THEN '入口'
        WHEN node_type = 'hallway' THEN '走廊'
        WHEN node_type = 'elevator' THEN '电梯'
        WHEN node_type = 'stairs' THEN '楼梯'
        WHEN node_type = 'room' THEN '房间'
        ELSE '其他'
    END AS '类型说明',
    description AS '描述'
FROM map_nodes
ORDER BY floor_level, coordinates_y DESC, coordinates_x;

-- 4. 检查坐标异常（超出常见范围 0-50）
SELECT 
    node_id,
    node_name,
    floor_level,
    coordinates_x,
    coordinates_y,
    CASE 
        WHEN coordinates_x < 0 OR coordinates_x > 50 THEN 'X坐标异常'
        WHEN coordinates_y < 0 OR coordinates_y > 50 THEN 'Y坐标异常'
        ELSE '正常'
    END AS '状态'
FROM map_nodes
WHERE coordinates_x < 0 OR coordinates_x > 50 
   OR coordinates_y < 0 OR coordinates_y > 50
ORDER BY floor_level;

-- 5. 按楼层查看节点分布（可视化用）
SELECT 
    floor_level AS '楼层',
    node_name AS '节点名称',
    node_type AS '类型',
    coordinates_x AS 'X',
    coordinates_y AS 'Y',
    -- 生成简单的坐标网格表示（每5个单位一个标记）
    CONCAT(
        REPEAT(' ', FLOOR(coordinates_x / 5)),
        '●',
        REPEAT(' ', FLOOR((50 - coordinates_x) / 5))
    ) AS 'X轴位置',
    CONCAT(
        REPEAT(' ', FLOOR(coordinates_y / 5)),
        '●',
        REPEAT(' ', FLOOR((50 - coordinates_y) / 5))
    ) AS 'Y轴位置'
FROM map_nodes
ORDER BY floor_level, coordinates_y DESC, coordinates_x;

-- 6. 检查是否有坐标重复的节点（可能的问题）
SELECT 
    floor_level,
    coordinates_x,
    coordinates_y,
    COUNT(*) AS '重复数量',
    GROUP_CONCAT(node_name SEPARATOR ', ') AS '节点名称'
FROM map_nodes
GROUP BY floor_level, coordinates_x, coordinates_y
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 7. 统计每个楼层的节点密度（用于判断是否需要调整坐标范围）
SELECT 
    floor_level AS '楼层',
    COUNT(*) AS '节点数',
    (MAX(coordinates_x) - MIN(coordinates_x)) AS 'X轴跨度',
    (MAX(coordinates_y) - MIN(coordinates_y)) AS 'Y轴跨度',
    ROUND(COUNT(*) / ((MAX(coordinates_x) - MIN(coordinates_x)) * (MAX(coordinates_y) - MIN(coordinates_y))), 2) AS '节点密度'
FROM map_nodes
GROUP BY floor_level
ORDER BY floor_level;

-- 8. 查看与诊室关联的节点坐标
SELECT 
    l.location_id AS '诊室ID',
    l.location_name AS '诊室名称',
    l.floor_level AS '楼层',
    n.node_id AS '节点ID',
    n.node_name AS '节点名称',
    n.coordinates_x AS 'X坐标',
    n.coordinates_y AS 'Y坐标'
FROM locations l
LEFT JOIN map_nodes n ON l.map_node_id = n.node_id
WHERE n.node_id IS NOT NULL
ORDER BY l.floor_level, n.coordinates_y DESC, n.coordinates_x;

