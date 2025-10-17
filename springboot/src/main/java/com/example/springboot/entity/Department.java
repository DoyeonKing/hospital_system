package com.example.springboot.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.util.Set;

/**
 * 科室表
 */
@Entity
@Table(name = "departments") // 确保表名正确
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer departmentId; // 对应 department_id

    // 对应 parent_id 字段, 指向本表
    @JsonIgnore // <--- 新增：断开向上的序列化循环
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private Department parentDepartment;

    @Column(nullable = false, length = 100)
    private String name; // 科室名称

    private String description; // 科室职能描述

    // 孩子部门: 使用 @JsonIgnore 打破 Jackson 序列化循环引用
    @JsonIgnore
    @OneToMany(mappedBy = "parentDepartment", fetch = FetchType.LAZY)
    private Set<Department> childrenDepartments;

    // =======================================================
    // 手动生成的 Getter 和 Setter 方法 (保持不变)
    // =======================================================

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }

    public Department getParentDepartment() {
        return parentDepartment;
    }

    public void setParentDepartment(Department parentDepartment) {
        this.parentDepartment = parentDepartment;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Set<Department> getChildrenDepartments() {
        return childrenDepartments;
    }

    public void setChildrenDepartments(Set<Department> childrenDepartments) {
        this.childrenDepartments = childrenDepartments;
    }
}