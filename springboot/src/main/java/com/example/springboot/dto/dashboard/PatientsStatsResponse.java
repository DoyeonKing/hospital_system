package com.example.springboot.dto.dashboard;

import lombok.Data;

import java.util.List;

@Data
public class PatientsStatsResponse {
    private long monthlyNewRegistrations;
    private String teacherStaffStudentRatio;
    private long totalNoShows;

    private List<String> last30DaysDates;
    private List<Integer> last30DaysCounts;

    private List<SimpleNameValue> patientType;
    private List<TimeSlotItem> timeSlotData;

    @Data
    public static class TimeSlotItem {
        private String time;
        private long count;
    }
}


