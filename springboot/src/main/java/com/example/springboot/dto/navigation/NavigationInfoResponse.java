package com.example.springboot.dto.navigation;

import lombok.Data;

/**
 * 导航信息响应DTO
 */
@Data
public class NavigationInfoResponse {
    private Integer locationId;
    private String locationName;
    private String building;
    private Integer floorLevel;
    private String roomNumber;
    private Double latitude;
    private Double longitude;
    private String addressDetail;
    private Integer mapNodeId;
}






