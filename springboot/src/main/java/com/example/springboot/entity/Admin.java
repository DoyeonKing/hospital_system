package com.example.springboot.entity; // 包名调整

import com.example.springboot.entity.enums.AdminStatus; // 导入路径调整
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * 管理员表
 */
@Entity
@Table(name = "admins")
@Data
public class Admin {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "admin_id")
    private Integer adminId;

    @Column(nullable = false, unique = true, length = 100)
    private String username; // 管理员登录用户名

    @Column(name = "password_hash", nullable = false)
    private String passwordHash; // 哈希加盐后的密码

    @Column(name = "full_name", length = 100)
    private String fullName; // 管理员真实姓名

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AdminStatus status; // 账户状态

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt; // 账户创建时间

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "admin_roles",
            joinColumns = @JoinColumn(name = "admin_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();

    @Column(name = "failed_login_count", nullable = false)
    private Integer failedLoginCount = 0; // 登录失败次数

    @Column(name = "last_failed_login_time")
    private LocalDateTime lastFailedLoginTime; // 最后一次失败登录时间

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil; // 锁定到期时间（为null表示永久锁定，需管理员解锁）
}
