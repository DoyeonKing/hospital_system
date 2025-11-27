package com.example.springboot.repository;

import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.LeaveRequest;
import com.example.springboot.entity.enums.LeaveRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Integer> {
    List<LeaveRequest> findByDoctor(Doctor doctor);
    List<LeaveRequest> findByStatus(LeaveRequestStatus status);
    List<LeaveRequest> findByStartTimeBeforeAndEndTimeAfterAndStatus(LocalDateTime end, LocalDateTime start, LeaveRequestStatus status);
}
