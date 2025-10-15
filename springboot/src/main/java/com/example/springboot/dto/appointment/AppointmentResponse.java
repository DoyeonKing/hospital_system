package com.example.springboot.dto.appointment;

import com.example.springboot.dto.doctor.DoctorResponse; // 导入医生响应DTO
import com.example.springboot.dto.patient.PatientResponse; // 导入患者响应DTO
import com.example.springboot.dto.schedule.ScheduleResponse; // 导入排班响应DTO
import com.example.springboot.entity.enums.AppointmentStatus;
import com.example.springboot.entity.enums.PaymentStatus;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AppointmentResponse {
    private Integer appointmentId;
    private PatientResponse patient; // 患者信息
    private ScheduleResponse schedule; // 排班信息
    private Integer appointmentNumber;
    private AppointmentStatus status;
    private PaymentStatus paymentStatus;
    private String paymentMethod;
    private String transactionId;
    private LocalDateTime checkInTime;
    private LocalDateTime createdAt;
}
