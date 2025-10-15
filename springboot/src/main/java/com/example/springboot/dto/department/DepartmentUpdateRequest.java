package com.example.springboot.dto.department;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DepartmentUpdateRequest {
    private Integer clinicId;
    private Integer parentId;
    @Size(max = 100, message = "科室名称长度不能超过100个字符")
    private String name;
    private String description;
}
