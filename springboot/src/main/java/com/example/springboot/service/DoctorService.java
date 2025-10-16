package com.example.springboot.service;

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

import java.util.List;
import java.util.Optional;

@Service
public class DoctorService {

    private final DoctorRepository doctorRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;

    @Autowired
    public DoctorService(DoctorRepository doctorRepository, PasswordEncoderUtil passwordEncoderUtil) {
        this.doctorRepository = doctorRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
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
