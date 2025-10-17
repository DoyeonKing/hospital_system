package com.example.springboot.service;

import com.example.springboot.dto.auth.LoginResponse;
import com.example.springboot.dto.doctor.DoctorActivateRequest;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.enums.DoctorStatus;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.util.PasswordEncoderUtil;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import com.example.springboot.entity.Department;
import com.example.springboot.repository.DepartmentRepository;

@Service
public class DoctorService {

    private final DoctorRepository doctorRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;
    private final DepartmentRepository departmentRepository;

    @Autowired
    public DoctorService(DoctorRepository doctorRepository, PasswordEncoderUtil passwordEncoderUtil, DepartmentRepository departmentRepository) { // 【修改构造函数】
        this.doctorRepository = doctorRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
        this.departmentRepository = departmentRepository;
    }

    // =========================================================================
    // 【医生登录】
    // =========================================================================

    /**
     * 医生登录
     * @param identifier 医生工号
     * @param password 密码
     * @return 登录响应
     */
    @Transactional(readOnly = true)
    public LoginResponse login(String identifier, String password) {
        // 1. 查找医生
        Doctor doctor = doctorRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new IllegalArgumentException("工号或密码错误"));

        // 2. 验证密码
        if (!passwordEncoderUtil.matches(password, doctor.getPasswordHash())) {
            throw new IllegalArgumentException("工号或密码错误");
        }

        // 3. 检查账户状态
        if (doctor.getStatus() == DoctorStatus.inactive) {
            throw new IllegalArgumentException("账户未激活，请先激活账户");
        }
        
        if (doctor.getStatus() == DoctorStatus.locked) {
            throw new IllegalArgumentException("账户已被锁定，请联系管理员");
        }

        // 4. 构建用户信息
        Map<String, Object> doctorInfo = new HashMap<>();
        doctorInfo.put("doctorId", doctor.getDoctorId());
        doctorInfo.put("identifier", doctor.getIdentifier());
        doctorInfo.put("fullName", doctor.getFullName());
        doctorInfo.put("title", doctor.getTitle());
        doctorInfo.put("phoneNumber", doctor.getPhoneNumber());
        doctorInfo.put("departmentName", doctor.getDepartment() != null ? doctor.getDepartment().getName() : null);
        doctorInfo.put("status", doctor.getStatus().name());

        // 5. 返回登录响应
        return LoginResponse.builder()
                .token(null) // 暂不使用token
                .userType("doctor")
                .userInfo(doctorInfo)
                .build();
    }

    // =========================================================================
    // 【账号激活 - 接口 1】验证初始信息和密码
    // =========================================================================

    /**
     * Verifies initial account information: identifier existence, inactive status, and initial password.
     * @param identifier Doctor's identifier (work ID).
     * @param initialPassword Initial password provided by the school/hospital.
     */
    @Transactional(readOnly = true)
    public void verifyInitialActivation(String identifier, String initialPassword) {

        // 1. Find doctor record
        Doctor doctor = doctorRepository.findByIdentifier(identifier)
                .orElseThrow(() -> new ResourceNotFoundException("Identifier not found or doctor record not system-registered."));

        // 2. Check: Is the account already active?
        // 假设 DoctorStatus.ACTIVE 表示已激活
        if (doctor.getStatus() == DoctorStatus.active) {
            throw new IllegalArgumentException("Account is already active. Please proceed to login.");
        }

        // 3. Check: Does the initial password match? (Hashing Comparison)
        String storedInitialPasswordHash = doctor.getPasswordHash();

        if (storedInitialPasswordHash == null ||
                !passwordEncoderUtil.matches(initialPassword, storedInitialPasswordHash)) {
            throw new IllegalArgumentException("Initial password verification failed.");
        }
    }

    // =========================================================================
    // 【账号激活 - 接口 2】身份验证与激活 (存储新密码哈希)
    // =========================================================================

    /**
     * Activates the account: performs identity verification (ID card ending), sets the new password, and updates status to ACTIVE.
     * @param request Contains identifier, ID card ending (last 6 digits), and new password details.
     */
    @Transactional
    public void activateAccount(DoctorActivateRequest request) {

        // 1. Basic password validation
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("New passwords do not match.");
        }
        if (request.getNewPassword() == null || request.getNewPassword().length() < 6 || request.getNewPassword().length() > 20) {
            throw new IllegalArgumentException("Password length must be between 6 and 20 characters.");
        }

        // 2. Find doctor record
        Doctor doctor = doctorRepository.findByIdentifier(request.getIdentifier())
                .orElseThrow(() -> new ResourceNotFoundException("Doctor information not found."));

        // 3. Identity Verification (using ID Card number)
        String storedIdCard = doctor.getIdCardNumber();
        String requestedEnding = request.getIdCardEnding();

        if (storedIdCard == null || storedIdCard.isEmpty()) {
            throw new IllegalArgumentException("System data is missing (ID card number). Cannot proceed with identity verification.");
        }

        // Compare the ending of the stored ID card number with the provided ending (e.g., last 6 digits)
        int requiredLength = requestedEnding.length();
        if (storedIdCard.length() < requiredLength ||
                !storedIdCard.substring(storedIdCard.length() - requiredLength).equals(requestedEnding)) {
            throw new IllegalArgumentException("Identity verification failed: Last " + requiredLength + " digits of ID card do not match.");
        }

        // 4. Update password and status
        String hashedPassword = passwordEncoderUtil.encodePassword(request.getNewPassword());

        doctor.setPasswordHash(hashedPassword);
        doctor.setStatus(DoctorStatus.active); // Set to active status
        doctorRepository.save(doctor);
    }
    // =========================================================================
    // 【新增核心业务方法】将医生分配到指定科室
    // =========================================================================

    /**
     * 【核心业务方法】将医生分配到指定科室（更新 Doctor.department 字段）。
     * 业务逻辑：根据工号查找医生，如果不存在则创建，无论如何都更新其所属科室和基本信息。
     * @param departmentId 目标科室的ID
     * @param identifier 医生的工号/ID
     * @param fullName 医生姓名
     * @param title 职称
     * @return 更新后的医生响应 DTO DoctorResponse
     */
    @Transactional
    public DoctorResponse assignDoctorToDepartment(
            Integer departmentId,
            String identifier,
            String fullName,
            String title) {

        // 1. 验证目标科室是否存在
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("科室ID " + departmentId + " 不存在"));

        // 2. 根据工号查找医生
        // 假设 DoctorRepository 中存在 findByIdentifier(String identifier) 方法
        Optional<Doctor> existingDoctor = doctorRepository.findByIdentifier(identifier);

        Doctor doctor;

        if (existingDoctor.isPresent()) {
            // 3a. 医生已存在：更新其信息和科室
            doctor = existingDoctor.get();

            // 业务校验：检查医生是否已经属于该科室
            if (doctor.getDepartment() != null && doctor.getDepartment().getDepartmentId().equals(departmentId)) {
                // 如果已存在于该科室，返回冲突
                throw new RuntimeException("医生 " + identifier + " 已经属于该科室");
            }

            // 更新医生基本信息和所属科室
            doctor.setFullName(fullName);
            doctor.setTitle(title);
            doctor.setDepartment(department); // 【核心操作】

        } else {
            // 3b. 医生不存在：创建新医生实体
            doctor = new Doctor();

            // 赋值前端提供的信息
            doctor.setIdentifier(identifier);
            doctor.setFullName(fullName);
            doctor.setTitle(title);
            doctor.setDepartment(department); // 设置所属科室

            // 处理非空约束字段 (来自 Doctor.java)
            String tempPassword = "DefaultTempPassword";
            doctor.setPasswordHash(passwordEncoderUtil.encodePassword(tempPassword));
            doctor.setStatus(DoctorStatus.inactive); // 默认设置为未激活状态
        }

        // 4. 保存到数据库
        Doctor savedDoctor = doctorRepository.save(doctor);

        // 5. 转换为 DTO 返回
        return convertToResponseDto(savedDoctor);
    }
    // =========================================================================
    // 【新增核心业务方法】删除科室成员
    // =========================================================================

    /**
     * 【核心业务方法】根据工号删除医生。
     * @param identifier 医生的工号/ID
     */
    @Transactional
    public void deleteDoctorByIdentifier(String identifier) {
        // 1. 查找医生
        Optional<Doctor> doctorOptional = doctorRepository.findByIdentifier(identifier);

        if (doctorOptional.isEmpty()) {
            throw new ResourceNotFoundException("工号为 " + identifier + " 的医生不存在");
        }

        // 2. 执行删除
        // 假设 DoctorRepository 中存在 delete(Doctor doctor) 方法
        doctorRepository.delete(doctorOptional.get());
    }

    // =========================================================================
    // 原有 CRUD 方法 (更新时增加 idCardNumber 字段的更新)
    // =========================================================================

    @Transactional(readOnly = true)
    public List<Doctor> findAllDoctors() {
        return doctorRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Doctor> findDoctorById(Integer id) {
        return doctorRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Doctor> findDoctorByIdentifier(String identifier) {
        return doctorRepository.findByIdentifier(identifier);
    }

    @Transactional
    public Doctor createDoctor(Doctor doctor) {
        // Ensure password is hashed upon creation
        doctor.setPasswordHash(passwordEncoderUtil.encodePassword(doctor.getPasswordHash()));
        return doctorRepository.save(doctor);
    }

    @Transactional
    public Doctor updateDoctor(Integer id, Doctor doctorDetails) {
        Doctor existingDoctor = doctorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + id));

        // Update fields
        existingDoctor.setDepartment(doctorDetails.getDepartment());
        existingDoctor.setIdentifier(doctorDetails.getIdentifier());

        // Update new field: idCardNumber
        existingDoctor.setIdCardNumber(doctorDetails.getIdCardNumber());

        if (doctorDetails.getPasswordHash() != null && !doctorDetails.getPasswordHash().isEmpty()) {
            existingDoctor.setPasswordHash(passwordEncoderUtil.encodePassword(doctorDetails.getPasswordHash()));
        }
        existingDoctor.setFullName(doctorDetails.getFullName());
        existingDoctor.setPhoneNumber(doctorDetails.getPhoneNumber());
        existingDoctor.setTitle(doctorDetails.getTitle());
        existingDoctor.setSpecialty(doctorDetails.getSpecialty());
        existingDoctor.setBio(doctorDetails.getBio());
        existingDoctor.setPhotoUrl(doctorDetails.getPhotoUrl());
        existingDoctor.setStatus(doctorDetails.getStatus());

        return doctorRepository.save(existingDoctor);
    }

    @Transactional
    public void deleteDoctor(Integer id) {
        if (!doctorRepository.existsById(id)) {
            throw new ResourceNotFoundException("Doctor not found with id " + id);
        }
        doctorRepository.deleteById(id);
    }

    public DoctorResponse convertToResponseDto(Doctor doctor) {
        if (doctor == null) {
            return null;
        }

        DoctorResponse response = new DoctorResponse();
        BeanUtils.copyProperties(doctor, response);
        return response;
    }
}
