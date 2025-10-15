package com.example.springboot.repository;

import com.example.springboot.entity.Clinic;
import com.example.springboot.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Integer> {
    List<Department> findByClinic(Clinic clinic);
    Optional<Department> findByClinicAndName(Clinic clinic, String name);
    List<Department> findByParentDepartment(Department parentDepartment);
    List<Department> findByParentDepartmentIsNullAndClinic(Clinic clinic); // 查询一级部门
}
