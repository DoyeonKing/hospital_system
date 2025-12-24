package com.example.springboot.controller;

import com.example.springboot.dto.audit.AuditLogQueryRequest;
import com.example.springboot.dto.audit.AuditLogResponse;
import com.example.springboot.entity.enums.ActorType;
import com.example.springboot.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 审计日志控制器
 * 提供审计日志的查询功能
 */
@RestController
@RequestMapping("/api/audit-logs")
@PreAuthorize("hasAuthority('audit_log_view')") // 需要审计日志查看权限
public class AuditLogController {

    private final AuditLogService auditLogService;

    @Autowired
    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    /**
     * 创建统一响应格式
     */
    private <T> Map<String, Object> createResponse(String code, String msg, T data) {
        Map<String, Object> response = new HashMap<>();
        response.put("code", code);
        response.put("msg", msg);
        response.put("data", data);
        return response;
    }

    /**
     * 获取所有审计日志
     */
    @GetMapping("/all")
    public ResponseEntity<?> getAllAuditLogs() {
        try {
            List<AuditLogResponse> logs = auditLogService.findAllAuditLogs();
            return ResponseEntity.ok(createResponse("200", "success", logs));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 根据ID获取审计日志
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getAuditLogById(@PathVariable Long id) {
        try {
            AuditLogResponse log = auditLogService.findAuditLogById(id);
            return ResponseEntity.ok(createResponse("200", "success", log));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    /**
     * 按操作者查询审计日志
     */
    @GetMapping("/actor")
    public ResponseEntity<?> getAuditLogsByActor(
            @RequestParam ActorType actorType,
            @RequestParam Integer actorId) {
        try {
            List<AuditLogResponse> logs = auditLogService.findLogsByActor(actorType, actorId);
            return ResponseEntity.ok(createResponse("200", "success", logs));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 按时间范围查询审计日志
     */
    @GetMapping("/time-range")
    public ResponseEntity<?> getAuditLogsByTimeRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        try {
            List<AuditLogResponse> logs = auditLogService.findLogsByTimeRange(start, end);
            return ResponseEntity.ok(createResponse("200", "success", logs));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 按目标实体查询审计日志
     */
    @GetMapping("/target")
    public ResponseEntity<?> getAuditLogsByTarget(
            @RequestParam String targetEntity,
            @RequestParam Integer targetId) {
        try {
            List<AuditLogResponse> logs = auditLogService.findLogsByTarget(targetEntity, targetId);
            return ResponseEntity.ok(createResponse("200", "success", logs));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 高级查询（支持多条件组合和分页）
     */
    @PostMapping("/search")
    public ResponseEntity<?> searchAuditLogs(@RequestBody AuditLogQueryRequest request) {
        try {
            Page<AuditLogResponse> page = auditLogService.findLogsByConditions(request);
            
            Map<String, Object> result = new HashMap<>();
            result.put("content", page.getContent());
            result.put("totalElements", page.getTotalElements());
            result.put("totalPages", page.getTotalPages());
            result.put("currentPage", page.getNumber());
            result.put("pageSize", page.getSize());
            result.put("hasNext", page.hasNext());
            result.put("hasPrevious", page.hasPrevious());
            
            return ResponseEntity.ok(createResponse("200", "success", result));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 获取审计日志统计信息
     */
    @GetMapping("/statistics")
    public ResponseEntity<?> getAuditLogStatistics(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        try {
            // 如果没有提供时间范围，默认查询最近7天
            if (start == null) {
                start = LocalDateTime.now().minusDays(7);
            }
            if (end == null) {
                end = LocalDateTime.now();
            }
            
            List<AuditLogResponse> logs = auditLogService.findLogsByTimeRange(start, end);
            
            // 统计信息
            Map<String, Object> statistics = new HashMap<>();
            statistics.put("total", logs.size());
            statistics.put("startTime", start);
            statistics.put("endTime", end);
            
            // 按操作类型统计
            Map<String, Long> actionCount = new HashMap<>();
            logs.forEach(log -> {
                String action = log.getAction();
                actionCount.put(action, actionCount.getOrDefault(action, 0L) + 1);
            });
            statistics.put("actionCount", actionCount);
            
            // 按操作者类型统计
            Map<String, Long> actorTypeCount = new HashMap<>();
            logs.forEach(log -> {
                String actorType = log.getActorType() != null ? log.getActorType().toString() : "unknown";
                actorTypeCount.put(actorType, actorTypeCount.getOrDefault(actorType, 0L) + 1);
            });
            statistics.put("actorTypeCount", actorTypeCount);
            
            return ResponseEntity.ok(createResponse("200", "success", statistics));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }
}


