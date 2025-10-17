package com.example.springboot.repository;

import com.example.springboot.entity.Doctor;
import org.apache.ibatis.annotations.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor; // 关键：新增导入
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

@Repository
// 继承 JpaSpecificationExecutor 以支持 findAll(Specification, Pageable) 方法，解决编译错误 2
public interface DoctorRepository extends JpaRepository<Doctor, Integer>, JpaSpecificationExecutor<Doctor> {
    // 通过工号查找医生
    Optional<Doctor> findByIdentifier(String identifier);

    // 检查工号是否存在
    boolean existsByIdentifier(String identifier);

    @Query("SELECT d FROM Doctor d JOIN FETCH d.department WHERE d.identifier LIKE %:id% OR d.fullName LIKE %:name%")
    Page<Doctor> findByKeywordWithDepartment(
            @Param("id") String id,
            @Param("name") String name,
            Pageable pageable);
}
