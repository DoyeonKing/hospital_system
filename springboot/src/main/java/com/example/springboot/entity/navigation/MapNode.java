package com.example.springboot.entity.navigation;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 地图节点表
 */
@Entity
@Table(name = "map_nodes")
@Data
public class MapNode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "node_id")
    private Integer nodeId;

    @Column(name = "node_name", nullable = false, length = 100)
    private String nodeName;

    @Enumerated(EnumType.STRING)
    @Column(name = "node_type", nullable = false)
    private NodeType nodeType;

    @Column(name = "coordinates_x", nullable = false, precision = 10, scale = 2)
    private BigDecimal coordinatesX;

    @Column(name = "coordinates_y", nullable = false, precision = 10, scale = 2)
    private BigDecimal coordinatesY;

    @Column(name = "floor_level", nullable = false)
    private Integer floorLevel;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_accessible", nullable = false)
    private Boolean isAccessible = true;

    // 以下字段不在数据库表中，标记为 @Transient 以避免 Hibernate 尝试从数据库读取
    @Transient
    private String building;

    @Transient
    private String qrCode;

    @Transient
    private Boolean entry;

    @Transient
    private Boolean elevator;

    @Transient
    private Boolean stairs;

    // 为了兼容NavigationService中的方法，添加别名字段
    public BigDecimal getMapX() {
        return coordinatesX;
    }

    public void setMapX(BigDecimal mapX) {
        this.coordinatesX = mapX;
    }

    public BigDecimal getMapY() {
        return coordinatesY;
    }

    public void setMapY(BigDecimal mapY) {
        this.coordinatesY = mapY;
    }

    public enum NodeType {
        room, hallway, elevator, stairs, entrance
    }
}


