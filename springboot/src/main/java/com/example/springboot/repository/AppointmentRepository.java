package com.example.springboot.repository;

import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Integer> {
    List<Appointment> findByPatient(Patient patient);
    List<Appointment> findBySchedule(Schedule schedule);
    boolean existsByPatientAndSchedule(Patient patient, Schedule schedule);
    long countBySchedule(Schedule schedule);
    List<Appointment> findByScheduleScheduleDateAndScheduleSlotStartTimeBeforeAndStatus(
            java.time.LocalDate scheduleDate, java.time.LocalTime checkInTime, com.example.springboot.entity.enums.AppointmentStatus status);
}
