package com.example.springboot.controller;

import com.example.springboot.dto.admin.RoleResponse;
import com.example.springboot.service.RoleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 角色控制器
 */
@RestController
@RequestMapping("/api/role")
@CrossOrigin(origins = "*")
public class RoleController {

    private final RoleService roleService;

    @Autowired
    public RoleController(RoleService roleService) {
        this.roleService = roleService;
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
     * 获取所有角色列表
     */
    @GetMapping("/list")
    public ResponseEntity<?> getAllRoles() {
        try {
            List<RoleResponse> roles = roleService.findAllRoles();
            return ResponseEntity.ok(createResponse("200", "success", roles));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 根据ID获取角色
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getRoleById(@PathVariable Integer id) {
        try {
            RoleResponse role = roleService.findRoleById(id);
            return ResponseEntity.ok(createResponse("200", "success", role));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }
}
