package com.example.springboot.entity; // 包名调整

import jakarta.persistence.*;
import lombok.Data;

import java.util.Set;

/**
 * 科室表
 */
@Entity
@Table(name = "departments")
@Data
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer departmentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "clinic_id", nullable = false)
    private Clinic clinic; // 所属校医院/诊所

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private Department parentDepartment; // 指向本表, 用于层级关系

    @Column(nullable = false, length = 100)
    private String name; // 科室名称

    private String description; // 科室职能描述

    // 孩子部门
    @OneToMany(mappedBy = "parentDepartment", fetch = FetchType.LAZY)
    private Set<Department> childrenDepartments;
}
