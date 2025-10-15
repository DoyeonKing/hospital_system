package com.example.springboot.dto.patient; // 包名调整

import com.example.springboot.entity.enums.PatientStatus; // 导入路径调整
import com.example.springboot.entity.enums.PatientType;   // 导入路径调整
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PatientUpdateRequest {
    @Size(max = 100, message = "学号或工号长度不能超过100个字符")
    private String identifier;

    private PatientType patientType;

    @Size(min = 6, max = 255, message = "密码长度至少为6个字符")
    private String password;

    @Size(max = 100, message = "姓名长度不能超过100个字符")
    private String fullName;

    @Size(max = 20, message = "电话号码长度不能超过20个字符")
    private String phoneNumber;

    private PatientStatus status;
}
