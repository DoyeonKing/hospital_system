package com.example.springboot.dto.patient;

import com.example.springboot.entity.enums.PatientType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 患者自主注册请求DTO
 */
@Data
public class PatientSelfRegisterRequest {
    @NotBlank(message = "学号/工号不能为空")
    @Size(max = 100, message = "学号/工号长度不能超过100个字符")
    private String identifier;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 20, message = "密码长度必须在6-20位之间")
    private String password;

    @NotBlank(message = "姓名不能为空")
    @Size(max = 100, message = "姓名长度不能超过100个字符")
    private String fullName;

    @NotBlank(message = "手机号不能为空")
    @Size(max = 20, message = "手机号长度不能超过20个字符")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phoneNumber;

    @NotBlank(message = "身份证号不能为空")
    @Size(min = 15, max = 18, message = "身份证号长度必须在15-18位之间")
    private String idCardNumber;

    @NotNull(message = "患者类型不能为空")
    private PatientType patientType;

    /**
     * 身份证正面照片URL
     * 前端先上传文件获取URL，然后提交注册请求
     */
    @NotBlank(message = "身份证正面照片不能为空")
    private String idCardFrontUrl;

    /**
     * 身份证背面照片URL
     * 前端先上传文件获取URL，然后提交注册请求
     */
    @NotBlank(message = "身份证背面照片不能为空")
    private String idCardBackUrl;
}

