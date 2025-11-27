package com.example.springboot.dto.navigation;

import lombok.Data;

/**
 * 楼层平面图DTO
 */
@Data
public class FloorMapDto {
    private Long mapId;
    private String building;
    private Integer floorLevel;
    private String mapImageUrl;
    private Double scaleRatio;
    private Integer mapWidth;
    private Integer mapHeight;
    private String svgPayload;
}



