package com.example.springboot.service;

import com.example.springboot.dto.admin.AdminCreateRequest;
import com.example.springboot.dto.admin.AdminResponse;
import com.example.springboot.dto.admin.AdminUpdateRequest;
import com.example.springboot.dto.admin.PermissionResponse;
import com.example.springboot.dto.admin.RoleResponse;
import com.example.springboot.dto.auth.LoginResponse;
import com.example.springboot.entity.Admin;
import com.example.springboot.entity.Permission;
import com.example.springboot.entity.Role;
import com.example.springboot.common.Constants;
import com.example.springboot.entity.enums.AdminStatus;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AdminRepository;
import com.example.springboot.repository.RoleRepository;
import com.example.springboot.util.PasswordEncoderUtil;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.hibernate.Hibernate;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminService {

    @PersistenceContext
    private EntityManager entityManager;
    
    private final AdminRepository adminRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;
    
    @Autowired
    private com.example.springboot.security.JwtTokenProvider jwtTokenProvider;

    @Autowired
    public AdminService(AdminRepository adminRepository, RoleRepository roleRepository, PasswordEncoderUtil passwordEncoderUtil) {
        this.adminRepository = adminRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
    }

    // =========================================================================
    // 【管理员登录】
    // =========================================================================

    /**
     * 管理员登录
     * @param username 管理员用户名
     * @param password 密码
     * @return 登录响应
     */
    @Transactional
    public LoginResponse login(String username, String password) {
        LocalDateTime now = LocalDateTime.now();
        
        // 1. 查找管理员
        Admin admin = adminRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("用户名或密码错误"));

        // 2. 检查账户状态（在验证密码之前）
        if (admin.getStatus() == AdminStatus.inactive) {
            throw new IllegalArgumentException("账户未激活，请联系系统管理员");
        }

        // 3. 检查账户锁定状态
        // 如果账户状态是locked，检查是否已到解锁时间
        if (admin.getStatus() == AdminStatus.locked) {
            if (admin.getLockedUntil() != null && now.isAfter(admin.getLockedUntil())) {
                // 自动解锁：重置状态和失败次数
                admin.setStatus(AdminStatus.active);
                admin.setFailedLoginCount(0);
                admin.setLastFailedLoginTime(null);
                admin.setLockedUntil(null);
                adminRepository.save(admin);
            } else {
                // 仍在锁定期内
                throw new IllegalArgumentException("账户已被锁定，请联系系统管理员");
            }
        }

        // 4. 初始化失败登录计数（如果为null）
        if (admin.getFailedLoginCount() == null) {
            admin.setFailedLoginCount(0);
        }

        // 5. 验证密码
        boolean passwordMatches = passwordEncoderUtil.matches(password, admin.getPasswordHash());
        
        if (!passwordMatches) {
            // 登录失败：增加失败次数
            int newFailureCount = admin.getFailedLoginCount() + 1;
            admin.setFailedLoginCount(newFailureCount);
            admin.setLastFailedLoginTime(now);
            
            // 检查是否达到锁定阈值
            if (newFailureCount >= Constants.MAX_LOGIN_FAILURE_COUNT) {
                // 自动锁定账户
                admin.setStatus(AdminStatus.locked);
                admin.setLockedUntil(now.plusMinutes(Constants.ACCOUNT_LOCK_DURATION_MINUTES));
                adminRepository.saveAndFlush(admin); // 使用saveAndFlush强制立即写入数据库
                throw new IllegalArgumentException("登录失败次数过多，账户已被锁定，请" + Constants.ACCOUNT_LOCK_DURATION_MINUTES + "分钟后再试或联系系统管理员");
            } else {
                // 未达到阈值，只保存失败次数
                adminRepository.saveAndFlush(admin); // 使用saveAndFlush强制立即写入数据库
                int remainingAttempts = Constants.MAX_LOGIN_FAILURE_COUNT - newFailureCount;
                throw new IllegalArgumentException("用户名或密码错误，还可尝试" + remainingAttempts + "次");
            }
        }

        // 6. 密码正确，登录成功：重置失败次数
        if (admin.getFailedLoginCount() > 0) {
            admin.setFailedLoginCount(0);
            admin.setLastFailedLoginTime(null);
            adminRepository.save(admin);
        }

        // 7. 获取角色列表
        List<String> roles = admin.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toList());

        // 8. 构建用户信息
        Map<String, Object> adminInfo = new HashMap<>();
        adminInfo.put("adminId", admin.getAdminId());
        adminInfo.put("username", admin.getUsername());
        adminInfo.put("fullName", admin.getFullName());
        adminInfo.put("status", admin.getStatus().name());
        adminInfo.put("roles", roles);

        // 9. 生成Token
        String token = jwtTokenProvider.generateToken(
            admin.getUsername(), 
            "admin", 
            (long) admin.getAdminId()
        );

        // 10. 返回登录响应
        return LoginResponse.builder()
                .token(token)  // 返回实际Token
                .userType("admin")
                .userInfo(adminInfo)
                .build();
    }

    @Transactional(readOnly = true)
    public List<AdminResponse> findAllAdmins() {
        System.out.println("AdminService: 使用原生 SQL 查询所有管理员（包含角色和权限）");
        List<Object[]> results = adminRepository.findAllAdminsWithRolesNative();
        System.out.println("AdminService: 查询到 " + results.size() + " 行数据");
        
        // 手动组装数据：将多行数据合并为管理员对象
        Map<Integer, AdminResponse> adminMap = new LinkedHashMap<>();
        Map<String, RoleResponse> roleMap = new HashMap<>(); // key: adminId_roleId
        
        for (Object[] row : results) {
            Integer adminId = (Integer) row[0];
            String username = (String) row[1];
            String fullName = (String) row[2];
            String statusStr = (String) row[3];
            java.sql.Timestamp createdAt = (java.sql.Timestamp) row[4];
            Integer roleId = row[5] != null ? (Integer) row[5] : null;
            String roleName = row[6] != null ? (String) row[6] : null;
            String roleDescription = row[7] != null ? (String) row[7] : null;
            Integer permissionId = row[8] != null ? (Integer) row[8] : null;
            String permissionName = row[9] != null ? (String) row[9] : null;
            String permissionDescription = row[10] != null ? (String) row[10] : null;
            
            System.out.println("AdminService: 处理数据行 - adminId=" + adminId + ", username=" + username + 
                             ", roleId=" + roleId + ", roleName=" + roleName + 
                             ", permissionId=" + permissionId + ", permissionName=" + permissionName);
            
            // 获取或创建 AdminResponse
            AdminResponse adminResponse = adminMap.computeIfAbsent(adminId, id -> {
                AdminResponse resp = new AdminResponse();
                resp.setAdminId(adminId);
                resp.setUsername(username);
                resp.setFullName(fullName);
                resp.setStatus(AdminStatus.valueOf(statusStr));
                resp.setCreatedAt(createdAt != null ? createdAt.toLocalDateTime() : null);
                resp.setRoles(new HashSet<>());
                return resp;
            });
            
            // 处理角色信息
            if (roleId != null && roleName != null) {
                String roleKey = adminId + "_" + roleId;
                RoleResponse roleResponse = roleMap.get(roleKey);
                
                if (roleResponse == null) {
                    // 创建新的角色
                    roleResponse = new RoleResponse();
                    roleResponse.setRoleId(roleId);
                    roleResponse.setRoleName(roleName);
                    roleResponse.setDescription(roleDescription);
                    roleResponse.setPermissions(new HashSet<>());
                    roleMap.put(roleKey, roleResponse);
                    adminResponse.getRoles().add(roleResponse);
                }
                
                // 添加权限信息
                if (permissionId != null && permissionName != null) {
                    PermissionResponse permissionResponse = new PermissionResponse();
                    permissionResponse.setPermissionId(permissionId);
                    permissionResponse.setPermissionName(permissionName);
                    permissionResponse.setDescription(permissionDescription);
                    roleResponse.getPermissions().add(permissionResponse);
                }
            }
        }
        
        List<AdminResponse> responses = new ArrayList<>(adminMap.values());
        System.out.println("AdminService: 组装完成，返回 " + responses.size() + " 个管理员");
        
        if (!responses.isEmpty()) {
            AdminResponse first = responses.get(0);
            System.out.println("AdminService: 第一个管理员 - " + first.getUsername());
            System.out.println("AdminService: 第一个管理员的角色数量 - " + first.getRoles().size());
            if (!first.getRoles().isEmpty()) {
                RoleResponse firstRole = first.getRoles().iterator().next();
                System.out.println("AdminService: 第一个角色 - " + firstRole.getRoleName());
                System.out.println("AdminService: 第一个角色的权限数量 - " + firstRole.getPermissions().size());
            }
        }
        
        return responses;
    }

    @Transactional(readOnly = true)
    public AdminResponse findAdminById(Integer id) {
        Admin admin = adminRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Admin not found with id " + id));
        
        // 强制初始化角色和权限
        Hibernate.initialize(admin.getRoles());
        if (admin.getRoles() != null) {
            for (Role role : admin.getRoles()) {
                Hibernate.initialize(role.getPermissions());
            }
        }
        
        return convertToResponseDto(admin);
    }

    @Transactional(readOnly = true)
    public AdminResponse findAdminByUsername(String username) {
        Admin admin = adminRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Admin not found with username " + username));
        
        // 强制初始化角色和权限
        Hibernate.initialize(admin.getRoles());
        if (admin.getRoles() != null) {
            for (Role role : admin.getRoles()) {
                Hibernate.initialize(role.getPermissions());
            }
        }
        
        return convertToResponseDto(admin);
    }

    @Transactional
    public AdminResponse createAdmin(AdminCreateRequest request) {
        Admin admin = new Admin();
        BeanUtils.copyProperties(request, admin, "password", "roleIds"); // 忽略密码和角色ID，单独处理
        admin.setPasswordHash(passwordEncoderUtil.encodePassword(request.getPassword()));

        if (request.getRoleIds() != null && !request.getRoleIds().isEmpty()) {
            Set<Role> roles = new HashSet<>(roleRepository.findAllById(request.getRoleIds()));
            admin.setRoles(roles);
        }

        return convertToResponseDto(adminRepository.save(admin));
    }

    @Transactional
    public AdminResponse updateAdmin(Integer id, AdminUpdateRequest request) {
        System.out.println("AdminService: 使用原生 SQL 更新管理员 ID=" + id);
        
        // 1. 检查管理员是否存在
        if (!adminRepository.existsById(id)) {
            throw new ResourceNotFoundException("Admin not found with id " + id);
        }
        
        // 2. 使用原生 SQL 更新管理员基本信息
        StringBuilder updateSql = new StringBuilder("UPDATE admins SET ");
        List<String> updates = new ArrayList<>();
        
        if (request.getFullName() != null) {
            updates.add("full_name = '" + request.getFullName() + "'");
        }
        if (request.getStatus() != null) {
            updates.add("status = '" + request.getStatus().name() + "'");
        }
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            String encodedPassword = passwordEncoderUtil.encodePassword(request.getPassword());
            updates.add("password_hash = '" + encodedPassword + "'");
        }
        
        if (!updates.isEmpty()) {
            updateSql.append(String.join(", ", updates));
            updateSql.append(" WHERE admin_id = ").append(id);
            
            System.out.println("AdminService: 执行 SQL - " + updateSql);
            entityManager.createNativeQuery(updateSql.toString()).executeUpdate();
        }
        
        // 3. 更新角色关联（如果提供了）
        if (request.getRoleIds() != null) {
            // 删除旧的角色关联
            String deleteSql = "DELETE FROM admin_roles WHERE admin_id = " + id;
            System.out.println("AdminService: 执行 SQL - " + deleteSql);
            entityManager.createNativeQuery(deleteSql).executeUpdate();
            
            // 插入新的角色关联
            for (Integer roleId : request.getRoleIds()) {
                String insertSql = "INSERT INTO admin_roles (admin_id, role_id) VALUES (" + id + ", " + roleId + ")";
                System.out.println("AdminService: 执行 SQL - " + insertSql);
                entityManager.createNativeQuery(insertSql).executeUpdate();
            }
            System.out.println("AdminService: 更新了 " + request.getRoleIds().size() + " 个角色");
        }
        
        // 4. 使用原生 SQL 查询更新后的管理员信息
        List<Object[]> results = adminRepository.findAllAdminsWithRolesNative();
        Map<Integer, AdminResponse> adminMap = new LinkedHashMap<>();
        Map<String, RoleResponse> roleMap = new HashMap<>();
        
        for (Object[] row : results) {
            Integer adminId = (Integer) row[0];
            if (!adminId.equals(id)) continue; // 只处理当前管理员
            
            String username = (String) row[1];
            String fullName = (String) row[2];
            String statusStr = (String) row[3];
            java.sql.Timestamp createdAt = (java.sql.Timestamp) row[4];
            Integer roleId = row[5] != null ? (Integer) row[5] : null;
            String roleName = row[6] != null ? (String) row[6] : null;
            String roleDescription = row[7] != null ? (String) row[7] : null;
            Integer permissionId = row[8] != null ? (Integer) row[8] : null;
            String permissionName = row[9] != null ? (String) row[9] : null;
            String permissionDescription = row[10] != null ? (String) row[10] : null;
            
            AdminResponse adminResponse = adminMap.computeIfAbsent(adminId, aid -> {
                AdminResponse resp = new AdminResponse();
                resp.setAdminId(adminId);
                resp.setUsername(username);
                resp.setFullName(fullName);
                resp.setStatus(AdminStatus.valueOf(statusStr));
                resp.setCreatedAt(createdAt != null ? createdAt.toLocalDateTime() : null);
                resp.setRoles(new HashSet<>());
                return resp;
            });
            
            if (roleId != null && roleName != null) {
                String roleKey = adminId + "_" + roleId;
                RoleResponse roleResponse = roleMap.get(roleKey);
                
                if (roleResponse == null) {
                    roleResponse = new RoleResponse();
                    roleResponse.setRoleId(roleId);
                    roleResponse.setRoleName(roleName);
                    roleResponse.setDescription(roleDescription);
                    roleResponse.setPermissions(new HashSet<>());
                    roleMap.put(roleKey, roleResponse);
                    adminResponse.getRoles().add(roleResponse);
                }
                
                if (permissionId != null && permissionName != null) {
                    PermissionResponse permissionResponse = new PermissionResponse();
                    permissionResponse.setPermissionId(permissionId);
                    permissionResponse.setPermissionName(permissionName);
                    permissionResponse.setDescription(permissionDescription);
                    roleResponse.getPermissions().add(permissionResponse);
                }
            }
        }
        
        AdminResponse result = adminMap.get(id);
        if (result == null) {
            throw new ResourceNotFoundException("Admin not found after update: " + id);
        }
        
        System.out.println("AdminService: 更新完成");
        return result;
    }

    @Transactional
    public void deleteAdmin(Integer id) {
        if (!adminRepository.existsById(id)) {
            throw new ResourceNotFoundException("Admin not found with id " + id);
        }
        adminRepository.deleteById(id);
    }

    public AdminResponse convertToResponseDto(Admin admin) {
        System.out.println("AdminService.convertToResponseDto: 转换管理员 " + admin.getUsername());
        
        AdminResponse response = new AdminResponse();
        // 排除 roles 字段，避免循环引用
        BeanUtils.copyProperties(admin, response, "roles");
        
        // 手动设置角色
        if (admin.getRoles() != null && !admin.getRoles().isEmpty()) {
            System.out.println("AdminService.convertToResponseDto: 开始转换 " + admin.getRoles().size() + " 个角色");
            Set<RoleResponse> roleResponses = admin.getRoles().stream()
                    .map(this::convertRoleToResponseDto)
                    .collect(Collectors.toSet());
            response.setRoles(roleResponses);
            System.out.println("AdminService.convertToResponseDto: 转换后的角色数量 = " + roleResponses.size());
        } else {
            System.out.println("AdminService.convertToResponseDto: 角色为空，设置空集合");
            response.setRoles(new HashSet<>());
        }
        
        return response;
    }

    private RoleResponse convertRoleToResponseDto(Role role) {
        RoleResponse response = new RoleResponse();
        // 排除 permissions 字段，避免循环引用
        BeanUtils.copyProperties(role, response, "permissions");
        
        // 手动设置权限
        if (role.getPermissions() != null && !role.getPermissions().isEmpty()) {
            response.setPermissions(role.getPermissions().stream()
                    .map(this::convertPermissionToResponseDto)
                    .collect(Collectors.toSet()));
        } else {
            response.setPermissions(new HashSet<>());
        }
        return response;
    }

    private PermissionResponse convertPermissionToResponseDto(Permission permission) {
        PermissionResponse response = new PermissionResponse();
        BeanUtils.copyProperties(permission, response);
        return response;
    }

    // =========================================================================
    // 【权限管理】
    // =========================================================================

    /**
     * 获取管理员的所有权限
     * @param adminId 管理员ID
     * @return 权限名称集合
     */
    @Transactional(readOnly = true)
    public Set<String> getAdminPermissions(Integer adminId) {
        System.out.println("AdminService: 开始查询管理员权限，adminId=" + adminId);
        
        // 先验证管理员是否存在
        if (!adminRepository.existsById(adminId)) {
            throw new ResourceNotFoundException("管理员不存在，ID: " + adminId);
        }
        
        // 使用原生 SQL 直接查询权限
        Set<String> permissions = adminRepository.findPermissionNamesByAdminId(adminId);
        System.out.println("AdminService: 通过原生SQL查询到的权限=" + permissions);
        System.out.println("AdminService: 权限数量=" + (permissions != null ? permissions.size() : 0));
        
        return permissions != null ? permissions : Collections.emptySet();
    }

    /**
     * 获取管理员的详细权限信息（包含权限描述）
     * @param adminId 管理员ID
     * @return 权限响应对象集合
     */
    @Transactional(readOnly = true)
    public Set<PermissionResponse> getAdminPermissionDetails(Integer adminId) {
        // 使用 JOIN FETCH 查询管理员及其角色和权限
        Admin admin = adminRepository.findByIdWithRolesAndPermissions(adminId)
                .orElseThrow(() -> new ResourceNotFoundException("管理员不存在，ID: " + adminId));
        
        Set<Role> roles = admin.getRoles();
        // 强制初始化角色集合
        Hibernate.initialize(roles);
        
        if (roles == null || roles.isEmpty()) {
            return Collections.emptySet();
        }
        
        Set<PermissionResponse> permissionResponses = new HashSet<>();
        for (Role role : roles) {
            Set<Permission> permissions = role.getPermissions();
            // 强制初始化权限集合
            Hibernate.initialize(permissions);
            if (permissions != null) {
                for (Permission permission : permissions) {
                    permissionResponses.add(convertPermissionToResponseDto(permission));
                }
            }
        }
        
        return permissionResponses;
    }
}
