package com.example.springboot.dto.patient;

import lombok.Data;

@Data
public class PatientSimpleResponse {
    // 根据业务需求添加字段，例如：
    private Long patientId;
    private String Name;
    private String identifier;
    private String phone;
}