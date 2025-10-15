package com.example.springboot.repository;

import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Integer> {
    List<Schedule> findByDoctorAndScheduleDateBetween(Doctor doctor, LocalDate startDate, LocalDate endDate);
    List<Schedule> findByScheduleDateAndStatus(LocalDate scheduleDate, ScheduleStatus status);
    Optional<Schedule> findByDoctorAndScheduleDateAndTimeSlot(Doctor doctor, LocalDate scheduleDate, TimeSlot timeSlot);
    List<Schedule> findByDoctorAndScheduleDateGreaterThanEqualAndStatus(Doctor doctor, LocalDate date, ScheduleStatus status);
}
