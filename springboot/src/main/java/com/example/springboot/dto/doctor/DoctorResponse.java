package com.example.springboot.dto.doctor;

import com.example.springboot.dto.department.DepartmentDTO; // 导入部门响应DTO
import com.example.springboot.entity.enums.DoctorStatus;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class DoctorResponse {
    private Integer doctorId;
    private DepartmentDTO department; // 科室信息
    private String identifier;
    private String fullName;
    private String phoneNumber;
    private String title;
    private String specialty;
    private String bio;
    private String photoUrl;
    private DoctorStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
