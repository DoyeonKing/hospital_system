package com.example.springboot.repository;

import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.enums.AppointmentStatus;
import com.example.springboot.entity.enums.AppointmentType;
import org.apache.ibatis.annotations.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Integer> {
    List<Appointment> findByPatient(Patient patient);
    List<Appointment> findBySchedule(Schedule schedule);
    boolean existsByPatientAndSchedule(Patient patient, Schedule schedule);
    
    /**
     * 检查患者是否有该排班的有效预约（排除已取消的预约）
     */
    @Query("SELECT COUNT(a) > 0 FROM Appointment a WHERE a.patient = :patient AND a.schedule = :schedule AND a.status != com.example.springboot.entity.enums.AppointmentStatus.cancelled")
    boolean existsByPatientAndScheduleAndStatusNotCancelled(@Param("patient") Patient patient, @Param("schedule") Schedule schedule);
    
    /**
     * 统计排班的有效预约数（排除已取消的预约）
     */
    @Query("SELECT COUNT(a) FROM Appointment a WHERE a.schedule = :schedule AND a.status != com.example.springboot.entity.enums.AppointmentStatus.cancelled")
    long countByScheduleAndStatusNotCancelled(@Param("schedule") Schedule schedule);
    long countBySchedule(Schedule schedule);
    List<Appointment> findByScheduleScheduleDateAndScheduleSlotStartTimeBeforeAndStatus(
            java.time.LocalDate scheduleDate, java.time.LocalTime checkInTime, com.example.springboot.entity.enums.AppointmentStatus status);

    /**
     * 统计指定日期的预约总数（按排班日期计算）
     */
    long countBySchedule_ScheduleDate(LocalDate scheduleDate);

    /**
     * 统计指定日期、指定状态的预约数量（用于当前候诊人数等）
     */
    long countByStatusAndSchedule_ScheduleDate(AppointmentStatus status, LocalDate scheduleDate);

    /**
     * 查询指定创建时间范围内的预约记录
     */
    List<Appointment> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    /**
     * 查询指定排班日期的所有预约
     */
    List<Appointment> findBySchedule_ScheduleDate(LocalDate scheduleDate);

    /**
     * 查询排班日期在指定范围内的所有预约
     */
    List<Appointment> findBySchedule_ScheduleDateBetween(LocalDate startDate, LocalDate endDate);
    // 添加复杂查询方法 - 查询患者所有未完成、未取消的预约（排班结束时间还没到的）
    // 判断逻辑：排班日期在今天之后，或者排班日期是今天但结束时间在今天之后
    @Query("SELECT a FROM Appointment a WHERE a.patient = :patient " +
            "AND a.status != com.example.springboot.entity.enums.AppointmentStatus.cancelled " +
            "AND a.status != com.example.springboot.entity.enums.AppointmentStatus.completed " +
            "AND (a.schedule.scheduleDate > :today " +
            "OR (a.schedule.scheduleDate = :today2 AND a.schedule.slot.endTime > :now)) " +
            "ORDER BY a.schedule.scheduleDate ASC, a.schedule.slot.startTime ASC")
    List<Appointment> findByPatientAndScheduleScheduleDateAfterOrScheduleScheduleDateEqualAndScheduleSlotStartTimeAfter(
            @Param("patient") Patient patient,
            @Param("today") LocalDate today,
            @Param("today") LocalDate today2,
            @Param("now") LocalTime now);

    List<Appointment> findByScheduleDoctorDoctorId(Integer doctorId);
    
    /**
     * 根据医生ID和日期查询预约列表（包含患者和患者档案信息）
     * @param doctorId 医生ID
     * @param scheduleDate 排班日期
     * @return 预约列表
     */
    @Query("SELECT a FROM Appointment a " +
           "LEFT JOIN FETCH a.patient p " +
           "LEFT JOIN FETCH p.patientProfile " +
           "LEFT JOIN FETCH a.schedule s " +
           "LEFT JOIN FETCH s.doctor " +
           "LEFT JOIN FETCH s.slot " +
           "WHERE s.doctor.doctorId = :doctorId " +
           "AND s.scheduleDate = :scheduleDate " +
           "ORDER BY s.slot.startTime ASC, a.appointmentNumber ASC")
    List<Appointment> findByDoctorIdAndDate(
            @Param("doctorId") Integer doctorId,
            @Param("scheduleDate") LocalDate scheduleDate);

    @Query("SELECT MAX(a.appointmentNumber) FROM Appointment a WHERE a.schedule = :schedule")
    Integer findMaxAppointmentNumberBySchedule(@Param("schedule") Schedule schedule);

    Appointment findTopByScheduleOrderByAppointmentNumberDesc(Schedule schedule);

    @Query(""" 
            SELECT a FROM Appointment a
            JOIN FETCH a.schedule s
            JOIN FETCH s.doctor d
            JOIN FETCH d.department dept
            LEFT JOIN FETCH dept.parentDepartment parent
            LEFT JOIN FETCH s.slot slot
            LEFT JOIN FETCH s.location loc
            WHERE s.scheduleDate BETWEEN :startDate AND :endDate
              AND (:departmentId IS NULL OR dept.departmentId = :departmentId)
              AND (:doctorId IS NULL OR d.doctorId = :doctorId)
              AND a.status = :status
              AND a.checkInTime IS NOT NULL
            """)
    List<Appointment> findAppointmentsForRegistrationHours(
            @Param("departmentId") Integer departmentId,
            @Param("doctorId") Integer doctorId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") com.example.springboot.entity.enums.AppointmentStatus status);
    
    /**
     * 查询某个排班下指定状态的预约（用于叫号队列）
     */
    @Query("SELECT a FROM Appointment a WHERE a.schedule = :schedule AND a.status = :status")
    List<Appointment> findByScheduleAndStatus(
            @Param("schedule") Schedule schedule, 
            @Param("status") com.example.springboot.entity.enums.AppointmentStatus status);
    
    // ===== 加号功能相关查询方法 =====
    
    /**
     * 查询超时未支付的加号预约（参考候补的expireNotifiedWaitlists实现）
     * 用于定时任务检查并取消超时的加号预约
     */
    @Query("SELECT a FROM Appointment a WHERE a.appointmentType = :appointmentType " +
           "AND a.status = :status " +
           "AND a.paymentDeadline IS NOT NULL " +
           "AND a.paymentDeadline < :now")
    List<Appointment> findExpiredAddOnPayments(
            @Param("appointmentType") AppointmentType appointmentType,
            @Param("status") AppointmentStatus status,
            @Param("now") LocalDateTime now);
    
    /**
     * 根据预约类型和状态查询预约列表
     */
    List<Appointment> findByAppointmentTypeAndStatus(
            AppointmentType appointmentType, 
            AppointmentStatus status);
    
    /**
     * 查询指定排班和类型的最大预约序号（用于加号序号分配）
     */
    @Query("SELECT MAX(a.appointmentNumber) FROM Appointment a " +
           "WHERE a.schedule = :schedule AND a.appointmentType = :appointmentType")
    Integer findMaxAppointmentNumberByScheduleAndType(
            @Param("schedule") Schedule schedule,
            @Param("appointmentType") AppointmentType appointmentType);
    
    /**
     * 统计指定排班的待支付加号数量（用于计算实际可用号源）
     */
    @Query("SELECT COUNT(a) FROM Appointment a " +
           "WHERE a.schedule = :schedule " +
           "AND a.appointmentType = :appointmentType " +
           "AND a.status = :status")
    Integer countByScheduleAndTypeAndStatus(
            @Param("schedule") Schedule schedule,
            @Param("appointmentType") AppointmentType appointmentType,
            @Param("status") AppointmentStatus status);

    /**
     * 统计指定创建时间范围内的预约数量
     */
    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    /**
     * 统计指定状态的预约数量
     */
    long countByStatusIn(List<AppointmentStatus> statuses);

    /**
     * 统计今天或未来的候诊人数（已签到但未就诊，或已预约但未就诊）
     */
    @Query("SELECT COUNT(a) FROM Appointment a " +
           "WHERE a.status IN :statuses " +
           "AND a.schedule.scheduleDate >= :today")
    long countPendingPatientsByStatusInAndScheduleDateAfter(
            @Param("statuses") List<AppointmentStatus> statuses,
            @Param("today") LocalDate today);

    /**
     * 统计已签到且未完成的总人数（不管日期）
     * CHECKED_IN 状态本身就是已签到但未完成，所以只需要统计状态为 CHECKED_IN 的预约
     */
    @Query("SELECT COUNT(a) FROM Appointment a " +
           "WHERE a.status = com.example.springboot.entity.enums.AppointmentStatus.CHECKED_IN")
    long countCheckedInAndNotCompleted();

    /**
     * 按日期范围分组统计预约数量
     */
    @Query("SELECT DATE(a.createdAt) as date, COUNT(a) as count " +
           "FROM Appointment a " +
           "WHERE a.createdAt BETWEEN :start AND :end " +
           "GROUP BY DATE(a.createdAt) " +
           "ORDER BY DATE(a.createdAt)")
    List<Map<String, Object>> countByDateRangeGroupByDate(
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    /**
     * 按支付状态分组统计
     */
    @Query("SELECT a.paymentStatus as status, COUNT(a) as count " +
           "FROM Appointment a " +
           "GROUP BY a.paymentStatus")
    List<Map<String, Object>> countByPaymentStatus();

    /**
     * 按科室统计预约数量 Top 5
     */
    @Query("SELECT d.name as name, COUNT(a) as count " +
           "FROM Appointment a " +
           "JOIN a.schedule s " +
           "JOIN s.doctor doc " +
           "JOIN doc.department d " +
           "GROUP BY d.departmentId, d.name " +
           "ORDER BY COUNT(a) DESC")
    List<Map<String, Object>> countByDepartmentTop5();

    /**
     * 按医生统计预约数量 Top 5
     */
    @Query("SELECT doc.fullName as name, d.name as department, COUNT(a) as count " +
           "FROM Appointment a " +
           "JOIN a.schedule s " +
           "JOIN s.doctor doc " +
           "JOIN doc.department d " +
           "GROUP BY doc.doctorId, doc.fullName, d.name " +
           "ORDER BY COUNT(a) DESC")
    List<Map<String, Object>> countByDoctorTop5();

    /**
     * 按时间段统计预约数量（所有历史数据）
     */
    @Query("SELECT CONCAT(ts.startTime, '-', ts.endTime) as time, COUNT(a) as count " +
           "FROM Appointment a " +
           "JOIN a.schedule s " +
           "JOIN s.slot ts " +
           "GROUP BY ts.slotId, ts.startTime, ts.endTime " +
           "ORDER BY ts.startTime")
    List<Map<String, Object>> countByTimeSlot();

    /**
     * 按时间段统计指定日期范围内的预约数量
     */
    @Query("SELECT CONCAT(ts.startTime, '-', ts.endTime) as time, COUNT(a) as count " +
           "FROM Appointment a " +
           "JOIN a.schedule s " +
           "JOIN s.slot ts " +
           "WHERE s.scheduleDate BETWEEN :startDate AND :endDate " +
           "GROUP BY ts.slotId, ts.startTime, ts.endTime " +
           "ORDER BY ts.startTime")
    List<Map<String, Object>> countByTimeSlotAndDateRange(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    /**
     * 根据患者姓名和科室ID查询该患者在该科室的所有就诊记录
     * @param patientName 患者姓名
     * @param departmentId 科室ID
     * @return 预约列表
     */
    @Query("SELECT a FROM Appointment a " +
           "LEFT JOIN FETCH a.patient p " +
           "LEFT JOIN FETCH p.patientProfile " +
           "LEFT JOIN FETCH a.schedule s " +
           "LEFT JOIN FETCH s.doctor d " +
           "LEFT JOIN FETCH d.department dept " +
           "LEFT JOIN FETCH s.slot " +
           "WHERE p.fullName LIKE %:patientName% " +
           "AND dept.departmentId = :departmentId " +
           "ORDER BY s.scheduleDate DESC, s.slot.startTime DESC")
    List<Appointment> findByPatientNameAndDepartment(
            @Param("patientName") String patientName,
            @Param("departmentId") Integer departmentId);
    // ===== 加号功能相关查询方法 =====
    
    /**
     * 查询超时未支付的加号预约（参考候补的expireNotifiedWaitlists实现）
     * 用于定时任务检查并取消超时的加号预约
     */
    @Query("SELECT a FROM Appointment a WHERE a.appointmentType = :appointmentType " +
           "AND a.status = :status " +
           "AND a.paymentDeadline IS NOT NULL " +
           "AND a.paymentDeadline < :now")
    List<Appointment> findExpiredAddOnPayments(
            @Param("appointmentType") AppointmentType appointmentType,
            @Param("status") AppointmentStatus status,
            @Param("now") LocalDateTime now);
    
    /**
     * 根据预约类型和状态查询预约列表
     */
    List<Appointment> findByAppointmentTypeAndStatus(
            AppointmentType appointmentType, 
            AppointmentStatus status);
    
    /**
     * 查询指定排班和类型的最大预约序号（用于加号序号分配）
     */
    @Query("SELECT MAX(a.appointmentNumber) FROM Appointment a " +
           "WHERE a.schedule = :schedule AND a.appointmentType = :appointmentType")
    Integer findMaxAppointmentNumberByScheduleAndType(
            @Param("schedule") Schedule schedule,
            @Param("appointmentType") AppointmentType appointmentType);
    
    /**
     * 统计指定排班的待支付加号数量（用于计算实际可用号源）
     */
    @Query("SELECT COUNT(a) FROM Appointment a " +
           "WHERE a.schedule = :schedule " +
           "AND a.appointmentType = :appointmentType " +
           "AND a.status = :status")
    Integer countByScheduleAndTypeAndStatus(
            @Param("schedule") Schedule schedule,
            @Param("appointmentType") AppointmentType appointmentType,
            @Param("status") AppointmentStatus status);
}
