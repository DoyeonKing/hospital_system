package com.example.springboot.service;

import com.example.springboot.dto.leaverequest.LeaveRequestCreateRequest;
import com.example.springboot.dto.leaverequest.LeaveRequestResponse;
import com.example.springboot.dto.leaverequest.LeaveRequestUpdateRequest;
import com.example.springboot.entity.Admin;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.LeaveRequest;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.enums.LeaveRequestStatus;
import com.example.springboot.entity.enums.ScheduleStatus;
import com.example.springboot.entity.enums.DoctorStatus;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.AdminRepository;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.repository.LeaveRequestRepository;
import com.example.springboot.repository.ScheduleRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class LeaveRequestService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final DoctorRepository doctorRepository;
    private final AdminRepository adminRepository;
    private final ScheduleRepository scheduleRepository;
    private final DoctorService doctorService; // For converting doctor entity to DTO
    private final AdminService adminService; // For converting admin entity to DTO
    private final NotificationService notificationService; // For sending notifications

    @Autowired
    public LeaveRequestService(LeaveRequestRepository leaveRequestRepository,
                               DoctorRepository doctorRepository,
                               AdminRepository adminRepository,
                               ScheduleRepository scheduleRepository,
                               DoctorService doctorService,
                               AdminService adminService,
                               NotificationService notificationService) {
        this.leaveRequestRepository = leaveRequestRepository;
        this.doctorRepository = doctorRepository;
        this.adminRepository = adminRepository;
        this.scheduleRepository = scheduleRepository;
        this.doctorService = doctorService;
        this.adminService = adminService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<LeaveRequestResponse> findAllLeaveRequests() {
        List<LeaveRequest> requests = leaveRequestRepository.findAll();
        // 强制加载医生信息以避免LazyInitializationException
        requests.forEach(request -> {
            if (request.getDoctor() != null) {
                request.getDoctor().getFullName(); // 触发lazy loading
                if (request.getDoctor().getDepartment() != null) {
                    request.getDoctor().getDepartment().getName(); // 触发department lazy loading
                }
            }
            if (request.getApprover() != null) {
                request.getApprover().getFullName(); // 触发approver lazy loading
            }
        });
        return requests.stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public LeaveRequestResponse findLeaveRequestById(Integer id) {
        LeaveRequest leaveRequest = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("LeaveRequest not found with id " + id));
        return convertToResponseDto(leaveRequest);
    }

    @Transactional(readOnly = true)
    public List<LeaveRequestResponse> findLeaveRequestsByDoctor(Integer doctorId) {
        Doctor doctor = doctorRepository.findById(doctorId)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + doctorId));
        
        // 检查医生是否已删除
        if (doctor.getStatus() == DoctorStatus.deleted) {
            throw new BadRequestException("医生已删除，无法查询请假记录");
        }
        
        List<LeaveRequest> requests = leaveRequestRepository.findByDoctor(doctor);
        // 强制加载医生和审批人信息以避免LazyInitializationException
        requests.forEach(request -> {
            if (request.getDoctor() != null) {
                request.getDoctor().getFullName(); // 触发lazy loading
                if (request.getDoctor().getDepartment() != null) {
                    request.getDoctor().getDepartment().getName(); // 触发department lazy loading
                }
            }
            if (request.getApprover() != null) {
                request.getApprover().getFullName(); // 触发approver lazy loading
            }
        });
        
        return requests.stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<LeaveRequestResponse> findLeaveRequestsByStatus(LeaveRequestStatus status) {
        List<LeaveRequest> requests = leaveRequestRepository.findByStatus(status);
        // 强制加载医生信息以避免LazyInitializationException
        requests.forEach(request -> {
            if (request.getDoctor() != null) {
                request.getDoctor().getFullName(); // 触发lazy loading
                if (request.getDoctor().getDepartment() != null) {
                    request.getDoctor().getDepartment().getName(); // 触发department lazy loading
                }
            }
            if (request.getApprover() != null) {
                request.getApprover().getFullName(); // 触发approver lazy loading
            }
        });
        return requests.stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public LeaveRequestResponse createLeaveRequest(LeaveRequestCreateRequest request) {
        Doctor doctor = doctorRepository.findById(request.getDoctorId())
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + request.getDoctorId()));

        if (request.getStartTime().isAfter(request.getEndTime())) {
            throw new BadRequestException("Start time cannot be after end time.");
        }

        // 可以添加逻辑：检查医生在申请时段是否有已安排的排班，如果有，需要特殊处理
        // List<Schedule> conflictingSchedules = scheduleRepository.findByDoctorAndScheduleDateBetween(...)
        // 简单处理：当前仅创建申请

        LeaveRequest leaveRequest = new LeaveRequest();
        BeanUtils.copyProperties(request, leaveRequest, "doctorId");
        leaveRequest.setDoctor(doctor);
        leaveRequest.setStatus(LeaveRequestStatus.PENDING); // 初始状态为待审批
        leaveRequest.setCreatedAt(LocalDateTime.now());
        leaveRequest.setUpdatedAt(LocalDateTime.now());
        return convertToResponseDto(leaveRequestRepository.save(leaveRequest));
    }

    @Transactional
    public LeaveRequestResponse updateLeaveRequest(Integer id, LeaveRequestUpdateRequest request) {
        System.out.println("=== Service: updateLeaveRequest ===");
        System.out.println("请假申请ID: " + id);
        System.out.println("请求状态: " + request.getStatus());
        System.out.println("审批人ID: " + request.getApproverId());
        
        LeaveRequest existingRequest = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("LeaveRequest not found with id " + id));

        System.out.println("现有请假状态: " + existingRequest.getStatus());
        
        // 只有PENDING状态的申请可以修改或审批
        if (existingRequest.getStatus() != LeaveRequestStatus.PENDING && request.getStatus() != null && request.getStatus() != existingRequest.getStatus()) {
            throw new BadRequestException("Only pending leave requests can be updated or approved/rejected.");
        }

        if (request.getRequestType() != null) existingRequest.setRequestType(request.getRequestType());
        if (request.getStartTime() != null) existingRequest.setStartTime(request.getStartTime());
        if (request.getEndTime() != null) existingRequest.setEndTime(request.getEndTime());
        if (request.getReason() != null) existingRequest.setReason(request.getReason());

        if (request.getStartTime() != null && request.getEndTime() != null && request.getStartTime().isAfter(request.getEndTime())) {
            throw new BadRequestException("Start time cannot be after end time.");
        }

        if (request.getStatus() != null) {
            System.out.println("设置新状态: " + request.getStatus());
            existingRequest.setStatus(request.getStatus());
            if (request.getStatus() == LeaveRequestStatus.APPROVED) {
                System.out.println("处理批准逻辑...");
                // 如果申请被批准，需要更新相关排班的状态
                updateAffectedSchedules(existingRequest.getDoctor(), existingRequest.getStartTime(), existingRequest.getEndTime(), ScheduleStatus.cancelled);
                
                // 发送批准通知
                try {
                    notificationService.sendLeaveApprovedNotification(
                        existingRequest.getDoctor().getDoctorId(),
                        existingRequest.getRequestId(),
                        existingRequest.getStartTime().toString(),
                        existingRequest.getEndTime().toString(),
                        request.getApproverComments()
                    );
                } catch (Exception e) {
                    // 通知发送失败不影响主流程
                    System.err.println("Failed to send leave approved notification: " + e.getMessage());
                }
            } else if (request.getStatus() == LeaveRequestStatus.REJECTED) {
                // 如果被拒绝，不做排班更改
                
                // 发送拒绝通知
                try {
                    notificationService.sendLeaveRejectedNotification(
                        existingRequest.getDoctor().getDoctorId(),
                        existingRequest.getRequestId(),
                        existingRequest.getStartTime().toString(),
                        existingRequest.getEndTime().toString(),
                        request.getApproverComments()
                    );
                } catch (Exception e) {
                    // 通知发送失败不影响主流程
                    System.err.println("Failed to send leave rejected notification: " + e.getMessage());
                }
            }
        }

        if (request.getApproverId() != null) {
            Admin approver = adminRepository.findById(request.getApproverId())
                    .orElseThrow(() -> new ResourceNotFoundException("Approver Admin not found with id " + request.getApproverId()));
            existingRequest.setApprover(approver);
        }
        if (request.getApproverComments() != null) existingRequest.setApproverComments(request.getApproverComments());

        existingRequest.setUpdatedAt(LocalDateTime.now());
        LeaveRequest savedRequest = leaveRequestRepository.save(existingRequest);
        System.out.println("保存后的状态: " + savedRequest.getStatus());
        System.out.println("保存后的审批人ID: " + (savedRequest.getApprover() != null ? savedRequest.getApprover().getAdminId() : "null"));
        return convertToResponseDto(savedRequest);
    }

    @Transactional
    public void deleteLeaveRequest(Integer id) {
        if (!leaveRequestRepository.existsById(id)) {
            throw new ResourceNotFoundException("LeaveRequest not found with id " + id);
        }
        leaveRequestRepository.deleteById(id);
    }

    /**
     * Helper method to update schedules affected by an approved leave request.
     */
    private void updateAffectedSchedules(Doctor doctor, LocalDateTime startTime, LocalDateTime endTime, ScheduleStatus newStatus) {
        java.time.LocalDate startDate = startTime.toLocalDate();
        java.time.LocalDate endDate = endTime.toLocalDate();

        List<Schedule> affectedSchedules = scheduleRepository.findByDoctorAndScheduleDateBetween(doctor, startDate, endDate);

        for (Schedule schedule : affectedSchedules) {
            LocalDateTime scheduleStartTime = LocalDateTime.of(schedule.getScheduleDate(), schedule.getSlot().getStartTime());
            LocalDateTime scheduleEndTime = LocalDateTime.of(schedule.getScheduleDate(), schedule.getSlot().getEndTime());

            // 检查排班时间是否与请假时间段重叠
            boolean overlaps = !scheduleEndTime.isBefore(startTime) && !scheduleStartTime.isAfter(endTime);

            if (overlaps) {
                schedule.setStatus(newStatus);
                scheduleRepository.save(schedule);
                // TODO: Handle existing appointments for these canceled schedules (e.g., notify patients, automatically cancel)
            }
        }
    }


    private LeaveRequestResponse convertToResponseDto(LeaveRequest leaveRequest) {
        LeaveRequestResponse response = new LeaveRequestResponse();
        BeanUtils.copyProperties(leaveRequest, response, "doctor", "approver");

        if (leaveRequest.getDoctor() != null) {
            response.setDoctor(doctorService.convertToResponseDto(leaveRequest.getDoctor()));
        }
        if (leaveRequest.getApprover() != null) {
            response.setApprover(adminService.findAdminById(leaveRequest.getApprover().getAdminId())); // 避免无限递归，这里直接通过ID获取简单AdminResponse
        }
        return response;
    }
}
