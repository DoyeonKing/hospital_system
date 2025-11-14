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
    private final NotificationService notificationService;

    @Autowired
    public WaitlistService(WaitlistRepository waitlistRepository,
                           PatientRepository patientRepository,
                           ScheduleRepository scheduleRepository,
                           AppointmentRepository appointmentRepository,
                           PatientService patientService,
                           ScheduleService scheduleService,
                           AppointmentService appointmentService,
                           NotificationService notificationService) {
        this.waitlistRepository = waitlistRepository;
        this.patientRepository = patientRepository;
        this.scheduleRepository = scheduleRepository;
        this.appointmentRepository = appointmentRepository;
        this.patientService = patientService;
        this.scheduleService = scheduleService;
        this.appointmentService = appointmentService;
        this.notificationService = notificationService;
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
        return waitlistRepository.findByScheduleAndStatusOrderByCreatedAtAsc(schedule, WaitlistStatus.waiting).stream()
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
        if (waitlistRepository.existsByPatientAndScheduleAndStatus(patient, schedule, WaitlistStatus.waiting)) {
            throw new BadRequestException("Patient is already on the waitlist for this schedule.");
        }

        Waitlist waitlist = new Waitlist();
        waitlist.setPatient(patient);
        waitlist.setSchedule(schedule);
        waitlist.setStatus(WaitlistStatus.waiting);  // 新候补记录状态为 waiting
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

        // 获取最早的等待中的候补条目
        List<Waitlist> pendingWaitlists = waitlistRepository.findByScheduleAndStatusOrderByCreatedAtAsc(schedule, WaitlistStatus.waiting);
        if (pendingWaitlists.isEmpty()) {
            return null; // 没有等待中的候补人员
        }

        for (Waitlist waitlist : pendingWaitlists) {
            Patient patient = waitlist.getPatient();
            // 再次检查患者状态和是否已预约
            if (patient.getPatientProfile() != null && patient.getPatientProfile().getBlacklistStatus() == BlacklistStatus.blacklisted) {
                waitlist.setStatus(WaitlistStatus.expired); // 标记为过期（拒绝）
                waitlistRepository.save(waitlist);
                continue;
            }
            if (appointmentRepository.existsByPatientAndSchedule(patient, schedule)) {
                waitlist.setStatus(WaitlistStatus.expired); // 标记为过期（已有预约）
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

            waitlist.setStatus(WaitlistStatus.notified); // 标记为已通知（等待支付）
            waitlist.setNotificationSentAt(LocalDateTime.now()); // 记录通知发送时间
            waitlistRepository.save(waitlist); // 保存候补

            Appointment savedAppointment = appointmentRepository.save(newAppointment); // 保存新预约
            
            // 发送候补可用通知
            try {
                String departmentName = "未知科室";
                String doctorName = "未知医生";
                String scheduleDate = "";
                String slotName = "";
                
                if (schedule != null) {
                    if (schedule.getDoctor() != null && schedule.getDoctor().getDepartment() != null) {
                        departmentName = schedule.getDoctor().getDepartment().getName();
                    }
                    if (schedule.getDoctor() != null) {
                        doctorName = schedule.getDoctor().getFullName();
                    }
                    if (schedule.getScheduleDate() != null) {
                        scheduleDate = schedule.getScheduleDate().toString();
                    }
                    if (schedule.getSlot() != null) {
                        slotName = schedule.getSlot().getSlotName();
                    }
                }
                
                notificationService.sendWaitlistAvailableNotification(
                        patient.getPatientId().intValue(),
                        waitlist.getWaitlistId(),
                        departmentName,
                        doctorName,
                        scheduleDate,
                        slotName
                );
            } catch (Exception e) {
                // 通知发送失败不影响流程，只记录日志
                System.err.println("Failed to send waitlist available notification: " + e.getMessage());
            }
            
            return savedAppointment; // 返回新预约
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

        if (waitlist.getStatus() != WaitlistStatus.waiting) {
            throw new BadRequestException("Only waiting waitlist entries can be canceled");
        }

        WaitlistUpdateRequest request = new WaitlistUpdateRequest();
        request.setStatus(WaitlistStatus.expired);
        return updateWaitlist(waitlistId, request);
    }

    @Transactional
    public AppointmentResponse processWaitlistPayment(Integer waitlistId, PaymentRequest paymentData) {
        // 1. 查找候补记录
        Waitlist waitlist = waitlistRepository.findById(waitlistId)
                .orElseThrow(() -> new ResourceNotFoundException("Waitlist not found with id " + waitlistId));

        // 2. 检查状态必须是 notified（已通知）
        if (waitlist.getStatus() != WaitlistStatus.notified) {
            throw new BadRequestException("Only notified waitlist entries can be paid");
        }

        Schedule schedule = waitlist.getSchedule();
        Patient patient = waitlist.getPatient();

        // 3. 检查是否还有空位（可能在通知后被其他人预约了）
        if (schedule.getBookedSlots() >= schedule.getTotalSlots()) {
            throw new BadRequestException("No available slot, the schedule is already fully booked");
        }

        // 4. 检查患者是否已经有这个排班的预约了
        if (appointmentRepository.existsByPatientAndSchedule(patient, schedule)) {
            throw new BadRequestException("Patient already has an appointment for this schedule");
        }

        // 5. 为当前患者创建正式预约
        Appointment appointment = new Appointment();
        appointment.setPatient(patient);
        appointment.setSchedule(schedule);
        appointment.setAppointmentNumber(schedule.getBookedSlots() + 1);
        appointment.setStatus(AppointmentStatus.scheduled);  // 已预约状态
        appointment.setPaymentStatus(PaymentStatus.paid);    // 已支付
        appointment.setPaymentMethod(paymentData.getPaymentMethod());
        appointment.setTransactionId(paymentData.getTransactionId());
        appointment.setCreatedAt(LocalDateTime.now());

        // 6. 更新排班的已预约数
        schedule.setBookedSlots(schedule.getBookedSlots() + 1);
        scheduleRepository.save(schedule);

        // 7. 更新候补状态为已预约
        waitlist.setStatus(WaitlistStatus.booked);
        waitlistRepository.save(waitlist);

        // 8. 保存预约
        Appointment savedAppointment = appointmentRepository.save(appointment);
        
        // 9. 发送支付成功通知
        try {
            String departmentName = "未知科室";
            String doctorName = "未知医生";
            String scheduleDate = "";
            String slotName = "";
            Double fee = 0.0;
            
            if (schedule != null) {
                if (schedule.getDoctor() != null && schedule.getDoctor().getDepartment() != null) {
                    departmentName = schedule.getDoctor().getDepartment().getName();
                }
                if (schedule.getDoctor() != null) {
                    doctorName = schedule.getDoctor().getFullName();
                }
                if (schedule.getScheduleDate() != null) {
                    scheduleDate = schedule.getScheduleDate().toString();
                }
                if (schedule.getSlot() != null) {
                    slotName = schedule.getSlot().getSlotName();
                }
                if (schedule.getFee() != null) {
                    fee = schedule.getFee().doubleValue();
                }
            }
            
            notificationService.sendPaymentSuccessNotification(
                    patient.getPatientId().intValue(),
                    savedAppointment.getAppointmentId(),
                    departmentName,
                    doctorName,
                    scheduleDate,
                    slotName,
                    fee
            );
        } catch (Exception e) {
            // 通知发送失败不影响支付流程，只记录日志
            System.err.println("Failed to send payment success notification for waitlist: " + e.getMessage());
        }
        
        return appointmentService.findAppointmentById(savedAppointment.getAppointmentId());
    }
}
