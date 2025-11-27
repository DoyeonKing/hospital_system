package com.example.springboot.repository;

import com.example.springboot.entity.navigation.FloorMap;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 楼层平面图Repository
 */
@Repository
public interface FloorMapRepository extends JpaRepository<FloorMap, Long> {
    
    /**
     * 根据楼栋和楼层查找平面图
     */
    Optional<FloorMap> findByBuildingAndFloorLevel(String building, Integer floorLevel);
}




