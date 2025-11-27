package com.example.springboot.dto.navigation;

import lombok.Data;

import java.util.List;

/**
 * 路径段DTO
 */
@Data
public class PathSegmentDto {
    private String building;
    private Integer floorLevel;
    private List<CoordinateDto> points;
}






