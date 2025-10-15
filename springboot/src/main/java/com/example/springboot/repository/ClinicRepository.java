package com.example.springboot.repository;

import com.example.springboot.entity.Clinic;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ClinicRepository extends JpaRepository<Clinic, Integer> {
    Optional<Clinic> findByName(String name);
    boolean existsByName(String name);
}
