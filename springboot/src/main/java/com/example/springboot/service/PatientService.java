//package com.example.springboot.service;
//
//// 导入 Spring Boot 核心组件和实体/DTO
//import com.example.springboot.dto.patient.PatientResponse;
//import com.example.springboot.entity.Patient;
//import com.example.springboot.entity.PatientProfile;
//import com.example.springboot.entity.enums.PatientStatus; // <<<<<< 确保导入您的 PatientStatus 枚举
//import com.example.springboot.exception.ResourceNotFoundException;
//import com.example.springboot.repository.PatientRepository;
//import com.example.springboot.repository.PatientProfileRepository;
//import com.example.springboot.util.PasswordEncoderUtil; // 导入您的密码工具类
//import org.springframework.beans.BeanUtils;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.util.List;
//import java.util.Optional;
//
//@Service
//public class PatientService {
//
//    private final PatientRepository patientRepository;
//    private final PatientProfileRepository patientProfileRepository;
//    private final PasswordEncoderUtil passwordEncoderUtil;
//
//    // 构造函数注入
//    @Autowired
//    public PatientService(PatientRepository patientRepository, PatientProfileRepository patientProfileRepository, PasswordEncoderUtil passwordEncoderUtil) {
//        this.patientRepository = patientRepository;
//        this.patientProfileRepository = patientProfileRepository;
//        this.passwordEncoderUtil = passwordEncoderUtil;
//    }
//
//    // =========================================================================
//    // 【修改】账户激活功能 - 接口 1: 验证初始信息和密码
//    // =========================================================================
//
//    /**
//     * 验证账户初始信息：检查学号/工号是否存在、未激活，并验证初始密码
//     * @param identifier 学号/工号
//     * @param initialPassword 校方初始密码
//     * @throws ResourceNotFoundException 如果患者不存在
//     * @throws IllegalArgumentException 如果账户已激活或密码错误
//     */
//    @Transactional(readOnly = true)
//    public void verifyInitialActivation(String identifier, String initialPassword) {
//
//        // 1. 查找患者主记录
//        Patient patient = patientRepository.findByIdentifier(identifier)
//                .orElseThrow(() -> new ResourceNotFoundException("学号/工号不存在或系统未录入。"));
//
//        // 2. 校验：账户是否已经激活
//        if (patient.getStatus() == PatientStatus.active) { // 假设 ACTIVE 是您的枚举值
//            throw new IllegalArgumentException("该账户已处于激活状态，请直接登录。");
//        }
//
//        // 3. 校验：初始密码是否匹配
//        String storedInitialPasswordHash = patient.getPasswordHash();
//
//        // 使用您的密码工具类进行密码校验
//        if (storedInitialPasswordHash == null ||
//                !passwordEncoderUtil.matches(initialPassword, storedInitialPasswordHash)) {
//            // 注意：这里假设您的 PasswordEncoderUtil 有一个 matches(rawPassword, encodedPassword) 方法
//            throw new IllegalArgumentException("初始密码错误，验证失败。");
//        }
//
//        // 如果未激活且密码正确，则验证通过
//    }
//
//    // =========================================================================
//    // 账户激活功能 - 接口 2: 身份验证与激活
//    // =========================================================================
//
//    /**
//     * 激活账户：验证身份，设置密码，更新状态
//     * @param identifier 学号/工号
//     * @param idCardEnding 身份证号后6位
//     * @param newPassword 新密码
//     * @param confirmPassword 确认密码
//     * @throws IllegalArgumentException 如果校验失败（密码不一致、身份验证失败）
//     * @throws ResourceNotFoundException 如果患者信息找不到
//     */
//    @Transactional
//    public void activateAccount(String identifier, String idCardEnding, String newPassword, String confirmPassword) {
//
//        // 1. 基本校验：密码一致性和长度
//        if (!newPassword.equals(confirmPassword)) {
//            throw new IllegalArgumentException("两次输入的新密码不一致。");
//        }
//        if (newPassword == null || newPassword.length() < 6 || newPassword.length() > 20) {
//            throw new IllegalArgumentException("密码长度必须在 6-20 位之间。");
//        }
//
//        // 2. 查找患者主记录
//        Patient patient = patientRepository.findByIdentifier(identifier)
//                .orElseThrow(() -> new ResourceNotFoundException("患者信息不存在。"));
//
//        // 3. 身份验证
//        // 通过 patient_id 查找 PatientProfile 记录
//        PatientProfile profile = patientProfileRepository.findById(patient.getPatientId())
//                .orElseThrow(() -> new ResourceNotFoundException("未找到身份证信息（数据异常）。"));
//
//        String fullIdCard = profile.getIdCardNumber();
//
//        // 身份验证逻辑：检查数据库中的完整身份证号是否以用户输入的后6位结尾
//        if (fullIdCard == null || fullIdCard.length() < 6 || !fullIdCard.endsWith(idCardEnding)) {
//            throw new IllegalArgumentException("身份验证失败：身份证号后6位不匹配。");
//        }
//
//        // 4. 更新密码和状态
//        String hashedPassword = passwordEncoderUtil.encodePassword(newPassword); // 使用您的加密工具
//
//        // 更新 patients 表的 password_hash 和 status
//        patient.setPasswordHash(hashedPassword);
//        patient.setStatus(PatientStatus.active); // 设置为激活状态
//        patientRepository.save(patient);
//    }
//
//    // =========================================================================
//    // 【原有】 CRUD 方法 (保持不变)
//    // =========================================================================
//
//    @Transactional(readOnly = true)
//    public List<Patient> findAllPatients() {
//        return patientRepository.findAll();
//    }
//
//    @Transactional(readOnly = true)
//    public Optional<Patient> findPatientById(Long id) {
//        return patientRepository.findById(id);
//    }
//
//    @Transactional(readOnly = true)
//    public Optional<Patient> findPatientByIdentifier(String identifier) {
//        return patientRepository.findByIdentifier(identifier);
//    }
//
//    @Transactional
//    public Patient createPatient(Patient patient) {
//        patient.setPasswordHash(passwordEncoderUtil.encodePassword(patient.getPasswordHash()));
//        return patientRepository.save(patient);
//    }
//
//    @Transactional
//    public Patient updatePatient(Long id, Patient patientDetails) {
//        Patient existingPatient = patientRepository.findById(id)
//                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + id));
//
//        existingPatient.setIdentifier(patientDetails.getIdentifier());
//        existingPatient.setPatientType(patientDetails.getPatientType());
//        if (patientDetails.getPasswordHash() != null && !patientDetails.getPasswordHash().isEmpty()) {
//            existingPatient.setPasswordHash(passwordEncoderUtil.encodePassword(patientDetails.getPasswordHash()));
//        }
//        existingPatient.setFullName(patientDetails.getFullName());
//        existingPatient.setPhoneNumber(patientDetails.getPhoneNumber());
//        existingPatient.setStatus(patientDetails.getStatus());
//
//        return patientRepository.save(existingPatient);
//    }
//
//    @Transactional
//    public void deletePatient(Long id) {
//        if (!patientRepository.existsById(id)) {
//            throw new ResourceNotFoundException("Patient not found with id " + id);
//        }
//        patientRepository.deleteById(id);
//    }
//
//    @Transactional
//    public PatientProfile savePatientProfile(PatientProfile patientProfile) {
//        return patientProfileRepository.save(patientProfile);
//    }
//
//    public PatientResponse convertToResponseDto(Patient patient) {
//        if (patient == null) {
//            return null;
//        }
//
//        PatientResponse response = new PatientResponse();
//        BeanUtils.copyProperties(patient, response);  // Copy properties from patient to response
//        return response;
//    }
//
//}
package com.example.springboot.service;

// 导入 Spring Boot 核心组件和实体/DTO
import com.example.springboot.dto.auth.LoginResponse;
import com.example.springboot.dto.common.PageResponse; // 导入新增方法所需的DTO
import com.example.springboot.dto.patient.MedicalHistoryResponse; // 导入新增方法所需的DTO
import com.example.springboot.dto.patient.MedicalHistoryUpdateRequest; // 导入新增方法所需的DTO
import com.example.springboot.dto.patient.PatientResponse;
import com.example.springboot.dto.patient.PatientProfileResponse;
import com.example.springboot.dto.patient.PatientSimpleResponse;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.PatientProfile;
import com.example.springboot.common.Constants;
import com.example.springboot.entity.enums.BlacklistStatus;
import com.example.springboot.entity.enums.PatientStatus; // <<<<<< 确保导入您的 PatientStatus 枚举
import com.example.springboot.entity.enums.RegistrationSource;
import com.example.springboot.entity.enums.VerificationStatus;
import com.example.springboot.entity.PatientIdentityVerification;
import com.example.springboot.entity.Admin;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.repository.PatientProfileRepository;
import com.example.springboot.repository.PatientIdentityVerificationRepository;
import com.example.springboot.repository.AdminRepository;
import com.example.springboot.util.PasswordEncoderUtil; // 导入您的密码工具类
import com.example.springboot.dto.patient.PatientSelfRegisterRequest;
import com.example.springboot.dto.patient.PatientRegistrationResponse;
import com.example.springboot.dto.verification.VerificationResponse;
import jakarta.persistence.criteria.JoinType;
import org.hibernate.Hibernate;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PatientService {

    private final PatientRepository patientRepository;
    private final PatientProfileRepository patientProfileRepository;
    private final PatientIdentityVerificationRepository verificationRepository;
    private final AdminRepository adminRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;
    
    @Autowired
    private com.example.springboot.security.JwtTokenProvider jwtTokenProvider;

    // 构造函数注入
    @Autowired
    public PatientService(PatientRepository patientRepository, 
                         PatientProfileRepository patientProfileRepository,
                         PatientIdentityVerificationRepository verificationRepository,
                         AdminRepository adminRepository,
                         PasswordEncoderUtil passwordEncoderUtil) {
        this.patientRepository = patientRepository;
        this.patientProfileRepository = patientProfileRepository;
        this.verificationRepository = verificationRepository;
        this.adminRepository = adminRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
    }

    // =========================================================================
    // 【患者登录】
    // =========================================================================

    /**
     * 患者登录
     * @param identifier 学号/工号
     * @param password 密码
     * @return 登录响应
     */
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public LoginResponse login(String identifier, String password) {
        LocalDateTime now = LocalDateTime.now();
        
        // 1. 查找患者
        Patient patient = patientRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new IllegalArgumentException("学号/工号或密码错误"));
        
        // 调试日志：记录查询到的失败次数
        System.out.println("[PatientService] 查询到的失败次数: " + patient.getFailedLoginCount() + 
                          ", 最后失败时间: " + patient.getLastFailedLoginTime());

        // 2. 检查账户状态（在验证密码之前）
        if (patient.getStatus() == PatientStatus.inactive) {
            // 如果是自主注册的用户，检查身份验证审核状态
            if (patient.getRegistrationSource() == RegistrationSource.self_registered) {
                PatientIdentityVerification verification = verificationRepository
                    .findByPatient_PatientId(patient.getPatientId())
                    .orElse(null);
                
                if (verification != null) {
                    if (verification.getStatus() == VerificationStatus.pending) {
                        throw new IllegalArgumentException("身份验证审核中，请耐心等待管理员审核");
                    } else if (verification.getStatus() == VerificationStatus.rejected) {
                        String reason = verification.getRejectionReason() != null 
                            ? "，拒绝原因：" + verification.getRejectionReason()
                            : "";
                        throw new IllegalArgumentException("身份验证未通过" + reason + "，请联系管理员");
                    }
                }
            }
            throw new IllegalArgumentException("账户未激活，请先激活账户");
        }
        
        if (patient.getStatus() == PatientStatus.deleted) {
            throw new IllegalArgumentException("账户已删除，无法登录");
        }

        // 3. 检查账户锁定状态
        // 如果账户状态是locked，检查是否已到解锁时间
        if (patient.getStatus() == PatientStatus.locked) {
            if (patient.getLockedUntil() != null && now.isAfter(patient.getLockedUntil())) {
                // 自动解锁：重置状态和失败次数
                patient.setStatus(PatientStatus.active);
                patient.setFailedLoginCount(0);
                patient.setLastFailedLoginTime(null);
                patient.setLockedUntil(null);
                patientRepository.save(patient);
            } else {
                // 仍在锁定期内
                throw new IllegalArgumentException("账户已被锁定，请联系管理员");
            }
        }

        // 4. 初始化失败登录计数（如果为null）
        if (patient.getFailedLoginCount() == null) {
            patient.setFailedLoginCount(0);
        }

        // 5. 检查失败登录时间窗口：如果距离最后一次失败登录超过30分钟，重置失败次数
        // 这样可以避免失败次数无限累积，给用户重新尝试的机会
        if (patient.getLastFailedLoginTime() != null && patient.getFailedLoginCount() > 0) {
            long minutesSinceLastFailure = java.time.Duration.between(patient.getLastFailedLoginTime(), now).toMinutes();
            if (minutesSinceLastFailure >= Constants.ACCOUNT_LOCK_DURATION_MINUTES) {
                // 超过时间窗口，重置失败次数
                patient.setFailedLoginCount(0);
                patient.setLastFailedLoginTime(null);
                patientRepository.save(patient);
            }
        }

        // 6. 验证密码
        boolean passwordMatches = passwordEncoderUtil.matches(password, patient.getPasswordHash());
        
        if (!passwordMatches) {
            // 登录失败：增加失败次数
            // 重新从数据库查询，确保获取最新的失败次数（避免缓存问题）
            Patient freshPatient = patientRepository.findByIdentifier(identifier)
                    .orElseThrow(() -> new IllegalArgumentException("学号/工号或密码错误"));
            
            int currentFailureCount = freshPatient.getFailedLoginCount() != null ? freshPatient.getFailedLoginCount() : 0;
            int newFailureCount = currentFailureCount + 1;
            
            System.out.println("[PatientService] 登录失败 - 当前失败次数: " + currentFailureCount + 
                              ", 新失败次数: " + newFailureCount);
            
            freshPatient.setFailedLoginCount(newFailureCount);
            freshPatient.setLastFailedLoginTime(now);
            
            // 保存失败次数到数据库（确保事务提交）
            patientRepository.save(freshPatient);
            // 强制刷新到数据库，确保数据已保存
            patientRepository.flush();
            
            // 验证保存是否成功
            Patient verifyPatient = patientRepository.findByIdentifier(identifier).orElse(null);
            if (verifyPatient != null) {
                System.out.println("[PatientService] 保存后验证 - 失败次数: " + verifyPatient.getFailedLoginCount());
            }
            
            // 检查是否达到锁定阈值
            if (newFailureCount >= Constants.MAX_LOGIN_FAILURE_COUNT) {
                // 自动锁定账户
                freshPatient.setStatus(PatientStatus.locked);
                freshPatient.setLockedUntil(now.plusMinutes(Constants.ACCOUNT_LOCK_DURATION_MINUTES));
                patientRepository.save(freshPatient);
                patientRepository.flush();
                throw new IllegalArgumentException("登录失败次数过多，账户已被锁定，请" + Constants.ACCOUNT_LOCK_DURATION_MINUTES + "分钟后再试或联系管理员");
            } else {
                // 未达到阈值，计算剩余次数
                int remainingAttempts = Constants.MAX_LOGIN_FAILURE_COUNT - newFailureCount;
                throw new IllegalArgumentException("学号/工号或密码错误，还可尝试" + remainingAttempts + "次");
            }
        }

        // 7. 密码正确，登录成功：重置失败次数
        if (patient.getFailedLoginCount() != null && patient.getFailedLoginCount() > 0) {
            patient.setFailedLoginCount(0);
            patient.setLastFailedLoginTime(null);
            patientRepository.save(patient);
        }

        // 7. 构建用户信息
        Map<String, Object> patientInfo = new HashMap<>();
        patientInfo.put("patientId", patient.getPatientId());
        patientInfo.put("identifier", patient.getIdentifier());
        patientInfo.put("fullName", patient.getFullName());
        patientInfo.put("phoneNumber", patient.getPhoneNumber());
        patientInfo.put("patientType", patient.getPatientType().name());
        patientInfo.put("status", patient.getStatus().name());

        // 8. 生成Token
        String token = jwtTokenProvider.generateToken(
            patient.getIdentifier(), 
            "patient", 
            patient.getPatientId()
        );

        // 9. 返回登录响应
        return LoginResponse.builder()
                .token(token)  // 返回实际Token
                .userType("patient")
                .userInfo(patientInfo)
                .build();
    }

    // =========================================================================
    // 【修改】账户激活功能 - 接口 1: 验证初始信息和密码
    // =========================================================================

    /**
     * 验证账户初始信息：检查学号/工号是否存在、未激活，并验证初始密码
     * @param identifier 学号/工号
     * @param initialPassword 校方初始密码
     * @throws ResourceNotFoundException 如果患者不存在
     * @throws IllegalArgumentException 如果账户已激活或密码错误
     */
    @Transactional(readOnly = true)
    public void verifyInitialActivation(String identifier, String initialPassword) {

        // 1. 查找患者主记录
        Patient patient = patientRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new ResourceNotFoundException("学号/工号不存在或系统未录入。"));

        // 2. 校验：账户是否已经激活
        if (patient.getStatus() == PatientStatus.active) { // 假设 ACTIVE 是您的枚举值
            throw new IllegalArgumentException("该账户已处于激活状态，请直接登录。");
        }

        // 3. 校验：初始密码是否匹配
        String storedInitialPasswordHash = patient.getPasswordHash();

        // 使用您的密码工具类进行密码校验
        if (storedInitialPasswordHash == null ||
                !passwordEncoderUtil.matches(initialPassword, storedInitialPasswordHash)) {
            // 注意：这里假设您的 PasswordEncoderUtil 有一个 matches(rawPassword, encodedPassword) 方法
            throw new IllegalArgumentException("初始密码错误，验证失败。");
        }

        // 如果未激活且密码正确，则验证通过
    }

    // =========================================================================
    // 账户激活功能 - 接口 2: 身份验证与激活
    // =========================================================================

    /**
     * 激活账户：验证身份，设置密码，更新状态
     * @param identifier 学号/工号
     * @param idCardEnding 身份证号后6位
     * @param newPassword 新密码
     * @param confirmPassword 确认密码
     * @throws IllegalArgumentException 如果校验失败（密码不一致、身份验证失败）
     * @throws ResourceNotFoundException 如果患者信息找不到
     */
    @Transactional
    public void activateAccount(String identifier, String idCardEnding, String newPassword, String confirmPassword) {

        // 1. 基本校验：密码一致性和长度
        if (!newPassword.equals(confirmPassword)) {
            throw new IllegalArgumentException("两次输入的新密码不一致。");
        }
        if (newPassword == null || newPassword.length() < 6 || newPassword.length() > 20) {
            throw new IllegalArgumentException("密码长度必须在 6-20 位之间。");
        }

        // 2. 查找患者主记录
        Patient patient = patientRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new ResourceNotFoundException("患者信息不存在。"));

        // 3. 身份验证
        // 通过 patient_id 查找 PatientProfile 记录
        PatientProfile profile = patientProfileRepository.findById(patient.getPatientId())
                .orElseThrow(() -> new ResourceNotFoundException("未找到身份证信息（数据异常）。"));

        String fullIdCard = profile.getIdCardNumber();

        // 身份验证逻辑：检查数据库中的完整身份证号是否以用户输入的后6位结尾
        if (fullIdCard == null || fullIdCard.length() < 6 || !fullIdCard.endsWith(idCardEnding)) {
            throw new IllegalArgumentException("身份验证失败：身份证号后6位不匹配。");
        }

        // 4. 更新密码和状态
        String hashedPassword = passwordEncoderUtil.encodePassword(newPassword); // 使用您的加密工具

        // 更新 patients 表的 password_hash 和 status
        patient.setPasswordHash(hashedPassword);
        patient.setStatus(PatientStatus.active); // 设置为激活状态
        patientRepository.save(patient);
    }


    // =========================================================================
    // CRUD Operations for Patient
    // =========================================================================

    @Transactional(readOnly = true)
    public List<Patient> findAllPatients() {
        return patientRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Patient> findPatientById(Long id) {
        return patientRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Patient> findPatientByIdentifier(String identifier) {
        return patientRepository.findByIdentifier(identifier);
    }

    @Transactional
    public Patient createPatient(Patient patient) {
        // Encode password before saving
        if (patient.getPasswordHash() != null && !patient.getPasswordHash().isEmpty()) {
            patient.setPasswordHash(passwordEncoderUtil.encodePassword(patient.getPasswordHash()));
        }
        return patientRepository.save(patient);
    }

    @Transactional
    public Patient updatePatient(Long id, Patient patientDetails) {
        Patient existingPatient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + id));

        existingPatient.setIdentifier(patientDetails.getIdentifier());
        existingPatient.setPatientType(patientDetails.getPatientType());
        if (patientDetails.getPasswordHash() != null && !patientDetails.getPasswordHash().isEmpty()) {
            existingPatient.setPasswordHash(passwordEncoderUtil.encodePassword(patientDetails.getPasswordHash()));
        }
        existingPatient.setFullName(patientDetails.getFullName());
        existingPatient.setPhoneNumber(patientDetails.getPhoneNumber());
        existingPatient.setStatus(patientDetails.getStatus());

        return patientRepository.save(existingPatient);
    }

    @Transactional
    public void deletePatient(Long id) {
        if (!patientRepository.existsById(id)) {
            throw new ResourceNotFoundException("Patient not found with id " + id);
        }
        patientRepository.deleteById(id);
    }

    @Transactional
    public PatientProfile savePatientProfile(PatientProfile patientProfile) {
        return patientProfileRepository.save(patientProfile);
    }

    public PatientResponse convertToResponseDto(Patient patient) {
        if (patient == null) {
            return null;
        }

        PatientResponse response = new PatientResponse();
        BeanUtils.copyProperties(patient, response);  // Copy properties from patient to response
        
        // 加载并转换患者档案信息
        if (patient.getPatientId() != null) {
            Optional<PatientProfile> profileOpt = patientProfileRepository.findById(patient.getPatientId());
            if (profileOpt.isPresent()) {
                PatientProfile profile = profileOpt.get();
                PatientProfileResponse profileResponse = new PatientProfileResponse();
                BeanUtils.copyProperties(profile, profileResponse);
                if (profile.getBlacklistStatus() != null) {
                    profileResponse.setBlacklistStatus(profile.getBlacklistStatus().name());
                }
                response.setPatientProfile(profileResponse);
            }
        }
        
        return response;
    }

    // =========================================================================
    // 【新增】处理病历记录的方法 (解决 UserServiceImpl 编译错误)
    // =========================================================================

    /**
     * 【新增】查询所有病历记录的方法。
     * * 注意：由于缺少 MedicalHistory 实体和对应的 Repository，
     * 此处仅返回一个空的 PageResponse 以解决编译错误。
     * 实际业务逻辑需要关联 Patient 或 PatientProfile 并查询 MedicalHistory 实体。
     * * @param page 页码 (从 1 开始)
     * @param pageSize 每页大小
     * @return 包含病历记录列表的分页响应
     */
    @Transactional(readOnly = true)
    public PageResponse<MedicalHistoryResponse> getMedicalHistories(Integer page, Integer pageSize) {
        // 校验分页参数
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1 || pageSize > 100) {
            pageSize = 10;
        }

        // 调试：检查数据库中患者总数
        long totalPatients = patientRepository.count();
        System.out.println("=== 病历历史查询调试 ===");
        System.out.println("数据库中患者总数: " + totalPatients);
        System.out.println("查询参数 - 页码: " + page + ", 页大小: " + pageSize);

        // 构建分页参数（JPA页码从0开始）
        Pageable pageable = PageRequest.of(page - 1, pageSize);

        // 分页查询患者及其关联的档案信息（使用JOIN FETCH优化关联查询）
// 分页查询患者及其关联的档案信息（修复JOIN FETCH导致的语义错误）
        Page<Patient> patientPage = patientRepository.findAll((Specification<Patient>) (root, query, cb) -> {
            // 1. 用普通JOIN替换fetch，避免触发JOIN FETCH的语义校验
            root.join("patientProfile", JoinType.LEFT); // 仅关联查询，不迫切加载
            query.distinct(true); // 去重，避免重复记录
            return cb.conjunction();
        }, pageable);

// 2. 遍历结果时手动初始化关联实体（解决懒加载问题）
        List<MedicalHistoryResponse> content = patientPage.getContent().stream()
                .map(patient -> {
                    // 手动初始化patientProfile（因为是LAZY加载）
                    if (patient.getPatientProfile() != null) {
                        Hibernate.initialize(patient.getPatientProfile());
                    }
                    // 后续转换逻辑不变...
                    MedicalHistoryResponse response = new MedicalHistoryResponse();
                    response.setId(patient.getPatientId());
                    response.setName(patient.getFullName());

                    PatientProfile profile = patient.getPatientProfile();
                    if (profile != null) {
                        response.setIdCard(profile.getIdCardNumber());
                        response.setPastMedicalHistory(profile.getMedicalHistory());
                        response.setAllergyHistory(profile.getAllergies());
                        response.setIsBlacklisted(profile.getBlacklistStatus() == BlacklistStatus.blacklisted);
                    } else {
                        response.setPastMedicalHistory("");
                        response.setAllergyHistory("");
                        response.setIsBlacklisted(false);
                    }
                    return response;
                })
                .collect(Collectors.toList());
        
        System.out.println("转换后的病历记录数量: " + content.size());

        // 构建分页响应
        return new PageResponse<>(
                content,
                patientPage.getTotalElements(),
                patientPage.getTotalPages(),
                page,
                pageSize
        );
    }
    /**
     * 【新增】更新指定病历记录的方法。
     * * 注意：由于缺少 MedicalHistory 实体，此方法暂时抛出异常，
     * 以确保编译通过，并提醒开发者需要 MedicalHistory 实体才能实现真正的更新。
     * * @param id 病历记录 ID
     * @param request 包含更新内容的请求 DTO
     * @return 包含更新后病历记录的分页响应 (返回值格式为满足接口要求)
     */
    @Transactional
    public PageResponse<MedicalHistoryResponse> updateMedicalHistory(Long id, MedicalHistoryUpdateRequest request) {
        // 抛出异常，提示需要 MedicalHistory 实体
        throw new UnsupportedOperationException("真正的病历记录更新需要 MedicalHistory 实体及其 Repository.");
    }

    @Transactional(readOnly = true)
    public PatientSimpleResponse getPatientSimpleInfo(Long patientId) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + patientId));

        PatientSimpleResponse response = new PatientSimpleResponse();
        response.setPatientId(patient.getPatientId());
        response.setName(patient.getFullName());
        response.setPhone(patient.getPhoneNumber());
        return response;
    }

    // =========================================================================
    // 【新增】患者自主注册功能
    // =========================================================================

    /**
     * 学生/教师自主注册
     * @param request 注册请求（包含身份证明材料）
     * @return 注册结果
     */
    @Transactional
    public PatientRegistrationResponse selfRegister(PatientSelfRegisterRequest request) {
        // 1. 检查学号/工号是否已存在
        if (patientRepository.findByIdentifier(request.getIdentifier()).isPresent()) {
            throw new IllegalArgumentException("该学号/工号已被注册");
        }

        // 2. 检查手机号是否已存在
        if (request.getPhoneNumber() != null && 
            patientRepository.findByPhoneNumber(request.getPhoneNumber()).isPresent()) {
            throw new IllegalArgumentException("该手机号已被注册");
        }

        // 3. 检查身份证号是否已被使用（包括已审核通过的患者档案和待审核/已通过的验证记录）
        // 3.1 检查已激活患者的身份证号（在 PatientProfile 中）
        if (patientProfileRepository.existsByIdCardNumber(request.getIdCardNumber())) {
            throw new IllegalArgumentException("该身份证号已被注册");
        }
        
        // 3.2 检查身份验证记录中是否已有相同的身份证号（待审核或已通过）
        // 注意：同一个身份证号可能有多条记录（如被拒绝后重新提交），所以需要查询所有记录
        List<PatientIdentityVerification> existingVerifications = 
            verificationRepository.findByIdCardNumberOrderByCreatedAtDesc(request.getIdCardNumber());
        
        // 检查是否有待审核或已通过的记录
        for (PatientIdentityVerification verification : existingVerifications) {
            if (verification.getStatus() == VerificationStatus.pending) {
                throw new IllegalArgumentException("该身份证号正在审核中，请勿重复提交");
            } else if (verification.getStatus() == VerificationStatus.approved) {
                throw new IllegalArgumentException("该身份证号已被注册");
            }
            // 如果状态是 rejected，允许重新提交（继续检查下一条记录）
        }

        // 4. 创建患者账户（状态为inactive，等待审核）
        Patient patient = new Patient();
        patient.setIdentifier(request.getIdentifier());
        patient.setPasswordHash(passwordEncoderUtil.encodePassword(request.getPassword()));
        patient.setFullName(request.getFullName());
        patient.setPhoneNumber(request.getPhoneNumber());
        patient.setPatientType(request.getPatientType());
        patient.setStatus(PatientStatus.inactive); // 初始状态为未激活
        patient.setRegistrationSource(RegistrationSource.self_registered);
        
        Patient savedPatient = patientRepository.save(patient);

        // 5. 创建身份验证申请记录
        PatientIdentityVerification verification = new PatientIdentityVerification();
        verification.setPatient(savedPatient);
        verification.setIdentifier(request.getIdentifier());
        verification.setFullName(request.getFullName());
        verification.setIdCardNumber(request.getIdCardNumber());
        verification.setPhoneNumber(request.getPhoneNumber());
        verification.setPatientType(request.getPatientType());
        verification.setIdCardFrontUrl(request.getIdCardFrontUrl()); // 身份证正面照片URL
        verification.setIdCardBackUrl(request.getIdCardBackUrl()); // 身份证背面照片URL
        verification.setStatus(VerificationStatus.pending);
        
        verificationRepository.save(verification);

        return PatientRegistrationResponse.builder()
            .patientId(savedPatient.getPatientId())
            .identifier(savedPatient.getIdentifier())
            .message("注册成功，请等待管理员审核身份信息")
            .status("pending")
            .build();
    }

    /**
     * 管理员审核身份验证申请
     * @param verificationId 验证申请ID
     * @param adminId 审核管理员ID
     * @param approved 是否通过
     * @param rejectionReason 拒绝原因（如果拒绝）
     */
    @Transactional
    public void reviewIdentityVerification(Long verificationId, Integer adminId, 
                                           boolean approved, String rejectionReason) {
        PatientIdentityVerification verification = 
            verificationRepository.findById(verificationId)
                .orElseThrow(() -> new ResourceNotFoundException("验证申请不存在"));

        if (verification.getStatus() != VerificationStatus.pending) {
            throw new IllegalArgumentException("该申请已审核，无法重复审核");
        }

        Admin admin = adminRepository.findById(adminId)
            .orElseThrow(() -> new ResourceNotFoundException("管理员不存在"));

        Patient patient = verification.getPatient();

        if (approved) {
            // 审核通过：激活账户，创建患者档案
            verification.setStatus(VerificationStatus.approved);
            patient.setStatus(PatientStatus.active);

            // 创建患者档案
            if (patientProfileRepository.findById(patient.getPatientId()).isEmpty()) {
                PatientProfile profile = new PatientProfile();
                profile.setPatient(patient);
                profile.setIdCardNumber(verification.getIdCardNumber());
                profile.setBlacklistStatus(com.example.springboot.entity.enums.BlacklistStatus.normal);
                patientProfileRepository.save(profile);
            }
        } else {
            // 审核拒绝
            if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
                throw new IllegalArgumentException("拒绝审核时必须提供拒绝原因");
            }
            verification.setStatus(VerificationStatus.rejected);
            verification.setRejectionReason(rejectionReason);
            // 账户保持inactive状态
        }

        verification.setReviewedBy(admin);
        verification.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(verification);
        patientRepository.save(patient);
    }

    /**
     * 获取待审核的身份验证申请列表
     */
    @Transactional(readOnly = true)
    public List<VerificationResponse> getPendingVerifications() {
        List<PatientIdentityVerification> verifications = 
            verificationRepository.findPendingVerifications(VerificationStatus.pending);
        
        return verifications.stream()
            .map(v -> {
                VerificationResponse response = VerificationResponse.builder()
                    .verificationId(v.getVerificationId())
                    .patientId(v.getPatient().getPatientId())
                    .identifier(v.getIdentifier())
                    .fullName(v.getFullName())
                    .idCardNumber(v.getIdCardNumber())
                    .phoneNumber(v.getPhoneNumber())
                    .patientType(v.getPatientType())
                    .idCardFrontUrl(v.getIdCardFrontUrl())
                    .idCardBackUrl(v.getIdCardBackUrl())
                    .status(v.getStatus())
                    .rejectionReason(v.getRejectionReason())
                    .createdAt(v.getCreatedAt())
                    .updatedAt(v.getUpdatedAt())
                    .build();
                
                if (v.getReviewedBy() != null) {
                    response.setReviewedBy(v.getReviewedBy().getAdminId());
                    response.setReviewedByName(v.getReviewedBy().getFullName());
                    response.setReviewedAt(v.getReviewedAt());
                }
                
                return response;
            })
            .collect(Collectors.toList());
    }

    /**
     * 获取所有身份验证申请（包括已审核的）
     */
    @Transactional(readOnly = true)
    public List<VerificationResponse> getAllVerifications() {
        List<PatientIdentityVerification> verifications = verificationRepository.findAll();
        
        return verifications.stream()
            .map(v -> {
                VerificationResponse response = VerificationResponse.builder()
                    .verificationId(v.getVerificationId())
                    .patientId(v.getPatient().getPatientId())
                    .identifier(v.getIdentifier())
                    .fullName(v.getFullName())
                    .idCardNumber(v.getIdCardNumber())
                    .phoneNumber(v.getPhoneNumber())
                    .patientType(v.getPatientType())
                    .idCardFrontUrl(v.getIdCardFrontUrl())
                    .idCardBackUrl(v.getIdCardBackUrl())
                    .status(v.getStatus())
                    .rejectionReason(v.getRejectionReason())
                    .createdAt(v.getCreatedAt())
                    .updatedAt(v.getUpdatedAt())
                    .build();
                
                if (v.getReviewedBy() != null) {
                    response.setReviewedBy(v.getReviewedBy().getAdminId());
                    response.setReviewedByName(v.getReviewedBy().getFullName());
                    response.setReviewedAt(v.getReviewedAt());
                }
                
                return response;
            })
            .collect(Collectors.toList());
    }
}
