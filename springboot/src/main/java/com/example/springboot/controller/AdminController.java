package com.example.springboot.controller;

import com.example.springboot.dto.admin.AdminCreateRequest;
import com.example.springboot.dto.admin.AdminResponse;
import com.example.springboot.dto.admin.AdminUpdateRequest;
import com.example.springboot.dto.admin.PermissionResponse;
import com.example.springboot.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 管理员控制器
 */
@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    private final AdminService adminService;

    @Autowired
    public AdminController(AdminService adminService) {
        this.adminService = adminService;
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
     * 获取所有管理员
     */
    @GetMapping
    public ResponseEntity<?> getAllAdmins() {
        try {
            List<AdminResponse> admins = adminService.findAllAdmins();
            return ResponseEntity.ok(createResponse("200", "success", admins));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createResponse("500", e.getMessage(), null));
        }
    }

    /**
     * 根据ID获取管理员
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getAdminById(@PathVariable Integer id) {
        try {
            AdminResponse admin = adminService.findAdminById(id);
            return ResponseEntity.ok(createResponse("200", "success", admin));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    /**
     * 根据用户名获取管理员
     */
    @GetMapping("/username/{username}")
    public ResponseEntity<?> getAdminByUsername(@PathVariable String username) {
        try {
            AdminResponse admin = adminService.findAdminByUsername(username);
            return ResponseEntity.ok(createResponse("200", "success", admin));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    /**
     * 创建管理员
     */
    @PostMapping
    public ResponseEntity<?> createAdmin(@RequestBody AdminCreateRequest request) {
        try {
            AdminResponse admin = adminService.createAdmin(request);
            return ResponseEntity.ok(createResponse("200", "管理员创建成功", admin));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(createResponse("400", e.getMessage(), null));
        }
    }

    /**
     * 更新管理员
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateAdmin(
            @PathVariable Integer id,
            @RequestBody AdminUpdateRequest request) {
        try {
            AdminResponse admin = adminService.updateAdmin(id, request);
            return ResponseEntity.ok(createResponse("200", "管理员更新成功", admin));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(createResponse("400", e.getMessage(), null));
        }
    }

    /**
     * 删除管理员
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteAdmin(@PathVariable Integer id) {
        try {
            adminService.deleteAdmin(id);
            return ResponseEntity.ok(createResponse("200", "管理员删除成功", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    // =========================================================================
    // 【权限相关接口】
    // =========================================================================

    /**
     * 获取管理员的所有权限名称
     * @param adminId 管理员ID
     * @return 权限名称集合
     */
    @GetMapping("/{adminId}/permissions")
    public ResponseEntity<?> getAdminPermissions(@PathVariable Integer adminId) {
        try {
            System.out.println("AdminController: 收到权限请求，adminId=" + adminId);
            Set<String> permissions = adminService.getAdminPermissions(adminId);
            System.out.println("AdminController: 获取到的权限集合=" + permissions);
            System.out.println("AdminController: 权限数量=" + (permissions != null ? permissions.size() : 0));
            
            // 将 Set 转换为 List 以确保 JSON 序列化为数组
            List<String> permissionList = new ArrayList<>(permissions);
            System.out.println("AdminController: 转换后的权限列表=" + permissionList);
            
            return ResponseEntity.ok(createResponse("200", "success", permissionList));
        } catch (Exception e) {
            System.err.println("AdminController: 获取权限失败 - " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }

    /**
     * 获取管理员的详细权限信息
     * @param adminId 管理员ID
     * @return 权限详细信息集合
     */
    @GetMapping("/{adminId}/permissions/details")
    public ResponseEntity<?> getAdminPermissionDetails(@PathVariable Integer adminId) {
        try {
            Set<PermissionResponse> permissions = adminService.getAdminPermissionDetails(adminId);
            return ResponseEntity.ok(createResponse("200", "success", permissions));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createResponse("404", e.getMessage(), null));
        }
    }
}
