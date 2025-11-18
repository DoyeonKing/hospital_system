package com.example.springboot.controller;

import com.example.springboot.dto.appointment.AppointmentCreateRequest;
import com.example.springboot.dto.appointment.AppointmentResponse;
import com.example.springboot.dto.appointment.AppointmentUpdateRequest;
import com.example.springboot.service.AppointmentService;
import com.example.springboot.service.WaitlistService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;
    private final WaitlistService waitlistService;

    @Autowired
    public AppointmentController(AppointmentService appointmentService, WaitlistService waitlistService) {
        this.appointmentService = appointmentService;
        this.waitlistService = waitlistService;
    }

    /**
     * 获取患者的所有预约
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<AppointmentResponse>> getPatientAppointments(@PathVariable Long patientId) {
        return ResponseEntity.ok(appointmentService.findByPatientId(patientId));
    }

    /**
     * 获取指定医生的预约患者列表
     */
    @GetMapping("/doctor/{doctorId}")
    public ResponseEntity<List<AppointmentResponse>> getDoctorAppointments(@PathVariable Integer doctorId) {
        return ResponseEntity.ok(appointmentService.findByDoctorId(doctorId));
    }

    /**
     * 获取患者即将就诊的预约
     */
    @GetMapping("/patient/{patientId}/upcoming")
    public ResponseEntity<List<AppointmentResponse>> getUpcomingAppointments(@PathVariable Long patientId) {
        return ResponseEntity.ok(appointmentService.findUpcomingByPatientId(patientId));
    }

    /**
     * 创建预约
     */
    @PostMapping
    public ResponseEntity<AppointmentResponse> createAppointment(@RequestBody AppointmentCreateRequest request) {
        return ResponseEntity.ok(appointmentService.createAppointment(request));
    }

    /**
     * 取消预约
     */
    @PutMapping("/{appointmentId}/cancel")
    public ResponseEntity<AppointmentResponse> cancelAppointment(@PathVariable Integer appointmentId) {
        return ResponseEntity.ok(appointmentService.cancelAppointment(appointmentId));
    }

    /**
     * 获取预约详情
     */
    @GetMapping("/{appointmentId}")
    public ResponseEntity<AppointmentResponse> getAppointmentDetail(@PathVariable Integer appointmentId) {
        return ResponseEntity.ok(appointmentService.findAppointmentById(appointmentId));
    }

    /**
     * 更新预约支付状态
     */
    @PutMapping("/{appointmentId}")
    public ResponseEntity<AppointmentResponse> updateAppointmentPayment(
            @PathVariable Integer appointmentId,
            @RequestBody AppointmentUpdateRequest request) {
        return ResponseEntity.ok(appointmentService.updateAppointment(appointmentId, request));
    }

    /**
     * 支付挂号费用
     */
    @PostMapping("/{appointmentId}/pay")
    public ResponseEntity<AppointmentResponse> payForAppointment(
            @PathVariable Integer appointmentId,
            @RequestBody AppointmentUpdateRequest paymentData) {
        return ResponseEntity.ok(appointmentService.processPayment(appointmentId, paymentData));
    }
}