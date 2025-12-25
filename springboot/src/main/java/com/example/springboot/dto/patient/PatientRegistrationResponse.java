package com.example.springboot.dto.patient;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 患者注册响应DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PatientRegistrationResponse {
    private Long patientId;
    private String identifier;
    private String message;
    private String status; // pending, approved, rejected
}

