package com.example.springboot.service;

import com.example.springboot.dto.department.DepartmentCreateRequest;
import com.example.springboot.dto.department.DepartmentResponse;
import com.example.springboot.dto.department.DepartmentUpdateRequest;
import com.example.springboot.entity.Clinic;
import com.example.springboot.entity.Department;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.ClinicRepository;
import com.example.springboot.repository.DepartmentRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class DepartmentService {

    private final DepartmentRepository departmentRepository;
    private final ClinicRepository clinicRepository;
    private final ClinicService clinicService; // 注入 ClinicService 以便转换 Clinic 为 DTO

    @Autowired
    public DepartmentService(DepartmentRepository departmentRepository,
                             ClinicRepository clinicRepository,
                             ClinicService clinicService) {
        this.departmentRepository = departmentRepository;
        this.clinicRepository = clinicRepository;
        this.clinicService = clinicService;
    }

    @Transactional(readOnly = true)
    public List<DepartmentResponse> findAllDepartments() {
        return departmentRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DepartmentResponse findDepartmentById(Integer id) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id " + id));
        return convertToResponseDto(department);
    }

    @Transactional(readOnly = true)
    public List<DepartmentResponse> findDepartmentsByClinic(Integer clinicId) {
        Clinic clinic = clinicRepository.findById(clinicId)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + clinicId));
        return departmentRepository.findByClinic(clinic).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DepartmentResponse> findDepartmentsByClinicHierarchy(Integer clinicId) {
        Clinic clinic = clinicRepository.findById(clinicId)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + clinicId));

        List<Department> topLevelDepartments = departmentRepository.findByParentDepartmentIsNullAndClinic(clinic);

        return topLevelDepartments.stream()
                .map(this::convertToHierarchyResponseDto)
                .sorted(Comparator.comparing(DepartmentResponse::getName)) // 按名称排序
                .collect(Collectors.toList());
    }


    @Transactional
    public DepartmentResponse createDepartment(DepartmentCreateRequest request) {
        Clinic clinic = clinicRepository.findById(request.getClinicId())
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + request.getClinicId()));

        if (departmentRepository.findByClinicAndName(clinic, request.getName()).isPresent()) {
            throw new BadRequestException("Department with name '" + request.getName() + "' already exists in this clinic.");
        }

        Department department = new Department();
        BeanUtils.copyProperties(request, department, "clinicId", "parentId");
        department.setClinic(clinic);

        if (request.getParentId() != null) {
            Department parentDepartment = departmentRepository.findById(request.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent Department not found with id " + request.getParentId()));
            if (!parentDepartment.getClinic().equals(clinic)) {
                throw new BadRequestException("Parent department must belong to the same clinic.");
            }
            department.setParentDepartment(parentDepartment);
        }

        return convertToResponseDto(departmentRepository.save(department));
    }

    @Transactional
    public DepartmentResponse updateDepartment(Integer id, DepartmentUpdateRequest request) {
        Department existingDepartment = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id " + id));

        Clinic clinic = null;
        if (request.getClinicId() != null) {
            clinic = clinicRepository.findById(request.getClinicId())
                    .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + request.getClinicId()));
            existingDepartment.setClinic(clinic);
        } else {
            clinic = existingDepartment.getClinic(); // 使用现有诊所进行名称唯一性检查
        }

        if (request.getName() != null && !request.getName().equals(existingDepartment.getName())) {
            if (departmentRepository.findByClinicAndName(clinic, request.getName()).isPresent()) {
                throw new BadRequestException("Department with name '" + request.getName() + "' already exists in this clinic.");
            }
            existingDepartment.setName(request.getName());
        }

        if (request.getDescription() != null) existingDepartment.setDescription(request.getDescription());

        if (request.getParentId() != null) {
            Department parentDepartment = departmentRepository.findById(request.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent Department not found with id " + request.getParentId()));
            if (!parentDepartment.getClinic().equals(existingDepartment.getClinic())) {
                throw new BadRequestException("Parent department must belong to the same clinic.");
            }
            // 避免循环引用
            if (parentDepartment.getDepartmentId().equals(existingDepartment.getDepartmentId())) {
                throw new BadRequestException("A department cannot be its own parent.");
            }
            // 检查是否将自己设置为子部门的父部门
            if (isAncestorOf(existingDepartment, parentDepartment)) {
                throw new BadRequestException("Cannot set a descendant department as parent.");
            }
            existingDepartment.setParentDepartment(parentDepartment);
        } else if (request.getParentId() != null && request.getParentId() == 0) { // 如果传入 0 或其他约定值表示解除父子关系
            existingDepartment.setParentDepartment(null);
        }

        return convertToResponseDto(departmentRepository.save(existingDepartment));
    }

    @Transactional
    public void deleteDepartment(Integer id) {
        if (!departmentRepository.existsById(id)) {
            throw new ResourceNotFoundException("Department not found with id " + id);
        }
        // TODO: Consider business logic for deleting departments with associated doctors or child departments.
        // For now, let's allow it but in a real app, it would be restricted or require cascading deletion.
        departmentRepository.deleteById(id);
    }

    // Helper method to convert Entity to Response DTO
    public DepartmentResponse convertToResponseDto(Department department) {
        DepartmentResponse response = new DepartmentResponse();
        BeanUtils.copyProperties(department, response, "clinic", "parentDepartment", "childrenDepartments");
        response.setClinic(clinicService.convertToResponseDto(department.getClinic()));
        if (department.getParentDepartment() != null) {
            response.setParentId(department.getParentDepartment().getDepartmentId());
        }
        return response;
    }

    // Helper method to convert Entity to Hierarchy Response DTO (with nested children)
    private DepartmentResponse convertToHierarchyResponseDto(Department department) {
        DepartmentResponse response = new DepartmentResponse();
        BeanUtils.copyProperties(department, response, "clinic", "parentDepartment", "childrenDepartments");
        response.setClinic(clinicService.convertToResponseDto(department.getClinic()));
        if (department.getParentDepartment() != null) {
            response.setParentId(department.getParentDepartment().getDepartmentId());
        }

        Set<Department> children = department.getChildrenDepartments();
        if (children != null && !children.isEmpty()) {
            response.setChildrenDepartments(
                    children.stream()
                            .map(this::convertToHierarchyResponseDto) // 递归调用
                            .sorted(Comparator.comparing(DepartmentResponse::getName))
                            .collect(Collectors.toList())
            );
        } else {
            response.setChildrenDepartments(List.of());
        }
        return response;
    }

    // 检查 targetDepartment 是否是 sourceDepartment 的祖先
    private boolean isAncestorOf(Department sourceDepartment, Department targetDepartment) {
        Department current = targetDepartment.getParentDepartment();
        while (current != null) {
            if (current.equals(sourceDepartment)) {
                return true;
            }
            current = current.getParentDepartment();
        }
        return false;
    }
}
