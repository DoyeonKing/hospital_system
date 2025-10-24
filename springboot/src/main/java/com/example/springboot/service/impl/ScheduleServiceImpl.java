package com.example.springboot.service.impl;

import com.example.springboot.dto.*;
import com.example.springboot.entity.Schedule;
import com.example.springboot.repository.ScheduleRepository;
import com.example.springboot.service.ScheduleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 排班服务实现
 */
@Service
@Transactional
public class ScheduleServiceImpl implements ScheduleService {
    
    @Autowired
    private ScheduleRepository scheduleRepository;
    
    @Override
    @Transactional(readOnly = true)
    public Page<ScheduleResponse> getSchedules(ScheduleListRequest request) {
        // 创建分页参数
        Pageable pageable = PageRequest.of(0, 100); // 设置较大的页面大小
        
        // 执行查询
        Page<Schedule> schedulePage = scheduleRepository.findSchedulesWithDetails(
                request.getDepartmentId(),
                request.getStartDate(),
                request.getEndDate(),
                null, // 不筛选状态
                pageable
        );
        
        // 转换为响应DTO
        return schedulePage.map(ScheduleResponse::fromEntity);
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
    
    @Override
    public ScheduleResponse createSchedule(ScheduleResponse request) {
        // 这里需要根据实际需求实现创建逻辑
        throw new UnsupportedOperationException("创建排班功能暂未实现");
    }
    
    @Override
    public void deleteSchedule(Integer scheduleId) {
        if (!scheduleRepository.existsById(scheduleId)) {
            throw new RuntimeException("排班不存在");
        }
        scheduleRepository.deleteById(scheduleId);
    }
}
