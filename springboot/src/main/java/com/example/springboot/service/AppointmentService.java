package com.example.springboot.service;

import com.example.springboot.common.Constants;
import com.example.springboot.dto.appointment.AppointmentCreateRequest;
import com.example.springboot.dto.appointment.AppointmentResponse;
import com.example.springboot.dto.appointment.AppointmentUpdateRequest;
import com.example.springboot.dto.appointment.CheckInRequest;
import com.example.springboot.dto.appointment.CheckInResponse;
import com.example.springboot.dto.appointment.QrCodeResponse;
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
import org.springframework.context.annotation.Lazy;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
public class AppointmentService {

    private static final Logger logger = LoggerFactory.getLogger(AppointmentService.class);

    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final ScheduleRepository scheduleRepository;
    private final PatientService patientService; // For updating patient profile (no-show count)
    private final DoctorService doctorService; // To get Doctor details for response
    private final DepartmentService departmentService; // To get Department details for response
    private final TimeSlotService timeSlotService; // To get TimeSlot details for response
    private final ScheduleService scheduleService;
    private final NotificationService notificationService;
    private final WaitlistService waitlistService;
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String QR_TOKEN_PREFIX = "qr:token:";
    private static final int QR_TOKEN_MIN_EXPIRE_SECONDS = 1800; // 最小30分钟过期
    private static final int QR_REFRESH_INTERVAL_SECONDS = 60; // 建议60秒刷新一次
    // 签到时间限制：已改为随到随签，只要在工作时间结束之前都可以签到


    @Autowired
    public AppointmentService(AppointmentRepository appointmentRepository,
                              PatientRepository patientRepository,
                              ScheduleRepository scheduleRepository,
                              PatientService patientService,
                              DoctorService doctorService,
                              DepartmentService departmentService,
                              TimeSlotService timeSlotService,
                              ScheduleService scheduleService,
                              NotificationService notificationService,
                              @Lazy WaitlistService waitlistService) {
        this.appointmentRepository = appointmentRepository;
        this.patientRepository = patientRepository;
        this.scheduleRepository = scheduleRepository;
        this.patientService = patientService;
        this.doctorService = doctorService;
        this.departmentService = departmentService;
        this.timeSlotService = timeSlotService;
        this.scheduleService = scheduleService;
        this.notificationService = notificationService;
        this.waitlistService = waitlistService;
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

        // Check if patient already has an active appointment for this schedule (excluding cancelled appointments)
        if (appointmentRepository.existsByPatientAndScheduleAndStatusNotCancelled(patient, schedule)) {
            throw new BadRequestException("Patient already has an appointment for this schedule.");
        }

        Appointment appointment = new Appointment();
        appointment.setPatient(patient);
        appointment.setSchedule(schedule);
        appointment.setAppointmentNumber(getNextAppointmentNumberForRebooking(schedule, patient)); // 自动分配就诊序号
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

        AppointmentStatus originalStatus = existingAppointment.getStatus();
        boolean shouldRestoreSlots = false;
        boolean shouldAssignNewNumber = false;

        // Update fields if provided in request
        if (request.getAppointmentNumber() != null) existingAppointment.setAppointmentNumber(request.getAppointmentNumber());
        if (request.getStatus() != null) {
            AppointmentStatus newStatus = request.getStatus();
            // Handle specific status transitions and logic
            if (newStatus == AppointmentStatus.cancelled && originalStatus != AppointmentStatus.cancelled) {
                // 如果是取消预约，需要减少排班的已预约数
                Schedule schedule = existingAppointment.getSchedule();
                if (schedule.getBookedSlots() > 0) {
                    schedule.setBookedSlots(schedule.getBookedSlots() - 1);
                    scheduleRepository.save(schedule);
                    
                    // 取消预约后，触发候补自动填充
                    // 注意：这里 schedule.getBookedSlots() 已经是减少后的值了
                    System.out.println("取消预约后，检查候补填充 - bookedSlots: " + schedule.getBookedSlots() + ", totalSlots: " + schedule.getTotalSlots());
                    if (schedule.getBookedSlots() < schedule.getTotalSlots()) {
                        // 有空余号源，尝试从候补队列中填充
                        try {
                            // 刷新 schedule 对象，确保获取最新的 bookedSlots 值
                            schedule = scheduleRepository.findById(schedule.getScheduleId())
                                    .orElseThrow(() -> new ResourceNotFoundException("Schedule not found"));
                            
                            System.out.println("刷新后检查 - bookedSlots: " + schedule.getBookedSlots() + ", totalSlots: " + schedule.getTotalSlots());
                            // 再次检查是否有空余号源（防止并发问题）
                            if (schedule.getBookedSlots() < schedule.getTotalSlots()) {
                                System.out.println("开始触发候补自动填充，scheduleId: " + schedule.getScheduleId());
                                Appointment filledAppointment = waitlistService.createAppointmentFromWaitlist(schedule.getScheduleId());
                                if (filledAppointment != null) {
                                    System.out.println("候补填充成功，创建预约ID: " + filledAppointment.getAppointmentId());
                                } else {
                                    System.out.println("候补填充返回null，可能没有可用的候补或候补不符合条件");
                                }
                            } else {
                                System.out.println("刷新后发现号源已满，跳过候补填充");
                            }
                        } catch (Exception e) {
                            // 候补填充失败不影响取消预约流程，只记录日志
                            System.err.println("Failed to fill waitlist after appointment cancellation: " + e.getMessage());
                            e.printStackTrace(); // 打印完整堆栈，便于调试
                        }
                    } else {
                        System.out.println("取消预约后号源仍满，无需候补填充");
                    }
                }
            } else if (newStatus == AppointmentStatus.NO_SHOW && originalStatus != AppointmentStatus.NO_SHOW) {
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
            } else if (newStatus == AppointmentStatus.cancelled && originalStatus == AppointmentStatus.CHECKED_IN) {
                // 已签到的预约不能取消
                throw new BadRequestException("已签到的预约不能取消，如需取消请联系管理员");
            } else if (originalStatus == AppointmentStatus.cancelled && isActiveStatus(newStatus)) {
                shouldRestoreSlots = true;
                shouldAssignNewNumber = true;
            }
            existingAppointment.setStatus(newStatus);
        }
        if (request.getPaymentStatus() != null) existingAppointment.setPaymentStatus(request.getPaymentStatus());
        if (request.getPaymentMethod() != null) existingAppointment.setPaymentMethod(request.getPaymentMethod());
        if (request.getTransactionId() != null) existingAppointment.setTransactionId(request.getTransactionId());
        // 不允许通过 updateAppointment 接口直接设置签到时间，必须通过签到接口
        // 如果请求中包含 checkInTime，忽略它（避免误操作）
        // if (request.getCheckInTime() != null) existingAppointment.setCheckInTime(request.getCheckInTime());

        if (shouldAssignNewNumber) {
            existingAppointment.setAppointmentNumber(
                    getNextAppointmentNumberForRebooking(existingAppointment.getSchedule(), existingAppointment.getPatient()));
        }

        if (shouldRestoreSlots) {
            Schedule schedule = existingAppointment.getSchedule();
            schedule.setBookedSlots(schedule.getBookedSlots() + 1);
            scheduleRepository.save(schedule);
        }

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
    public List<AppointmentResponse> findByDoctorId(Integer doctorId) {
        return appointmentRepository.findByScheduleDoctorDoctorId(doctorId).stream()
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

        // 检查预约时间是否已过去
        if (appointment.getSchedule() != null && appointment.getSchedule().getScheduleDate() != null 
                && appointment.getSchedule().getSlot() != null 
                && appointment.getSchedule().getSlot().getStartTime() != null) {
            LocalDate scheduleDate = appointment.getSchedule().getScheduleDate();
            LocalTime startTime = appointment.getSchedule().getSlot().getStartTime();
            LocalDateTime scheduleDateTime = LocalDateTime.of(scheduleDate, startTime);
            LocalDateTime now = LocalDateTime.now();
            
            // 如果预约时间已过去，不允许取消
            if (scheduleDateTime.isBefore(now) || scheduleDateTime.isEqual(now)) {
                throw new BadRequestException("Cannot cancel appointment that has already passed");
            }
        }

        AppointmentUpdateRequest request = new AppointmentUpdateRequest();
        request.setStatus(AppointmentStatus.cancelled);
        AppointmentResponse response = updateAppointment(appointmentId, request);
        
        // 注意：候补自动填充已在 updateAppointment 方法中处理（当状态变为 cancelled 时）
        // 这里只需要发送通知即可
        
        // 取消预约后发送通知
        try {
            Schedule schedule = appointment.getSchedule();
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
            
            notificationService.sendCancellationNotification(
                    appointment.getPatient().getPatientId().intValue(),
                    appointmentId,
                    departmentName,
                    doctorName,
                    scheduleDate,
                    slotName
            );
        } catch (Exception e) {
            // 通知发送失败不影响取消流程，只记录日志
            System.err.println("Failed to send cancellation notification: " + e.getMessage());
        }
        
        return response;
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
        AppointmentResponse response = updateAppointment(appointmentId, paymentData);
        
        // 支付成功后发送通知
        try {
            Schedule schedule = appointment.getSchedule();
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
                    appointment.getPatient().getPatientId().intValue(),
                    appointmentId,
                    departmentName,
                    doctorName,
                    scheduleDate,
                    slotName,
                    fee
            );
        } catch (Exception e) {
            // 通知发送失败不影响支付流程，只记录日志
            System.err.println("Failed to send payment success notification: " + e.getMessage());
        }
        
        return response;
    }

    private int getNextAppointmentNumberForRebooking(Schedule schedule, Patient patient) {
        Appointment lastAppointment = appointmentRepository.findTopByScheduleOrderByAppointmentNumberDesc(schedule);
        int baseNumber = (lastAppointment == null || lastAppointment.getAppointmentNumber() == null)
                ? 0
                : lastAppointment.getAppointmentNumber();

        if (lastAppointment != null && lastAppointment.getPatient() != null
                && Objects.equals(lastAppointment.getPatient().getPatientId(), patient.getPatientId())) {
            return baseNumber + 1;
        }

        return baseNumber + 1;
    }

    private boolean isActiveStatus(AppointmentStatus status) {
        return status == AppointmentStatus.scheduled || 
               status == AppointmentStatus.PENDING_PAYMENT || 
               status == AppointmentStatus.CHECKED_IN;
    }

    /**
     * 生成预约二维码Token
     */
    @Transactional(readOnly = true)
    public QrCodeResponse generateQrCode(Integer appointmentId) {
        logger.info("========== 开始生成二维码Token ==========");
        logger.info("预约ID: {}", appointmentId);
        LocalDateTime requestTime = LocalDateTime.now();
        logger.info("请求时间: {}", requestTime);
        
        // 1. 验证预约是否存在
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> {
                    logger.error("预约不存在，ID: {}", appointmentId);
                    return new ResourceNotFoundException("预约不存在，ID: " + appointmentId);
                });
        logger.info("预约信息查询成功 - 预约ID: {}, 状态: {}, 患者ID: {}", 
                appointment.getAppointmentId(), appointment.getStatus(), appointment.getPatient().getPatientId());

        // 2. 验证预约状态（必须是 scheduled）
        // 只有 scheduled 和 CHECKED_IN 状态可以生成二维码（已签到但未就诊的也可以刷新二维码）
        if (appointment.getStatus() != AppointmentStatus.scheduled && appointment.getStatus() != AppointmentStatus.CHECKED_IN) {
            logger.warn("预约状态不正确，无法生成二维码 - 预约ID: {}, 当前状态: {}, 允许的状态: scheduled, CHECKED_IN", 
                    appointmentId, appointment.getStatus());
            throw new BadRequestException("预约状态不正确，无法生成二维码。当前状态: " + appointment.getStatus());
        }
        logger.info("预约状态验证通过 - 状态: {}", appointment.getStatus());

        // 3. 验证预约时间（只要在排班结束时间之前都可以生成二维码）
        Schedule schedule = appointment.getSchedule();
        if (schedule == null || schedule.getScheduleDate() == null || schedule.getSlot() == null) {
            logger.error("预约排班信息不完整 - 预约ID: {}, schedule: {}, scheduleDate: {}, slot: {}", 
                    appointmentId, schedule != null, 
                    schedule != null ? schedule.getScheduleDate() : null,
                    schedule != null && schedule.getSlot() != null ? schedule.getSlot().getSlotId() : null);
            throw new BadRequestException("预约排班信息不完整");
        }
        logger.info("排班信息查询成功 - 排班ID: {}, 排班日期: {}, 时间段: {} - {}", 
                schedule.getScheduleId(), schedule.getScheduleDate(), 
                schedule.getSlot().getStartTime(), schedule.getSlot().getEndTime());

        LocalDateTime scheduleEndTime = LocalDateTime.of(schedule.getScheduleDate(), schedule.getSlot().getEndTime());
        LocalDateTime now = LocalDateTime.now();
        logger.info("时间验证 - 当前时间: {}, 排班结束时间: {}", now, scheduleEndTime);
        
        // 如果排班结束时间已过去，不允许生成二维码
        // 允许在排班开始时间之前生成二维码（随到随签）
        if (now.isAfter(scheduleEndTime)) {
            Duration timePassed = Duration.between(scheduleEndTime, now);
            logger.warn("排班结束时间已过，无法生成二维码 - 预约ID: {}, 排班结束时间: {}, 当前时间: {}, 已过: {}分钟", 
                    appointmentId, scheduleEndTime, now, timePassed.toMinutes());
            throw new BadRequestException("排班结束时间已过（" + 
                schedule.getScheduleDate() + " " + schedule.getSlot().getEndTime() + "），无法生成二维码");
        }

        // 4. 计算Token过期时间：动态设置为排班结束时间，但不少于最小过期时间
        Duration timeUntilEnd = Duration.between(now, scheduleEndTime);
        long expireSeconds = Math.max(timeUntilEnd.getSeconds(), QR_TOKEN_MIN_EXPIRE_SECONDS);
        long expireMinutes = expireSeconds / 60;
        long timeUntilEndMinutes = timeUntilEnd.toMinutes();
        logger.info("Token过期时间计算 - 距离排班结束: {}分钟 ({}秒), 最小过期时间: {}分钟 ({}秒), 最终过期时间: {}分钟 ({}秒)", 
                timeUntilEndMinutes, timeUntilEnd.getSeconds(),
                QR_TOKEN_MIN_EXPIRE_SECONDS / 60, QR_TOKEN_MIN_EXPIRE_SECONDS,
                expireMinutes, expireSeconds);
        
        // 生成Token
        long timestamp = System.currentTimeMillis();
        String random = generateRandomString(6); // 6位随机字符串
        String qrToken = String.format("APPOINTMENT_%d_%d_%s", appointmentId, timestamp, random);
        logger.info("Token生成成功 - Token: {}, 生成时间戳: {}", qrToken, timestamp);

        // 5. 存储到Redis（动态过期时间：排班结束时间或最小30分钟，取较大值）
        String redisKey = QR_TOKEN_PREFIX + qrToken;
        try {
            redisTemplate.opsForValue().set(redisKey, 
                    String.valueOf(appointmentId), 
                    expireSeconds, 
                    TimeUnit.SECONDS);
            logger.info("Token已存储到Redis - Redis Key: {}, 预约ID: {}, 过期时间: {}秒 ({}分钟)", 
                    redisKey, appointmentId, expireSeconds, expireMinutes);
            
            // 验证Redis存储是否成功
            String storedValue = redisTemplate.opsForValue().get(redisKey);
            if (storedValue != null && storedValue.equals(String.valueOf(appointmentId))) {
                logger.info("Redis存储验证成功 - Key: {}, Value: {}", redisKey, storedValue);
            } else {
                logger.error("Redis存储验证失败 - Key: {}, 期望值: {}, 实际值: {}", 
                        redisKey, appointmentId, storedValue);
            }
        } catch (Exception e) {
            logger.error("Redis存储失败 - Key: {}, 预约ID: {}, 错误信息: {}", 
                    redisKey, appointmentId, e.getMessage(), e);
            throw new BadRequestException("二维码Token存储失败，请重试");
        }

        // 6. 返回响应
        QrCodeResponse response = new QrCodeResponse();
        response.setAppointmentId(appointmentId);
        response.setQrToken(qrToken);
        response.setExpiresIn((int) expireSeconds);
        response.setRefreshInterval(QR_REFRESH_INTERVAL_SECONDS);

        logger.info("二维码Token生成完成 - 预约ID: {}, Token: {}, 过期时间: {}秒, 刷新间隔: {}秒", 
                appointmentId, qrToken, expireSeconds, QR_REFRESH_INTERVAL_SECONDS);
        logger.info("========== 二维码Token生成结束 ==========");
        return response;
    }

    /**
     * 扫码签到
     */
    @Transactional
    public CheckInResponse checkIn(CheckInRequest request) {
        logger.info("========== 开始扫码签到 ==========");
        String qrToken = request.getQrToken();
        LocalDateTime checkInRequestTime = LocalDateTime.now();
        logger.info("签到请求时间: {}", checkInRequestTime);
        logger.info("二维码Token: {}", qrToken);
        
        if (qrToken == null || qrToken.isEmpty()) {
            logger.error("二维码Token为空");
            throw new BadRequestException("二维码Token不能为空");
        }

        // 1. 从Redis查询Token对应的预约ID
        String redisKey = QR_TOKEN_PREFIX + qrToken;
        logger.info("查询Redis - Key: {}", redisKey);
        
        String appointmentIdStr = null;
        try {
            appointmentIdStr = redisTemplate.opsForValue().get(redisKey);
            logger.info("Redis查询结果 - Key: {}, Value: {}", redisKey, appointmentIdStr);
        } catch (Exception e) {
            logger.error("Redis查询失败 - Key: {}, 错误信息: {}", redisKey, e.getMessage(), e);
            throw new BadRequestException("二维码验证失败，请重试");
        }

        if (appointmentIdStr == null) {
            logger.warn("二维码Token在Redis中不存在或已过期 - Token: {}, Redis Key: {}", qrToken, redisKey);
            
            // 尝试解析Token获取预约ID（用于调试）
            try {
                String[] tokenParts = qrToken.split("_");
                if (tokenParts.length >= 2) {
                    String possibleAppointmentId = tokenParts[1];
                    logger.info("从Token解析可能的预约ID: {}", possibleAppointmentId);
                }
            } catch (Exception e) {
                logger.debug("Token解析失败: {}", e.getMessage());
            }
            
            throw new BadRequestException("二维码已过期或无效，请患者刷新二维码后重试");
        }

        final Integer appointmentId;
        try {
            appointmentId = Integer.parseInt(appointmentIdStr);
            logger.info("预约ID解析成功: {}", appointmentId);
        } catch (NumberFormatException e) {
            logger.error("预约ID格式错误 - 原始值: {}, 错误信息: {}", appointmentIdStr, e.getMessage());
            throw new BadRequestException("二维码Token格式错误，请刷新二维码后重试");
        }

        // 2. 查询预约
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> {
                    logger.error("预约不存在 - 预约ID: {}", appointmentId);
                    return new ResourceNotFoundException("预约不存在，ID: " + appointmentId);
                });
        logger.info("预约信息查询成功 - 预约ID: {}, 状态: {}, 患者: {}, 就诊序号: {}", 
                appointment.getAppointmentId(), appointment.getStatus(), 
                appointment.getPatient().getFullName(), appointment.getAppointmentNumber());

        // 3. 验证预约状态（必须是 scheduled，已签到的不能重复签到）
        if (appointment.getStatus() == AppointmentStatus.CHECKED_IN) {
            logger.warn("预约已签到，重复签到 - 预约ID: {}, 原签到时间: {}", 
                    appointmentId, appointment.getCheckInTime());
            // Token已使用，删除Token
            try {
                redisTemplate.delete(redisKey);
                logger.info("已删除Redis中的Token - Key: {}", redisKey);
            } catch (Exception e) {
                logger.error("删除Redis Token失败 - Key: {}, 错误: {}", redisKey, e.getMessage());
            }
            throw new BadRequestException("该预约已签到（签到时间：" + appointment.getCheckInTime() + "），请勿重复操作。预约ID：" + appointmentId + "，如需重新签到，可以清除签到记录。");
        }
        
        if (appointment.getStatus() != AppointmentStatus.scheduled) {
            logger.warn("预约状态不正确，无法签到 - 预约ID: {}, 当前状态: {}, 期望状态: scheduled", 
                    appointmentId, appointment.getStatus());
            // Token已使用，删除Token
            try {
                redisTemplate.delete(redisKey);
                logger.info("已删除Redis中的Token - Key: {}", redisKey);
            } catch (Exception e) {
                logger.error("删除Redis Token失败 - Key: {}, 错误: {}", redisKey, e.getMessage());
            }
            throw new BadRequestException("预约状态不正确，无法签到。当前状态: " + appointment.getStatus() + "，只有已预约（scheduled）状态的预约才能签到。");
        }
        logger.info("预约状态验证通过 - 状态: scheduled");

        // 5. 验证签到时间（随到随签：只要在工作时间结束之前都可以签到）
        Schedule schedule = appointment.getSchedule();
        if (schedule == null || schedule.getScheduleDate() == null || schedule.getSlot() == null) {
            logger.error("预约排班信息不完整 - 预约ID: {}, schedule: {}, scheduleDate: {}, slot: {}", 
                    appointmentId, schedule != null, 
                    schedule != null ? schedule.getScheduleDate() : null,
                    schedule != null && schedule.getSlot() != null ? schedule.getSlot().getSlotId() : null);
            try {
                redisTemplate.delete(redisKey);
            } catch (Exception e) {
                logger.error("删除Redis Token失败: {}", e.getMessage());
            }
            throw new BadRequestException("预约排班信息不完整");
        }
        logger.info("排班信息查询成功 - 排班ID: {}, 排班日期: {}, 时间段: {} - {}", 
                schedule.getScheduleId(), schedule.getScheduleDate(), 
                schedule.getSlot().getStartTime(), schedule.getSlot().getEndTime());

        LocalDateTime scheduleEndTime = LocalDateTime.of(schedule.getScheduleDate(), schedule.getSlot().getEndTime());
        LocalDateTime now = LocalDateTime.now();
        logger.info("时间验证 - 当前时间: {}, 排班结束时间: {}", now, scheduleEndTime);
        
        // 检查当前时间是否在排班结束时间之后
        if (now.isAfter(scheduleEndTime)) {
            Duration timePassed = Duration.between(scheduleEndTime, now);
            logger.warn("签到时间已超过排班结束时间 - 预约ID: {}, 排班结束时间: {}, 当前时间: {}, 已过: {}分钟", 
                    appointmentId, scheduleEndTime, now, timePassed.toMinutes());
            try {
                redisTemplate.delete(redisKey);
                logger.info("已删除Redis中的Token - Key: {}", redisKey);
            } catch (Exception e) {
                logger.error("删除Redis Token失败: {}", e.getMessage());
            }
            throw new BadRequestException("签到时间已超过排班结束时间（" + 
                schedule.getScheduleDate() + " " + schedule.getSlot().getEndTime() + "），无法签到");
        }
        logger.info("时间验证通过 - 当前时间在排班结束时间之前");
        
        // 允许提前签到：在排班开始时间之前也可以签到（随到随签）
        // 只要在排班结束时间之前都可以签到，不做其他时间限制

        // 6. 更新签到时间和状态
        appointment.setCheckInTime(now);
        appointment.setStatus(AppointmentStatus.CHECKED_IN); // 设置状态为已签到
        try {
            appointmentRepository.save(appointment);
            logger.info("签到信息已保存 - 预约ID: {}, 签到时间: {}, 新状态: CHECKED_IN", 
                    appointmentId, now, appointment.getStatus());
        } catch (Exception e) {
            logger.error("保存签到信息失败 - 预约ID: {}, 错误信息: {}", appointmentId, e.getMessage(), e);
            throw new BadRequestException("签到失败，请重试");
        }

        // 7. 立即删除Token（确保一次性使用）
        try {
            Boolean deleted = redisTemplate.delete(redisKey);
            logger.info("Token已删除 - Key: {}, 删除结果: {}", redisKey, deleted);
        } catch (Exception e) {
            logger.error("删除Token失败 - Key: {}, 错误信息: {}", redisKey, e.getMessage(), e);
            // 即使删除失败也不影响签到结果，只记录日志
        }

        // 8. 返回签到信息
        CheckInResponse response = new CheckInResponse();
        response.setAppointmentId(appointmentId);
        response.setPatientName(appointment.getPatient().getFullName());
        
        if (schedule.getDoctor() != null) {
            if (schedule.getDoctor().getDepartment() != null) {
                response.setDepartmentName(schedule.getDoctor().getDepartment().getName());
                logger.info("科室信息: {}", schedule.getDoctor().getDepartment().getName());
            }
            response.setDoctorName(schedule.getDoctor().getFullName());
            logger.info("医生信息: {}", schedule.getDoctor().getFullName());
        }
        
        response.setCheckInTime(now);
        response.setAppointmentNumber(appointment.getAppointmentNumber());

        logger.info("签到成功 - 预约ID: {}, 患者: {}, 就诊序号: {}, 签到时间: {}", 
                appointmentId, response.getPatientName(), response.getAppointmentNumber(), now);
        logger.info("========== 扫码签到结束 ==========");
        return response;
    }

    /**
     * 清除预约签到时间（管理员功能）
     */
    @Transactional
    public AppointmentResponse clearCheckIn(Integer appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("预约不存在，ID: " + appointmentId));
        
        if (appointment.getStatus() != AppointmentStatus.CHECKED_IN) {
            throw new BadRequestException("该预约状态不是已签到（当前状态：" + appointment.getStatus() + "），无需清除");
        }
        
        // 清除签到时间和状态（改回 scheduled）
        appointment.setCheckInTime(null);
        appointment.setStatus(AppointmentStatus.scheduled); // 改回已预约状态
        appointmentRepository.save(appointment);
        
        return convertToResponseDto(appointment);
    }

    /**
     * 生成随机字符串
     */
    private String generateRandomString(int length) {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }
}