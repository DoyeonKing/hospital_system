package com.example.springboot.controller;

import com.example.springboot.dto.admin.PermissionCreateRequest;
import com.example.springboot.dto.admin.PermissionResponse;
import com.example.springboot.dto.admin.PermissionUpdateRequest;
import com.example.springboot.service.PermissionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 权限管理控制器
 * 提供权限的CRUD操作
 */
@RestController
@RequestMapping("/api/permissions")
@PreAuthorize("hasAuthority('system_config')") // 需要系统配置权限
public class PermissionController {

    private final PermissionService permissionService;

    @Autowired
    public PermissionController(PermissionService permissionService) {
        this.permissionService = permissionService;
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
     * 获取所有权限列表
     */
    @GetMapping("/list")
    public ResponseEntity<?> getAllPermissions() {
        try {
            List<PermissionResponse> permissions = permissionService.findAllPermissions();
            return ResponseEntity.ok(createResponse("200", "success", permissions));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 根据ID获取权限
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getPermissionById(@PathVariable Integer id) {
        try {
            PermissionResponse permission = permissionService.findPermissionById(id);
            return ResponseEntity.ok(createResponse("200", "success", permission));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    /**
     * 创建新权限
     */
    @PostMapping
    public ResponseEntity<?> createPermission(@RequestBody PermissionCreateRequest request) {
        try {
            PermissionResponse permission = permissionService.createPermission(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(createResponse("201", "Permission created successfully", permission));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(createResponse("400", e.getMessage(), null));
        }
    }

    /**
     * 更新权限
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updatePermission(
            @PathVariable Integer id,
            @RequestBody PermissionUpdateRequest request) {
        try {
            PermissionResponse permission = permissionService.updatePermission(id, request);
            return ResponseEntity.ok(createResponse("200", "Permission updated successfully", permission));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(createResponse("400", e.getMessage(), null));
        }
    }

    /**
     * 删除权限
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePermission(@PathVariable Integer id) {
        try {
            permissionService.deletePermission(id);
            return ResponseEntity.ok(createResponse("200", "Permission deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(createResponse("400", e.getMessage(), null));
        }
    }

    /**
     * 获取权限分配给哪些角色
     */
    @GetMapping("/{id}/roles")
    public ResponseEntity<?> getPermissionRoles(@PathVariable Integer id) {
        try {
            PermissionResponse permission = permissionService.findPermissionById(id);
            // 这里可以添加获取该权限分配给哪些角色的逻辑
            return ResponseEntity.ok(createResponse("200", "success", permission));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }
}










