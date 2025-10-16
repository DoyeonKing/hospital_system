package com.example.springboot.service;

import com.example.springboot.dto.department.DepartmentDTO;
import com.example.springboot.dto.department.DepartmentResponseDTO; // 引入Response DTO
import com.example.springboot.entity.Department;
import com.example.springboot.repository.DepartmentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
import java.util.Set; // 引入 Set 用于处理子科室
import org.hibernate.Hibernate; // <--- 引入 Hibernate
import com.example.springboot.dto.department.DepartmentDTO;
import com.example.springboot.dto.department.DepartmentResponseDTO;
import com.example.springboot.dto.department.DepartmentQueryDTO; // <-- 引入查询 DTO
import com.example.springboot.entity.Department;
import com.example.springboot.repository.DepartmentRepository;
import org.springframework.data.domain.Page; // <-- 引入 Page
import org.springframework.data.domain.PageRequest; // <-- 引入 PageRequest
import org.springframework.data.domain.Sort; // <-- 引入 Sort
import org.springframework.data.jpa.domain.Specification; // <-- 引入 Specification
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors; // <-- 引入 Collectors 用于 Page 转换
import org.hibernate.Hibernate;
import com.example.springboot.specifications.DepartmentSpecification;
import com.example.springboot.dto.department.DepartmentQueryDTO; // 引入查询DTO
import org.springframework.data.domain.Page; // 引入 Spring Data 的 Page 类型

@Service
public class DepartmentService {

    private final DepartmentRepository departmentRepository;

    public DepartmentService(DepartmentRepository departmentRepository) {
        this.departmentRepository = departmentRepository;
    }

    /**
     * 创建新科室
     * @param departmentDTO 包含新科室信息的DTO
     * @return 创建成功的科室的响应DTO
     * @throws RuntimeException 如果科室名称已存在或上级科室不存在
     */
    @Transactional
    public DepartmentResponseDTO createDepartment(DepartmentDTO departmentDTO) {
        // 1. 检查科室名称是否已存在
        if (departmentRepository.findByName(departmentDTO.getName()).isPresent()) {
            throw new RuntimeException("科室名称已存在: " + departmentDTO.getName());
        }

        Department newDepartment = new Department();
        newDepartment.setName(departmentDTO.getName());
        newDepartment.setDescription(departmentDTO.getDescription());

        // 用于存储查找到的上级科室
        Department parentDepartment = null;

        // 2. 处理上级科室 (parentDepartmentName)
        String parentName = departmentDTO.getParentDepartmentName();
        if (parentName != null && !parentName.trim().isEmpty()) {
            // 通过名称查找上级科室
            Optional<Department> parentOpt = departmentRepository.findByName(parentName);

            if (parentOpt.isPresent()) {
                parentDepartment = parentOpt.get(); // 记录上级科室实体
                newDepartment.setParentDepartment(parentDepartment);
            } else {
                // 如果上级科室名称存在, 但找不到对应的科室, 则抛出错误
                throw new RuntimeException("上级科室不存在: " + parentName);
            }
        } else {
            // parentDepartmentName 为空, parentDepartment 字段设为 null
            newDepartment.setParentDepartment(null);
        }

        // 3. 保存新科室
        Department savedDepartment = departmentRepository.save(newDepartment);

        // 4. 将保存的实体转换为 Response DTO，避免序列化问题
        return convertToResponseDTO(savedDepartment, parentDepartment);
    }

    /**
     * 编辑科室的描述信息
     * @param departmentDTO 包含科室名称和新的描述
     * @return 更新成功的科室的响应DTO
     * @throws RuntimeException 如果科室不存在
     */
    @Transactional
    public DepartmentResponseDTO updateDepartmentDescription(DepartmentDTO departmentDTO) {
        String departmentName = departmentDTO.getName();
        String newDescription = departmentDTO.getDescription();

        // 1. 通过名称查找科室
        Optional<Department> departmentOpt = departmentRepository.findByName(departmentName);

        if (departmentOpt.isEmpty()) {
            throw new RuntimeException("要编辑的科室不存在: " + departmentName);
        }

        Department departmentToUpdate = departmentOpt.get();

        // 2. 更新描述信息
        departmentToUpdate.setDescription(newDescription);

        // 3. 保存更新
        Department updatedDepartment = departmentRepository.save(departmentToUpdate);

        // 4. 转换为 Response DTO 返回。需要传递当前的上级科室实体。
        return convertToResponseDTO(updatedDepartment, updatedDepartment.getParentDepartment());
    }

    /**
     * 根据名称删除科室。
     * 删除前将所有子科室的上级科室ID置为空（解除关联）。
     * @param name 要删除的科室名称
     * @throws RuntimeException 如果科室不存在
     */
    @Transactional
    public void deleteDepartmentByName(String name) {
        // 1. 查找科室
        Optional<Department> departmentOpt = departmentRepository.findByName(name);

        if (departmentOpt.isEmpty()) {
            throw new RuntimeException("要删除的科室不存在: " + name);
        }

        Department departmentToDelete = departmentOpt.get();

        // 2. 强制初始化子科室集合，解决 LazyInitializationException
        Set<Department> children = departmentToDelete.getChildrenDepartments();

        // 强制加载集合 (如果 children 不为 null)
        if (children != null) {
            Hibernate.initialize(children); // <--- 关键修复点
        }

        // 3. 处理子科室 (解除关联)
        if (children != null && !children.isEmpty()) {
            for (Department child : children) {
                // 现在数据库允许 parent_id 为 NULL，所以这个操作应该成功
                child.setParentDepartment(null);
                departmentRepository.save(child);
            }
        }

        // 4. 删除科室
        departmentRepository.delete(departmentToDelete);
    }

    /**
     * 查询科室列表（分页、过滤和排序）
     * @param queryDTO 包含查询条件、分页和排序信息的DTO
     * @return 分页结果的响应DTO Page<DepartmentResponseDTO>
     */
    @Transactional(readOnly = true) // 查询操作使用 readOnly 事务
    public Page<DepartmentResponseDTO> queryDepartments(DepartmentQueryDTO queryDTO) {
        // 1. 设置分页和排序参数
        int page = queryDTO.getPage() != null ? queryDTO.getPage() : 0; // 默认页码 0
        int size = queryDTO.getSize() != null ? queryDTO.getSize() : 10; // 默认每页 10 条
        String sortBy = queryDTO.getSortBy() != null ? queryDTO.getSortBy() : "departmentId"; // 默认排序字段
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(queryDTO.getSortOrder()) ? Sort.Direction.DESC : Sort.Direction.ASC;

        // 构建 Pageable 对象
        PageRequest pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortBy));

        // 2. 构建查询条件 Specification
        Specification<Department> spec = DepartmentSpecification.buildSpecification(queryDTO);

        // 3. 执行查询
        // JpaRepository.findAll(Specification, Pageable) 方法
        Page<Department> departmentPage = departmentRepository.findAll(spec, pageable);

        // 4. 转换实体 Page 为 Response DTO Page
        return departmentPage.map(department -> {
            // 在 Page.map 转换过程中，需要注意获取 ParentDepartment 的 Name。
            // 实体转换时，需要确保 parentDepartment 已被加载，
            // 否则在非事务方法中可能会引发 LazyInitializationException。
            // 由于 findAll 是在 @Transactional(readOnly = true) 中执行的，
            // 且 parentDepartment 是 FetchType.LAZY，最好的方式是通过 DTO 的构造器或
            // 明确指定 JOIN FETCH。

            // 简单处理：由于是在事务中，直接访问 getParentDepartment() 理论上是安全的。
            // 但为了健壮性，若需要减少 N+1 查询，应考虑自定义 Repository 方法使用 JOIN FETCH。
            // 这里我们沿用现有的 convertToResponseDTO 逻辑。

            Department parent = department.getParentDepartment(); // 尝试获取上级科室

            // 强制加载 parentDepartment 避免在 DTO 转换后可能发生的 LazyInitializationException
            // 如果你使用的是 DTO 投影，则不需要手动加载
            if (parent != null && !Hibernate.isInitialized(parent)) {
                Hibernate.initialize(parent);
            }

            return convertToResponseDTO(department, parent);
        });
    }

    /**
     * 将 Department 实体转换为 DepartmentResponseDTO
     */
    private DepartmentResponseDTO convertToResponseDTO(Department department, Department parentDepartment) {
        DepartmentResponseDTO dto = new DepartmentResponseDTO();
        dto.setDepartmentId(department.getDepartmentId());
        dto.setName(department.getName());
        dto.setDescription(department.getDescription());

        // 设置上级科室信息
        if (parentDepartment != null) {
            dto.setParentDepartmentId(parentDepartment.getDepartmentId());
            dto.setParentDepartmentName(parentDepartment.getName());
        }

        return dto;
    }

}