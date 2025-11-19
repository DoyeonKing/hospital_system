package com.example.springboot.service.impl;

import com.example.springboot.dto.schedule.*;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Location;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.repository.LocationRepository;
import com.example.springboot.repository.ScheduleRepository;
import com.example.springboot.repository.TimeSlotRepository;
import com.example.springboot.service.ScheduleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 排班服务实现
 */
@Service
@Transactional
public class ScheduleServiceImpl implements ScheduleService {
    
    @Autowired
    private ScheduleRepository scheduleRepository;

    @Autowired
    private DoctorRepository doctorRepository;

    @Autowired
    private TimeSlotRepository timeSlotRepository;

    @Autowired
    private LocationRepository locationRepository;


    
//    @Override
//    @Transactional(readOnly = true)
//    public Page<ScheduleResponse> getSchedules(ScheduleListRequest request) {
//        // 创建分页参数
//        Pageable pageable = PageRequest.of(0, 100); // 设置较大的页面大小
//
//        // 执行查询
//        Page<Schedule> schedulePage = scheduleRepository.findSchedulesWithDetails(
//                request.getDepartmentId(),
//                request.getStartDate(),
//                request.getEndDate(),
//                null, // 不筛选状态
//                pageable
//        );
//
//        // 转换为响应DTO
//        return schedulePage.map(ScheduleResponse::fromEntity);
//    }



    @Override
    @Transactional(readOnly = true)
    public Page<ScheduleResponse> getSchedules(ScheduleListRequest request, Pageable pageable) {
        // 使用传入的分页参数
        Page<Schedule> schedulePage = scheduleRepository.findSchedulesWithDetails(
                request.getDepartmentId(),
                request.getStartDate(),
                request.getEndDate(),
                null, // 不筛选状态
                pageable
        );
        return schedulePage.map(ScheduleResponse::fromEntity);
    }

    // 保留原有方法并复用新方法
    @Override
    @Transactional(readOnly = true)
    public Page<ScheduleResponse> getSchedules(ScheduleListRequest request) {
        // 默认分页参数
        Pageable defaultPageable = PageRequest.of(0, 100);
        return getSchedules(request, defaultPageable);
    }
    
    @Override
    @Transactional(readOnly = true)
    public ScheduleResponse getScheduleById(Integer scheduleId) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("排班不存在"));
        return ScheduleResponse.fromEntity(schedule);
    }
    
    @Override
    public ScheduleResponse updateSchedule(Integer scheduleId, ScheduleUpdateRequest request) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("排班不存在"));
        
        if (request.getTotalSlots() != null) {
            schedule.setTotalSlots(request.getTotalSlots());
        }
        if (request.getFee() != null) {
            schedule.setFee(request.getFee());
        }
        
        Schedule savedSchedule = scheduleRepository.save(schedule);
        return ScheduleResponse.fromEntity(savedSchedule);
    }
    
    @Override
    public List<ScheduleResponse> batchUpdateSchedules(ScheduleBatchUpdateRequest request) {
        return request.getUpdates().stream()
                .map(updateItem -> {
                    Schedule schedule = scheduleRepository.findById(updateItem.getScheduleId())
                            .orElseThrow(() -> new RuntimeException("排班不存在: " + updateItem.getScheduleId()));
                    
                    if (updateItem.getTotalSlots() != null) {
                        schedule.setTotalSlots(updateItem.getTotalSlots());
                    }
                    if (updateItem.getFee() != null) {
                        schedule.setFee(updateItem.getFee());
                    }
                    
                    Schedule savedSchedule = scheduleRepository.save(schedule);
                    return ScheduleResponse.fromEntity(savedSchedule);
                })
                .collect(Collectors.toList());
    }
    
//    @Override
//    public ScheduleResponse createSchedule(ScheduleResponse request) {
//        // 这里需要根据实际需求实现创建逻辑
//        throw new UnsupportedOperationException("创建排班功能暂未实现");
//    }
    
    @Override
    public void deleteSchedule(Integer scheduleId) {
        if (!scheduleRepository.existsById(scheduleId)) {
            throw new RuntimeException("排班不存在");
        }
        scheduleRepository.deleteById(scheduleId);
    }

    @Override
    public void deleteScheduleByParams(ScheduleDeleteRequest request) {
        // 1. 获取关联实体
        Doctor doctor = doctorRepository.findById(request.getDoctorId())
                .orElseThrow(() -> new ResourceNotFoundException("医生不存在: " + request.getDoctorId()));

        TimeSlot slot = timeSlotRepository.findById(request.getSlotId())
                .orElseThrow(() -> new ResourceNotFoundException("时间段不存在: " + request.getSlotId()));

        Location location = locationRepository.findById(request.getLocationId())
                .orElseThrow(() -> new ResourceNotFoundException("就诊地点不存在: " + request.getLocationId()));

        // 2. 查询符合条件的排班
        Schedule schedule = scheduleRepository
                .findByDoctorAndScheduleDateAndSlot(doctor, request.getScheduleDate(), slot)
                .orElseThrow(() -> new ResourceNotFoundException("未找到符合条件的排班记录"));

        // 3. 校验排班地点是否匹配（避免同一医生同一时段在不同地点的排班被误删）
        if (!schedule.getLocation().getLocationId().equals(request.getLocationId())) {
            throw new BadRequestException("排班地点不匹配，无法删除");
        }

        // 4. 执行删除
        scheduleRepository.delete(schedule);
    }

    @Override
    public ScheduleResponse createSchedule(ScheduleCreateRequest request) {
        // 1. 验证并获取关联实体
        Doctor doctor = doctorRepository.findById(request.getDoctorId())
                .orElseThrow(() -> new ResourceNotFoundException("医生不存在: " + request.getDoctorId()));

        TimeSlot slot = timeSlotRepository.findById(request.getSlotId())
                .orElseThrow(() -> new ResourceNotFoundException("时间段不存在: " + request.getSlotId()));

        Location location = locationRepository.findById(request.getLocationId())
                .orElseThrow(() -> new ResourceNotFoundException("就诊地点不存在: " + request.getLocationId()));

        // 2. 检查是否存在重复排班（根据唯一约束）
        Optional<Schedule> existingSchedule = scheduleRepository
                .findByDoctorAndScheduleDateAndSlot(doctor, request.getScheduleDate(), slot);
        if (existingSchedule.isPresent()) {
            throw new BadRequestException("该医生在指定日期和时间段已存在排班");
        }

        // 3. 创建排班实体
        Schedule schedule = new Schedule();
        schedule.setDoctor(doctor);
        schedule.setScheduleDate(request.getScheduleDate());
        schedule.setSlot(slot);
        schedule.setLocation(location);
        schedule.setTotalSlots(request.getTotalSlots());
        schedule.setBookedSlots(0); // 初始已预约数为0
        schedule.setFee(request.getFee());
        schedule.setStatus(ScheduleStatus.available); // 初始状态为可用
        schedule.setRemarks(request.getRemarks());

        // 4. 保存到数据库
        Schedule savedSchedule = scheduleRepository.save(schedule);

        // 5. 转换为响应DTO并返回
        return ScheduleResponse.fromEntity(savedSchedule);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ScheduleResponse> getSchedulesByDoctorId(Integer doctorId, String startDate, String endDate, Pageable pageable) {
        // 解析日期参数
        java.time.LocalDate start = null;
        java.time.LocalDate end = null;
        
        if (startDate != null && !startDate.isEmpty()) {
            try {
                start = java.time.LocalDate.parse(startDate);
            } catch (Exception e) {
                System.err.println("解析开始日期失败: " + startDate);
            }
        }
        
        if (endDate != null && !endDate.isEmpty()) {
            try {
                end = java.time.LocalDate.parse(endDate);
            } catch (Exception e) {
                System.err.println("解析结束日期失败: " + endDate);
            }
        }
        
        // 查询排班数据
        Page<Schedule> schedulePage = scheduleRepository.findSchedulesByDoctorIdAndDateRange(
                doctorId, start, end, pageable);
        
        // 转换为响应DTO
        return schedulePage.map(ScheduleResponse::fromEntity);
    }
}

