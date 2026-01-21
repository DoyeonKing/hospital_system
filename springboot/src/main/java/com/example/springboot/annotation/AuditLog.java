package com.example.springboot.annotation;

import java.lang.annotation.*;

/**
 * 审计日志注解
 * 用于标记需要记录审计日志的方法
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface AuditLog {
    
    /**
     * 操作描述
     */
    String action() default "";
    
    /**
     * 目标实体类型（表名）
     */
    String targetEntity() default "";
    
    /**
     * 是否记录详细信息
     */
    boolean recordDetails() default true;
}















