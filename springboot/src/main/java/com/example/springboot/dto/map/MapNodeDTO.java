package com.example.springboot.dto.map;

import lombok.Data;

/**
 * 地图节点数据传输对象
 * 用于定义关键点（如大门、电梯、诊室）
 */
@Data
public class MapNodeDTO {
    /**
     * 节点ID
     */
    private Integer nodeId;
    
    /**
     * 节点名称（如"医院大门"、"分诊台"、"内科诊室"）
     */
    private String name;
    
    /**
     * X坐标（网格坐标）
     */
    private int x;
    
    /**
     * Y坐标（网格坐标）
     */
    private int y;
    
    /**
     * 关联的Location表ID（诊室节点才有此值）
     */
    private Integer locationId;
    
    public MapNodeDTO() {
    }
    
    public MapNodeDTO(Integer nodeId, String name, int x, int y, Integer locationId) {
        this.nodeId = nodeId;
        this.name = name;
        this.x = x;
        this.y = y;
        this.locationId = locationId;
    }
}




