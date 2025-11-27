package com.example.springboot.service;

import com.example.springboot.dto.map.MapConfigResponse;
import com.example.springboot.dto.map.MapGridDTO;
import com.example.springboot.dto.map.MapNodeDTO;
import com.example.springboot.entity.Location;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.LocationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * 地图服务
 * 提供地图配置和节点查询功能
 */
@Service
public class MapService {
    
    // 地图网格尺寸
    private static final int GRID_WIDTH = 40;
    private static final int GRID_HEIGHT = 30;
    
    // 网格矩阵（0=通路，1=障碍物）
    private int[][] gridMatrix;
    
    // 节点列表
    private List<MapNodeDTO> nodes;
    
    private final LocationRepository locationRepository;
    
    /**
     * 构造函数：初始化地图数据
     */
    @Autowired
    public MapService(LocationRepository locationRepository) {
        this.locationRepository = locationRepository;
        System.out.println("[MapService] 开始初始化地图数据...");
        initializeMapData();
        System.out.println("[MapService] 地图数据初始化完成，节点数量: " + nodes.size());
    }
    
    /**
     * 初始化地图数据
     * 创建一个40x30的网格，设置障碍物，并预设关键节点
     */
    private void initializeMapData() {
        // 初始化网格矩阵（全部设为通路）
        gridMatrix = new int[GRID_HEIGHT][GRID_WIDTH];
        
        // 设置障碍物（墙壁区域）
        // 左侧墙壁（x=0到x=3）
        for (int y = 0; y < GRID_HEIGHT; y++) {
            for (int x = 0; x < 4; x++) {
                if (y < 8 || y > 12) { // 留出通道
                    gridMatrix[y][x] = 1;
                }
            }
        }
        
        // 右侧墙壁（x=36到x=39）
        for (int y = 0; y < GRID_HEIGHT; y++) {
            for (int x = 36; x < GRID_WIDTH; x++) {
                if (y < 18 || y > 22) { // 留出通道
                    gridMatrix[y][x] = 1;
                }
            }
        }
        
        // 中间横向墙壁（y=15到y=17，x=10到x=30）
        for (int y = 15; y < 18; y++) {
            for (int x = 10; x < 31; x++) {
                gridMatrix[y][x] = 1;
            }
        }
        
        // 上方横向墙壁（y=0到y=2）
        for (int y = 0; y < 3; y++) {
            for (int x = 0; x < GRID_WIDTH; x++) {
                gridMatrix[y][x] = 1;
            }
        }
        
        // 下方横向墙壁（y=27到y=29），但起点(20,29)需要可通行
        for (int y = 27; y < GRID_HEIGHT; y++) {
            for (int x = 0; x < GRID_WIDTH; x++) {
                // 起点(20,29)周围留出通道（x=18到x=22）
                if (!(y == 29 && x >= 18 && x <= 22)) {
                    gridMatrix[y][x] = 1;
                }
            }
        }
        
        // 中间纵向墙壁（x=15到x=17，y=5到y=12）
        for (int y = 5; y < 13; y++) {
            for (int x = 15; x < 18; x++) {
                gridMatrix[y][x] = 1;
            }
        }
        
        // 确保关键节点位置是通路
        // Node 1: 医院大门 (20, 29)
        gridMatrix[29][20] = 0;
        gridMatrix[28][20] = 0;
        gridMatrix[29][19] = 0;
        gridMatrix[29][21] = 0;
        
        // Node 2: 分诊台 (20, 20)
        gridMatrix[20][20] = 0;
        gridMatrix[20][19] = 0;
        gridMatrix[20][21] = 0;
        gridMatrix[19][20] = 0;
        gridMatrix[21][20] = 0;
        
        // Node 3: 电梯口 (35, 20)
        gridMatrix[20][35] = 0;
        gridMatrix[20][34] = 0;
        gridMatrix[20][36] = 0;
        gridMatrix[19][35] = 0;
        gridMatrix[21][35] = 0;
        
        // Node 4: 内科诊室 (5, 10)
        gridMatrix[10][5] = 0;
        gridMatrix[10][4] = 0;
        gridMatrix[10][6] = 0;
        gridMatrix[9][5] = 0;
        gridMatrix[11][5] = 0;
        
        // Node 5: 外科诊室 (5, 5)
        gridMatrix[5][5] = 0;
        gridMatrix[5][4] = 0;
        gridMatrix[5][6] = 0;
        gridMatrix[4][5] = 0;
        gridMatrix[6][5] = 0;
        
        // 确保起点到终点有通路（创建主要通道）
        // 从起点(20,29)向上到(20,20)，然后向左到(5,20)，再向上到(5,10)
        for (int y = 20; y <= 29; y++) {
            gridMatrix[y][20] = 0; // 纵向通道
        }
        for (int x = 5; x <= 20; x++) {
            // 避开中间横向墙壁（y=15到y=17）
            if (x < 10 || x > 30) {
                gridMatrix[20][x] = 0; // 横向通道
            }
        }
        for (int y = 10; y <= 20; y++) {
            gridMatrix[y][5] = 0; // 纵向通道到内科诊室
        }
        
        // 初始化节点列表
        nodes = new ArrayList<>();
        // 添加固定的公共节点
        nodes.add(new MapNodeDTO(1, "医院大门", 20, 29, null));
        nodes.add(new MapNodeDTO(2, "分诊台", 20, 20, null));
        nodes.add(new MapNodeDTO(3, "电梯口", 35, 20, null));
        
        // 从数据库加载真实的就诊地点信息
        try {
            List<Location> locations = locationRepository.findAll();
            System.out.println("[MapService] 从数据库加载了 " + locations.size() + " 个就诊地点");
            
            // 预定义的节点坐标映射（根据mapNodeId或locationId）
            // 这里可以根据实际情况调整坐标
            Map<Integer, int[]> nodeCoordinates = new HashMap<>();
            nodeCoordinates.put(1, new int[]{5, 10}); // locationId=1的坐标
            nodeCoordinates.put(2, new int[]{5, 5});  // locationId=2的坐标
            nodeCoordinates.put(3, new int[]{35, 10}); // locationId=3的坐标（如果有）
            nodeCoordinates.put(4, new int[]{35, 5});  // locationId=4的坐标（如果有）
            
            int nodeIdCounter = 4; // 从4开始，因为1-3是公共节点
            for (Location location : locations) {
                int[] coordinates = nodeCoordinates.getOrDefault(location.getLocationId(), new int[]{5, 10});
                
                // 使用真实的就诊地点名称
                MapNodeDTO node = new MapNodeDTO(
                    nodeIdCounter++,
                    location.getLocationName(), // 从数据库获取真实名称
                    coordinates[0],
                    coordinates[1],
                    location.getLocationId()
                );
                nodes.add(node);
                
                System.out.println("[MapService] 添加节点: " + location.getLocationName() + 
                    " (locationId=" + location.getLocationId() + 
                    ", 坐标=[" + coordinates[0] + "," + coordinates[1] + "])");
            }
        } catch (Exception e) {
            System.err.println("[MapService] 从数据库加载就诊地点失败，使用默认数据: " + e.getMessage());
            // 如果数据库加载失败，使用默认数据
        nodes.add(new MapNodeDTO(4, "内科诊室", 5, 10, 1));
        nodes.add(new MapNodeDTO(5, "外科诊室", 5, 5, 2));
        }
    }
    
    /**
     * 获取地图配置
     * @return 包含网格和所有节点的配置响应
     */
    public MapConfigResponse getMapConfig() {
        System.out.println("[MapService] 获取地图配置，节点数量: " + (nodes != null ? nodes.size() : 0));
        System.out.println("[MapService] 网格矩阵是否为空: " + (gridMatrix == null));
        
        if (gridMatrix == null || nodes == null) {
            System.err.println("[MapService] 警告：地图数据未初始化，重新初始化...");
            initializeMapData();
        }
        
        MapGridDTO grid = new MapGridDTO(GRID_WIDTH, GRID_HEIGHT, gridMatrix);
        MapConfigResponse response = new MapConfigResponse(grid, new ArrayList<>(nodes));
        
        System.out.println("[MapService] 返回配置，grid宽度: " + grid.getWidth() + ", 高度: " + grid.getHeight());
        System.out.println("[MapService] 返回节点数量: " + response.getNodes().size());
        
        return response;
    }
    
    /**
     * 根据locationId查询对应的地图节点
     * @param locationId 诊室ID
     * @return 对应的地图节点，如果不存在则抛出异常
     */
    public MapNodeDTO getNodeByLocationId(Integer locationId) {
        if (locationId == null) {
            throw new IllegalArgumentException("locationId不能为空");
        }
        
        return nodes.stream()
                .filter(node -> locationId.equals(node.getLocationId()))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                    "未找到locationId为" + locationId + "的地图节点"));
    }
    
    /**
     * 根据nodeId查询节点
     * @param nodeId 节点ID
     * @return 对应的地图节点
     */
    public MapNodeDTO getNodeByNodeId(Integer nodeId) {
        if (nodeId == null) {
            throw new IllegalArgumentException("nodeId不能为空");
        }
        
        return nodes.stream()
                .filter(node -> nodeId.equals(node.getNodeId()))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                    "未找到nodeId为" + nodeId + "的地图节点"));
    }
}

