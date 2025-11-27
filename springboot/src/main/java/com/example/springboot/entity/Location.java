package com.example.springboot.entity;

import com.example.springboot.entity.navigation.MapNode;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 诊室表
 */
@Entity
@Table(name = "locations")
@Data
public class Location {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer locationId;

    @Column(name = "location_name", length = 100)
    private String locationName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    @JsonIgnore
    private Department department;

    @Column(name = "floor_level")
    private Integer floorLevel;

    @Column(name = "building", length = 50)
    private String building;

    @Column(name = "room_number", length = 20)
    private String roomNumber;

    @Column(name = "capacity")
    private Integer capacity;

    // 以下字段在数据库中不存在，使用@Transient标记，不持久化到数据库
    @Transient
    private BigDecimal latitude;

    @Transient
    private BigDecimal longitude;

    @Transient
    private String addressDetail;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "map_node_id")
    @JsonIgnore
    private MapNode mapNode;
}