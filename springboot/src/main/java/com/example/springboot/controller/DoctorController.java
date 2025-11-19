package com.example.springboot.controller;

import com.example.springboot.dto.appointment.PatientAppointmentDTO;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.Appointment;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.dto.doctor.DoctorChangePasswordRequest;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.dto.doctor.DoctorUpdateInfoRequest;
import com.example.springboot.entity.Doctor;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.service.DoctorService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import java.time.LocalDate;
import java.util.List;
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
     * @param doctorId 医生ID
     * @return 医生详细信息
     */
    @GetMapping("/{doctorId}")
    public ResponseEntity<?> getDoctorById(@PathVariable Integer doctorId) {
        try {
            var doctor = doctorService.findDoctorById(doctorId)
                    .orElseThrow(() -> new RuntimeException("医生不存在"));
            DoctorResponse response = doctorService.convertToResponseDto(doctor);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取医生信息时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
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
            doctorInfo.put("fullName", doctor.getFullName());
            doctorInfo.put("departmentName", doctor.getDepartment() != null ? doctor.getDepartment().getName() : null);
            doctorInfo.put("title", doctor.getTitle());
            doctorInfo.put("phoneNumber", doctor.getPhoneNumber());

            return new ResponseEntity<>(doctorInfo, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("获取医生信息时发生错误: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // DoctorController.java 中添加接口
    @PutMapping(value = "/info", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> updateDoctorInfo(
            @RequestParam("identifier") String identifier,
            @RequestParam(value = "phoneNumber", required = false) String phoneNumber,
            @RequestParam(value = "specialty", required = false) String specialty,
            @RequestParam(value = "bio", required = false) String bio,
            @RequestParam(value = "avatarFile", required = false) MultipartFile avatarFile) {

        try {
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

    // 在DoctorAuthController.java中添加以下接口
    /**
     * 医生修改密码接口
     * URL: POST /api/doctor/auth/change-password
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
}

