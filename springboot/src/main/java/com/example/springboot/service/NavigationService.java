package com.example.springboot.service;

import com.example.springboot.dto.navigation.*;
import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Location;
import com.example.springboot.entity.navigation.MapEdge;
import com.example.springboot.entity.navigation.MapNode;
import com.example.springboot.entity.navigation.FloorMap;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.repository.MapEdgeRepository;
import com.example.springboot.repository.MapNodeRepository;
import com.example.springboot.repository.FloorMapRepository;
import com.example.springboot.repository.LocationRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 导航服务 - 严格遵循TDD第4.2章和5.1章
 * 实现A*算法进行路径规划，支持跨楼层导航
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NavigationService {

    private final MapNodeRepository mapNodeRepository;
    private final MapEdgeRepository mapEdgeRepository;
    private final FloorMapRepository floorMapRepository;
    private final AppointmentRepository appointmentRepository;
    private final LocationRepository locationRepository;

    // 内存中的图结构：节点ID -> 邻接列表（节点ID -> 边权重）
    private Map<Long, Map<Long, EdgeInfo>> graph = new HashMap<>();

    // 节点信息缓存
    private Map<Long, MapNode> nodeCache = new HashMap<>();

    /**
     * 服务启动时加载地图数据到内存 - 严格遵循TDD要求
     */
    @PostConstruct
    public void loadGraphToMemory() {
        log.info("开始加载地图数据到内存...");
        try {
            // 加载所有节点
            List<MapNode> nodes = mapNodeRepository.findAll();
            nodeCache.clear();
            for (MapNode node : nodes) {
                nodeCache.put(node.getNodeId().longValue(), node);
            }
            log.info("加载了 {} 个节点", nodes.size());

            // 构建图结构
            graph.clear();
            List<MapEdge> edges = mapEdgeRepository.findAll();
            for (MapEdge edge : edges) {
                Long fromId = edge.getFromNode().getNodeId().longValue();
                Long toId = edge.getToNode().getNodeId().longValue();

                // 添加正向边
                graph.computeIfAbsent(fromId, k -> new HashMap<>())
                        .put(toId, new EdgeInfo(edge));

                // 如果是双向边，添加反向边
                if (Boolean.TRUE.equals(edge.getBidirectional())) {
                    graph.computeIfAbsent(toId, k -> new HashMap<>())
                            .put(fromId, new EdgeInfo(edge, true));
                }
            }
            log.info("加载了 {} 条边，构建了 {} 个节点的图", edges.size(), graph.size());
            log.info("地图数据加载完成");
        } catch (Exception e) {
            log.error("加载地图数据失败", e);
            throw new RuntimeException("地图数据加载失败: " + e.getMessage(), e);
        }
    }

    /**
     * 根据预约ID获取导航信息 - TDD 5.1 API接口1
     */
    @Transactional(readOnly = true)
    public NavigationInfoResponse getNavigationInfoByAppointment(Integer appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("预约不存在，ID: " + appointmentId));

        Location location = appointment.getSchedule().getLocation();
        if (location == null) {
            throw new ResourceNotFoundException("预约关联的诊室不存在");
        }

        NavigationInfoResponse response = new NavigationInfoResponse();
        response.setLocationId(location.getLocationId());
        response.setLocationName(location.getLocationName());
        response.setBuilding(location.getBuilding());
        response.setFloorLevel(location.getFloorLevel());
        response.setRoomNumber(location.getRoomNumber());
        response.setLatitude(location.getLatitude() != null ? location.getLatitude().doubleValue() : null);
        response.setLongitude(location.getLongitude() != null ? location.getLongitude().doubleValue() : null);
        response.setAddressDetail(location.getAddressDetail());

        // 获取关联的地图节点
        if (location.getMapNode() != null) {
            MapNode mapNode = location.getMapNode();
            response.setMapNodeId(mapNode.getNodeId());
        }

        return response;
    }

    /**
     * 根据诊室ID获取导航信息 - TDD 5.1 API接口1
     */
    @Transactional(readOnly = true)
    public NavigationInfoResponse getNavigationInfoByLocationId(Integer locationId) {
        Location location = locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("诊室不存在，ID: " + locationId));

        NavigationInfoResponse response = new NavigationInfoResponse();
        response.setLocationId(location.getLocationId());
        response.setLocationName(location.getLocationName());
        response.setBuilding(location.getBuilding());
        response.setFloorLevel(location.getFloorLevel());
        response.setRoomNumber(location.getRoomNumber());
        response.setLatitude(location.getLatitude() != null ? location.getLatitude().doubleValue() : null);
        response.setLongitude(location.getLongitude() != null ? location.getLongitude().doubleValue() : null);
        response.setAddressDetail(location.getAddressDetail());

        if (location.getMapNode() != null) {
            response.setMapNodeId(location.getMapNode().getNodeId());
        }

        return response;
    }

    /**
     * 扫码定位接口 - TDD 5.1 API接口2
     * 解析二维码内容，格式：HOSPITAL_NODE_{nodeId}
     */
    @Transactional(readOnly = true)
    public MapNodeDto scanLocation(String qrCode) {
        // 解析二维码：HOSPITAL_NODE_{nodeId}
        if (qrCode == null || !qrCode.startsWith("HOSPITAL_NODE_")) {
            throw new IllegalArgumentException("无效的二维码格式，应为 HOSPITAL_NODE_{nodeId}");
        }

        String nodeIdStr = qrCode.substring("HOSPITAL_NODE_".length());
        try {
            Integer nodeId = Integer.parseInt(nodeIdStr);
            MapNode node = mapNodeRepository.findById(nodeId)
                    .orElseThrow(() -> new ResourceNotFoundException("节点不存在，二维码: " + qrCode));
            return convertToNodeDto(node);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("无效的节点ID格式: " + nodeIdStr);
        }
    }

    /**
     * 路径规划接口 - TDD 5.1 API接口3
     * 使用A*算法计算最优路径，支持跨楼层
     */
    @Transactional(readOnly = true)
    public NavigationPathResponse planRoute(Long startNodeId, Long endNodeId, Boolean preferAccessible) {
        // 验证节点是否存在
        MapNode startNode = nodeCache.get(startNodeId);
        MapNode endNode = nodeCache.get(endNodeId);
        if (startNode == null) {
            throw new ResourceNotFoundException("起点节点不存在，ID: " + startNodeId);
        }
        if (endNode == null) {
            throw new ResourceNotFoundException("终点节点不存在，ID: " + endNodeId);
        }

        // 如果起点和终点相同
        if (startNodeId.equals(endNodeId)) {
            NavigationPathResponse response = new NavigationPathResponse();
            response.setNodes(Arrays.asList(convertToNodeDto(startNode)));
            response.setTotalDistance(0.0);
            response.setRequiresFloorChange(false);
            return response;
        }

        // 使用A*算法计算路径
        List<Long> path = aStarPathFinding(startNodeId, endNodeId);
        if (path == null || path.isEmpty()) {
            throw new RuntimeException("无法找到从节点 " + startNodeId + " 到节点 " + endNodeId + " 的路径");
        }

        // 构建响应
        NavigationPathResponse response = buildPathResponse(path);
        return response;
    }

    /**
     * A*路径规划算法实现
     */
    private List<Long> aStarPathFinding(Long startId, Long endId) {
        // 开放列表：待评估的节点 (f值, 节点ID)
        PriorityQueue<AStarNode> openSet = new PriorityQueue<>(Comparator.comparingDouble(n -> n.f));
        // 已访问的节点
        Set<Long> closedSet = new HashSet<>();
        // 从起点到每个节点的最短距离
        Map<Long, Double> gScore = new HashMap<>();
        // 节点的父节点（用于回溯路径）
        Map<Long, Long> cameFrom = new HashMap<>();

        // 初始化
        gScore.put(startId, 0.0);
        MapNode startNode = nodeCache.get(startId);
        MapNode endNode = nodeCache.get(endId);
        double hStart = heuristic(startNode, endNode);
        openSet.offer(new AStarNode(startId, 0.0, hStart));

        while (!openSet.isEmpty()) {
            AStarNode current = openSet.poll();
            Long currentId = current.nodeId;

            // 到达目标
            if (currentId.equals(endId)) {
                return reconstructPath(cameFrom, currentId);
            }

            closedSet.add(currentId);

            // 遍历邻居节点
            Map<Long, EdgeInfo> neighbors = graph.getOrDefault(currentId, new HashMap<>());
            for (Map.Entry<Long, EdgeInfo> entry : neighbors.entrySet()) {
                Long neighborId = entry.getKey();
                EdgeInfo edgeInfo = entry.getValue();

                if (closedSet.contains(neighborId)) {
                    continue;
                }

                // 计算从起点到邻居的实际距离
                double tentativeGScore = gScore.get(currentId) + edgeInfo.getWeight();

                // 如果这个路径更好，更新
                if (!gScore.containsKey(neighborId) || tentativeGScore < gScore.get(neighborId)) {
                    cameFrom.put(neighborId, currentId);
                    gScore.put(neighborId, tentativeGScore);

                    MapNode neighborNode = nodeCache.get(neighborId);
                    double hScore = heuristic(neighborNode, endNode);
                    double fScore = tentativeGScore + hScore;

                    // 检查是否已在开放列表中
                    AStarNode existing = openSet.stream()
                            .filter(n -> n.nodeId.equals(neighborId))
                            .findFirst()
                            .orElse(null);
                    if (existing != null) {
                        openSet.remove(existing);
                    }
                    openSet.offer(new AStarNode(neighborId, tentativeGScore, hScore));
                }
            }
        }

        return null; // 未找到路径
    }

    /**
     * 启发式函数：使用欧几里得距离（考虑楼层差异）
     */
    private double heuristic(MapNode from, MapNode to) {
        if (from == null || to == null) {
            return Double.MAX_VALUE;
        }

        // 同楼层：使用平面坐标距离
        // 注意：building 字段可能是 null（@Transient 字段），需要空值检查
        String fromBuilding = from.getBuilding();
        String toBuilding = to.getBuilding();
        boolean sameBuilding = (fromBuilding == null && toBuilding == null) ||
                              (fromBuilding != null && fromBuilding.equals(toBuilding));
        
        if (from.getFloorLevel().equals(to.getFloorLevel()) && sameBuilding) {
            double dx = from.getMapX().subtract(to.getMapX()).doubleValue();
            double dy = from.getMapY().subtract(to.getMapY()).doubleValue();
            return Math.sqrt(dx * dx + dy * dy);
        }

        // 不同楼层：添加楼层切换惩罚（假设每层3米高）
        int floorDiff = Math.abs(from.getFloorLevel() - to.getFloorLevel());
        double horizontalDist = 100.0; // 假设跨楼层需要额外移动100米
        double verticalDist = floorDiff * 3.0; // 每层3米
        return horizontalDist + verticalDist;
    }

    /**
     * 重构路径（从终点回溯到起点）
     */
    private List<Long> reconstructPath(Map<Long, Long> cameFrom, Long currentId) {
        List<Long> path = new ArrayList<>();
        path.add(currentId);

        while (cameFrom.containsKey(currentId)) {
            currentId = cameFrom.get(currentId);
            path.add(0, currentId); // 添加到开头
        }

        return path;
    }

    /**
     * 构建路径响应对象，包含指引信息和跨楼层提示
     */
    private NavigationPathResponse buildPathResponse(List<Long> path) {
        NavigationPathResponse response = new NavigationPathResponse();
        List<MapNodeDto> nodes = new ArrayList<>();
        List<NavigationInstructionDto> instructions = new ArrayList<>();
        List<PathSegmentDto> segments = new ArrayList<>();
        List<CrossFloorHintDto> crossFloorHints = new ArrayList<>();

        double totalDistance = 0.0;
        boolean requiresFloorChange = false;

        for (int i = 0; i < path.size(); i++) {
            Long nodeId = path.get(i);
            MapNode node = nodeCache.get(nodeId);
            nodes.add(convertToNodeDto(node));

            // 构建路径段和指引
            if (i < path.size() - 1) {
                Long nextNodeId = path.get(i + 1);
                MapEdge edge = findEdge(nodeId, nextNodeId);
                if (edge != null) {
                    MapNode nextNode = nodeCache.get(nextNodeId);

                    // 构建路径段（PathSegmentDto需要building, floorLevel, points）
                    PathSegmentDto segment = new PathSegmentDto();
                    segment.setBuilding(node.getBuilding());
                    segment.setFloorLevel(node.getFloorLevel());
                    // 解析path_points JSON或构建点列表
                    List<CoordinateDto> points = parsePathPoints(edge.getPathPoints(), node, nextNode);
                    segment.setPoints(points);
                    segments.add(segment);
                    totalDistance += edge.getDistanceMeters().doubleValue();

                    // 生成指引
                    NavigationInstructionDto instruction = new NavigationInstructionDto();
                    instruction.setStep(i + 1);
                    instruction.setInstruction(edge.getDirectionHint() != null ? edge.getDirectionHint() : "继续前进");
                    instruction.setDistance(edge.getDistanceMeters().doubleValue());
                    instruction.setTransitionType(edge.getTransitionType());
                    instruction.setFloorLevel(node.getFloorLevel());
                    instructions.add(instruction);

                    // 检查跨楼层
                    if (!node.getFloorLevel().equals(nextNode.getFloorLevel())) {
                        requiresFloorChange = true;
                        CrossFloorHintDto hint = new CrossFloorHintDto();
                        hint.setFloorLevel(nextNode.getFloorLevel());
                        hint.setBuilding(nextNode.getBuilding());
                        hint.setMessage(buildFloorChangeHint(node, nextNode, edge));
                        crossFloorHints.add(hint);
                    }
                }
            }
        }

        response.setNodes(nodes);
        response.setInstructions(instructions);
        response.setPathSegments(segments);
        response.setTotalDistance(totalDistance);
        response.setRequiresFloorChange(requiresFloorChange);
        response.setCrossFloorHints(crossFloorHints);

        return response;
    }

    /**
     * 查找两个节点之间的边
     */
    private MapEdge findEdge(Long fromId, Long toId) {
        Map<Long, EdgeInfo> neighbors = graph.get(fromId);
        if (neighbors == null) {
            return null;
        }
        EdgeInfo edgeInfo = neighbors.get(toId);
        return edgeInfo != null ? edgeInfo.edge : null;
    }

    /**
     * 构建跨楼层提示消息
     */
    private String buildFloorChangeHint(MapNode from, MapNode to, MapEdge edge) {
        int floorDiff = to.getFloorLevel() - from.getFloorLevel();
        String direction = floorDiff > 0 ? "上" : "下";
        String method = "ELEVATOR".equals(edge.getTransitionType()) ? "电梯"
                : "STAIRS".equals(edge.getTransitionType()) ? "楼梯" : "电梯或楼梯";
        return String.format("目标在第%d层，请乘坐%s到%d楼", to.getFloorLevel(), method, to.getFloorLevel());
    }

    /**
     * 解析路径点（从JSON字符串或构建默认点列表）
     * 
     * @param pathPointsJson JSON格式的路径点字符串
     * @param fromNode       起点节点
     * @param toNode         终点节点
     * @return 坐标点列表
     */
    private List<CoordinateDto> parsePathPoints(String pathPointsJson, MapNode fromNode, MapNode toNode) {
        List<CoordinateDto> points = new ArrayList<>();

        // 如果pathPoints不为空，尝试解析JSON
        if (pathPointsJson != null && !pathPointsJson.trim().isEmpty()) {
            try {
                // 使用 Spring Boot 默认的 ObjectMapper 解析 JSON
                // 格式假设为: [{"x":1.0,"y":2.0}, {"x":3.0,"y":4.0}]
                com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

                // 解析JSON数组
                com.fasterxml.jackson.databind.JsonNode jsonNode = objectMapper.readTree(pathPointsJson);
                if (jsonNode.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode pointNode : jsonNode) {
                        CoordinateDto coord = new CoordinateDto();
                        if (pointNode.has("x")) {
                            coord.setX(pointNode.get("x").asDouble());
                        }
                        if (pointNode.has("y")) {
                            coord.setY(pointNode.get("y").asDouble());
                        }
                        points.add(coord);
                    }
                }

                // 如果成功解析，返回解析结果
                if (!points.isEmpty()) {
                    return points;
                }
            } catch (Exception e) {
                log.warn("解析路径点JSON失败，将使用默认点: {}", e.getMessage());
            }
        }

        // 如果JSON解析失败或为空，构建默认路径点（起点和终点）
        if (fromNode != null && fromNode.getMapX() != null && fromNode.getMapY() != null) {
            CoordinateDto startCoord = new CoordinateDto();
            startCoord.setX(fromNode.getMapX().doubleValue());
            startCoord.setY(fromNode.getMapY().doubleValue());
            points.add(startCoord);
        }

        if (toNode != null && toNode.getMapX() != null && toNode.getMapY() != null) {
            CoordinateDto endCoord = new CoordinateDto();
            endCoord.setX(toNode.getMapX().doubleValue());
            endCoord.setY(toNode.getMapY().doubleValue());
            points.add(endCoord);
        }

        return points;
    }

    /**
     * 搜索节点 - 用于前端搜索功能
     * 同时搜索 MapNode 的 nodeName 和 Location 的 locationName
     */
    @Transactional(readOnly = true)
    public List<MapNodeDto> searchNodes(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return Collections.emptyList();
        }

        String searchKeyword = keyword.trim();
        Set<MapNodeDto> resultSet = new LinkedHashSet<>(); // 使用 LinkedHashSet 去重并保持顺序

        // 1. 搜索 MapNode 的 nodeName
        List<MapNode> mapNodes = mapNodeRepository.findByNodeNameContainingIgnoreCase(searchKeyword);
        for (MapNode node : mapNodes) {
            resultSet.add(convertToNodeDto(node));
        }

        // 2. 搜索 Location 的 locationName，通过关联的 mapNode 转换为 MapNodeDto
        List<Location> locations = locationRepository.findByLocationNameContainingIgnoreCase(searchKeyword);
        for (Location location : locations) {
            if (location.getMapNode() != null) {
                // 如果 Location 关联了 MapNode，使用该 MapNode
                MapNodeDto dto = convertToNodeDto(location.getMapNode());
                // 可以覆盖 nodeName 为 locationName，让搜索结果更准确
                dto.setNodeName(location.getLocationName());
                resultSet.add(dto);
            } else {
                // 如果 Location 没有关联 MapNode，创建一个临时的 MapNodeDto
                // 这种情况应该很少，但为了完整性还是处理一下
                MapNodeDto dto = new MapNodeDto();
                dto.setNodeId(location.getLocationId());
                dto.setNodeName(location.getLocationName());
                dto.setNodeType(MapNode.NodeType.room);
                dto.setFloorLevel(location.getFloorLevel() != null ? location.getFloorLevel() : 1);
                dto.setBuilding(location.getBuilding());
                dto.setDescription("诊室: " + location.getLocationName());
                resultSet.add(dto);
            }
        }

        return new ArrayList<>(resultSet);
    }

    /**
     * 获取入口节点列表
     */
    @Transactional(readOnly = true)
    public List<MapNodeDto> getEntranceNodes() {
        // 使用 nodeType 查找入口节点（entrance 类型）
        List<MapNode> nodes = mapNodeRepository.findByNodeType(MapNode.NodeType.entrance);
        return nodes.stream()
                .map(this::convertToNodeDto)
                .collect(Collectors.toList());
    }

    /**
     * 获取楼层平面图 - TDD 5.1 API接口4
     */
    @Transactional(readOnly = true)
    public FloorMapDto getFloorMap(String building, Integer floorLevel) {
        FloorMap floorMap = floorMapRepository.findByBuildingAndFloorLevel(building, floorLevel)
                .orElseThrow(() -> new ResourceNotFoundException(
                        String.format("楼层平面图不存在，建筑: %s, 楼层: %d", building, floorLevel)));

        FloorMapDto dto = new FloorMapDto();
        dto.setMapId(floorMap.getMapId());
        dto.setBuilding(floorMap.getBuilding());
        dto.setFloorLevel(floorMap.getFloorLevel());
        dto.setMapImageUrl(floorMap.getMapImageUrl());
        dto.setScaleRatio(floorMap.getScaleRatio());
        dto.setMapWidth(floorMap.getMapWidth());
        dto.setMapHeight(floorMap.getMapHeight());
        dto.setSvgPayload(floorMap.getSvgPayload());

        return dto;
    }

    /**
     * 手动选择位置接口 - TDD 5.1 API接口5
     */
    @Transactional(readOnly = true)
    public MapNodeDto confirmLocation(Long nodeId) {
        MapNode node = nodeCache.get(nodeId);
        if (node == null) {
            node = mapNodeRepository.findById(nodeId.intValue())
                    .orElseThrow(() -> new ResourceNotFoundException("节点不存在，ID: " + nodeId));
            nodeCache.put(node.getNodeId().longValue(), node);
        }
        return convertToNodeDto(node);
    }

    /**
     * 转换为DTO
     */
    private MapNodeDto convertToNodeDto(MapNode node) {
        MapNodeDto dto = new MapNodeDto();
        dto.setNodeId(node.getNodeId());
        dto.setNodeName(node.getNodeName());
        dto.setBuilding(node.getBuilding());
        dto.setFloorLevel(node.getFloorLevel());
        dto.setNodeType(node.getNodeType());
        dto.setQrCode(node.getQrCode());
        dto.setMapX(node.getMapX() != null ? node.getMapX().doubleValue() : null);
        dto.setMapY(node.getMapY() != null ? node.getMapY().doubleValue() : null);
        dto.setDescription(node.getDescription());
        dto.setEntry(node.getEntry());
        dto.setElevator(node.getElevator());
        dto.setStairs(node.getStairs());

        // 设置坐标
        if (node.getMapX() != null && node.getMapY() != null) {
            CoordinateDto coord = new CoordinateDto();
            coord.setX(node.getMapX().doubleValue());
            coord.setY(node.getMapY().doubleValue());
            dto.setCoordinate(coord);
        }

        return dto;
    }

    /**
     * A*算法节点内部类
     */
    private static class AStarNode {
        Long nodeId;
        double g; // 从起点到当前节点的实际距离
        double h; // 从当前节点到终点的启发式距离
        double f; // f = g + h

        AStarNode(Long nodeId, double g, double h) {
            this.nodeId = nodeId;
            this.g = g;
            this.h = h;
            this.f = g + h;
        }
    }

    /**
     * 边信息内部类
     */
    private static class EdgeInfo {
        MapEdge edge;
        boolean isReverse;

        EdgeInfo(MapEdge edge) {
            this(edge, false);
        }

        EdgeInfo(MapEdge edge, boolean isReverse) {
            this.edge = edge;
            this.isReverse = isReverse;
        }

        double getWeight() {
            return edge.getDistanceMeters().doubleValue();
        }
    }
}
