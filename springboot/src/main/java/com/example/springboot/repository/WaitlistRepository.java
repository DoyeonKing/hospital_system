package com.example.springboot.repository;

import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.Waitlist;
import com.example.springboot.entity.enums.WaitlistStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface WaitlistRepository extends JpaRepository<Waitlist, Integer> {
    List<Waitlist> findByScheduleAndStatusOrderByCreatedAtAsc(Schedule schedule, WaitlistStatus status);
    Optional<Waitlist> findByPatientAndScheduleAndStatus(Patient patient, Schedule schedule, WaitlistStatus status);
    boolean existsByPatientAndScheduleAndStatus(Patient patient, Schedule schedule, WaitlistStatus status);
    List<Waitlist> findByCreatedAtBeforeAndStatus(LocalDateTime time, WaitlistStatus status);
    List<Waitlist> findByPatient(Patient patient);
    Page<Waitlist> findByScheduleAndStatusOrderByCreatedAtAsc(Schedule schedule, WaitlistStatus status, Pageable pageable);
    Page<Waitlist> findByScheduleOrderByCreatedAtAsc(Schedule schedule, Pageable pageable);
    long countByScheduleAndStatusAndCreatedAtBefore(Schedule schedule, WaitlistStatus status, LocalDateTime createdAt);
}
