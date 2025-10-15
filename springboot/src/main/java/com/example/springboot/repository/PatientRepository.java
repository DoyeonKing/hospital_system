package com.example.springboot.repository; // 包名调整

import com.example.springboot.entity.Patient; // 导入路径调整
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientRepository extends JpaRepository<Patient, Long> {
    Optional<Patient> findByIdentifier(String identifier);
    boolean existsByIdentifier(String identifier);
}
