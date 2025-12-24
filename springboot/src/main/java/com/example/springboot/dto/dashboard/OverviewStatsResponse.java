package com.example.springboot.dto.dashboard;

import lombok.Data;

import java.util.List;

@Data
public class OverviewStatsResponse {
    private long todayAppointments;
    private long activeDoctorsToday;
    private long pendingPatients;
    private long totalPatients;

    private List<String> last7DaysDates;
    private List<Integer> last7DaysCounts;

    private List<SimpleNameValue> paymentStatus; // 已支付/待支付/退款

    private long totalHistoricalAppointments;
    private long totalHistoricalCancellations;
    private List<String> last30DaysAppointmentDates;
    private List<Integer> last30DaysAppointmentCounts;
    private List<String> last30DaysCancellationDates;
    private List<Integer> last30DaysCancellationCounts;
}


