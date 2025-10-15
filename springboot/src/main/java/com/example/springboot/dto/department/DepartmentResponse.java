package com.example.springboot.dto.department;

import com.example.springboot.dto.clinic.ClinicResponse; // 导入诊所响应DTO
import lombok.Data;

import java.util.List;

@Data
public class DepartmentResponse {
    private Integer departmentId;
    private ClinicResponse clinic; // 诊所信息
    private Integer parentId; // 上级部门ID
    private String name;
    private String description;
    private List<DepartmentResponse> childrenDepartments; // 包含子部门，用于树形结构
}
