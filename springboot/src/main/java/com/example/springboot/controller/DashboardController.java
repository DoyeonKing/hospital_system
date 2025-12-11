package com.example.springboot.controller;

import com.example.springboot.dto.dashboard.DoctorsStatsResponse;
import com.example.springboot.dto.dashboard.OverviewStatsResponse;
import com.example.springboot.dto.dashboard.PatientsStatsResponse;
import com.example.springboot.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    /**
     * 获取运营总览统计数据
     */
    @GetMapping("/overview")
    public ResponseEntity<OverviewStatsResponse> getOverview() {
        OverviewStatsResponse response = dashboardService.getOverviewStats();
        return ResponseEntity.ok(response);
    }

    /**
     * 获取医生资源分析统计数据
     */
    @GetMapping("/doctors")
    public ResponseEntity<DoctorsStatsResponse> getDoctors() {
        DoctorsStatsResponse response = dashboardService.getDoctorsStats();
        return ResponseEntity.ok(response);
    }

    /**
     * 获取患者群体画像统计数据
     * @param startDate 起始日期（可选，格式：yyyy-MM-dd）
     * @param endDate 结束日期（可选，格式：yyyy-MM-dd）
     */
    @GetMapping("/patients")
    public ResponseEntity<PatientsStatsResponse> getPatients(
            @RequestParam(required = false) java.time.LocalDate startDate,
            @RequestParam(required = false) java.time.LocalDate endDate) {
        PatientsStatsResponse response = dashboardService.getPatientsStats(startDate, endDate);
        return ResponseEntity.ok(response);
    }
}

