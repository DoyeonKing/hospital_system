package com.example.springboot.repository;

import com.example.springboot.entity.PatientProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientProfileRepository extends JpaRepository<PatientProfile, Long> {
    Optional<PatientProfile> findByIdCardNumber(String idCardNumber);
    boolean existsByIdCardNumber(String idCardNumber);
}
