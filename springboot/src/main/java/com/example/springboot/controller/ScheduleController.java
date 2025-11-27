package com.example.springboot.controller;

import com.example.springboot.dto.*;
import com.example.springboot.service.ScheduleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 排班管理控制器
 */
@RestController
@RequestMapping("/api/schedules")
@CrossOrigin(origins = "*")
public class ScheduleController {
    
    @Autowired
    private ScheduleService scheduleService;
    
    /**
     * 获取排班列表
     */
    @GetMapping
    public ResponseEntity<Page<ScheduleResponse>> getSchedules(
            @RequestParam(required = false) Integer departmentId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {
        
        try {
            System.out.println("=== 后端接收到的请求参数 ===");
            System.out.println("departmentId: " + departmentId + " (类型: " + (departmentId != null ? departmentId.getClass().getSimpleName() : "null") + ")");
            System.out.println("startDate: " + startDate + " (类型: " + (startDate != null ? startDate.getClass().getSimpleName() : "null") + ")");
            System.out.println("endDate: " + endDate + " (类型: " + (endDate != null ? endDate.getClass().getSimpleName() : "null") + ")");
            System.out.println("=============================");
            
            ScheduleListRequest request = new ScheduleListRequest();
            request.setDepartmentId(departmentId);
            if (startDate != null && !startDate.isEmpty()) {
                try {
                    java.time.LocalDate parsedStartDate = java.time.LocalDate.parse(startDate);
                    request.setStartDate(parsedStartDate);
                    System.out.println("成功解析开始日期: " + parsedStartDate);
                } catch (Exception e) {
                    System.err.println("解析开始日期失败: " + startDate + ", 错误: " + e.getMessage());
                }
            }
            if (endDate != null && !endDate.isEmpty()) {
                try {
                    java.time.LocalDate parsedEndDate = java.time.LocalDate.parse(endDate);
                    request.setEndDate(parsedEndDate);
                    System.out.println("成功解析结束日期: " + parsedEndDate);
                } catch (Exception e) {
                    System.err.println("解析结束日期失败: " + endDate + ", 错误: " + e.getMessage());
                }
            }
            
            System.out.println("准备调用服务层...");
            Page<ScheduleResponse> schedules = scheduleService.getSchedules(request);
            System.out.println("查询结果: " + schedules.getTotalElements() + " 条记录");
            return ResponseEntity.ok(schedules);
        } catch (Exception e) {
            System.err.println("查询排班数据时发生错误:");
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
    
    /**
     * 获取单个排班详情
     */
    @GetMapping("/{id}")
    public ResponseEntity<ScheduleResponse> getScheduleById(@PathVariable Integer id) {
        try {
            ScheduleResponse schedule = scheduleService.getScheduleById(id);
            return ResponseEntity.ok(schedule);
        } catch (Exception e) {
            System.err.println("获取排班详情时发生错误: " + e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }
    
    /**
     * 更新单个排班
     */
    @PutMapping("/{id}")
    public ResponseEntity<ScheduleResponse> updateSchedule(
            @PathVariable Integer id,
            @RequestBody ScheduleUpdateRequest request) {
        try {
            ScheduleResponse schedule = scheduleService.updateSchedule(id, request);
            return ResponseEntity.ok(schedule);
        } catch (Exception e) {
            System.err.println("更新排班时发生错误: " + e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }
    
    /**
     * 批量更新排班
     */
    @PutMapping("/batch-update")
    public ResponseEntity<List<ScheduleResponse>> batchUpdateSchedules(
            @RequestBody ScheduleBatchUpdateRequest request) {
        try {
            System.out.println("收到批量更新请求: " + request.getUpdates().size() + " 条记录");
            List<ScheduleResponse> schedules = scheduleService.batchUpdateSchedules(request);
            System.out.println("批量更新完成: " + schedules.size() + " 条记录");
            return ResponseEntity.ok(schedules);
        } catch (Exception e) {
            System.err.println("批量更新排班时发生错误: " + e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }
    
    /**
     * 创建排班
     */
    @PostMapping
    public ResponseEntity<ScheduleResponse> createSchedule(@RequestBody ScheduleResponse request) {
        try {
            ScheduleResponse schedule = scheduleService.createSchedule(request);
            return ResponseEntity.ok(schedule);
        } catch (Exception e) {
            System.err.println("创建排班时发生错误: " + e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }
    
    /**
     * 删除排班
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Integer id) {
        try {
            scheduleService.deleteSchedule(id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            System.err.println("删除排班时发生错误: " + e.getMessage());
            return ResponseEntity.status(500).build();
        }
    }
}
