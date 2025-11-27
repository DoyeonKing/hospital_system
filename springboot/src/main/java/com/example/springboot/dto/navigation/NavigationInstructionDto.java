package com.example.springboot.dto.navigation;

import lombok.Data;

/**
 * 导航指引DTO
 */
@Data
public class NavigationInstructionDto {
    private Integer step;
    private String instruction;
    private Double distance;
    private String transitionType;
    private Integer floorLevel;
}






