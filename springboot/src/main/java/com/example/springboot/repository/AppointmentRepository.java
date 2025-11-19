package com.example.springboot.repository;

import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import org.apache.ibatis.annotations.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Integer> {
    List<Appointment> findByPatient(Patient patient);
    List<Appointment> findBySchedule(Schedule schedule);
    boolean existsByPatientAndSchedule(Patient patient, Schedule schedule);
    long countBySchedule(Schedule schedule);
    List<Appointment> findByScheduleScheduleDateAndScheduleSlotStartTimeBeforeAndStatus(
            java.time.LocalDate scheduleDate, java.time.LocalTime checkInTime, com.example.springboot.entity.enums.AppointmentStatus status);
    // 添加复杂查询方法
    @Query("SELECT a FROM Appointment a WHERE a.patient = :patient " +
            "AND (a.schedule.scheduleDate > :today " +
            "OR (a.schedule.scheduleDate = :today2 AND a.schedule.slot.startTime > :now))")
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
}
