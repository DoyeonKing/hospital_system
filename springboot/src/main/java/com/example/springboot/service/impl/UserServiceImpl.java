package com.example.springboot.service.impl;

import com.example.springboot.dto.doctor.DoctorUpdateRequest;
import com.example.springboot.dto.patient.*;
import com.example.springboot.dto.user.UserUpdateRequest;
import com.example.springboot.entity.enums.PatientType;
import com.example.springboot.util.PasswordEncoderUtil;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.PageRequest;
import com.example.springboot.dto.admin.AdminCreateRequest;
import com.example.springboot.dto.admin.AdminResponse;
import com.example.springboot.dto.common.PageResponse;
import com.example.springboot.dto.doctor.DoctorCreateRequest;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.dto.patient.PatientCreateRequest;
import com.example.springboot.dto.patient.PatientResponse;
import com.example.springboot.dto.user.UserCreateRequest;
import com.example.springboot.dto.user.UserImportResponse;
import com.example.springboot.dto.user.UserResponse;
import com.example.springboot.entity.*;
import com.example.springboot.entity.enums.BlacklistStatus;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.*;
import com.example.springboot.service.AdminService;
import com.example.springboot.service.DoctorService;
import com.example.springboot.service.PatientService;
import com.example.springboot.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final PatientRepository patientRepository;
    private final DoctorRepository doctorRepository;
    private final AdminRepository adminRepository;
    private final ClinicRepository clinicRepository;
    private final DepartmentRepository departmentRepository;
    private final PatientProfileRepository patientProfileRepository;
    private final PatientService patientService;
    private final DoctorService doctorService;
    private final AdminService adminService;
    private final PasswordEncoderUtil passwordEncoderUtil;

    @Override
    @Transactional
    public UserResponse createUser(UserCreateRequest request) {
        // 统一账号唯一性校验
        validateIdentifierUniqueness(request.getId());

        // 根据角色创建不同用户
        return switch (request.getRole().toUpperCase()) {
            case "PATIENT" -> createPatientUser(request);
            case "DOCTOR" -> createDoctorUser(request);
            //case "ADMIN" -> createAdminUser(request);
            default -> throw new BadRequestException("不支持的用户角色: " + request.getRole());
        };
    }

    @Override
    @Transactional
    public UserImportResponse importUsers(List<UserCreateRequest> requests) {
        UserImportResponse response = new UserImportResponse();
        response.setTotal(requests.size());

        for (UserCreateRequest request : requests) {
            try {
                // 复用单个创建逻辑
                createUser(request);
                response.setSuccess(response.getSuccess() + 1);
            } catch (Exception e) {
                response.setFailed(response.getFailed() + 1);
                response.getErrorMessages().add(
                        String.format("账号[%s]创建失败: %s", request.getId(), e.getMessage())
                );
            }
        }

        return response;
    }

    private void validateIdentifierUniqueness(String identifier) {
        if (patientRepository.existsByIdentifier(identifier) ||
                doctorRepository.existsByIdentifier(identifier) ||
                adminRepository.existsByUsername(identifier)) {
            throw new BadRequestException("账号已存在: " + identifier);
        }
    }

    private UserResponse createPatientUser(UserCreateRequest request) {
        // 身份证号唯一性校验
        if (request.getId_card() != null &&
                patientProfileRepository.existsByIdCardNumber(request.getId_card())) {
            throw new BadRequestException("身份证号已存在: " + request.getId_card());
        }

        // 转换为患者创建请求
        PatientCreateRequest patientRequest = new PatientCreateRequest();
        patientRequest.setIdentifier(request.getId()); // id -> identifier
        patientRequest.setPassword(request.getPassword());
        patientRequest.setFullName(request.getName()); // name -> fullName
        patientRequest.setPhoneNumber(request.getPhone()); // phone -> phoneNumber
        patientRequest.setPatientType(request.getPatientType());
        patientRequest.setStatus(request.getPatientStatus());
        patientRequest.setIdCardNumber(request.getId_card()); // id_card -> idCardNumber
        patientRequest.setAllergies(request.getAllergy_history()); // allergy_history -> allergies
        patientRequest.setMedicalHistory(request.getPast_medical_history()); // past_medical_history -> medicalHistory

        // 创建患者(使用正确的转换逻辑)
        Patient patient = new Patient();
        patient.setIdentifier(request.getId());
        patient.setPasswordHash(request.getPassword());
        patient.setFullName(request.getName());
        patient.setPhoneNumber(request.getPhone());
        patient.setPatientType(request.getPatientType());
        patient.setStatus(request.getPatientStatus());

        Patient savedPatient = patientService.createPatient(patient);

        // 创建患者档案
        if (request.getId_card() != null) {
            PatientProfile profile = new PatientProfile();
            profile.setPatient(savedPatient);
            profile.setIdCardNumber(request.getId_card());
            profile.setAllergies(request.getAllergy_history());
            profile.setMedicalHistory(request.getPast_medical_history());
            profile.setBlacklistStatus(BlacklistStatus.normal);
            patientProfileRepository.save(profile);
        }

        UserResponse response = new UserResponse();
        response.setRole("PATIENT");
        response.setUserDetails(patientService.convertToResponseDto(savedPatient));
        return response;
    }

    private UserResponse createDoctorUser(UserCreateRequest request) {
        DoctorCreateRequest doctorRequest = new DoctorCreateRequest();
        doctorRequest.setClinicId(request.getClinicId());
        doctorRequest.setDepartmentId(request.getDepartmentId());
        doctorRequest.setIdentifier(request.getId()); // id -> identifier
        doctorRequest.setPassword(request.getPassword());
        doctorRequest.setFullName(request.getName()); // name -> fullName
        doctorRequest.setPhoneNumber(request.getPhone()); // phone -> phoneNumber
        doctorRequest.setTitle(request.getTitle());
        doctorRequest.setSpecialty(request.getSpecialty());
        doctorRequest.setBio(request.getBio());
        doctorRequest.setPhotoUrl(request.getPhotoUrl());
        doctorRequest.setStatus(request.getDoctorStatus());

        Clinic clinic = clinicRepository.findById(doctorRequest.getClinicId())
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id: " + doctorRequest.getClinicId()));
        Department department = departmentRepository.findById(doctorRequest.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with id: " + doctorRequest.getDepartmentId()));


        // 创建医生
        Doctor doctor = new Doctor();
        doctor.setClinic(clinic);          // 关键：设置诊所关联
        doctor.setDepartment(department);  // 关键：设置科室关联
        doctor.setIdentifier(doctorRequest.getIdentifier());
        doctor.setPasswordHash(doctorRequest.getPassword());
        doctor.setFullName(doctorRequest.getFullName());
        doctor.setPhoneNumber(doctorRequest.getPhoneNumber());
        doctor.setTitle(doctorRequest.getTitle());
        doctor.setSpecialty(doctorRequest.getSpecialty());
        doctor.setBio(doctorRequest.getBio());
        doctor.setPhotoUrl(doctorRequest.getPhotoUrl());
        doctor.setStatus(doctorRequest.getStatus());

        Doctor savedDoctor = doctorService.createDoctor(doctor);

        UserResponse response = new UserResponse();
        response.setRole("DOCTOR");
        response.setUserDetails(doctorService.convertToResponseDto(savedDoctor));
        return response;
    }

//    private UserResponse createAdminUser(UserCreateRequest request) {
//        AdminCreateRequest adminRequest = new AdminCreateRequest();
//        adminRequest.setUsername(request.getIdentifier());
//        adminRequest.setPassword(request.getPassword());
//        adminRequest.setFullName(request.getFullName());
//        adminRequest.setStatus(request.getAdminStatus());
//        adminRequest.setRoleIds(request.getRoleIds());
//
//        AdminResponse savedAdmin = adminService.createAdmin(adminRequest);
//
//        UserResponse response = new UserResponse();
//        response.setRole("ADMIN");
//        response.setUserDetails(savedAdmin);
//        return response;
//    }

    // 实现搜索方法
    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> searchUsers(String id, String name, int page, int pageSize) {
        // 构建分页参数 (注意页码从0开始，前端传1时需要减1)
        Pageable pageable = PageRequest.of(page - 1, pageSize);

        // 1. 查询患者
        Page<Patient> patientPage = patientRepository.findAll((Specification<Patient>) (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (id != null && !id.isEmpty()) {
                predicates.add(cb.like(root.get("identifier"), "%" + id + "%"));
            }
            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(root.get("fullName"), "%" + name + "%"));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        }, pageable);

        // 2. 查询医生
        Page<Doctor> doctorPage = doctorRepository.findAll((Specification<Doctor>) (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (id != null && !id.isEmpty()) {
                predicates.add(cb.like(root.get("identifier"), "%" + id + "%"));
            }
            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(root.get("fullName"), "%" + name + "%"));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        }, pageable);

        // 3. 查询管理员
        Page<Admin> adminPage = adminRepository.findAll((Specification<Admin>) (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (id != null && !id.isEmpty()) {
                predicates.add(cb.like(root.get("username"), "%" + id + "%"));
            }
            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(root.get("fullName"), "%" + name + "%"));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        }, pageable);

        // 4. 合并结果并转换为UserResponse
        List<UserResponse> userResponses = new ArrayList<>();

        // 添加患者
        userResponses.addAll(patientPage.getContent().stream()
                .map(patient -> {
                    UserResponse response = new UserResponse();
                    response.setRole("PATIENT");
                    response.setUserDetails(patientService.convertToResponseDto(patient));
                    return response;
                })
                .collect(Collectors.toList()));

        // 添加医生
        userResponses.addAll(doctorPage.getContent().stream()
                .map(doctor -> {
                    UserResponse response = new UserResponse();
                    response.setRole("DOCTOR");
                    response.setUserDetails(doctorService.convertToResponseDto(doctor));
                    return response;
                })
                .collect(Collectors.toList()));

        // 添加管理员
        userResponses.addAll(adminPage.getContent().stream()
                .map(admin -> {
                    UserResponse response = new UserResponse();
                    response.setRole("ADMIN");
                    response.setUserDetails(adminService.convertToResponseDto(admin));
                    return response;
                })
                .collect(Collectors.toList()));

        // 计算总条数
        long totalElements = patientPage.getTotalElements() + doctorPage.getTotalElements() + adminPage.getTotalElements();
        // 计算总页数
        int totalPages = (int) Math.ceil((double) totalElements / pageSize);

        return new PageResponse<>(
                userResponses,
                totalElements,
                totalPages,
                page,
                pageSize
        );
    }
}