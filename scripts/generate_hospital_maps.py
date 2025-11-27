import os
import json
import random
import math
from PIL import Image, ImageDraw, ImageFont, ImageColor
from collections import defaultdict

# 创建输出目录
output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'hospital_maps')
os.makedirs(output_dir, exist_ok=True)

# 从locations表提取的楼层和房间信息
locations_data = [
    # 门诊楼1F
    {"location_id": 1, "location_name": "门诊楼101室", "building": "门诊楼", "floor_level": 1, "room_number": "101", "map_node_id": 1},
    {"location_id": 2, "location_name": "门诊楼102室", "building": "门诊楼", "floor_level": 1, "room_number": "102", "map_node_id": 2},
    {"location_id": 3, "location_name": "门诊楼103室", "building": "门诊楼", "floor_level": 1, "room_number": "103", "map_node_id": 3},
    # 门诊楼2F
    {"location_id": 4, "location_name": "门诊楼201室", "building": "门诊楼", "floor_level": 2, "room_number": "201", "map_node_id": 4},
    {"location_id": 5, "location_name": "门诊楼202室", "building": "门诊楼", "floor_level": 2, "room_number": "202", "map_node_id": 5},
    {"location_id": 6, "location_name": "门诊楼203室", "building": "门诊楼", "floor_level": 2, "room_number": "203", "map_node_id": 6},
    # 门诊楼3F
    {"location_id": 7, "location_name": "门诊楼301室", "building": "门诊楼", "floor_level": 3, "room_number": "301", "map_node_id": 7},
    {"location_id": 8, "location_name": "门诊楼302室", "building": "门诊楼", "floor_level": 3, "room_number": "302", "map_node_id": 8},
    # 外科楼1F
    {"location_id": 9, "location_name": "外科楼101室", "building": "外科楼", "floor_level": 1, "room_number": "101", "map_node_id": 9},
    {"location_id": 10, "location_name": "外科楼102室", "building": "外科楼", "floor_level": 1, "room_number": "102", "map_node_id": 10},
    # 专科楼2F
    {"location_id": 11, "location_name": "专科楼201室", "building": "专科楼", "floor_level": 2, "room_number": "201", "map_node_id": 11},
    {"location_id": 12, "location_name": "专科楼202室", "building": "专科楼", "floor_level": 2, "room_number": "202", "map_node_id": 12},
]

def generate_floors_from_locations(locations):
    """从位置数据生成楼层配置"""
    floors_dict = {}

    for loc in locations:
        key = (loc['building'], loc['floor_level'])
        if key not in floors_dict:
            floors_dict[key] = {
                'building': loc['building'],
                'level': loc['floor_level'],
                'name': f"{loc['floor_level']}F",
                'rooms': []
            }
        floors_dict[key]['rooms'].append(loc['location_name'])

    return list(floors_dict.values())

floors = generate_floors_from_locations(locations_data)

def deterministic_random(seed, x, y):
    """生成确定性随机数"""
    random.seed(f"{seed}-{x}-{y}")
    return random.random()

def get_fixed_coordinates(location, index, total):
    """为每个位置生成固定的坐标"""
    building = location['building']
    floor = location['floor_level']
    room_num = int(''.join(filter(str.isdigit, location['room_number'] or '0')))

    # 根据楼栋和楼层确定基础偏移量
    if building == '门诊楼':
        base_x, base_y = 200, 200
        if floor == 1:
            base_y += 0
        elif floor == 2:
            base_y += 400
        else:  # floor 3
            base_y += 800
    elif building == '外科楼':
        base_x, base_y = 600, 200
    else:  # 专科楼
        base_x, base_y = 600, 600

    # 根据房间号生成相对位置
    col = (room_num % 10) - 1
    row = (room_num // 100) - 1

    # 确保坐标在合理范围内
    x = base_x + col * 150
    y = base_y + (index % 5) * 100

    # 添加一些随机性但保持确定性
    rand_x = deterministic_random(f"{building}-{floor}-{room_num}", "x", 0) * 40 - 20
    rand_y = deterministic_random(f"{building}-{floor}-{room_num}", "y", 1) * 40 - 20

    return int(x + rand_x), int(y + rand_y)

def draw_node(draw, node, node_size=8, font=None):
    """绘制单个节点"""
    x, y = node['x'], node['y']

    # 设置节点颜色
    node_colors = {
        'room': 'blue',
        'entrance': 'green',
        'elevator': 'red',
        'stair': 'purple',
        'hallway': 'gray'
    }

    color = node_colors.get(node['type'], 'black')
    size = node_size

    # 绘制节点
    if node['type'] == 'room':
        # 房间用矩形表示
        half_width = node.get('width', 60) // 2
        half_height = node.get('height', 40) // 2
        draw.rectangle([x-half_width, y-half_height, x+half_width, y+half_height],
                      fill=color, outline='black', width=1)
    else:
        # 其他节点用圆形表示
        draw.ellipse([x-size, y-size, x+size, y+size], fill=color)

    # 添加标签
    label = node['name']
    if font:
        text_bbox = draw.textbbox((0, 0), label, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
        draw.text((x - text_width//2, y + size + 5), label, fill='black', font=font)

def draw_edge(draw, edge, nodes_dict, color='gray', width=2):
    """绘制边"""
    start_node = nodes_dict.get(edge['source'])
    end_node = nodes_dict.get(edge['target'])

    if not start_node or not end_node:
        return

    start_x, start_y = start_node['x'], start_node['y']
    end_x, end_y = end_node['x'], end_node['y']

    # 如果是房间到走廊的边，调整起点到房间边缘
    if start_node['type'] == 'room' and end_node['type'] == 'hallway':
        # 计算房间中心到走廊中心的方向
        dx = end_x - start_x
        dy = end_y - start_y
        dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0:
            # 计算房间边缘的交点
            half_width = start_node.get('width', 60) // 2
            half_height = start_node.get('height', 40) // 2

            # 计算方向向量
            dx /= dist
            dy /= dist

            # 找到与房间矩形的交点
            # 计算从中心到各边的距离
            if abs(dx) > 1e-6:
                tx1 = (half_width) / abs(dx)
                tx2 = (-half_width) / abs(dx)
                tx = max(tx1, tx2) if dx > 0 else min(tx1, tx2)
            else:
                tx = float('inf')

            if abs(dy) > 1e-6:
                ty1 = (half_height) / abs(dy)
                ty2 = (-half_height) / abs(dy)
                ty = max(ty1, ty2) if dy > 0 else min(ty1, ty2)
            else:
                ty = float('inf')

            # 取较小的t值（先接触的边）
            t = min(tx, ty)
            start_x = start_x + dx * t
            start_y = start_y + dy * t

    draw.line([(start_x, start_y), (end_x, end_y)], fill=color, width=width)

def generate_floor_map(floor, locations, nodes=None, edges=None):
    """生成单个楼层的地图图片"""
    width, height = 1200, 1000  # 增加画布大小
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)

    # 绘制背景和网格
    for i in range(0, width, 50):
        draw.line([(i, 0), (i, height)], fill='#f0f0f0')
    for i in range(0, height, 50):
        draw.line([(0, i), (width, i)], fill='#f0f0f0')

    # 绘制外框
    margin = 50
    draw.rectangle([margin, margin, width-margin, height-margin], outline='#333', width=3)

    # 加载字体
    try:
        font = ImageFont.truetype("simhei.ttf", 12)
        title_font = ImageFont.truetype("simhei.ttf", 24)
    except:
        font = ImageFont.load_default()
        title_font = ImageFont.load_default()

    # 如果有节点和边数据，绘制它们
    if nodes and edges:
        # 创建节点字典以便快速查找
        nodes_dict = {node['id']: node for node in nodes}

        # 先绘制边
        for edge in edges:
            draw_edge(draw, edge, nodes_dict)

        # 再绘制节点（这样节点会覆盖边的端点）
        for node in nodes:
            draw_node(draw, node, font=font)

    # 添加标题
    title = f"{floor['building']} - {floor['name']}"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 20), title, fill='#333', font=title_font)

    # 添加图例
    legend_x = width - 180
    legend_y = 50
    legend_items = [
        ('房间', 'blue'),
        ('入口', 'green'),
        ('电梯', 'red'),
        ('楼梯', 'purple'),
        ('走廊', 'gray')
    ]

    for i, (text, color) in enumerate(legend_items):
        y = legend_y + i * 25
        draw.rectangle([legend_x, y, legend_x + 15, y + 15], fill=color, outline='black', width=1)
        draw.text((legend_x + 20, y - 2), text, fill='black', font=font)

    # 保存图片
    img_path = os.path.join(output_dir, f"{floor['building']}-{floor['name']}.png")
    img.save(img_path)
    print(f"生成地图: {img_path}")

    return img_path

def generate_floor_plan(floor, locations):
    """为单个楼层生成节点和路径"""
    width, height = 1200, 1000
    margin = 50

    nodes = []
    edges = []

    # 获取当前楼层的所有位置
    floor_locations = [loc for loc in locations
                      if loc['building'] == floor['building']
                      and loc['floor_level'] == floor['level']]

    # 1. 添加入口节点（固定位置）
    entrance1 = {
        'id': f"{floor['building']}-{floor['name']}-entrance1",
        'type': 'entrance',
        'x': margin + 100,
        'y': margin + 100,
        'floor': floor['name'],
        'building': floor['building'],
        'name': '主入口'
    }
    nodes.append(entrance1)

    # 2. 添加电梯和楼梯（固定位置）
    elevator1 = {
        'id': f"{floor['building']}-{floor['name']}-elevator1",
        'type': 'elevator',
        'x': width - margin - 100,
        'y': height // 2 - 100,
        'floor': floor['name'],
        'building': floor['building'],
        'name': '电梯1'
    }
    nodes.append(elevator1)

    stair = {
        'id': f"{floor['building']}-{floor['name']}-stair",
        'type': 'stair',
        'x': width // 2,
        'y': height - margin - 100,
        'floor': floor['name'],
        'building': floor['building'],
        'name': '楼梯'
    }
    nodes.append(stair)

    # 3. 添加上传的诊室节点
    for i, loc in enumerate(floor_locations):
        x, y = get_fixed_coordinates(loc, i, len(floor_locations))

        room = {
            'id': f"room-{loc['location_id']}",
            'type': 'room',
            'x': x,
            'y': y,
            'floor': floor['name'],
            'building': floor['building'],
            'name': loc['location_name'],
            'location_id': loc['location_id'],
            'width': 60,  # 减小房间宽度
            'height': 40   # 减小房间高度
        }
        nodes.append(room)

    # 4. 添加走廊节点（连接入口、电梯和房间）
    hallway_nodes = []
    for i in range(3):  # 3个水平走廊节点
        node = {
            'id': f"{floor['building']}-{floor['name']}-hallway-{i}",
            'type': 'hallway',
            'x': margin + 200 + i * 350,  # 增加节点间距
            'y': height // 2,
            'floor': floor['name'],
            'building': floor['building'],
            'name': f"走廊-{i+1}"
        }
        nodes.append(node)
        hallway_nodes.append(node)

    # 5. 添加边（连接节点）
    # 连接入口到最近的走廊
    for entrance in [entrance1]:
        closest = min(hallway_nodes,
                     key=lambda n: (n['x']-entrance['x'])**2 + (n['y']-entrance['y'])**2)
        edges.append({
            'source': entrance['id'],
            'target': closest['id'],
            'weight': 1,
            'type': 'corridor'
        })

    # 连接电梯和楼梯到走廊
    for special_node in [elevator1, stair]:
        closest = min(hallway_nodes,
                     key=lambda n: (n['x']-special_node['x'])**2 + (n['y']-special_node['y'])**2)
        edges.append({
            'source': special_node['id'],
            'target': closest['id'],
            'weight': 1,
            'type': 'corridor'
        })

    # 连接房间到最近的走廊
    room_nodes = [n for n in nodes if n['type'] == 'room']
    for room in room_nodes:
        closest = min(hallway_nodes,
                     key=lambda n: (n['x']-room['x'])**2 + (n['y']-room['y'])**2)
        edges.append({
            'source': room['id'],
            'target': closest['id'],
            'weight': 1,
            'type': 'door'
        })

    # 连接走廊节点
    for i in range(len(hallway_nodes)-1):
        edges.append({
            'source': hallway_nodes[i]['id'],
            'target': hallway_nodes[i+1]['id'],
            'weight': 2,
            'type': 'corridor'
        })

    return nodes, edges

def generate_sql(nodes, edges, node_id_mapping):
    """生成SQL插入语句"""
    # 1. 清空现有数据（如果需要）
    sql = "-- 清空现有数据\n"
    sql += "SET FOREIGN_KEY_CHECKS = 0;\n"
    sql += "TRUNCATE TABLE map_edges;\n"
    sql += "TRUNCATE TABLE map_nodes;\n"
    sql += "TRUNCATE TABLE maps;\n"
    sql += "SET FOREIGN_KEY_CHECKS = 1;\n\n"

    # 2. 插入maps表数据
    sql += "-- 插入地图数据\n"
    sql += "INSERT INTO maps (building, floor_level, floor_name, map_image_url) VALUES\n"
    for floor in floors:
        sql += f"  ('{floor['building']}', {floor['level']}, '{floor['name']}', '/static/maps/{floor['building']}-{floor['name']}.png'),\n"
    sql = sql.rstrip(",\n") + ";\n\n"

    # 3. 插入map_nodes表数据
    sql += "-- 插入节点数据\n"
    sql += "INSERT INTO map_nodes (node_id, node_name, node_type, x_coordinate, y_coordinate, floor_level, building, is_accessible, description) VALUES\n"

    for node in nodes:
        node_id = node_id_mapping.get(node['id'])
        if not node_id:
            print(f"警告: 未找到节点ID映射: {node['id']}")
            continue

        desc = []
        if 'location_id' in node:
            desc.append(f"location_id:{node['location_id']}")
        if 'width' in node and 'height' in node:
            desc.append(f"size:{node['width']}x{node['height']}")

        sql += f"  ({node_id}, '{node['name']}', '{node['type']}', {node['x']}, {node['y']}, "
        sql += f"{node['floor'][:-1]}, '{node['building']}', TRUE, "
        sql += f"'{';'.join(desc)}'),\n"

    sql = sql.rstrip(",\n") + ";\n\n"

    # 4. 插入map_edges表数据
    sql += "-- 插入边数据\n"
    sql += "INSERT INTO map_edges (start_node_id, end_node_id, weight, is_bidirectional, is_accessible, description) VALUES\n"

    for edge in edges:
        start_id = node_id_mapping.get(edge['source'])
        end_id = node_id_mapping.get(edge['target'])

        if not start_id or not end_id:
            print(f"警告: 无法找到边的节点: {edge['source']} -> {edge['target']}")
            continue

        sql += f"  ({start_id}, {end_id}, {edge['weight']}, TRUE, TRUE, '{edge['type']}'),\n"

    sql = sql.rstrip(",\n") + ";\n\n"

    # 5. 更新locations表的map_node_id
    sql += "-- 更新locations表的map_node_id\n"
    for node in nodes:
        if 'location_id' in node and node['id'] in node_id_mapping:
            sql += f"UPDATE locations SET map_node_id = {node_id_mapping[node['id']]} WHERE location_id = {node['location_id']};\n"

    return sql

def main():
    # 生成所有楼层的地图和节点数据
    all_nodes = []
    all_edges = []
    node_id_mapping = {}  # 存储节点ID映射

    # 先收集所有节点和边
    for floor in floors:
        print(f"\n处理楼层: {floor['building']} {floor['name']}")

        # 生成节点和边
        nodes, edges = generate_floor_plan(floor, locations_data)
        all_nodes.extend(nodes)
        all_edges.extend(edges)

        print(f"  生成节点: {len(nodes)} 个, 边: {len(edges)} 条")

    # 为所有节点分配唯一的node_id
    node_id_counter = 1
    for node in all_nodes:
        node_id_mapping[node['id']] = node_id_counter
        node['unique_id'] = node_id_counter
        node_id_counter += 1

    # 按楼层生成地图图片
    for floor in floors:
        # 获取当前楼层的节点和边
        floor_nodes = [n for n in all_nodes if n['building'] == floor['building'] and n['floor'] == floor['name']]
        floor_edges = [e for e in all_edges
                      if any(n['id'] in [e['source'], e['target']] for n in floor_nodes)]

        # 生成地图图片
        generate_floor_map(floor, locations_data, floor_nodes, floor_edges)

    # 生成SQL
    sql = generate_sql(all_nodes, all_edges, node_id_mapping)
    sql_path = os.path.join(output_dir, 'map_data.sql')
    with open(sql_path, 'w', encoding='utf-8') as f:
        f.write(sql)
    print(f"\n生成SQL文件: {sql_path}")

    # 生成JSON（用于前端）
    map_data = {
        'nodes': [{'id': node_id_mapping[n['id']], 'name': n['name'], 'type': n['type'],
                  'x': n['x'], 'y': n['y'], 'floor': n['floor'],
                  'building': n['building']}
                 for n in all_nodes if n['id'] in node_id_mapping],
        'edges': [{'source': node_id_mapping[e['source']],
                  'target': node_id_mapping[e['target']],
                  'weight': e['weight'], 'type': e['type']}
                 for e in all_edges
                 if e['source'] in node_id_mapping and e['target'] in node_id_mapping]
    }

    json_path = os.path.join(output_dir, 'map_data.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(map_data, f, ensure_ascii=False, indent=2)
    print(f"生成JSON文件: {json_path}")

    print("\n地图数据生成完成！")
    print(f"\n请将生成的地图图片复制到前端静态资源目录: {os.path.abspath(os.path.join(output_dir, '*.png'))}")
    print(f"然后执行SQL文件: {os.path.abspath(sql_path)}")

if __name__ == "__main__":
    main()