package com.example.springboot.dto.schedule;

import com.example.springboot.dto.doctor.DoctorResponse; // 导入医生响应DTO
import com.example.springboot.entity.enums.ScheduleStatus;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
public class ScheduleResponse {
    private Integer scheduleId;
    private DoctorResponse doctor; // 医生信息
    private LocalDate scheduleDate;
    private Integer timeSlotId; // 仅时间段ID，或更详细的TimeSlotResponse
    private String timeSlotName; // 方便展示
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer totalSlots;
    private Integer bookedSlots;
    private BigDecimal fee;
    private ScheduleStatus status;
    private String remarks;
}
