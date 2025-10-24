package com.example.springboot.dto;

import com.example.springboot.entity.Schedule;
import lombok.Data;
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
    private LocalDate scheduleDate;
    private Integer slotId;
    private Integer locationId;
    private String location;
    private Integer totalSlots;
    private Integer bookedSlots;
    private java.math.BigDecimal fee;
    private String status;
    private String remarks;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // 关联查询字段
    private String doctorName;
    private String doctorTitle;
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
        response.setFee(schedule.getFee());
        response.setStatus(schedule.getStatus() != null ? schedule.getStatus().name() : null);
        response.setRemarks(schedule.getRemarks());
        response.setCreatedAt(schedule.getCreatedAt());
        response.setUpdatedAt(schedule.getUpdatedAt());
        
        // 安全地访问关联对象
        if (schedule.getDoctor() != null) {
            response.setDoctorId(schedule.getDoctor().getDoctorId());
            response.setDoctorName(schedule.getDoctor().getFullName());
            response.setDoctorTitle(schedule.getDoctor().getTitle());
            
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
}
