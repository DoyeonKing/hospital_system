package com.example.springboot.repository;

import com.example.springboot.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor; // <-- 引入
import java.util.Optional;

public interface DepartmentRepository extends JpaRepository<Department, Integer>, JpaSpecificationExecutor<Department> { // <-- 继承 JpaSpecificationExecutor

    /**
     * 根据科室名称查找科室
     * @param name 科室名称
     * @return 匹配的科室 Optional
     */
    Optional<Department> findByName(String name);
}