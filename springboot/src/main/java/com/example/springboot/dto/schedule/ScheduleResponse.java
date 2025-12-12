package com.example.springboot.dto.schedule;

import com.example.springboot.dto.fee.FeeDetailDTO; // 导入费用详情DTO
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.enums.PatientType; // 导入患者类型
import com.example.springboot.util.FeeCalculator; // 导入费用计算工具
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 排班响应DTO
 */
@Data
public class ScheduleResponse {
    
    private Integer scheduleId;
    private Integer doctorId;
    private String doctorIdentifier;
    private LocalDate scheduleDate;
    private Integer slotId;
    private Integer locationId;
    private String location;
    private Integer totalSlots;
    private Integer bookedSlots;
    private Integer remainingSlots; // 剩余号源数（totalSlots - bookedSlots）
    private java.math.BigDecimal fee;
    private String status;
    private String remarks;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private FeeDetailDTO feeDetail; // 费用详情（可选，当需要患者类型时计算）
    
    // 关联查询字段
    private String doctorName;
    private String doctorTitle;
    private String doctorSpecialty; // 医生擅长领域
    private String doctorPhotoUrl;  // 医生头像
    private Integer departmentId;
    private String departmentName;
    private String slotName;
    private LocalTime startTime;
    private LocalTime endTime;
    
    /**
     * 从实体转换为响应DTO
     */
    public static ScheduleResponse fromEntity(Schedule schedule) {
        ScheduleResponse response = new ScheduleResponse();
        response.setScheduleId(schedule.getScheduleId());
        response.setScheduleDate(schedule.getScheduleDate());
        response.setTotalSlots(schedule.getTotalSlots());
        response.setBookedSlots(schedule.getBookedSlots());
        // 计算剩余号源数（包含锁定的候补号源）
        if (schedule.getTotalSlots() != null && schedule.getBookedSlots() != null) {
            response.setRemainingSlots(Math.max(0, schedule.getTotalSlots() - schedule.getBookedSlots()));
        }
        response.setFee(schedule.getFee());
        response.setStatus(schedule.getStatus() != null ? schedule.getStatus().name() : null);
        response.setRemarks(schedule.getRemarks());
        response.setCreatedAt(schedule.getCreatedAt());
        response.setUpdatedAt(schedule.getUpdatedAt());
        
        // 安全地访问关联对象
        if (schedule.getDoctor() != null) {
            response.setDoctorId(schedule.getDoctor().getDoctorId());
            response.setDoctorIdentifier(schedule.getDoctor().getIdentifier());
            response.setDoctorName(schedule.getDoctor().getFullName());
            response.setDoctorTitle(schedule.getDoctor().getTitle());
            response.setDoctorSpecialty(schedule.getDoctor().getSpecialty());
            response.setDoctorPhotoUrl(schedule.getDoctor().getPhotoUrl());
            
            if (schedule.getDoctor().getDepartment() != null) {
                response.setDepartmentId(schedule.getDoctor().getDepartment().getDepartmentId());
                response.setDepartmentName(schedule.getDoctor().getDepartment().getName());
            }
        }
        
        if (schedule.getSlot() != null) {
            response.setSlotId(schedule.getSlot().getSlotId());
            response.setSlotName(schedule.getSlot().getSlotName());
            response.setStartTime(schedule.getSlot().getStartTime());
            response.setEndTime(schedule.getSlot().getEndTime());
        }
        
        if (schedule.getLocation() != null) {
            response.setLocationId(schedule.getLocation().getLocationId());
            response.setLocation(schedule.getLocation().getLocationName());
        }
        
        return response;
    }
    
    /**
     * 从实体转换为响应DTO（包含患者类型，用于计算报销）
     */
    public static ScheduleResponse fromEntityWithPatientType(Schedule schedule, PatientType patientType) {
        ScheduleResponse response = fromEntity(schedule);
        
        // 计算费用详情
        if (schedule.getFee() != null && patientType != null) {
            response.feeDetail = calculateFeeDetail(schedule.getFee(), patientType);
        }
        
        return response;
    }
    
    /**
     * 计算费用详情
     */
    private static FeeDetailDTO calculateFeeDetail(BigDecimal originalFee, PatientType patientType) {
        BigDecimal reimbursementRate = FeeCalculator.getReimbursementRate(patientType);
        BigDecimal reimbursementAmount = FeeCalculator.calculateReimbursementAmount(originalFee, patientType);
        BigDecimal actualFee = FeeCalculator.calculateActualFee(originalFee, patientType);
        String patientTypeName = FeeCalculator.getPatientTypeName(patientType);
        
        return new FeeDetailDTO(originalFee, reimbursementRate, reimbursementAmount, actualFee, patientTypeName);
    }
}
