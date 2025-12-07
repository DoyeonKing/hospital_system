package com.example.springboot.repository; // 包名调整

import com.example.springboot.entity.Admin; // 导入路径调整
import com.example.springboot.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.Set;

@Repository
public interface AdminRepository extends JpaRepository<Admin, Integer> , JpaSpecificationExecutor<Admin> {
    Optional<Admin> findByUsername(String username);
    boolean existsByUsername(String username);
    
    /**
     * 查询管理员并立即加载其角色（解决懒加载问题）
     */
    @Query("SELECT DISTINCT a FROM Admin a " +
           "LEFT JOIN FETCH a.roles " +
           "WHERE a.adminId = :adminId")
    Optional<Admin> findByIdWithRolesAndPermissions(@Param("adminId") Integer adminId);
    
    /**
     * 使用原生 SQL 直接查询管理员的所有权限名称
     */
    @Query(value = "SELECT DISTINCT p.permission_name " +
                   "FROM admins a " +
                   "INNER JOIN admin_roles ar ON a.admin_id = ar.admin_id " +
                   "INNER JOIN roles r ON ar.role_id = r.role_id " +
                   "INNER JOIN role_permissions rp ON r.role_id = rp.role_id " +
                   "INNER JOIN permissions p ON rp.permission_id = p.permission_id " +
                   "WHERE a.admin_id = :adminId " +
                   "ORDER BY p.permission_name", 
           nativeQuery = true)
    Set<String> findPermissionNamesByAdminId(@Param("adminId") Integer adminId);
}
