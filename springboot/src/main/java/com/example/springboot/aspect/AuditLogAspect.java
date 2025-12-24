package com.example.springboot.aspect;

import com.example.springboot.annotation.AuditLog;
import com.example.springboot.entity.enums.ActorType;
import com.example.springboot.repository.AdminRepository;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.security.JwtTokenProvider;
import com.example.springboot.service.AuditLogService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

/**
 * 审计日志切面
 * 自动记录标记了@AuditLog注解的方法调用
 */
@Aspect
@Component
public class AuditLogAspect {

    private final AuditLogService auditLogService;
    private final ObjectMapper objectMapper;
    private final JwtTokenProvider jwtTokenProvider;
    private final AdminRepository adminRepository;
    private final DoctorRepository doctorRepository;
    private final PatientRepository patientRepository;

    @Autowired
    public AuditLogAspect(AuditLogService auditLogService, 
                         ObjectMapper objectMapper,
                         JwtTokenProvider jwtTokenProvider,
                         AdminRepository adminRepository,
                         DoctorRepository doctorRepository,
                         PatientRepository patientRepository) {
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
        this.jwtTokenProvider = jwtTokenProvider;
        this.adminRepository = adminRepository;
        this.doctorRepository = doctorRepository;
        this.patientRepository = patientRepository;
    }

    @Around("@annotation(com.example.springboot.annotation.AuditLog)")
    public Object logAudit(ProceedingJoinPoint joinPoint) throws Throwable {
        // 获取方法签名
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        
        // 获取注解
        AuditLog auditLog = method.getAnnotation(AuditLog.class);
        
        // 获取当前用户信息
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Integer actorId = null;
        ActorType actorType = ActorType.admin; // 默认为管理员
        
        // 获取HTTP请求对象
        HttpServletRequest request = getHttpServletRequest();
        
        if (authentication != null && authentication.isAuthenticated()) {
            // 优先从JWT Token中获取用户ID和类型
            String token = extractTokenFromRequest(request);
            if (token != null && jwtTokenProvider.validateToken(token)) {
                try {
                    Long userId = jwtTokenProvider.getUserIdFromToken(token);
                    String userType = jwtTokenProvider.getUserTypeFromToken(token);
                    if (userId != null) {
                        actorId = userId.intValue();
                        actorType = convertUserTypeToActorType(userType);
                    }
                } catch (Exception e) {
                    System.err.println("Failed to extract user info from token: " + e.getMessage());
                }
            }
            
            // 如果Token中没有，尝试从数据库查询
            if (actorId == null) {
                String identifier = authentication.getName();
                actorId = extractActorIdFromDatabase(identifier, authentication);
                actorType = extractActorTypeFromAuthentication(authentication);
            }
        }
        
        // 执行目标方法
        Object result = null;
        String status = "SUCCESS";
        String errorMsg = null;
        
        try {
            result = joinPoint.proceed();
            return result;
        } catch (Exception e) {
            status = "FAILED";
            errorMsg = e.getMessage();
            throw e;
        } finally {
            // 异步记录审计日志（避免影响主业务）
            try {
                recordAuditLog(auditLog, joinPoint, actorId, actorType, request, result, status, errorMsg);
            } catch (Exception e) {
                // 日志记录失败不应影响主业务
                System.err.println("Failed to record audit log: " + e.getMessage());
            }
        }
    }

    /**
     * 记录审计日志
     */
    private void recordAuditLog(AuditLog auditLog, ProceedingJoinPoint joinPoint,
                                Integer actorId, ActorType actorType,
                                HttpServletRequest request, Object result,
                                String status, String errorMsg) {
        try {
            // 构建详细信息
            Map<String, Object> details = new HashMap<>();
            
            if (auditLog.recordDetails()) {
                // 记录方法参数
                Object[] args = joinPoint.getArgs();
                String[] paramNames = ((MethodSignature) joinPoint.getSignature()).getParameterNames();
                
                for (int i = 0; i < args.length; i++) {
                    if (args[i] != null && !isIgnoredType(args[i])) {
                        details.put(paramNames[i], args[i].toString());
                    }
                }
                
                // 记录请求信息
                if (request != null) {
                    details.put("requestMethod", request.getMethod());
                    details.put("requestUrl", request.getRequestURI());
                    details.put("remoteAddr", request.getRemoteAddr());
                }
                
                // 记录执行状态
                details.put("status", status);
                if (errorMsg != null) {
                    details.put("error", errorMsg);
                }
            }
            
            // 提取目标ID（如果参数中有ID）
            Integer targetId = extractTargetId(joinPoint.getArgs());
            
            // 将详细信息转为JSON
            String detailsJson = objectMapper.writeValueAsString(details);
            
            // 调用service记录日志
            auditLogService.createAuditLog(
                actorId,
                actorType,
                auditLog.action(),
                auditLog.targetEntity(),
                targetId,
                detailsJson
            );
            
            // 调试日志
            System.out.println("✅ Audit log recorded: actorId=" + actorId + ", actorType=" + actorType + 
                             ", action=" + auditLog.action() + ", targetEntity=" + auditLog.targetEntity() + 
                             ", targetId=" + targetId);
        } catch (Exception e) {
            System.err.println("❌ Error creating audit log: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 从HTTP请求中提取JWT Token
     */
    private String extractTokenFromRequest(HttpServletRequest request) {
        if (request == null) {
            return null;
        }
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        return null;
    }

    /**
     * 从数据库查询用户ID（备用方案）
     */
    private Integer extractActorIdFromDatabase(String identifier, Authentication authentication) {
        if (identifier == null) {
            return null;
        }
        
        try {
            // 根据权限判断用户类型
            boolean isAdmin = authentication.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().contains("ADMIN"));
            boolean isDoctor = authentication.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().contains("DOCTOR"));
            boolean isPatient = authentication.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().contains("PATIENT"));
            
            if (isAdmin) {
                return adminRepository.findByUsername(identifier)
                        .map(admin -> admin.getAdminId())
                        .orElse(null);
            } else if (isDoctor) {
                return doctorRepository.findByIdentifier(identifier)
                        .map(doctor -> doctor.getDoctorId())
                        .orElse(null);
            } else if (isPatient) {
                return patientRepository.findByIdentifier(identifier)
                        .map(patient -> patient.getPatientId().intValue())
                        .orElse(null);
            }
        } catch (Exception e) {
            System.err.println("Failed to extract actor ID from database: " + e.getMessage());
        }
        return null;
    }

    /**
     * 从认证信息中提取用户类型
     */
    private ActorType extractActorTypeFromAuthentication(Authentication authentication) {
        if (authentication == null) {
            return ActorType.admin;
        }
        
        return authentication.getAuthorities().stream()
                .map(a -> a.getAuthority().toUpperCase())
                .filter(auth -> auth.contains("ADMIN") || auth.contains("DOCTOR") || auth.contains("PATIENT"))
                .map(auth -> {
                    if (auth.contains("ADMIN")) return ActorType.admin;
                    if (auth.contains("DOCTOR")) return ActorType.doctor;
                    if (auth.contains("PATIENT")) return ActorType.patient;
                    return ActorType.admin;
                })
                .findFirst()
                .orElse(ActorType.admin);
    }

    /**
     * 将用户类型字符串转换为ActorType枚举
     */
    private ActorType convertUserTypeToActorType(String userType) {
        if (userType == null) {
            return ActorType.admin;
        }
        String type = userType.toLowerCase();
        if (type.equals("admin")) {
            return ActorType.admin;
        } else if (type.equals("doctor")) {
            return ActorType.doctor;
        } else if (type.equals("patient")) {
            return ActorType.patient;
        }
        return ActorType.admin;
    }

    /**
     * 提取目标实体ID
     */
    private Integer extractTargetId(Object[] args) {
        for (Object arg : args) {
            if (arg instanceof Integer) {
                return (Integer) arg;
            } else if (arg instanceof Long) {
                return ((Long) arg).intValue();
            }
        }
        return null;
    }

    /**
     * 判断是否为需要忽略的类型
     */
    private boolean isIgnoredType(Object obj) {
        return obj instanceof HttpServletRequest
            || obj instanceof org.springframework.web.multipart.MultipartFile;
    }

    /**
     * 获取HTTP请求对象
     */
    private HttpServletRequest getHttpServletRequest() {
        try {
            ServletRequestAttributes attributes = 
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attributes != null ? attributes.getRequest() : null;
        } catch (Exception e) {
            return null;
        }
    }
}

