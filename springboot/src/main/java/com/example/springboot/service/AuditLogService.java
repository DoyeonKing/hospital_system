package com.example.springboot.service;

import com.example.springboot.dto.audit.AuditLogQueryRequest;
import com.example.springboot.dto.audit.AuditLogResponse;
import com.example.springboot.entity.AuditLog;
import com.example.springboot.entity.enums.ActorType;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AuditLogRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.persistence.criteria.*;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    
    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @Transactional(readOnly = true)
    public List<AuditLogResponse> findAllAuditLogs() {
        return auditLogRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AuditLogResponse findAuditLogById(Long id) {
        AuditLog auditLog = auditLogRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("AuditLog not found with id " + id));
        return convertToResponseDto(auditLog);
    }

    @Transactional
    public AuditLog createAuditLog(Integer actorId, ActorType actorType, String action, String targetEntity, Integer targetId, String details) {
        AuditLog auditLog = new AuditLog();
        auditLog.setActorId(actorId);
        auditLog.setActorType(actorType);
        auditLog.setAction(action);
        auditLog.setTargetEntity(targetEntity);
        auditLog.setTargetId(targetId);
        auditLog.setDetails(details);
        auditLog.setCreatedAt(LocalDateTime.now());
        return auditLogRepository.save(auditLog);
    }

    // 可以添加更多基于查询条件的审计日志查找方法
    @Transactional(readOnly = true)
    public List<AuditLogResponse> findLogsByActor(ActorType actorType, Integer actorId) {
        return auditLogRepository.findByActorTypeAndActorId(actorType, actorId).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 按时间范围查询审计日志
     */
    @Transactional(readOnly = true)
    public List<AuditLogResponse> findLogsByTimeRange(LocalDateTime start, LocalDateTime end) {
        return auditLogRepository.findByCreatedAtBetween(start, end).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 按目标实体查询审计日志
     */
    @Transactional(readOnly = true)
    public List<AuditLogResponse> findLogsByTarget(String targetEntity, Integer targetId) {
        return auditLogRepository.findByTargetEntityAndTargetId(targetEntity, targetId).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 高级查询（支持多条件组合和分页）
     */
    @Transactional(readOnly = true)
    public Page<AuditLogResponse> findLogsByConditions(AuditLogQueryRequest request) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<AuditLog> query = cb.createQuery(AuditLog.class);
        Root<AuditLog> root = query.from(AuditLog.class);
        
        // 构建查询条件
        List<Predicate> predicates = new ArrayList<>();
        
        if (request.getActorId() != null) {
            predicates.add(cb.equal(root.get("actorId"), request.getActorId()));
        }
        
        if (request.getActorType() != null) {
            predicates.add(cb.equal(root.get("actorType"), request.getActorType()));
        }
        
        if (request.getAction() != null && !request.getAction().isEmpty()) {
            predicates.add(cb.like(root.get("action"), "%" + request.getAction() + "%"));
        }
        
        if (request.getTargetEntity() != null && !request.getTargetEntity().isEmpty()) {
            predicates.add(cb.equal(root.get("targetEntity"), request.getTargetEntity()));
        }
        
        if (request.getTargetId() != null) {
            predicates.add(cb.equal(root.get("targetId"), request.getTargetId()));
        }
        
        if (request.getStartTime() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), request.getStartTime()));
        }
        
        if (request.getEndTime() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), request.getEndTime()));
        }
        
        // 组合查询条件
        if (!predicates.isEmpty()) {
            query.where(cb.and(predicates.toArray(new Predicate[0])));
        }
        
        // 排序
        if ("DESC".equalsIgnoreCase(request.getSortDirection())) {
            query.orderBy(cb.desc(root.get(request.getSortBy())));
        } else {
            query.orderBy(cb.asc(root.get(request.getSortBy())));
        }
        
        // 执行查询
        TypedQuery<AuditLog> typedQuery = entityManager.createQuery(query);
        
        // 计算总数
        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<AuditLog> countRoot = countQuery.from(AuditLog.class);
        countQuery.select(cb.count(countRoot));
        if (!predicates.isEmpty()) {
            // 重新构建条件（因为predicates已经被使用）
            List<Predicate> countPredicates = buildPredicates(cb, countRoot, request);
            countQuery.where(cb.and(countPredicates.toArray(new Predicate[0])));
        }
        Long total = entityManager.createQuery(countQuery).getSingleResult();
        
        // 分页
        int page = request.getPage() != null ? request.getPage() : 0;
        int size = request.getSize() != null ? request.getSize() : 20;
        typedQuery.setFirstResult(page * size);
        typedQuery.setMaxResults(size);
        
        List<AuditLog> auditLogs = typedQuery.getResultList();
        List<AuditLogResponse> responses = auditLogs.stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
        
        return new PageImpl<>(responses, PageRequest.of(page, size), total);
    }
    
    /**
     * 构建查询条件（用于count查询）
     */
    private List<Predicate> buildPredicates(CriteriaBuilder cb, Root<AuditLog> root, AuditLogQueryRequest request) {
        List<Predicate> predicates = new ArrayList<>();
        
        if (request.getActorId() != null) {
            predicates.add(cb.equal(root.get("actorId"), request.getActorId()));
        }
        if (request.getActorType() != null) {
            predicates.add(cb.equal(root.get("actorType"), request.getActorType()));
        }
        if (request.getAction() != null && !request.getAction().isEmpty()) {
            predicates.add(cb.like(root.get("action"), "%" + request.getAction() + "%"));
        }
        if (request.getTargetEntity() != null && !request.getTargetEntity().isEmpty()) {
            predicates.add(cb.equal(root.get("targetEntity"), request.getTargetEntity()));
        }
        if (request.getTargetId() != null) {
            predicates.add(cb.equal(root.get("targetId"), request.getTargetId()));
        }
        if (request.getStartTime() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), request.getStartTime()));
        }
        if (request.getEndTime() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), request.getEndTime()));
        }
        
        return predicates;
    }

    private AuditLogResponse convertToResponseDto(AuditLog auditLog) {
        AuditLogResponse response = new AuditLogResponse();
        BeanUtils.copyProperties(auditLog, response);
        return response;
    }
}
