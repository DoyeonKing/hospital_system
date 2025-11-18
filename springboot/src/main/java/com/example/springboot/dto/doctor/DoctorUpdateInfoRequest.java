// DoctorUpdateInfoRequest.java
package com.example.springboot.dto.doctor;

import jakarta.validation.constraints.Pattern;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class DoctorUpdateInfoRequest {
    // 医生工号（用于标识要编辑的医生）
    private String identifier;

    // 手机号（可选更新字段）
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号码格式不正确")
    private String phoneNumber;

    // 擅长领域（可选更新字段）
    private String specialty;

    // 个人简介（可选更新字段）
    private String bio;

    // 头像图片（可选更新字段）
    private MultipartFile avatarFile;
}