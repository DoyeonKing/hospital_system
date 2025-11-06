package com.example.springboot.service;

import com.example.springboot.common.Constants;
import com.example.springboot.dto.appointment.AppointmentCreateRequest;
import com.example.springboot.dto.appointment.AppointmentResponse;
import com.example.springboot.dto.appointment.AppointmentUpdateRequest;
import com.example.springboot.dto.schedule.ScheduleResponse;
import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.enums.*;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.repository.ScheduleRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final ScheduleRepository scheduleRepository;
    private final PatientService patientService; // For updating patient profile (no-show count)
    private final DoctorService doctorService; // To get Doctor details for response
    private final DepartmentService departmentService; // To get Department details for response
    private final TimeSlotService timeSlotService; // To get TimeSlot details for response
    private final ScheduleService scheduleService;


    @Autowired
    public AppointmentService(AppointmentRepository appointmentRepository,
                              PatientRepository patientRepository,
                              ScheduleRepository scheduleRepository,
                              PatientService patientService,
                              DoctorService doctorService,
                              DepartmentService departmentService,
                              TimeSlotService timeSlotService,
                              ScheduleService scheduleService) {
        this.appointmentRepository = appointmentRepository;
        this.patientRepository = patientRepository;
        this.scheduleRepository = scheduleRepository;
        this.patientService = patientService;
        this.doctorService = doctorService;
        this.departmentService = departmentService;
        this.timeSlotService = timeSlotService;
        this.scheduleService = scheduleService;
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponse> findAllAppointments() {
        return appointmentRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AppointmentResponse findAppointmentById(Integer id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id " + id));
        return convertToResponseDto(appointment);
    }

    @Transactional
    public AppointmentResponse createAppointment(AppointmentCreateRequest request) {
        Patient patient = patientRepository.findById(request.getPatientId())
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + request.getPatientId()));

        // Check patient status
        if (patient.getStatus() == PatientStatus.deleted) {
            throw new BadRequestException("患者已删除，无法创建预约");
        }

        // Check patient blacklist status
        if (patient.getPatientProfile() != null && patient.getPatientProfile().getBlacklistStatus() == BlacklistStatus.blacklisted) {
            throw new BadRequestException("Patient is blacklisted and cannot make appointments.");
        }

        Schedule schedule = scheduleRepository.findById(request.getScheduleId())
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + request.getScheduleId()));

        if (schedule.getStatus() != ScheduleStatus.available) {
            throw new BadRequestException("Schedule is not active for booking.");
        }
        if (schedule.getBookedSlots() >= schedule.getTotalSlots()) {
            throw new BadRequestException("No available slots for this schedule.");
        }
        if (schedule.getScheduleDate().isBefore(java.time.LocalDate.now()) ||
                (schedule.getScheduleDate().isEqual(java.time.LocalDate.now()) && schedule.getSlot().getEndTime().isBefore(java.time.LocalTime.now()))) {
            throw new BadRequestException("Cannot book past or ongoing schedules.");
        }

        // Check if patient already has an active appointment for this schedule
        if (appointmentRepository.existsByPatientAndSchedule(patient, schedule)) {
            throw new BadRequestException("Patient already has an appointment for this schedule.");
        }

        Appointment appointment = new Appointment();
        appointment.setPatient(patient);
        appointment.setSchedule(schedule);
        appointment.setAppointmentNumber(schedule.getBookedSlots() + 1); // 自动分配就诊序号
        appointment.setStatus(AppointmentStatus.scheduled); // 初始状态为待支付
        appointment.setPaymentStatus(PaymentStatus.unpaid);
        appointment.setCreatedAt(LocalDateTime.now());

        // 增加排班的已预约数
        schedule.setBookedSlots(schedule.getBookedSlots() + 1);
        scheduleRepository.save(schedule); // 保存更新后的排班信息

        return convertToResponseDto(appointmentRepository.save(appointment));
    }

    @Transactional
    public AppointmentResponse updateAppointment(Integer id, AppointmentUpdateRequest request) {
        Appointment existingAppointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id " + id));

        // Update fields if provided in request
        if (request.getAppointmentNumber() != null) existingAppointment.setAppointmentNumber(request.getAppointmentNumber());
        if (request.getStatus() != null) {
            // Handle specific status transitions and logic
            if (request.getStatus() == AppointmentStatus.cancelled && existingAppointment.getStatus() != AppointmentStatus.cancelled) {
                // 如果是取消预约，需要减少排班的已预约数
                Schedule schedule = existingAppointment.getSchedule();
                if (schedule.getBookedSlots() > 0) {
                    schedule.setBookedSlots(schedule.getBookedSlots() - 1);
                    scheduleRepository.save(schedule);
                }
            } else if (request.getStatus() == AppointmentStatus.NO_SHOW && existingAppointment.getStatus() != AppointmentStatus.NO_SHOW) {
                // 如果是爽约，增加患者爽约次数并检查是否加入黑名单
                Patient patient = existingAppointment.getPatient();
                if (patient.getPatientProfile() != null) {
                    patient.getPatientProfile().setNoShowCount(patient.getPatientProfile().getNoShowCount() + 1);
                    if (patient.getPatientProfile().getNoShowCount() >= Constants.MAX_NO_SHOW_COUNT) {
                        patient.getPatientProfile().setBlacklistStatus(BlacklistStatus.blacklisted);
                    }
                    patientService.savePatientProfile(patient.getPatientProfile()); // 更新患者档案
                }
                // 爽约也应减少号源
                Schedule schedule = existingAppointment.getSchedule();
                if (schedule.getBookedSlots() > 0) {
                    schedule.setBookedSlots(schedule.getBookedSlots() - 1);
                    scheduleRepository.save(schedule);
                }
            }
            existingAppointment.setStatus(request.getStatus());
        }
        if (request.getPaymentStatus() != null) existingAppointment.setPaymentStatus(request.getPaymentStatus());
        if (request.getPaymentMethod() != null) existingAppointment.setPaymentMethod(request.getPaymentMethod());
        if (request.getTransactionId() != null) existingAppointment.setTransactionId(request.getTransactionId());
        if (request.getCheckInTime() != null) existingAppointment.setCheckInTime(request.getCheckInTime());

        return convertToResponseDto(appointmentRepository.save(existingAppointment));
    }

    @Transactional
    public void deleteAppointment(Integer id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id " + id));

        // 删除预约时，应减少对应排班的已预约数
        Schedule schedule = appointment.getSchedule();
        if (schedule.getBookedSlots() > 0) {
            schedule.setBookedSlots(schedule.getBookedSlots() - 1);
            scheduleRepository.save(schedule);
        }
        appointmentRepository.delete(appointment);
    }

    private AppointmentResponse convertToResponseDto(Appointment appointment) {
        AppointmentResponse response = new AppointmentResponse();
        BeanUtils.copyProperties(appointment, response);

        response.setPatient(patientService.convertToResponseDto(appointment.getPatient()));

        // ScheduleResponse 包含 Doctor, TimeSlot, Clinic, Department 信息
        response.setSchedule(ScheduleResponse.fromEntity(appointment.getSchedule()));

        return response;
    }

    // 在AppointmentService中添加以下方法
    @Transactional(readOnly = true)
    public List<AppointmentResponse> findByPatientId(Long patientId) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + patientId));
        return appointmentRepository.findByPatient(patient).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AppointmentResponse> findUpcomingByPatientId(Long patientId) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + patientId));
        return appointmentRepository.findByPatientAndScheduleScheduleDateAfterOrScheduleScheduleDateEqualAndScheduleSlotStartTimeAfter(
                        patient,
                        LocalDate.now(),
                        LocalDate.now(),
                        LocalTime.now()
                ).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AppointmentResponse cancelAppointment(Integer appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id " + appointmentId));

        if (appointment.getStatus() == AppointmentStatus.cancelled) {
            throw new BadRequestException("Appointment is already canceled");
        }

        AppointmentUpdateRequest request = new AppointmentUpdateRequest();
        request.setStatus(AppointmentStatus.cancelled);
        return updateAppointment(appointmentId, request);
    }

    @Transactional
    public AppointmentResponse processPayment(Integer appointmentId, AppointmentUpdateRequest paymentData) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Appointment not found with id " + appointmentId));

        if (appointment.getPaymentStatus() == PaymentStatus.paid) {
            throw new BadRequestException("Appointment is already paid");
        }

        paymentData.setPaymentStatus(PaymentStatus.paid);
        // 支付成功后，状态应该保持为 scheduled（已预约），而不是 completed（已完成）
        // completed 状态应该在就诊完成后由医生或系统标记
        if (appointment.getStatus() == AppointmentStatus.PENDING_PAYMENT) {
            paymentData.setStatus(AppointmentStatus.scheduled); // 从待支付改为已预约
        }
        // 如果已经是 scheduled 状态，则保持 scheduled 状态不变
        return updateAppointment(appointmentId, paymentData);
    }
}
