package com.example.springboot.repository;

import com.example.springboot.entity.navigation.MapEdge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * 地图路径Repository
 */
@Repository
public interface MapEdgeRepository extends JpaRepository<MapEdge, Integer> {
}






