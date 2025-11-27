package com.example.springboot.entity.navigation;

import jakarta.persistence.*;
import lombok.Data;

/**
 * 楼层平面图表
 */
@Entity
@Table(name = "floor_maps")
@Data
public class FloorMap {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "map_id")
    private Long mapId;

    @Column(name = "building", nullable = false, length = 50)
    private String building;

    @Column(name = "floor_level", nullable = false)
    private Integer floorLevel;

    @Column(name = "map_image_url", length = 500)
    private String mapImageUrl;

    @Column(name = "scale_ratio")
    private Double scaleRatio;

    @Column(name = "map_width")
    private Integer mapWidth;

    @Column(name = "map_height")
    private Integer mapHeight;

    @Column(name = "svg_payload", columnDefinition = "TEXT")
    private String svgPayload;
}




