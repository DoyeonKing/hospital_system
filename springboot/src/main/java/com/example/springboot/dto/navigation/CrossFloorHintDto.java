package com.example.springboot.dto.navigation;

import lombok.Data;

/**
 * 跨楼层提示DTO
 */
@Data
public class CrossFloorHintDto {
    private Integer floorLevel;
    private String building;
    private String message;
}






