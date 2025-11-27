package com.example.springboot.entity.navigation;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 地图路径表
 */
@Entity
@Table(name = "map_edges")
@Data
public class MapEdge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "edge_id")
    private Integer edgeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "start_node_id", nullable = false)
    private MapNode startNode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "end_node_id", nullable = false)
    private MapNode endNode;

    @Column(name = "distance", nullable = false, precision = 10, scale = 2)
    private BigDecimal distance;

    @Column(name = "walk_time", nullable = false)
    private Integer walkTime;

    @Column(name = "is_bidirectional", nullable = false)
    private Boolean isBidirectional = true;

    @Column(name = "accessibility_info", columnDefinition = "TEXT")
    private String accessibilityInfo;

    // 以下字段不在数据库表中，标记为 @Transient 以避免 Hibernate 尝试从数据库读取
    @Transient
    private String pathPoints;

    @Transient
    private String directionHint;

    @Transient
    private String transitionType;

    // 为了兼容NavigationService中的方法，添加别名方法
    public BigDecimal getDistanceMeters() {
        return distance;
    }

    public void setDistanceMeters(BigDecimal distanceMeters) {
        this.distance = distanceMeters;
    }

    // 别名方法：getFromNode() -> getStartNode()
    public MapNode getFromNode() {
        return startNode;
    }

    public void setFromNode(MapNode fromNode) {
        this.startNode = fromNode;
    }

    // 别名方法：getToNode() -> getEndNode()
    public MapNode getToNode() {
        return endNode;
    }

    public void setToNode(MapNode toNode) {
        this.endNode = toNode;
    }

    // 别名方法：getBidirectional() -> getIsBidirectional()
    public Boolean getBidirectional() {
        return isBidirectional;
    }

    public void setBidirectional(Boolean bidirectional) {
        this.isBidirectional = bidirectional;
    }
}



