package com.example.springboot.controller;

import com.example.springboot.common.BaseResponse;
import com.example.springboot.dto.navigation.*;
import com.example.springboot.service.NavigationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 导航控制器 - 严格遵循TDD第5.1章API接口设计
 */
@RestController
@RequestMapping("/api/navigation")
@Slf4j
@RequiredArgsConstructor
public class NavigationController {

    private final NavigationService navigationService;

    /**
     * API接口1：获取导航信息（根据预约ID）
     * GET /api/navigation/info-by-appointment/{appointmentId}
     */
    @GetMapping("/info-by-appointment/{appointmentId}")
    public BaseResponse<NavigationInfoResponse> getNavigationInfoByAppointment(
            @PathVariable Integer appointmentId) {
        try {
            NavigationInfoResponse info = navigationService.getNavigationInfoByAppointment(appointmentId);
            return BaseResponse.success(info);
        } catch (Exception e) {
            log.error("获取导航信息失败，预约ID: {}", appointmentId, e);
            return BaseResponse.error("获取导航信息失败: " + e.getMessage());
        }
    }

    /**
     * API接口1：获取导航信息（根据诊室ID）
     * GET /api/navigation/info-by-location/{locationId}
     */
    @GetMapping("/info-by-location/{locationId}")
    public BaseResponse<NavigationInfoResponse> getNavigationInfoByLocation(
            @PathVariable Integer locationId) {
        try {
            NavigationInfoResponse info = navigationService.getNavigationInfoByLocationId(locationId);
            return BaseResponse.success(info);
        } catch (Exception e) {
            log.error("获取导航信息失败，诊室ID: {}", locationId, e);
            return BaseResponse.error("获取导航信息失败: " + e.getMessage());
        }
    }

    /**
     * API接口2：扫码定位接口
     * POST /api/navigation/location-scan
     */
    @PostMapping("/location-scan")
    public BaseResponse<MapNodeDto> scanLocation(@RequestBody Map<String, String> request) {
        try {
            String qrCode = request.get("qrCode");
            if (qrCode == null || qrCode.trim().isEmpty()) {
                return BaseResponse.error("二维码内容不能为空");
            }
            MapNodeDto node = navigationService.scanLocation(qrCode.trim());
            return BaseResponse.success(node);
        } catch (Exception e) {
            log.error("扫码定位失败", e);
            return BaseResponse.error("扫码定位失败: " + e.getMessage());
        }
    }

    /**
     * API接口3：路径规划接口
     * GET /api/navigation/route?startNodeId={startNodeId}&endNodeId={endNodeId}&preferAccessible={preferAccessible}
     */
    @GetMapping("/route")
    public BaseResponse<NavigationPathResponse> planRoute(
            @RequestParam Long startNodeId,
            @RequestParam Long endNodeId,
            @RequestParam(required = false, defaultValue = "false") Boolean preferAccessible) {
        try {
            NavigationPathResponse path = navigationService.planRoute(startNodeId, endNodeId, preferAccessible);
            return BaseResponse.success(path);
        } catch (Exception e) {
            log.error("路径规划失败，起点: {}, 终点: {}", startNodeId, endNodeId, e);
            return BaseResponse.error("路径规划失败: " + e.getMessage());
        }
    }

    /**
     * 根据预约ID获取导航路径（便捷接口）
     * GET /api/navigation/route-by-appointment/{appointmentId}
     */
    @GetMapping("/route-by-appointment/{appointmentId}")
    public BaseResponse<NavigationPathResponse> getRouteByAppointment(
            @PathVariable Integer appointmentId,
            @RequestParam(required = false) Long startNodeId) {
        try {
            // 获取目标诊室信息
            NavigationInfoResponse info = navigationService.getNavigationInfoByAppointment(appointmentId);
            if (info.getMapNodeId() == null) {
                return BaseResponse.error("预约的诊室未关联地图节点");
            }
            
            // 如果没有指定起点，使用第一个入口节点作为默认起点
            if (startNodeId == null) {
                List<MapNodeDto> entrances = navigationService.getEntranceNodes();
                if (entrances.isEmpty()) {
                    return BaseResponse.error("未找到入口节点");
                }
                startNodeId = entrances.get(0).getNodeId().longValue();
            }
            
            NavigationPathResponse path = navigationService.planRoute(startNodeId, info.getMapNodeId().longValue(), false);
            return BaseResponse.success(path);
        } catch (Exception e) {
            log.error("根据预约获取路径失败，预约ID: {}", appointmentId, e);
            return BaseResponse.error("获取路径失败: " + e.getMessage());
        }
    }

    /**
     * API接口4：获取楼层平面图接口
     * GET /api/navigation/floor-map/{building}/{floorLevel}
     */
    @GetMapping("/floor-map/{building}/{floorLevel}")
    public BaseResponse<FloorMapDto> getFloorMap(
            @PathVariable String building,
            @PathVariable Integer floorLevel) {
        try {
            FloorMapDto floorMap = navigationService.getFloorMap(building, floorLevel);
            return BaseResponse.success(floorMap);
        } catch (Exception e) {
            log.error("获取楼层平面图失败，建筑: {}, 楼层: {}", building, floorLevel, e);
            return BaseResponse.error("获取楼层平面图失败: " + e.getMessage());
        }
    }

    /**
     * API接口5：手动选择位置接口
     * POST /api/navigation/confirm-location
     */
    @PostMapping("/confirm-location")
    public BaseResponse<MapNodeDto> confirmLocation(@RequestBody Map<String, Long> request) {
        try {
            Long nodeId = request.get("nodeId");
            if (nodeId == null) {
                return BaseResponse.error("节点ID不能为空");
            }
            MapNodeDto node = navigationService.confirmLocation(nodeId);
            return BaseResponse.success(node);
        } catch (Exception e) {
            log.error("确认位置失败", e);
            return BaseResponse.error("确认位置失败: " + e.getMessage());
        }
    }

    /**
     * 搜索节点接口
     * GET /api/navigation/search?keyword={keyword}
     */
    @GetMapping("/search")
    public BaseResponse<List<MapNodeDto>> searchNodes(@RequestParam String keyword) {
        try {
            List<MapNodeDto> nodes = navigationService.searchNodes(keyword);
            return BaseResponse.success(nodes);
        } catch (Exception e) {
            log.error("搜索节点失败，关键词: {}", keyword, e);
            return BaseResponse.error("搜索失败: " + e.getMessage());
        }
    }

    /**
     * 获取入口节点列表
     * GET /api/navigation/entrances
     */
    @GetMapping("/entrances")
    public BaseResponse<List<MapNodeDto>> getEntranceNodes() {
        try {
            List<MapNodeDto> entrances = navigationService.getEntranceNodes();
            return BaseResponse.success(entrances);
        } catch (Exception e) {
            log.error("获取入口节点失败", e);
            return BaseResponse.error("获取入口节点失败: " + e.getMessage());
        }
    }
}
