package com.example.springboot.service;

import com.example.springboot.dto.dashboard.DoctorsStatsResponse;
import com.example.springboot.dto.dashboard.OverviewStatsResponse;
import com.example.springboot.dto.dashboard.PatientsStatsResponse;

public interface DashboardService {
    /**
     * 获取运营总览统计数据
     */
    OverviewStatsResponse getOverviewStats();

    /**
     * 获取医生资源分析统计数据
     */
    DoctorsStatsResponse getDoctorsStats();

    /**
     * 获取患者群体画像统计数据
     * @param startDate 起始日期（可选，为null时统计所有数据）
     * @param endDate 结束日期（可选，为null时统计所有数据）
     */
    PatientsStatsResponse getPatientsStats(java.time.LocalDate startDate, java.time.LocalDate endDate);
}

