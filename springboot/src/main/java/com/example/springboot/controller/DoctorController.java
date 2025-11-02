package com.example.springboot.controller;

import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.service.DoctorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    @Autowired
    private DoctorService doctorService;

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
}

