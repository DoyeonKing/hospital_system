-- ============================================
-- 修复 locations 表插入问题
-- 1. 解决子查询返回多行错误（Error 1242）
-- 2. 修复重复数据问题
-- 3. 删除已插入的重复数据
-- ============================================

-- 第一步：删除重复的 location_name 数据（保留最早的记录）
-- 查找重复的 location_name
SELECT 
    location_name,
    COUNT(*) as count,
    GROUP_CONCAT(location_id ORDER BY location_id) as location_ids
FROM locations
GROUP BY location_name
HAVING COUNT(*) > 1;

-- 删除重复记录（保留每个 location_name 的最小 location_id）
DELETE l1 FROM locations l1
INNER JOIN locations l2 
WHERE l1.location_name = l2.location_name 
  AND l1.location_id > l2.location_id;

-- 第二步：修复后的 INSERT 语句
-- 主要修复：
-- 1. 子查询添加 LIMIT 1 确保只返回一行
-- 2. 优化 WHERE 条件，确保每个科室-房间组合只匹配一次
-- 3. 使用更精确的 JOIN 条件

INSERT INTO `locations` (`location_name`, `department_id`, `floor_level`, `building`, `room_number`, `capacity`, `map_node_id`)
SELECT 
    -- 诊室名称：楼栋名 + 房间号
    CONCAT(
        CASE 
            WHEN d.department_id BETWEEN 1 AND 10 THEN '内科楼'
            WHEN d.department_id BETWEEN 11 AND 21 THEN '外科楼'
            WHEN d.department_id BETWEEN 22 AND 32 THEN '儿科楼'
            WHEN d.department_id BETWEEN 33 AND 36 THEN '妇产科楼'
            ELSE '综合楼'
        END,
        room_num
    ) AS location_name,
    d.department_id AS department_id,
    -- 楼层分配：每个科室在对应楼栋的特定楼层
    CASE 
        -- 内科楼 (1-10科室)
        WHEN d.department_id = 1 THEN 1  -- 神经科 1楼
        WHEN d.department_id = 2 THEN 1  -- 消化科 1楼
        WHEN d.department_id = 3 THEN 2  -- 呼吸科 2楼
        WHEN d.department_id = 4 THEN 2  -- 心血管科 2楼
        WHEN d.department_id = 5 THEN 3  -- 内分泌科 3楼
        WHEN d.department_id = 6 THEN 3  -- 肝病科 3楼
        WHEN d.department_id = 7 THEN 4  -- 肾内科 4楼
        WHEN d.department_id = 8 THEN 4  -- 普通内科 4楼
        WHEN d.department_id = 9 THEN 5  -- 血液科 5楼
        WHEN d.department_id = 10 THEN 5 -- 风湿免疫科 5楼
        
        -- 外科楼 (11-21科室)
        WHEN d.department_id = 11 THEN 1  -- 乳腺科 1楼
        WHEN d.department_id = 12 THEN 1  -- 心外科 1楼
        WHEN d.department_id = 13 THEN 2  -- 普通外科 2楼
        WHEN d.department_id = 14 THEN 2  -- 泌尿科 2楼
        WHEN d.department_id = 15 THEN 3  -- 神经脑外科 3楼
        WHEN d.department_id = 16 THEN 3  -- 肛肠科 3楼
        WHEN d.department_id = 17 THEN 4  -- 肝胆科 4楼
        WHEN d.department_id = 18 THEN 4  -- 肿瘤科 4楼
        WHEN d.department_id = 19 THEN 5  -- 胸外科 5楼
        WHEN d.department_id = 20 THEN 5  -- 血管科 5楼
        WHEN d.department_id = 21 THEN 6  -- 男科 6楼
        
        -- 儿科楼 (22-32科室)
        WHEN d.department_id = 22 THEN 1  -- 儿科其他 1楼
        WHEN d.department_id = 23 THEN 1  -- 内科 1楼
        WHEN d.department_id = 24 THEN 2  -- 外科 2楼
        WHEN d.department_id = 25 THEN 2  -- 小儿口腔科 2楼
        WHEN d.department_id = 26 THEN 3  -- 新生儿科 3楼
        WHEN d.department_id = 27 THEN 3  -- 眼科 3楼
        WHEN d.department_id = 28 THEN 4  -- 神经内科 4楼
        WHEN d.department_id = 29 THEN 4  -- 精神心理 4楼
        WHEN d.department_id = 30 THEN 5  -- 耳鼻喉科 5楼
        WHEN d.department_id = 31 THEN 5  -- 营养保健科 5楼
        WHEN d.department_id = 32 THEN 6  -- 骨科 6楼
        
        -- 妇产科楼 (33-36科室)
        WHEN d.department_id = 33 THEN 1  -- 产科 1楼
        WHEN d.department_id = 34 THEN 2  -- 妇产科 2楼
        WHEN d.department_id = 35 THEN 3  -- 生殖医学科 3楼
        WHEN d.department_id = 36 THEN 4  -- 计划生育 4楼
        ELSE 1
    END AS floor_level,
    -- 楼栋名
    CASE 
        WHEN d.department_id BETWEEN 1 AND 10 THEN '内科楼'
        WHEN d.department_id BETWEEN 11 AND 21 THEN '外科楼'
        WHEN d.department_id BETWEEN 22 AND 32 THEN '儿科楼'
        WHEN d.department_id BETWEEN 33 AND 36 THEN '妇产科楼'
        ELSE '综合楼'
    END AS building,
    -- 房间号：楼层+2位数编号
    CASE 
        -- 内科楼
        WHEN d.department_id = 1 AND room_num = '101室' THEN '1-01'
        WHEN d.department_id = 1 AND room_num = '102室' THEN '1-02'
        WHEN d.department_id = 2 AND room_num = '103室' THEN '1-03'
        WHEN d.department_id = 2 AND room_num = '104室' THEN '1-04'
        WHEN d.department_id = 3 AND room_num = '201室' THEN '2-01'
        WHEN d.department_id = 3 AND room_num = '202室' THEN '2-02'
        WHEN d.department_id = 4 AND room_num = '203室' THEN '2-03'
        WHEN d.department_id = 4 AND room_num = '204室' THEN '2-04'
        WHEN d.department_id = 5 AND room_num = '301室' THEN '3-01'
        WHEN d.department_id = 5 AND room_num = '302室' THEN '3-02'
        WHEN d.department_id = 6 AND room_num = '303室' THEN '3-03'
        WHEN d.department_id = 6 AND room_num = '304室' THEN '3-04'
        WHEN d.department_id = 7 AND room_num = '401室' THEN '4-01'
        WHEN d.department_id = 7 AND room_num = '402室' THEN '4-02'
        WHEN d.department_id = 8 AND room_num = '403室' THEN '4-03'
        WHEN d.department_id = 8 AND room_num = '404室' THEN '4-04'
        WHEN d.department_id = 9 AND room_num = '501室' THEN '5-01'
        WHEN d.department_id = 9 AND room_num = '502室' THEN '5-02'
        WHEN d.department_id = 10 AND room_num = '503室' THEN '5-03'
        WHEN d.department_id = 10 AND room_num = '504室' THEN '5-04'
        
        -- 外科楼
        WHEN d.department_id = 11 AND room_num = '101室' THEN '1-01'
        WHEN d.department_id = 11 AND room_num = '102室' THEN '1-02'
        WHEN d.department_id = 12 AND room_num = '103室' THEN '1-03'
        WHEN d.department_id = 12 AND room_num = '104室' THEN '1-04'
        WHEN d.department_id = 13 AND room_num = '201室' THEN '2-01'
        WHEN d.department_id = 13 AND room_num = '202室' THEN '2-02'
        WHEN d.department_id = 14 AND room_num = '203室' THEN '2-03'
        WHEN d.department_id = 14 AND room_num = '204室' THEN '2-04'
        WHEN d.department_id = 15 AND room_num = '301室' THEN '3-01'
        WHEN d.department_id = 15 AND room_num = '302室' THEN '3-02'
        WHEN d.department_id = 16 AND room_num = '303室' THEN '3-03'
        WHEN d.department_id = 16 AND room_num = '304室' THEN '3-04'
        WHEN d.department_id = 17 AND room_num = '401室' THEN '4-01'
        WHEN d.department_id = 17 AND room_num = '402室' THEN '4-02'
        WHEN d.department_id = 18 AND room_num = '403室' THEN '4-03'
        WHEN d.department_id = 18 AND room_num = '404室' THEN '4-04'
        WHEN d.department_id = 19 AND room_num = '501室' THEN '5-01'
        WHEN d.department_id = 19 AND room_num = '502室' THEN '5-02'
        WHEN d.department_id = 20 AND room_num = '503室' THEN '5-03'
        WHEN d.department_id = 20 AND room_num = '504室' THEN '5-04'
        WHEN d.department_id = 21 AND room_num = '601室' THEN '6-01'
        WHEN d.department_id = 21 AND room_num = '602室' THEN '6-02'
        
        -- 儿科楼
        WHEN d.department_id = 22 AND room_num = '101室' THEN '1-01'
        WHEN d.department_id = 22 AND room_num = '102室' THEN '1-02'
        WHEN d.department_id = 23 AND room_num = '103室' THEN '1-03'
        WHEN d.department_id = 23 AND room_num = '104室' THEN '1-04'
        WHEN d.department_id = 24 AND room_num = '201室' THEN '2-01'
        WHEN d.department_id = 24 AND room_num = '202室' THEN '2-02'
        WHEN d.department_id = 25 AND room_num = '203室' THEN '2-03'
        WHEN d.department_id = 25 AND room_num = '204室' THEN '2-04'
        WHEN d.department_id = 26 AND room_num = '301室' THEN '3-01'
        WHEN d.department_id = 26 AND room_num = '302室' THEN '3-02'
        WHEN d.department_id = 27 AND room_num = '303室' THEN '3-03'
        WHEN d.department_id = 27 AND room_num = '304室' THEN '3-04'
        WHEN d.department_id = 28 AND room_num = '401室' THEN '4-01'
        WHEN d.department_id = 28 AND room_num = '402室' THEN '4-02'
        WHEN d.department_id = 29 AND room_num = '403室' THEN '4-03'
        WHEN d.department_id = 29 AND room_num = '404室' THEN '4-04'
        WHEN d.department_id = 30 AND room_num = '501室' THEN '5-01'
        WHEN d.department_id = 30 AND room_num = '502室' THEN '5-02'
        WHEN d.department_id = 31 AND room_num = '503室' THEN '5-03'
        WHEN d.department_id = 31 AND room_num = '504室' THEN '5-04'
        WHEN d.department_id = 32 AND room_num = '601室' THEN '6-01'
        WHEN d.department_id = 32 AND room_num = '602室' THEN '6-02'
        
        -- 妇产科楼
        WHEN d.department_id = 33 AND room_num = '101室' THEN '1-01'
        WHEN d.department_id = 33 AND room_num = '102室' THEN '1-02'
        WHEN d.department_id = 34 AND room_num = '201室' THEN '2-01'
        WHEN d.department_id = 34 AND room_num = '202室' THEN '2-02'
        WHEN d.department_id = 35 AND room_num = '301室' THEN '3-01'
        WHEN d.department_id = 35 AND room_num = '302室' THEN '3-02'
        WHEN d.department_id = 36 AND room_num = '401室' THEN '4-01'
        WHEN d.department_id = 36 AND room_num = '402室' THEN '4-02'
        
        -- 默认情况：使用楼层+房间号后4位
        ELSE CONCAT(
            CASE 
                -- 内科楼楼层
                WHEN d.department_id = 1 THEN '1'
                WHEN d.department_id = 2 THEN '1'
                WHEN d.department_id = 3 THEN '2'
                WHEN d.department_id = 4 THEN '2'
                WHEN d.department_id = 5 THEN '3'
                WHEN d.department_id = 6 THEN '3'
                WHEN d.department_id = 7 THEN '4'
                WHEN d.department_id = 8 THEN '4'
                WHEN d.department_id = 9 THEN '5'
                WHEN d.department_id = 10 THEN '5'
                -- 外科楼楼层
                WHEN d.department_id = 11 THEN '1'
                WHEN d.department_id = 12 THEN '1'
                WHEN d.department_id = 13 THEN '2'
                WHEN d.department_id = 14 THEN '2'
                WHEN d.department_id = 15 THEN '3'
                WHEN d.department_id = 16 THEN '3'
                WHEN d.department_id = 17 THEN '4'
                WHEN d.department_id = 18 THEN '4'
                WHEN d.department_id = 19 THEN '5'
                WHEN d.department_id = 20 THEN '5'
                WHEN d.department_id = 21 THEN '6'
                -- 儿科楼楼层
                WHEN d.department_id = 22 THEN '1'
                WHEN d.department_id = 23 THEN '1'
                WHEN d.department_id = 24 THEN '2'
                WHEN d.department_id = 25 THEN '2'
                WHEN d.department_id = 26 THEN '3'
                WHEN d.department_id = 27 THEN '3'
                WHEN d.department_id = 28 THEN '4'
                WHEN d.department_id = 29 THEN '4'
                WHEN d.department_id = 30 THEN '5'
                WHEN d.department_id = 31 THEN '5'
                WHEN d.department_id = 32 THEN '6'
                -- 妇产科楼楼层
                WHEN d.department_id = 33 THEN '1'
                WHEN d.department_id = 34 THEN '2'
                WHEN d.department_id = 35 THEN '3'
                WHEN d.department_id = 36 THEN '4'
                ELSE '1'
            END, 
            '-', 
            RIGHT(room_num, 4)
        )
    END AS room_number,
    5 AS capacity,  -- 每个诊室容纳5人
    -- 修复：子查询添加 LIMIT 1 确保只返回一行，避免 Error 1242
    (SELECT node_id FROM map_nodes 
     WHERE node_name = CONCAT(
        CASE 
            WHEN d.department_id BETWEEN 1 AND 10 THEN '内科楼'
            WHEN d.department_id BETWEEN 11 AND 21 THEN '外科楼'
            WHEN d.department_id BETWEEN 22 AND 32 THEN '儿科楼'
            WHEN d.department_id BETWEEN 33 AND 36 THEN '妇产科楼'
            ELSE '综合楼'
        END,
        room_num,
        '入口'
     ) 
     AND floor_level = CASE 
        -- 内科楼楼层
        WHEN d.department_id = 1 THEN 1
        WHEN d.department_id = 2 THEN 1
        WHEN d.department_id = 3 THEN 2
        WHEN d.department_id = 4 THEN 2
        WHEN d.department_id = 5 THEN 3
        WHEN d.department_id = 6 THEN 3
        WHEN d.department_id = 7 THEN 4
        WHEN d.department_id = 8 THEN 4
        WHEN d.department_id = 9 THEN 5
        WHEN d.department_id = 10 THEN 5
        -- 外科楼楼层
        WHEN d.department_id = 11 THEN 1
        WHEN d.department_id = 12 THEN 1
        WHEN d.department_id = 13 THEN 2
        WHEN d.department_id = 14 THEN 2
        WHEN d.department_id = 15 THEN 3
        WHEN d.department_id = 16 THEN 3
        WHEN d.department_id = 17 THEN 4
        WHEN d.department_id = 18 THEN 4
        WHEN d.department_id = 19 THEN 5
        WHEN d.department_id = 20 THEN 5
        WHEN d.department_id = 21 THEN 6
        -- 儿科楼楼层
        WHEN d.department_id = 22 THEN 1
        WHEN d.department_id = 23 THEN 1
        WHEN d.department_id = 24 THEN 2
        WHEN d.department_id = 25 THEN 2
        WHEN d.department_id = 26 THEN 3
        WHEN d.department_id = 27 THEN 3
        WHEN d.department_id = 28 THEN 4
        WHEN d.department_id = 29 THEN 4
        WHEN d.department_id = 30 THEN 5
        WHEN d.department_id = 31 THEN 5
        WHEN d.department_id = 32 THEN 6
        -- 妇产科楼楼层
        WHEN d.department_id = 33 THEN 1
        WHEN d.department_id = 34 THEN 2
        WHEN d.department_id = 35 THEN 3
        WHEN d.department_id = 36 THEN 4
        ELSE 1
     END
     LIMIT 1  -- 关键修复：确保只返回一行
    ) AS map_node_id
FROM `departments` d
-- 为每个科室生成对应的诊室
CROSS JOIN (
    SELECT '101室' AS room_num UNION SELECT '102室' UNION 
    SELECT '103室' UNION SELECT '104室' UNION
    SELECT '201室' UNION SELECT '202室' UNION
    SELECT '203室' UNION SELECT '204室' UNION
    SELECT '301室' UNION SELECT '302室' UNION
    SELECT '303室' UNION SELECT '304室' UNION
    SELECT '401室' UNION SELECT '402室' UNION
    SELECT '403室' UNION SELECT '404室' UNION
    SELECT '501室' UNION SELECT '502室' UNION
    SELECT '503室' UNION SELECT '504室' UNION
    SELECT '601室' UNION SELECT '602室'
) AS room_nums
WHERE d.department_id BETWEEN 1 AND 36
  -- 修复：使用更精确的匹配条件，确保每个科室-房间组合只匹配一次
  AND (
    -- 内科楼：1-10科室
    (d.department_id = 1 AND room_nums.room_num IN ('101室','102室')) OR
    (d.department_id = 2 AND room_nums.room_num IN ('103室','104室')) OR
    (d.department_id = 3 AND room_nums.room_num IN ('201室','202室')) OR
    (d.department_id = 4 AND room_nums.room_num IN ('203室','204室')) OR
    (d.department_id = 5 AND room_nums.room_num IN ('301室','302室')) OR
    (d.department_id = 6 AND room_nums.room_num IN ('303室','304室')) OR
    (d.department_id = 7 AND room_nums.room_num IN ('401室','402室')) OR
    (d.department_id = 8 AND room_nums.room_num IN ('403室','404室')) OR
    (d.department_id = 9 AND room_nums.room_num IN ('501室','502室')) OR
    (d.department_id = 10 AND room_nums.room_num IN ('503室','504室')) OR
  
    -- 外科楼：11-21科室
    (d.department_id = 11 AND room_nums.room_num IN ('101室','102室')) OR
    (d.department_id = 12 AND room_nums.room_num IN ('103室','104室')) OR
    (d.department_id = 13 AND room_nums.room_num IN ('201室','202室')) OR
    (d.department_id = 14 AND room_nums.room_num IN ('203室','204室')) OR
    (d.department_id = 15 AND room_nums.room_num IN ('301室','302室')) OR
    (d.department_id = 16 AND room_nums.room_num IN ('303室','304室')) OR
    (d.department_id = 17 AND room_nums.room_num IN ('401室','402室')) OR
    (d.department_id = 18 AND room_nums.room_num IN ('403室','404室')) OR
    (d.department_id = 19 AND room_nums.room_num IN ('501室','502室')) OR
    (d.department_id = 20 AND room_nums.room_num IN ('503室','504室')) OR
    (d.department_id = 21 AND room_nums.room_num IN ('601室','602室')) OR
  
    -- 儿科楼：22-32科室
    (d.department_id = 22 AND room_nums.room_num IN ('101室','102室')) OR
    (d.department_id = 23 AND room_nums.room_num IN ('103室','104室')) OR
    (d.department_id = 24 AND room_nums.room_num IN ('201室','202室')) OR
    (d.department_id = 25 AND room_nums.room_num IN ('203室','204室')) OR
    (d.department_id = 26 AND room_nums.room_num IN ('301室','302室')) OR
    (d.department_id = 27 AND room_nums.room_num IN ('303室','304室')) OR
    (d.department_id = 28 AND room_nums.room_num IN ('401室','402室')) OR
    (d.department_id = 29 AND room_nums.room_num IN ('403室','404室')) OR
    (d.department_id = 30 AND room_nums.room_num IN ('501室','502室')) OR
    (d.department_id = 31 AND room_nums.room_num IN ('503室','504室')) OR
    (d.department_id = 32 AND room_nums.room_num IN ('601室','602室')) OR
  
    -- 妇产科楼：33-36科室
    (d.department_id = 33 AND room_nums.room_num IN ('101室','102室')) OR
    (d.department_id = 34 AND room_nums.room_num IN ('201室','202室')) OR
    (d.department_id = 35 AND room_nums.room_num IN ('301室','302室')) OR
    (d.department_id = 36 AND room_nums.room_num IN ('401室','402室'))
  )
  -- 避免插入已存在的 location_name
  AND NOT EXISTS (
    SELECT 1 FROM locations l 
    WHERE l.location_name = CONCAT(
        CASE 
            WHEN d.department_id BETWEEN 1 AND 10 THEN '内科楼'
            WHEN d.department_id BETWEEN 11 AND 21 THEN '外科楼'
            WHEN d.department_id BETWEEN 22 AND 32 THEN '儿科楼'
            WHEN d.department_id BETWEEN 33 AND 36 THEN '妇产科楼'
            ELSE '综合楼'
        END,
        room_nums.room_num
    )
  )
ORDER BY d.department_id, room_nums.room_num;

-- 第三步：验证插入结果
SELECT 
    location_id,
    location_name,
    department_id,
    floor_level,
    building,
    room_number,
    capacity,
    map_node_id
FROM locations
WHERE department_id BETWEEN 1 AND 36
ORDER BY department_id, location_id;

-- 检查是否还有重复的 location_name
SELECT 
    location_name,
    COUNT(*) as count
FROM locations
GROUP BY location_name
HAVING COUNT(*) > 1;

