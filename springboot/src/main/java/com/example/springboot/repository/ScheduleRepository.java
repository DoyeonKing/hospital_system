package com.example.springboot.repository;

import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Integer> {
    List<Schedule> findByDoctorAndScheduleDateBetween(Doctor doctor, LocalDate startDate, LocalDate endDate);
    List<Schedule> findByScheduleDateAndStatus(LocalDate scheduleDate, ScheduleStatus status);
    Optional<Schedule> findByDoctorAndScheduleDateAndSlot(Doctor doctor, LocalDate scheduleDate, TimeSlot slot);
    List<Schedule> findByDoctorAndScheduleDateGreaterThanEqualAndStatus(Doctor doctor, LocalDate date, ScheduleStatus status);
    
    // 根据日期范围查找排班
    List<Schedule> findByScheduleDateBetween(LocalDate startDate, LocalDate endDate);
    
    /**
     * 分页查询排班列表（含关联信息）
     */
    @Query("SELECT s FROM Schedule s " +
           "LEFT JOIN s.doctor d " +
           "LEFT JOIN d.department dept " +
           "LEFT JOIN s.slot ts " +
           "LEFT JOIN s.location l " +
           "WHERE (:departmentId IS NULL OR dept.departmentId = :departmentId) " +
           "AND (:startDate IS NULL OR s.scheduleDate >= :startDate) " +
           "AND (:endDate IS NULL OR s.scheduleDate <= :endDate) " +
           "AND (:status IS NULL OR s.status = :status)")
    Page<Schedule> findSchedulesWithDetails(@Param("departmentId") Integer departmentId,
                                           @Param("startDate") LocalDate startDate,
                                           @Param("endDate") LocalDate endDate,
                                           @Param("status") String status,
                                           Pageable pageable);
}