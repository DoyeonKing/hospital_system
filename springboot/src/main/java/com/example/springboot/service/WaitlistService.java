package com.example.springboot.service;

import com.example.springboot.dto.appointment.AppointmentResponse;
import com.example.springboot.dto.appointment.AppointmentUpdateRequest;
import com.example.springboot.dto.payment.PaymentRequest;
import com.example.springboot.dto.waitlist.WaitlistCreateRequest;
import com.example.springboot.dto.waitlist.WaitlistResponse;
import com.example.springboot.dto.waitlist.WaitlistUpdateRequest;
import com.example.springboot.dto.schedule.ScheduleResponse;
import com.example.springboot.entity.Appointment;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.Waitlist;
import com.example.springboot.entity.enums.AppointmentStatus;
import com.example.springboot.entity.enums.BlacklistStatus;
import com.example.springboot.entity.enums.WaitlistStatus;
import com.example.springboot.entity.enums.PaymentStatus;
import com.example.springboot.entity.enums.PatientStatus;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AppointmentRepository;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.repository.ScheduleRepository;
import com.example.springboot.repository.WaitlistRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class WaitlistService {

    private final WaitlistRepository waitlistRepository;
    private final PatientRepository patientRepository;
    private final ScheduleRepository scheduleRepository;
    private final AppointmentRepository appointmentRepository; // For checking existing appointments
    private final PatientService patientService; // For converting patient entity to DTO
    private final ScheduleService scheduleService;
    private final AppointmentService appointmentService; // For converting schedule entity to DTO

    @Autowired
    public WaitlistService(WaitlistRepository waitlistRepository,
                           PatientRepository patientRepository,
                           ScheduleRepository scheduleRepository,
                           AppointmentRepository appointmentRepository,
                           PatientService patientService,
                           ScheduleService scheduleService,
                           AppointmentService appointmentService) {
        this.waitlistRepository = waitlistRepository;
        this.patientRepository = patientRepository;
        this.scheduleRepository = scheduleRepository;
        this.appointmentRepository = appointmentRepository;
        this.patientService = patientService;
        this.scheduleService = scheduleService;
        this.appointmentService = appointmentService;
    }

    @Transactional(readOnly = true)
    public List<WaitlistResponse> findAllWaitlists() {
        return waitlistRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public WaitlistResponse findWaitlistById(Integer id) {
        Waitlist waitlist = waitlistRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Waitlist entry not found with id " + id));
        return convertToResponseDto(waitlist);
    }

    @Transactional(readOnly = true)
    public List<WaitlistResponse> findWaitlistsBySchedule(Integer scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + scheduleId));
        return waitlistRepository.findByScheduleAndStatusOrderByCreatedAtAsc(schedule, WaitlistStatus.PENDING).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public WaitlistResponse createWaitlist(WaitlistCreateRequest request) {
        Patient patient = patientRepository.findById(request.getPatientId())
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + request.getPatientId()));
        Schedule schedule = scheduleRepository.findById(request.getScheduleId())
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + request.getScheduleId()));

        // 检查患者状态
        if (patient.getStatus() == PatientStatus.deleted) {
            throw new BadRequestException("患者已删除，无法加入候补队列");
        }

        // 检查患者是否已在黑名单
        if (patient.getPatientProfile() != null && patient.getPatientProfile().getBlacklistStatus() == BlacklistStatus.blacklisted) {
            throw new BadRequestException("Patient is blacklisted and cannot join waitlist.");
        }
        // 检查患者是否已有该排班的预约
        if (appointmentRepository.existsByPatientAndSchedule(patient, schedule)) {
            throw new BadRequestException("Patient already has an appointment for this schedule.");
        }
        // 检查患者是否已在该排班的候补队列中
        if (waitlistRepository.existsByPatientAndScheduleAndStatus(patient, schedule, WaitlistStatus.PENDING)) {
            throw new BadRequestException("Patient is already on the waitlist for this schedule.");
        }

        Waitlist waitlist = new Waitlist();
        waitlist.setPatient(patient);
        waitlist.setSchedule(schedule);
        waitlist.setStatus(WaitlistStatus.PENDING);
        waitlist.setCreatedAt(LocalDateTime.now());

        return convertToResponseDto(waitlistRepository.save(waitlist));
    }

    @Transactional
    public WaitlistResponse updateWaitlist(Integer id, WaitlistUpdateRequest request) {
        Waitlist existingWaitlist = waitlistRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Waitlist entry not found with id " + id));

        if (request.getStatus() != null) existingWaitlist.setStatus(request.getStatus());
        if (request.getNotificationSentAt() != null) existingWaitlist.setNotificationSentAt(request.getNotificationSentAt());

        return convertToResponseDto(waitlistRepository.save(existingWaitlist));
    }

    @Transactional
    public void deleteWaitlist(Integer id) {
        if (!waitlistRepository.existsById(id)) {
            throw new ResourceNotFoundException("Waitlist entry not found with id " + id);
        }
        waitlistRepository.deleteById(id);
    }

    /**
     * Attempts to fill an empty slot from the waitlist.
     * This method would typically be called by a scheduled task or when an appointment is canceled.
     *
     * @param scheduleId The ID of the schedule with an empty slot.
     * @return The created appointment response if a slot was filled, or null if no waitlist entry could fill it.
     */
    @Transactional
    public Appointment createAppointmentFromWaitlist(Integer scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + scheduleId));

        // 检查是否有空余号源
        if (schedule.getBookedSlots() >= schedule.getTotalSlots()) {
            return null; // 没有空余号源
        }

        // 获取最早的待处理候补条目
        List<Waitlist> pendingWaitlists = waitlistRepository.findByScheduleAndStatusOrderByCreatedAtAsc(schedule, WaitlistStatus.PENDING);
        if (pendingWaitlists.isEmpty()) {
            return null; // 没有待处理的候补人员
        }

        for (Waitlist waitlist : pendingWaitlists) {
            Patient patient = waitlist.getPatient();
            // 再次检查患者状态和是否已预约
            if (patient.getPatientProfile() != null && patient.getPatientProfile().getBlacklistStatus() == BlacklistStatus.blacklisted) {
                waitlist.setStatus(WaitlistStatus.REJECTED); // 标记为拒绝，跳过
                waitlistRepository.save(waitlist);
                continue;
            }
            if (appointmentRepository.existsByPatientAndSchedule(patient, schedule)) {
                waitlist.setStatus(WaitlistStatus.REJECTED); // 标记为拒绝，因为已经有预约了
                waitlistRepository.save(waitlist);
                continue;
            }

            // 找到合适的候补人员，创建预约
            Appointment newAppointment = new Appointment();
            newAppointment.setPatient(patient);
            newAppointment.setSchedule(schedule);
            newAppointment.setAppointmentNumber(schedule.getBookedSlots() + 1);
            newAppointment.setStatus(AppointmentStatus.PENDING_PAYMENT); // 初始状态待支付
            newAppointment.setPaymentStatus(PaymentStatus.unpaid);
            newAppointment.setCreatedAt(LocalDateTime.now());

            schedule.setBookedSlots(schedule.getBookedSlots() + 1); // 增加已预约数
            scheduleRepository.save(schedule); // 保存排班

            waitlist.setStatus(WaitlistStatus.FULFILLED); // 标记候补已完成
            waitlist.setNotificationSentAt(LocalDateTime.now()); // 假设此时通知已发送
            waitlistRepository.save(waitlist); // 保存候补

            return appointmentRepository.save(newAppointment); // 保存并返回新预约
        }
        return null; // 没有找到可以成功转换的候补人员
    }


    public WaitlistResponse convertToResponseDto(Waitlist waitlist) {
        WaitlistResponse response = new WaitlistResponse();
        BeanUtils.copyProperties(waitlist, response, "patient", "schedule");
        response.setPatient(patientService.convertToResponseDto(waitlist.getPatient()));
        response.setSchedule(ScheduleResponse.fromEntity(waitlist.getSchedule()));
        return response;
    }

    // 在WaitlistService中添加以下方法
    @Transactional(readOnly = true)
    public List<WaitlistResponse> findByPatientId(Long patientId) {
        Patient patient = patientRepository.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + patientId));
        return waitlistRepository.findByPatient(patient).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public WaitlistResponse cancelWaitlist(Integer waitlistId) {
        Waitlist waitlist = waitlistRepository.findById(waitlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Waitlist not found with id " + waitlistId));

        if (waitlist.getStatus() != WaitlistStatus.PENDING) {
            throw new BadRequestException("Only pending waitlist entries can be canceled");
        }

        WaitlistUpdateRequest request = new WaitlistUpdateRequest();
        request.setStatus(WaitlistStatus.expired);
        return updateWaitlist(waitlistId, request);
    }

    @Transactional
    public AppointmentResponse processWaitlistPayment(Integer waitlistId, PaymentRequest paymentData) {
        Waitlist waitlist = waitlistRepository.findById(waitlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Waitlist not found with id " + waitlistId));

        if (waitlist.getStatus() != WaitlistStatus.notified) {
            throw new BadRequestException("Only notified waitlist entries can be paid");
        }

        // 创建正式预约
        Appointment appointment = createAppointmentFromWaitlist(waitlist.getSchedule().getScheduleId());
        if (appointment == null) {
            throw new BadRequestException("No available slot to convert waitlist to appointment");
        }

        // 更新支付信息
        AppointmentUpdateRequest updateRequest = new AppointmentUpdateRequest();
        updateRequest.setPaymentStatus(PaymentStatus.paid);
        updateRequest.setPaymentMethod(paymentData.getPaymentMethod());
        updateRequest.setTransactionId(paymentData.getTransactionId());
        updateRequest.setStatus(AppointmentStatus.completed);

        return appointmentService.updateAppointment(appointment.getAppointmentId(), updateRequest);
    }
}
