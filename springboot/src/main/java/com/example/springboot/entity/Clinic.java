package com.example.springboot.entity; // 包名调整

import jakarta.persistence.*;
import lombok.Data;

/**
 * 校医院/诊所表
 */
@Entity
@Table(name = "clinics")
@Data
public class Clinic {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer clinicId;

    @Column(nullable = false)
    private String name; // 诊所名称

    private String province; // 省份
    private String city; // 城市
    private String district; // 区县

    @Column(name = "detailed_address")
    private String detailedAddress; // 详细地址
}
