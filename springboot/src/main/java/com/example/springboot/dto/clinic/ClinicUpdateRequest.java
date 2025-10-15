package com.example.springboot.dto.clinic;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ClinicUpdateRequest {
    private String name;
    private String province;
    private String city;
    private String district;

    @Size(max = 255, message = "详细地址长度不能超过255个字符")
    private String detailedAddress;
}
