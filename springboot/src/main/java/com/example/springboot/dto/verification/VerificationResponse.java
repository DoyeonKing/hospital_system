package com.example.springboot.dto.verification;

import com.example.springboot.entity.enums.PatientType;
import com.example.springboot.entity.enums.VerificationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 身份验证记录响应DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerificationResponse {
    private Long verificationId;
    private Long patientId;
    private String identifier;
    private String fullName;
    private String idCardNumber;
    private String phoneNumber;
    private PatientType patientType;
    private String idCardFrontUrl;
    private String idCardBackUrl;
    private VerificationStatus status;
    private String rejectionReason;
    private Integer reviewedBy;
    private String reviewedByName;
    private LocalDateTime reviewedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

