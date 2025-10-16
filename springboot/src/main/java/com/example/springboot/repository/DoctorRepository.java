package com.example.springboot.repository; // 包名调整

import com.example.springboot.entity.Doctor; // 导入路径调整
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DoctorRepository extends JpaRepository<Doctor, Integer> , JpaSpecificationExecutor<Doctor> {
    Optional<Doctor> findByIdentifier(String identifier);
    boolean existsByIdentifier(String identifier);
}
