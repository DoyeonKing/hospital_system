package com.example.springboot.common;

/**
 * 全局常量定义类
 * 用于存放全局可复用的系统级常量。
 */
public class Constants {

    /**
     * 患者最大允许爽约次数，超过即自动加入黑名单
     */
    public static final int MAX_NO_SHOW_COUNT = 3;

    /**
     * 默认分页大小（如果系统里有分页）
     */
    public static final int DEFAULT_PAGE_SIZE = 20;

    /**
     * Token 过期时间（举例）
     */
    public static final long TOKEN_EXPIRATION_HOURS = 24;

    /**
     * 默认系统时区
     */
    public static final String DEFAULT_TIMEZONE = "Asia/Shanghai";

    /**
     * 登录失败最大次数，超过即自动锁定账户
     */
    public static final int MAX_LOGIN_FAILURE_COUNT = 5;

    /**
     * 账户自动锁定时长（分钟），锁定后需要等待此时间后自动解锁，或由管理员手动解锁
     */
    public static final int ACCOUNT_LOCK_DURATION_MINUTES = 30;

    /**
     * JWT Token密钥（生产环境应从配置文件读取）
     * 注意：生产环境必须使用更安全的密钥，建议至少256位
     */
    public static final String JWT_SECRET = "your-secret-key-change-in-production-min-256-bits-hospital-system-2024";

    /**
     * JWT Token过期时间（秒）
     */
    public static final long JWT_EXPIRATION_SECONDS = 86400; // 24小时
}
