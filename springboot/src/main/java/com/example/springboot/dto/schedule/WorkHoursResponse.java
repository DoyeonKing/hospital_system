package com.example.springboot.dto.schedule;

import lombok.Data;

@Data
public class WorkHoursResponse {
    private String workDate;
    private String segmentLabel;
    private String firstCallDisplay;
    private String lastEndDisplay;
    private Double rawHours;
    private Double regHours;
    private Integer visitCount;
    private Boolean nightFlag;
    private String locations;
    private Double performancePoints;
}
