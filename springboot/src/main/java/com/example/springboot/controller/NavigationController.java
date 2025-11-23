package com.example.springboot.controller;

import com.example.springboot.dto.navigation.*;
import com.example.springboot.service.NavigationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/navigation")
public class NavigationController {

    private final NavigationService navigationService;

    @Autowired
    public NavigationController(NavigationService navigationService) {
        this.navigationService = navigationService;
    }

    /**
     * 计算两点之间的最短路径
     * GET /api/navigation/route?startNodeId={start}&endNodeId={end}&preferAccessible={prefer}
     */
    @GetMapping("/route")
    public ResponseEntity<NavigationRouteResponse> findRoute(
            @RequestParam Integer startNodeId,
            @RequestParam Integer endNodeId,
            @RequestParam(required = false, defaultValue = "false") Boolean preferAccessible) {
        NavigationRouteResponse response = navigationService.findRoute(startNodeId, endNodeId, preferAccessible);
        return ResponseEntity.ok(response);
    }

    /**
     * 根据预约ID获取导航路径（从入口到诊室）
     * GET /api/navigation/route-by-appointment/{appointmentId}
     */
    @GetMapping("/route-by-appointment/{appointmentId}")
    public ResponseEntity<NavigationRouteResponse> findRouteByAppointment(
            @PathVariable Integer appointmentId) {
        NavigationRouteResponse response = navigationService.findRouteByAppointment(appointmentId);
        return ResponseEntity.ok(response);
    }

    /**
     * 获取指定楼层的地图数据
     * GET /api/navigation/floor-map/{floorLevel}
     */
    @GetMapping("/floor-map/{floorLevel}")
    public ResponseEntity<FloorMapResponse> getFloorMap(@PathVariable Integer floorLevel) {
        FloorMapResponse response = navigationService.getFloorMap(floorLevel);
        return ResponseEntity.ok(response);
    }

    /**
     * 搜索地点
     * GET /api/navigation/search?keyword={keyword}
     */
    @GetMapping("/search")
    public ResponseEntity<List<MapNodeResponse>> searchNodes(@RequestParam String keyword) {
        List<MapNodeResponse> nodes = navigationService.searchNodes(keyword);
        return ResponseEntity.ok(nodes);
    }

    /**
     * 获取所有入口节点（通常作为导航起点）
     * GET /api/navigation/entrances
     */
    @GetMapping("/entrances")
    public ResponseEntity<List<MapNodeResponse>> getEntranceNodes() {
        List<MapNodeResponse> nodes = navigationService.getEntranceNodes();
        return ResponseEntity.ok(nodes);
    }

}

