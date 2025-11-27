package com.example.springboot.service;

import com.example.springboot.dto.ScheduleListRequest;
import com.example.springboot.dto.ScheduleResponse;
import com.example.springboot.dto.ScheduleUpdateRequest;
import com.example.springboot.dto.ScheduleBatchUpdateRequest;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * 排班服务接口
 */
public interface ScheduleService {
    
    /**
     * 获取排班列表
     */
    Page<ScheduleResponse> getSchedules(ScheduleListRequest request);
    
    /**
     * 根据ID获取排班详情
     */
    ScheduleResponse getScheduleById(Integer scheduleId);
    
    /**
     * 更新排班
     */
    ScheduleResponse updateSchedule(Integer scheduleId, ScheduleUpdateRequest request);
    
    /**
     * 批量更新排班
     */
    List<ScheduleResponse> batchUpdateSchedules(ScheduleBatchUpdateRequest request);
    
    /**
     * 创建排班
     */
    ScheduleResponse createSchedule(ScheduleResponse request);
    
    /**
     * 删除排班
     */
    void deleteSchedule(Integer scheduleId);
}