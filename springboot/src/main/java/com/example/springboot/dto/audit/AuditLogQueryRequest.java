package com.example.springboot.dto.audit;

import com.example.springboot.entity.enums.ActorType;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 审计日志查询请求DTO
 */
@Data
public class AuditLogQueryRequest {
    
    /**
     * 操作者ID
     */
    private Integer actorId;
    
    /**
     * 操作者类型
     */
    private ActorType actorType;
    
    /**
     * 操作行为（模糊匹配）
     */
    private String action;
    
    /**
     * 目标实体类型
     */
    private String targetEntity;
    
    /**
     * 目标实体ID
     */
    private Integer targetId;
    
    /**
     * 开始时间
     */
    private LocalDateTime startTime;
    
    /**
     * 结束时间
     */
    private LocalDateTime endTime;
    
    /**
     * 页码（从0开始）
     */
    private Integer page = 0;
    
    /**
     * 每页大小
     */
    private Integer size = 20;
    
    /**
     * 排序字段（默认按创建时间降序）
     */
    private String sortBy = "createdAt";
    
    /**
     * 排序方向（ASC/DESC）
     */
    private String sortDirection = "DESC";
}







