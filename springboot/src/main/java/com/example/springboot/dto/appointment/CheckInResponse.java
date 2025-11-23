package com.example.springboot.dto.appointment;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 扫码签到响应DTO
 */
@Data
public class CheckInResponse {
    private Integer appointmentId;
    private String patientName;
    private String departmentName;
    private String doctorName;
    private LocalDateTime checkInTime;
    private Integer appointmentNumber;
}



