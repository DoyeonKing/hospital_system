package com.example.springboot.dto.department;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DepartmentCreateRequest {
    @NotNull(message = "所属诊所ID不能为空")
    private Integer clinicId;

    private Integer parentId; // 上级部门ID，可以为空

    @NotBlank(message = "科室名称不能为空")
    @Size(max = 100, message = "科室名称长度不能超过100个字符")
    private String name;

    private String description;
}
