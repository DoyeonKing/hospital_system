package com.example.springboot.dto.navigation;

import com.example.springboot.entity.navigation.MapNode;
import lombok.Data;

/**
 * 地图节点DTO
 */
@Data
public class MapNodeDto {
    private Integer nodeId;
    private String nodeName;
    private String building;
    private Integer floorLevel;
    private MapNode.NodeType nodeType;
    private String qrCode;
    private Double mapX;
    private Double mapY;
    private String description;
    private Boolean entry;
    private Boolean elevator;
    private Boolean stairs;
    private CoordinateDto coordinate;
}




