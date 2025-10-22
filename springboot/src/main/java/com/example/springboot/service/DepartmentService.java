package com.example.springboot.service;

import com.example.springboot.dto.department.DepartmentDTO;
import com.example.springboot.dto.department.DepartmentResponseDTO;
import com.example.springboot.dto.department.DepartmentQueryDTO;
import com.example.springboot.dto.department.DepartmentTreeDTO;
import com.example.springboot.dto.department.DoctorDataDTO;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.Department;
import com.example.springboot.entity.ParentDepartment;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.enums.DoctorStatus;
import com.example.springboot.repository.DepartmentRepository;
import com.example.springboot.repository.ParentDepartmentRepository;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.specifications.DepartmentSpecification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.hibernate.Hibernate;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class DepartmentService {

    @Autowired
    private DepartmentRepository departmentRepository;
    
    @Autowired
    private ParentDepartmentRepository parentDepartmentRepository;
    
    @Autowired
    private DoctorRepository doctorRepository;

    /**
     * 创建新子科室
     * 
     * @param departmentDTO 包含新科室信息的DTO
     * @return 创建成功的科室的响应DTO
     * @throws RuntimeException 如果科室名称已存在或父科室不存在
     */
    @Transactional
    public DepartmentResponseDTO createDepartment(DepartmentDTO departmentDTO) {
        // 1. 检查科室名称是否已存在
        if (departmentRepository.existsByName(departmentDTO.getName())) {
            throw new RuntimeException("科室名称已存在: " + departmentDTO.getName());
        }

        // 2. 查找父科室
        String parentName = departmentDTO.getParentDepartmentName();
        if (parentName == null || parentName.trim().isEmpty()) {
            throw new RuntimeException("必须指定父科室");
        }
        
        ParentDepartment parentDepartment = parentDepartmentRepository.findByName(parentName)
                .orElseThrow(() -> new RuntimeException("父科室不存在: " + parentName));

        // 3. 创建新科室
        Department newDepartment = new Department(parentDepartment, departmentDTO.getName(), departmentDTO.getDescription());
        Department savedDepartment = departmentRepository.save(newDepartment);

        // 4. 转换为响应DTO
        return convertToResponseDTO(savedDepartment);
    }

    /**
     * 编辑科室的描述信息
     * 
     * @param departmentDTO 包含科室名称和新的描述
     * @return 更新成功的科室的响应DTO
     * @throws RuntimeException 如果科室不存在
     */
    @Transactional
    public DepartmentResponseDTO updateDepartmentDescription(DepartmentDTO departmentDTO) {
        String departmentName = departmentDTO.getName();
        String newDescription = departmentDTO.getDescription();

        // 1. 通过名称查找科室
        Department departmentToUpdate = departmentRepository.findByName(departmentName)
                .orElseThrow(() -> new RuntimeException("要编辑的科室不存在: " + departmentName));

        // 2. 更新描述信息
        departmentToUpdate.setDescription(newDescription);

        // 3. 保存更新
        Department updatedDepartment = departmentRepository.save(departmentToUpdate);

        // 4. 转换为响应DTO
        return convertToResponseDTO(updatedDepartment);
    }

    /**
     * 根据名称删除科室
     * 
     * @param name 要删除的科室名称
     * @throws RuntimeException 如果科室不存在
     */
    @Transactional
    public void deleteDepartmentByName(String name) {
        Department departmentToDelete = departmentRepository.findByName(name)
                .orElseThrow(() -> new RuntimeException("要删除的科室不存在: " + name));

        departmentRepository.delete(departmentToDelete);
    }

    /**
     * 查询科室列表（分页、过滤和排序）
     * 
     * @param queryDTO 包含查询条件、分页和排序信息的DTO
     * @return 分页结果的响应DTO Page<DepartmentResponseDTO>
     */
    @Transactional(readOnly = true)
    public Page<DepartmentResponseDTO> queryDepartments(DepartmentQueryDTO queryDTO) {
        // 1. 设置分页和排序参数
        int page = queryDTO.getPage() != null ? queryDTO.getPage() : 0;
        int size = queryDTO.getSize() != null ? queryDTO.getSize() : 10;
        
        // 确保页码不小于0
        if (page < 0) {
            page = 0;
        }
        
        // 确保页面大小在合理范围内
        if (size <= 0) {
            size = 10;
        } else if (size > 1000) {
            size = 1000; // 限制最大页面大小
        }
        
        String sortBy = queryDTO.getSortBy() != null ? queryDTO.getSortBy() : "departmentId";
        Sort.Direction sortDirection = "desc".equalsIgnoreCase(queryDTO.getSortOrder()) ? Sort.Direction.DESC
                : Sort.Direction.ASC;

        // 构建 Pageable 对象
        PageRequest pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortBy));

        // 2. 构建查询条件 Specification
        Specification<Department> spec = DepartmentSpecification.buildSpecification(queryDTO);

        // 3. 执行查询
        Page<Department> departmentPage = departmentRepository.findAll(spec, pageable);

        // 4. 转换实体 Page 为 Response DTO Page
        return departmentPage.map(department -> {
            // 强制加载parentDepartment避免LazyInitializationException
            ParentDepartment parent = department.getParentDepartment();
            if (parent != null && !Hibernate.isInitialized(parent)) {
                Hibernate.initialize(parent);
            }
            return convertToResponseDTO(department);
        });
    }

    /**
     * 根据科室ID获取科室信息
     * 
     * @param departmentId 科室ID
     * @return 科室响应DTO，如果不存在返回null
     */
    @Transactional(readOnly = true)
    public DepartmentResponseDTO getDepartmentById(Integer departmentId) {
        Optional<Department> departmentOpt = departmentRepository.findById(departmentId);

        if (departmentOpt.isEmpty()) {
            return null;
        }

        Department department = departmentOpt.get();
        return convertToResponseDTO(department);
    }

    /**
     * 根据父科室ID获取所有子科室
     * 
     * @param parentId 父科室ID
     * @return 子科室列表
     */
    @Transactional(readOnly = true)
    public List<DepartmentResponseDTO> getDepartmentsByParentId(Integer parentId) {
        List<Department> departments = departmentRepository.findByParentDepartmentId(parentId);
        return departments.stream()
                .map(this::convertToResponseDTO)
                .toList();
    }

    /**
     * 获取所有父科室
     * 
     * @return 父科室列表
     */
    @Transactional(readOnly = true)
    public List<ParentDepartment> getAllParentDepartments() {
        return parentDepartmentRepository.findAll();
    }

    /**
     * 获取科室树形结构数据（排除ID=999的未分配科室）
     * 
     * @return 树形结构的科室数据
     */
    @Transactional(readOnly = true)
    public List<DepartmentTreeDTO> getDepartmentTree() {
        // 1. 获取所有父科室（排除ID=999）
        List<ParentDepartment> parentDepartments = parentDepartmentRepository.findAll()
                .stream()
                .filter(parent -> !parent.getParentDepartmentId().equals(999))
                .toList();

        // 2. 获取所有子科室（排除ID=999）
        List<Department> allDepartments = departmentRepository.findAll()
                .stream()
                .filter(dept -> !dept.getDepartmentId().equals(999))
                .toList();

        // 3. 构建树形结构
        return parentDepartments.stream()
                .map(parent -> {
                    DepartmentTreeDTO parentNode = new DepartmentTreeDTO();
                    parentNode.setId(parent.getParentDepartmentId());
                    parentNode.setName(parent.getName());
                    parentNode.setType("parent");
                    parentNode.setDescription(parent.getDescription());
                    
                    // 添加子科室
                    List<DepartmentTreeDTO> children = allDepartments.stream()
                            .filter(dept -> dept.getParentDepartment().getParentDepartmentId().equals(parent.getParentDepartmentId()))
                            .map(this::convertToTreeDTO)
                            .toList();
                    parentNode.setChildren(children);
                    
                    return parentNode;
                })
                .toList();
    }

    /**
     * 根据科室ID获取该科室下的医生列表
     * 
     * @param departmentId 科室ID
     * @return 医生列表
     */
    @Transactional(readOnly = true)
    public List<DoctorResponse> getDoctorsByDepartmentId(Integer departmentId) {
        // 验证科室是否存在
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new RuntimeException("科室不存在: " + departmentId));

        // 获取该科室下的医生，排除已删除的医生
        List<Doctor> doctors = department.getDoctors().stream()
                .filter(doctor -> doctor.getStatus() != DoctorStatus.deleted)
                .toList();
        
        return doctors.stream()
                .map(this::convertToDoctorResponse)
                .toList();
    }

    /**
     * 将医生添加到指定科室
     * 
     * @param departmentId 科室ID
     * @param doctorData 医生信息
     * @return 添加后的医生信息
     */
    @Transactional
    public DoctorResponse addDoctorToDepartment(Integer departmentId, DoctorDataDTO doctorData) {
        // 1. 验证科室是否存在
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new RuntimeException("科室不存在: " + departmentId));

        // 2. 查找或创建医生
        Doctor doctor = doctorRepository.findByIdentifier(doctorData.getIdentifier())
                .orElse(new Doctor());

        // 3. 更新医生信息
        doctor.setIdentifier(doctorData.getIdentifier());
        doctor.setFullName(doctorData.getFullName());
        doctor.setTitle(doctorData.getTitle());
        doctor.setDepartment(department);
        
        // 设置默认值
        if (doctor.getPasswordHash() == null) {
            doctor.setPasswordHash("$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi"); // 默认密码
        }
        if (doctor.getStatus() == null) {
            doctor.setStatus(DoctorStatus.inactive);
        }

        // 4. 保存医生
        Doctor savedDoctor = doctorRepository.save(doctor);
        
        return convertToDoctorResponse(savedDoctor);
    }

    /**
     * 从科室中移除医生（将department_id设置为999）
     * 
     * @param departmentId 科室ID
     * @param doctorIdentifier 医生工号
     */
    @Transactional
    public void removeDoctorFromDepartment(Integer departmentId, String doctorIdentifier) {
        // 1. 查找医生
        Doctor doctor = doctorRepository.findByIdentifier(doctorIdentifier)
                .orElseThrow(() -> new RuntimeException("医生不存在: " + doctorIdentifier));

        // 2. 验证医生是否属于该科室
        if (doctor.getDepartment() == null || !doctor.getDepartment().getDepartmentId().equals(departmentId)) {
            throw new RuntimeException("医生不属于该科室");
        }

        // 3. 将医生移动到未分配科室（ID=999）
        Department unassignedDepartment = departmentRepository.findById(999)
                .orElseThrow(() -> new RuntimeException("未分配科室不存在，请先执行数据库初始化脚本"));
        
        doctor.setDepartment(unassignedDepartment);
        doctorRepository.save(doctor);
    }

    /**
     * 将 Department 实体转换为 DepartmentTreeDTO
     */
    private DepartmentTreeDTO convertToTreeDTO(Department department) {
        DepartmentTreeDTO dto = new DepartmentTreeDTO();
        dto.setId(department.getDepartmentId());
        dto.setName(department.getName());
        dto.setType("department");
        dto.setDescription(department.getDescription());
        dto.setParentId(department.getParentDepartment().getParentDepartmentId());
        return dto;
    }

    /**
     * 将 Doctor 实体转换为 DoctorResponse
     */
    private DoctorResponse convertToDoctorResponse(Doctor doctor) {
        DoctorResponse response = new DoctorResponse();
        response.setDoctorId(doctor.getDoctorId());
        response.setIdentifier(doctor.getIdentifier());
        response.setFullName(doctor.getFullName());
        response.setTitle(doctor.getTitle());
        response.setPhoneNumber(doctor.getPhoneNumber());
        response.setSpecialty(doctor.getSpecialty());
        response.setBio(doctor.getBio());
        response.setPhotoUrl(doctor.getPhotoUrl());
        response.setStatus(doctor.getStatus());
        
        // 设置科室信息
        if (doctor.getDepartment() != null) {
            DepartmentDTO deptDto = new DepartmentDTO();
            deptDto.setDepartmentId(doctor.getDepartment().getDepartmentId());
            deptDto.setName(doctor.getDepartment().getName());
            response.setDepartment(deptDto);
        }
        
        return response;
    }

    /**
     * 将 Department 实体转换为 DepartmentResponseDTO
     */
    private DepartmentResponseDTO convertToResponseDTO(Department department) {
        DepartmentResponseDTO dto = new DepartmentResponseDTO();
        dto.setDepartmentId(department.getDepartmentId());
        dto.setName(department.getName());
        dto.setDescription(department.getDescription());

        // 设置父科室信息
        ParentDepartment parent = department.getParentDepartment();
        if (parent != null) {
            dto.setParentDepartmentId(parent.getParentDepartmentId());
            dto.setParentDepartmentName(parent.getName());
        }

        return dto;
    }
}