package com.example.springboot.controller;

import com.example.springboot.dto.appointment.PatientAppointmentDTO;
import com.example.springboot.dto.doctor.DoctorChangePasswordRequest;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.dto.doctor.DoctorUpdateInfoRequest;
import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Doctor;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.service.DoctorService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    @Autowired
    private DoctorService doctorService;

    @Autowired
    private AppointmentRepository appointmentRepository;

    /**
     * 获取单个医生详细信息
     * 使用 GET /api/doctors/{doctorId}
     *
     * 权限控制：
     * - 医生只能查看自己的完整信息（包括手机号等敏感信息）
     * - 其他角色只能查看公开信息（姓名、科室、职称、擅长、简介、头像）
     *
     * @param doctorId 医生ID
     * @return 医生详细信息
     */
    @GetMapping("/{doctorId}")
    public ResponseEntity<?> getDoctorById(@PathVariable Integer doctorId) {
        try {
            // 获取当前登录用户信息
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String currentUserIdentifier = authentication.getName();
            boolean hasAdminRole = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));

            // 查找目标医生
            var doctor = doctorService.findDoctorById(doctorId)
                    .orElseThrow(() -> new ResourceNotFoundException("资源不存在"));

            // 检查是否是医生本人或管理员
            boolean isSelf = doctor.getIdentifier().equals(currentUserIdentifier);

            DoctorResponse response;
            if (isSelf || hasAdminRole) {
                // 医生本人或管理员：返回完整信息
                response = doctorService.convertToResponseDto(doctor);
            } else {
                // 其他人：只返回公开信息
                response = doctorService.convertToResponseDto(doctor);
                // 清除敏感信息
                response.setPhoneNumber(null);
            }

            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (ResourceNotFoundException e) {
            // 资源不存在，返回404
            throw e;  // 让GlobalExceptionHandler处理
        } catch (Exception e) {
            // 记录详细错误到日志，但只返回通用错误信息
            System.err.println("获取医生信息时发生错误: " + e.getMessage());
            e.printStackTrace();
            return new ResponseEntity<>("获取医生信息失败", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 获取医生指定日期的患者列表
     * 使用 GET /api/doctor/todays-appointments
     *
     * @param doctorId 医生ID (从请求参数获取)
     * @param date 日期 (YYYY-MM-DD格式)
     * @return 患者预约列表
     */
    @GetMapping("/todays-appointments")
    public ResponseEntity<?> getTodaysAppointments(
            @RequestParam Integer doctorId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        try {
            System.out.println("=== 获取医生患者列表 ===");
            System.out.println("doctorId: " + doctorId);
            System.out.println("date: " + date);
            
            // 查询预约列表
            List<Appointment> appointments = appointmentRepository.findByDoctorIdAndDate(doctorId, date);
            
            System.out.println("查询到 " + appointments.size() + " 条预约记录");
            
            // 转换为DTO
            List<PatientAppointmentDTO> result = appointments.stream()
                    .map(PatientAppointmentDTO::fromEntity)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            System.err.println("获取患者列表时发生错误: " + e.getMessage());
            e.printStackTrace();
            return new ResponseEntity<>("获取患者列表时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 通过医生工号获取医生信息
     * 使用 GET /api/doctors/identifier/{identifier}
     *
     * @param identifier 医生工号
     * @return 医生的姓名、所属科室、职称、手机号信息
     */
    @GetMapping("/identifier/{identifier}")
    public ResponseEntity<?> getDoctorByIdentifier(@PathVariable String identifier) {
        try {
            // 查找医生信息，不存在则抛出异常
            Doctor doctor = doctorService.findByIdentifier(identifier)
                    .orElseThrow(() -> new RuntimeException("医生不存在"));

            // 构建响应数据
            Map<String, Object> doctorInfo = new HashMap<>();
            doctorInfo.put("doctorId", doctor.getDoctorId()); // 建议加上ID，前端可能需要
            doctorInfo.put("fullName", doctor.getFullName());
            doctorInfo.put("departmentName", doctor.getDepartment() != null ? doctor.getDepartment().getName() : null);
            doctorInfo.put("title", doctor.getTitle());
            doctorInfo.put("phoneNumber", doctor.getPhoneNumber());
            // 补充前端可能需要的其他字段
            doctorInfo.put("specialty", doctor.getSpecialty());
            doctorInfo.put("bio", doctor.getBio());
            doctorInfo.put("photoUrl", doctor.getPhotoUrl());

            return new ResponseEntity<>(doctorInfo, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取医生信息时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * 更新医生信息 (包含头像上传)
     * 使用 PUT /api/doctors/info
     * 
     * 权限控制：医生只能修改自己的信息
     */
    @PutMapping(value = "/info", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> updateDoctorInfo(
            @RequestParam("identifier") String identifier,
            @RequestParam(value = "phoneNumber", required = false) String phoneNumber,
            @RequestParam(value = "specialty", required = false) String specialty,
            @RequestParam(value = "bio", required = false) String bio,
            @RequestParam(value = "avatarFile", required = false) MultipartFile avatarFile) {

        try {
            // 获取当前登录用户
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String currentUserIdentifier = authentication.getName();
            boolean isAdmin = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
            
            // 权限验证：只能修改自己的信息（管理员除外）
            if (!isAdmin && !currentUserIdentifier.equals(identifier)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "无权修改其他医生的信息"));
            }
            
            // 创建请求对象
            DoctorUpdateInfoRequest request = new DoctorUpdateInfoRequest();
            request.setIdentifier(identifier);
            request.setPhoneNumber(phoneNumber);
            request.setSpecialty(specialty);
            request.setBio(bio);
            request.setAvatarFile(avatarFile);

            DoctorResponse response = doctorService.updateDoctorInfo(request);
            return ResponseEntity.ok(response);

        } catch (ResourceNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "头像上传失败: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "更新医生信息失败: " + e.getMessage()));
        }
    }

    /**
     * 医生修改密码接口
     * URL: POST /api/doctors/change-password
     */
    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@Valid @RequestBody DoctorChangePasswordRequest request) {
        try {
            doctorService.changePassword(request);
            return ResponseEntity.ok().body("{\"message\": \"密码修改成功\"}");
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.badRequest().body("{\"error\": \"" + e.getMessage() + "\"}");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("{\"error\": \"" + e.getMessage() + "\"}");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("{\"error\": \"服务器内部错误，密码修改失败\"}");
        }
    }

    /**
     * 获取医生在指定时间段的排班和请假信息
     * 用于替班医生选择时的悬停显示
     * 
     * @param doctorId 医生ID
     * @param startDate 开始日期
     * @param endDate 结束日期
     * @return 医生的排班和请假信息
     */
    @GetMapping("/{doctorId}/schedule-and-leave")
    public ResponseEntity<?> getDoctorScheduleAndLeave(
            @PathVariable Integer doctorId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        try {
            Map<String, Object> result = doctorService.getDoctorScheduleAndLeave(doctorId, startDate, endDate);
            return ResponseEntity.ok(result);
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "获取医生信息失败: " + e.getMessage()));
        }
    }
    
    /**
     * 根据患者姓名查询该患者在本科室的所有就诊记录
     * 使用 GET /api/doctors/patient-history
     * 
     * @param doctorId 医生ID (用于获取科室信息)
     * @param patientName 患者姓名
     * @return 患者在该科室的就诊记录列表
     */
    @GetMapping("/patient-history")
    public ResponseEntity<?> getPatientHistoryByName(
            @RequestParam Integer doctorId,
            @RequestParam String patientName) {
        try {
            System.out.println("=== 查询患者就诊记录 ===");
            System.out.println("doctorId: " + doctorId);
            System.out.println("patientName: " + patientName);
            
            // 获取医生信息以获取科室ID
            Doctor doctor = doctorService.findDoctorById(doctorId)
                    .orElseThrow(() -> new ResourceNotFoundException("医生不存在"));
            
            Integer departmentId = doctor.getDepartment().getDepartmentId();
            System.out.println("departmentId: " + departmentId);
            
            // 查询该患者在该科室的所有就诊记录
            List<Appointment> appointments = appointmentRepository.findByPatientNameAndDepartment(
                    patientName, departmentId);
            
            System.out.println("查询到 " + appointments.size() + " 条就诊记录");
            
            // 转换为DTO
            List<PatientAppointmentDTO> result = appointments.stream()
                    .map(PatientAppointmentDTO::fromEntity)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (ResourceNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            System.err.println("查询患者就诊记录时发生错误: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "查询患者就诊记录失败: " + e.getMessage()));
        }
    }
}