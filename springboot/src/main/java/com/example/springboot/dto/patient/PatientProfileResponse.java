package com.example.springboot.dto.patient;

import com.example.springboot.entity.enums.Gender;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class PatientProfileResponse {
    private String idCardNumber;
    private String allergies;
    private String medicalHistory;
    private Integer noShowCount;
    private String blacklistStatus;
    private LocalDate birthDate;
    private Gender gender;
    private String homeAddress;
    private String emergencyContactName;
    private String emergencyContactPhone;
    private BigDecimal height;
    private BigDecimal weight;
}

