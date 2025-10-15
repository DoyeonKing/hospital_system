package com.example.springboot.dto.clinic;

import lombok.Data;

@Data
public class ClinicResponse {
    private Integer clinicId;
    private String name;
    private String province;
    private String city;
    private String district;
    private String detailedAddress;
}
