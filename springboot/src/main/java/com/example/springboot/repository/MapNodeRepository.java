package com.example.springboot.repository;

import com.example.springboot.entity.navigation.MapNode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * 地图节点Repository
 */
@Repository
public interface MapNodeRepository extends JpaRepository<MapNode, Integer> {
    
    /**
     * 根据节点名称模糊查询（忽略大小写）
     */
    java.util.List<MapNode> findByNodeNameContainingIgnoreCase(String nodeName);
    
    /**
     * 根据节点类型查找节点
     */
    java.util.List<MapNode> findByNodeType(MapNode.NodeType nodeType);
}
