package com.example.springboot.repository;

import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
public interface ScheduleRepository extends JpaRepository<Schedule, Integer> {
    List<Schedule> findByDoctorAndScheduleDateBetween(Doctor doctor, LocalDate startDate, LocalDate endDate);
    List<Schedule> findByScheduleDateAndStatus(LocalDate scheduleDate, ScheduleStatus status);
    Optional<Schedule> findByDoctorAndScheduleDateAndSlot(Doctor doctor, LocalDate scheduleDate, TimeSlot slot);
    List<Schedule> findByDoctorAndScheduleDateGreaterThanEqualAndStatus(Doctor doctor, LocalDate date, ScheduleStatus status);

    /**
     * 按日期范围与医生集合查询排班
     */
    List<Schedule> findByScheduleDateBetweenAndDoctorIn(LocalDate startDate, LocalDate endDate, List<Doctor> doctors);
    
    // 根据日期范围查找排班
    List<Schedule> findByScheduleDateBetween(LocalDate startDate, LocalDate endDate);

    // 根据具体日期查找排班
    List<Schedule> findByScheduleDate(LocalDate date);
    
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
    
    /**
     * 检查医生是否有未来的排班
     */
    @Query("SELECT COUNT(s) FROM Schedule s WHERE s.doctor = :doctor AND s.scheduleDate >= :currentDate")
    long countFutureSchedulesByDoctor(@Param("doctor") Doctor doctor, @Param("currentDate") LocalDate currentDate);
    
    /**
     * 检查科室下的所有医生是否有未来的排班
     */
    @Query("SELECT COUNT(s) FROM Schedule s WHERE s.doctor.department.departmentId = :departmentId AND s.scheduleDate >= :currentDate")
    long countFutureSchedulesByDepartment(@Param("departmentId") Integer departmentId, @Param("currentDate") LocalDate currentDate);
    
    /**
     * 检查地点是否在未来的排班中被使用
     */
    @Query("SELECT COUNT(s) FROM Schedule s WHERE s.location.locationId = :locationId AND s.scheduleDate >= :currentDate")
    long countFutureSchedulesByLocation(@Param("locationId") Integer locationId, @Param("currentDate") LocalDate currentDate);

    /**
     * 根据医生ID和日期范围查询排班（支持分页）
     */
    @Query("SELECT s FROM Schedule s " +
           "LEFT JOIN FETCH s.doctor d " +
           "LEFT JOIN FETCH s.slot ts " +
           "LEFT JOIN FETCH s.location l " +
           "WHERE s.doctor.doctorId = :doctorId " +
           "AND (:startDate IS NULL OR s.scheduleDate >= :startDate) " +
           "AND (:endDate IS NULL OR s.scheduleDate <= :endDate) " +
           "ORDER BY s.scheduleDate ASC, ts.startTime ASC")
    Page<Schedule> findSchedulesByDoctorIdAndDateRange(@Param("doctorId") Integer doctorId,
                                                        @Param("startDate") LocalDate startDate,
                                                        @Param("endDate") LocalDate endDate,
                                                        Pageable pageable);

    /**
     * 统计指定日期的不重复医生数量
     */
    @Query("SELECT COUNT(DISTINCT s.doctor.doctorId) " +
           "FROM Schedule s " +
           "JOIN s.doctor d " +
           "WHERE s.scheduleDate = :date " +
           "AND s.status <> com.example.springboot.entity.enums.ScheduleStatus.cancelled")
    long countDistinctDoctorsByScheduleDate(@Param("date") LocalDate date);
    
    /**
     * 查询指定日期的所有有效排班（排除已取消）
     */
    @Query("SELECT s FROM Schedule s " +
           "JOIN FETCH s.doctor d " +
           "WHERE s.scheduleDate = :date " +
           "AND s.status <> com.example.springboot.entity.enums.ScheduleStatus.cancelled")
    List<Schedule> findActiveSchedulesByDate(@Param("date") LocalDate date);

    /**
     * 删除指定科室在日期范围内的所有排班
     */
    @Modifying
    @Query("DELETE FROM Schedule s WHERE s.doctor.department.departmentId = :departmentId " +
           "AND s.scheduleDate >= :startDate AND s.scheduleDate <= :endDate")
    void deleteByDepartmentAndDateRange(@Param("departmentId") Integer departmentId,
                                        @Param("startDate") LocalDate startDate,
                                        @Param("endDate") LocalDate endDate);

    /**
     * 使用悲观锁查找排班，防止并发抢号问题
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM Schedule s WHERE s.scheduleId = :scheduleId")
    Optional<Schedule> findByIdWithLock(@Param("scheduleId") Integer scheduleId);

    /**
     * 原子性地增加 bookedSlots，只有在 bookedSlots < totalSlots 时才会更新
     * 返回受影响的行数，如果返回 0 表示号源已满或不存在
     * 这个方法使用数据库级别的原子更新，确保并发安全
     */
    @Modifying
    @Query("UPDATE Schedule s SET s.bookedSlots = s.bookedSlots + 1 " +
           "WHERE s.scheduleId = :scheduleId " +
           "AND s.bookedSlots < s.totalSlots " +
           "AND s.status = com.example.springboot.entity.enums.ScheduleStatus.available")
    int incrementBookedSlotsAtomically(@Param("scheduleId") Integer scheduleId);

    /**
     * 原子性地减少 bookedSlots，确保不会小于 0
     * 返回受影响的行数
     */
    @Modifying
    @Query("UPDATE Schedule s SET s.bookedSlots = s.bookedSlots - 1 " +
           "WHERE s.scheduleId = :scheduleId " +
           "AND s.bookedSlots > 0")
    int decrementBookedSlotsAtomically(@Param("scheduleId") Integer scheduleId);
}