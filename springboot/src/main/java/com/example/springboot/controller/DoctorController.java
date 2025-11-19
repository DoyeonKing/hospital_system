package com.example.springboot.controller;

import com.example.springboot.dto.appointment.PatientAppointmentDTO;
import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.Appointment;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.service.DoctorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
        }
    }
}

