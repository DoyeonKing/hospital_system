// 完善PatientUpdateRequest
package com.example.springboot.dto.patient;

import com.example.springboot.entity.enums.Gender;
import com.example.springboot.entity.enums.PatientStatus;
import com.example.springboot.entity.enums.PatientType;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class PatientUpdateRequest {
    // 基本信息
    @Size(max = 100, message = "学号或工号长度不能超过100个字符")
    private String identifier;

    private PatientType patientType;

    @Size(min = 6, max = 255, message = "密码长度至少为6个字符")
    private String password;

    @Size(max = 100, message = "姓名长度不能超过100个字符")
    private String fullName;

    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号码格式不正确")
    @Size(max = 20, message = "电话号码长度不能超过20个字符")
    private String phoneNumber;

    private String status;

    // 患者档案信息
    @Size(max = 18, message = "身份证号长度不能超过18个字符")
    private String idCardNumber;

    private String allergies; // 过敏史
    private String medicalHistory; // 既往病史
    
    // 新增字段
    private LocalDate birthDate; // 出生日期
    private Gender gender; // 性别
    
    @Size(max = 200, message = "家庭地址长度不能超过200个字符")
    private String homeAddress; // 家庭地址
    
    @Size(max = 100, message = "紧急联系人姓名长度不能超过100个字符")
    private String emergencyContactName; // 紧急联系人姓名
    
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "紧急联系人电话格式不正确")
    @Size(max = 20, message = "紧急联系人电话长度不能超过20个字符")
    private String emergencyContactPhone; // 紧急联系人电话
    
    private BigDecimal height; // 身高(cm)
    private BigDecimal weight; // 体重(kg)
}