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
    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> searchDoctors(String id, String name, int page, int pageSize) {
        // 构建分页参数 (页码从0开始)
        Pageable pageable = PageRequest.of(page - 1, pageSize);

        // 查询医生
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

        // 转换为UserResponse列表
        List<UserResponse> userResponses = doctorPage.getContent().stream()
                .map(doctor -> {
                    UserResponse response = new UserResponse();
                    response.setRole("DOCTOR");
                    response.setUserDetails(doctorService.convertToResponseDto(doctor));
                    return response;
                })
                .collect(Collectors.toList());

        // 构建分页响应（关键修改处）
        return new PageResponse<>(
                userResponses,
                doctorPage.getTotalElements(),
                doctorPage.getTotalPages(),
                page,
                pageSize
        );
    }

    @Override
    @Transactional
    public UserResponse updateUser(Long patient_id, Integer doctor_id, UserUpdateRequest request) {  // 参数类型改为Integer
        // 根据角色更新不同类型的用户
        return switch (request.getRole().toUpperCase()) {
            case "PATIENT" -> updatePatientUser(patient_id, request.getPatientUpdateRequest());
            case "DOCTOR" -> updateDoctorUser(doctor_id, request.getDoctorUpdateRequest());
            default -> throw new BadRequestException("不支持的用户角色: " + request.getRole());
        };
    }

    // 修改患者更新方法
    private UserResponse updatePatientUser(Long patientId, PatientUpdateRequest request) {
        // 查找患者（使用ID而非identifier）
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("患者不存在: " + patientId));

        // 更新患者信息
        if (request.getIdentifier() != null) {
            patient.setIdentifier(request.getIdentifier());
        }
        if (request.getPatientType() != null) {
            patient.setPatientType(request.getPatientType());
        }
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            patient.setPasswordHash(passwordEncoderUtil.encodePassword(request.getPassword()));
        }
        if (request.getFullName() != null) {
            patient.setFullName(request.getFullName());
        }
        if (request.getPhoneNumber() != null) {
            patient.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getStatus() != null) {
            patient.setStatus(request.getStatus());
        }

        Patient updatedPatient = patientRepository.save(patient);

        // 更新患者档案
        if (request.getIdCardNumber() != null || request.getAllergies() != null || request.getMedicalHistory() != null) {
            PatientProfile profile = patientProfileRepository.findById(patientId)
                    .orElse(new PatientProfile());

            profile.setPatient(updatedPatient);
            if (request.getIdCardNumber() != null) {
                profile.setIdCardNumber(request.getIdCardNumber());
            }
            if (request.getAllergies() != null) {
                profile.setAllergies(request.getAllergies());
            }
            if (request.getMedicalHistory() != null) {
                profile.setMedicalHistory(request.getMedicalHistory());
            }

            patientProfileRepository.save(profile);
        }

        UserResponse response = new UserResponse();
        response.setRole("PATIENT");
        response.setUserDetails(patientService.convertToResponseDto(updatedPatient));
        return response;
    }

    // 修改医生更新方法
    private UserResponse updateDoctorUser(Integer doctorId, DoctorUpdateRequest request) {
        // 查找医生（使用ID而非identifier）
        Doctor doctor = doctorRepository.findById(doctorId)
                .orElseThrow(() -> new ResourceNotFoundException("医生不存在: " + doctorId));

        // 处理诊所关联更新
        if (request.getClinicId() != null) {
            Clinic clinic = clinicRepository.findById(request.getClinicId())
                    .orElseThrow(() -> new ResourceNotFoundException("诊所不存在: " + request.getClinicId()));
            doctor.setClinic(clinic);
        }

        // 处理科室关联更新
        if (request.getDepartmentId() != null) {
            Department department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("科室不存在: " + request.getDepartmentId()));
            doctor.setDepartment(department);
        }

        // 更新医生基本信息
        if (request.getIdentifier() != null) {
            doctor.setIdentifier(request.getIdentifier());
        }
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            doctor.setPasswordHash(passwordEncoderUtil.encodePassword(request.getPassword()));
        }
        if (request.getFullName() != null) {
            doctor.setFullName(request.getFullName());
        }
        if (request.getPhoneNumber() != null) {
            doctor.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getTitle() != null) {
            doctor.setTitle(request.getTitle());
        }
        if (request.getSpecialty() != null) {
            doctor.setSpecialty(request.getSpecialty());
        }
        if (request.getBio() != null) {
            doctor.setBio(request.getBio());
        }
        if (request.getPhotoUrl() != null) {
            doctor.setPhotoUrl(request.getPhotoUrl());
        }
        if (request.getStatus() != null) {
            doctor.setStatus(request.getStatus());
        }

        Doctor updatedDoctor = doctorRepository.save(doctor);

        UserResponse response = new UserResponse();
        response.setRole("DOCTOR");
        response.setUserDetails(doctorService.convertToResponseDto(updatedDoctor));
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<MedicalHistoryResponse> getMedicalHistories(Integer page, Integer pageSize) {
        // 强制每页10条数据，忽略传入的pageSize
        int fixedPageSize = 10;
        // 处理页码（默认第一页）
        int actualPage = (page == null || page < 1) ? 0 : page - 1;

        Pageable pageable = PageRequest.of(actualPage, fixedPageSize);

        // 查询患者档案数据（假设通过patientProfileRepository查询）
        Page<PatientProfile> profilePage = patientProfileRepository.findAll(pageable);

        Page<Patient> patientPage = patientRepository.findAll(pageable);


        // 转换为MedicalHistoryResponse并排除isBlacklisted字段
        // 转换为病史响应DTO列表
        List<MedicalHistoryResponse> content = patientPage.getContent().stream()
                .map(patient -> {
                    MedicalHistoryResponse response = new MedicalHistoryResponse();
                    response.setId(patient.getPatientId());
                    response.setName(patient.getFullName());

                    // 获取患者档案信息
                    PatientProfile profile = patientProfileRepository.findById(patient.getPatientId()).orElse(null);
                    if (profile != null) {
                        response.setIdCard(profile.getIdCardNumber());
                        response.setAllergyHistory(profile.getAllergies());
                        response.setPastMedicalHistory(profile.getMedicalHistory());
                        response.setBlacklisted(profile.getBlacklistStatus() == BlacklistStatus.BLACKLISTED);
                    }

                    return response;
                })
                .collect(Collectors.toList());

        return new PageResponse<>(
                content,
                profilePage.getTotalElements(),
                profilePage.getTotalPages(),
                actualPage + 1,  // 转换为前端需要的页码（从1开始）
                fixedPageSize
        );
    }

    @Override
    @Transactional
    public PageResponse<MedicalHistoryResponse> updateMedicalHistory(Long id, MedicalHistoryUpdateRequest request) {
        // 查找患者信息（根据id查找）
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("用户不存在: " + id));

        // 查找或创建患者档案
        PatientProfile profile = patientProfileRepository.findByPatient(patient)
                .orElse(new PatientProfile());

        // 更新字段
        if (request.getAllergyHistory() != null) {
            profile.setAllergies(request.getAllergyHistory());
        }
        if (request.getPastMedicalHistory() != null) {
            profile.setMedicalHistory(request.getPastMedicalHistory());
        }
        if (request.getBlacklistStatus() != null) {
            profile.setBlacklistStatus(request.getBlacklistStatus());
        }

        // 设置关联并保存
        profile.setPatient(patient);
        patientProfileRepository.save(profile);

        // 构建返回结果
        MedicalHistoryResponse response = new MedicalHistoryResponse();
        response.setId(patient.getPatientId());
        response.setIdCard(profile.getIdCardNumber());
        response.setName(patient.getFullName());
        response.setAllergyHistory(profile.getAllergies());
        response.setPastMedicalHistory(profile.getMedicalHistory());
        response.setBlacklisted(BlacklistStatus.BLACKLISTED.equals(profile.getBlacklistStatus()));

        // 包装成分页响应（虽然这里只有一条记录）
        List<MedicalHistoryResponse> content = Collections.singletonList(response);
        return new PageResponse<>(content, 1, 1, 1, 10);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponse> searchPatients(String id, String name, int page, int pageSize) {
        // 强制设置患者分页大小为10
        pageSize = 10;

        // 构建分页参数 (页码从0开始)
        Pageable pageable = PageRequest.of(page - 1, pageSize);

        // 查询患者
        Page<Patient> patientPage = patientRepository.findAll((Specification<Patient>) (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            // 补充查询条件...
            if (id != null && !id.isEmpty()) {
                predicates.add(cb.like(root.get("identifier"), "%" + id + "%"));
            }
            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(root.get("fullName"), "%" + name + "%"));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        }, pageable);

        // 转换为UserResponse列表
        List<UserResponse> userResponses = patientPage.getContent().stream()
                .map(patient -> {
                    UserResponse response = new UserResponse();
                    response.setRole("PATIENT");
                    response.setUserDetails(patientService.convertToResponseDto(patient));
                    return response;
                })
                .collect(Collectors.toList());

        // 构建分页响应（关键修改处）
        return new PageResponse<>(
                userResponses,
                patientPage.getTotalElements(),
                patientPage.getTotalPages(),
                page,
                pageSize
        );
    }
}