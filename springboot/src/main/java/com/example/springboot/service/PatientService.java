package com.example.springboot.service;

// 导入 Spring Boot 核心组件和实体/DTO
import com.example.springboot.dto.patient.PatientResponse;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.PatientProfile;
import com.example.springboot.entity.enums.PatientStatus; // <<<<<< 确保导入您的 PatientStatus 枚举
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.repository.PatientProfileRepository;
import com.example.springboot.util.PasswordEncoderUtil; // 导入您的密码工具类
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class PatientService {

    private final PatientRepository patientRepository;
    private final PatientProfileRepository patientProfileRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;

    // 构造函数注入
    @Autowired
    public PatientService(PatientRepository patientRepository, PatientProfileRepository patientProfileRepository, PasswordEncoderUtil passwordEncoderUtil) {
        this.patientRepository = patientRepository;
        this.patientProfileRepository = patientProfileRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
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
    // 【原有】 CRUD 方法 (保持不变)
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
        patient.setPasswordHash(passwordEncoderUtil.encodePassword(patient.getPasswordHash()));
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
        return response;
    }
}