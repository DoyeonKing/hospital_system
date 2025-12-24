package com.example.springboot.repository;

import com.example.springboot.entity.Patient;
import com.example.springboot.entity.enums.PatientStatus;
import com.example.springboot.entity.enums.PatientType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public interface PatientRepository extends JpaRepository<Patient, Long>, JpaSpecificationExecutor<Patient> {
    Optional<Patient> findByIdentifier(String identifier);
    boolean existsByIdentifier(String identifier);
    Optional<Patient> findByPhoneNumber(String phoneNumber);

    long countByStatusNot(PatientStatus status);

    long countByStatusNotAndCreatedAtBetween(PatientStatus status, LocalDateTime start, LocalDateTime end);

    long countByStatusNotAndPatientType(PatientStatus status, PatientType patientType);

    /**
     * 统计指定创建时间范围内的患者数量
     */
    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    /**
     * 按患者类型统计数量
     */
    long countByPatientType(PatientType patientType);

    /**
     * 按日期范围分组统计患者注册数量
     */
    @Query("SELECT DATE(p.createdAt) as date, COUNT(p) as count " +
           "FROM Patient p " +
           "WHERE p.createdAt BETWEEN :start AND :end " +
           "AND p.status != com.example.springboot.entity.enums.PatientStatus.deleted " +
           "GROUP BY DATE(p.createdAt) " +
           "ORDER BY DATE(p.createdAt)")
    List<Map<String, Object>> countByDateRangeGroupByDate(
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    /**
     * 统计所有非删除状态的患者总数（用于累计注册用户）
     */
    @Query("SELECT COUNT(p) FROM Patient p WHERE p.status != com.example.springboot.entity.enums.PatientStatus.deleted")
    long countTotalActivePatients();
}