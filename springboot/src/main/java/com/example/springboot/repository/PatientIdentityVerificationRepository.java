package com.example.springboot.repository;

import com.example.springboot.entity.Patient;
import com.example.springboot.entity.PatientIdentityVerification;
import com.example.springboot.entity.enums.VerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PatientIdentityVerificationRepository extends JpaRepository<PatientIdentityVerification, Long> {
    /**
     * 根据患者查找身份验证记录
     */
    Optional<PatientIdentityVerification> findByPatient(Patient patient);

    /**
     * 根据患者ID查找身份验证记录
     */
    Optional<PatientIdentityVerification> findByPatient_PatientId(Long patientId);

    /**
     * 根据审核状态查找所有验证记录
     */
    List<PatientIdentityVerification> findByStatus(VerificationStatus status);

    /**
     * 查找待审核的记录（按创建时间倒序）
     */
    @Query("SELECT v FROM PatientIdentityVerification v WHERE v.status = :status ORDER BY v.createdAt DESC")
    List<PatientIdentityVerification> findPendingVerifications(@Param("status") VerificationStatus status);

    /**
     * 根据学号/工号查找身份验证记录
     */
    Optional<PatientIdentityVerification> findByIdentifier(String identifier);

    /**
     * 根据身份证号查找所有身份验证记录（用于检查身份证号是否已被使用）
     * 注意：同一个身份证号可能有多条记录（如被拒绝后重新提交）
     */
    List<PatientIdentityVerification> findByIdCardNumberOrderByCreatedAtDesc(String idCardNumber);
}

