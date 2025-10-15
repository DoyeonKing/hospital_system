package com.example.springboot.entity; // 包名调整

import com.example.springboot.entity.enums.DoctorStatus; // 导入路径调整
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * 医生表
 */
@Entity
@Table(name = "doctors")
@Data
public class Doctor {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer doctorId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "clinic_id", nullable = false)
    private Clinic clinic; // 所属校医院/诊所

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department; // 所属科室

    @Column(nullable = false, unique = true, length = 100)
    private String identifier; // 医生的工号

    @Column(name = "password_hash", nullable = false)
    private String passwordHash; // 哈希加盐后的密码

    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName; // 真实姓名

    @Column(name = "phone_number", unique = true, length = 20)
    private String phoneNumber; // 存储E.164标准格式

    private String title; // 职称 (如：“主治医师”)
    private String specialty; // 擅长领域描述
    private String bio; // 个人简介

    @Column(name = "photo_url")
    private String photoUrl; // 头像照片URL

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DoctorStatus status; // 账户状态

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt; // 账户创建时间

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt; // 信息最后更新时间
}
