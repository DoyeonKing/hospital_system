package com.example.springboot.dto.dashboard;

import lombok.Data;

import java.util.List;

@Data
public class DoctorsStatsResponse {
    private long totalDoctors;
    private long todayLeaveCount;
    private long totalDepartments;

    private List<SimpleNameValue> titleDistribution;
    private List<SimpleNameValue> departmentBusy;
    private List<DoctorWorkloadItem> doctorWorkload;

    @Data
    public static class DoctorWorkloadItem {
        private String name;
        private String department;
        private long value;
    }
}




















