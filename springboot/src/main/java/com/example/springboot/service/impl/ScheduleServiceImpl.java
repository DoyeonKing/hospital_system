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
import com.example.springboot.service.WaitlistService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
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
    
    @Autowired
    @Lazy  // 使用延迟加载避免循环依赖
    private WaitlistService waitlistService;
    
    @Autowired
    private com.example.springboot.repository.AppointmentRepository appointmentRepository;


    
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
        
        // 转换为响应DTO
        // 注意：患者预约界面需要使用数据库中的 bookedSlots（包含锁定的候补号源）
        // 这样当候补锁定了号源后，界面会正确显示"已约满"和"候补"按钮
        return schedulePage.map(schedule -> {
            ScheduleResponse response = ScheduleResponse.fromEntity(schedule);
            // 直接使用数据库中的 bookedSlots（包含锁定的候补号源）
            // 这样当候补锁定了号源后，bookedSlots = totalSlots，界面会显示"已约满"
            response.setBookedSlots(schedule.getBookedSlots());
            return response;
        });
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
        ScheduleResponse response = ScheduleResponse.fromEntity(schedule);
        // 动态统计实际有效预约数（排除已取消的）
        long actualBookedCount = appointmentRepository.countByScheduleAndStatusNotCancelled(schedule);
        response.setBookedSlots((int) actualBookedCount);
        return response;
    }
    
    @Override
    public ScheduleResponse updateSchedule(Integer scheduleId, ScheduleUpdateRequest request) {
        Schedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new RuntimeException("排班不存在"));
        
        // 记录原来的总号源数
        Integer oldTotalSlots = schedule.getTotalSlots();
        boolean slotsIncreased = false;
        
        if (request.getTotalSlots() != null) {
            schedule.setTotalSlots(request.getTotalSlots());
            // 检查号源是否增加
            if (request.getTotalSlots() > oldTotalSlots) {
                slotsIncreased = true;
            }
        }
        if (request.getFee() != null) {
            schedule.setFee(request.getFee());
        }
        
        Schedule savedSchedule = scheduleRepository.save(schedule);
        
        // 如果号源数量增加了，尝试触发候补自动填充
        if (slotsIncreased) {
            System.out.println("号源数量从 " + oldTotalSlots + " 增加到 " + request.getTotalSlots() + "，触发候补填充");
            try {
                // 尝试填充多个候补（根据新增的号源数量）
                int slotsToFill = request.getTotalSlots() - oldTotalSlots;
                for (int i = 0; i < slotsToFill; i++) {
                    // 检查是否还有空位
                    Schedule refreshedSchedule = scheduleRepository.findById(scheduleId)
                            .orElseThrow(() -> new RuntimeException("排班不存在"));
                    if (refreshedSchedule.getBookedSlots() < refreshedSchedule.getTotalSlots()) {
                        waitlistService.createAppointmentFromWaitlist(scheduleId);
                    } else {
                        System.out.println("号源已满，停止填充候补");
                        break;
                    }
                }
            } catch (Exception e) {
                System.err.println("触发候补填充失败: " + e.getMessage());
                e.printStackTrace();
            }
        }
        
        // 返回时使用动态统计的已预约数
        ScheduleResponse response = ScheduleResponse.fromEntity(savedSchedule);
        long actualBookedCount = appointmentRepository.countByScheduleAndStatusNotCancelled(savedSchedule);
        response.setBookedSlots((int) actualBookedCount);
        
        return response;
    }
    
    @Override
    public List<ScheduleResponse> batchUpdateSchedules(ScheduleBatchUpdateRequest request) {
        return request.getUpdates().stream()
                .map(updateItem -> {
                    Schedule schedule = scheduleRepository.findById(updateItem.getScheduleId())
                            .orElseThrow(() -> new RuntimeException("排班不存在: " + updateItem.getScheduleId()));
                    
                    // 记录原来的总号源数
                    Integer oldTotalSlots = schedule.getTotalSlots();
                    boolean slotsIncreased = false;
                    
                    if (updateItem.getTotalSlots() != null) {
                        schedule.setTotalSlots(updateItem.getTotalSlots());
                        // 检查号源是否增加
                        if (updateItem.getTotalSlots() > oldTotalSlots) {
                            slotsIncreased = true;
                        }
                    }
                    if (updateItem.getFee() != null) {
                        schedule.setFee(updateItem.getFee());
                    }
                    
                    Schedule savedSchedule = scheduleRepository.save(schedule);
                    
                    // 如果号源数量增加了，尝试触发候补自动填充
                    if (slotsIncreased) {
                        System.out.println("批量更新：号源数量从 " + oldTotalSlots + " 增加到 " + updateItem.getTotalSlots() + "，触发候补填充");
                        try {
                            // 尝试填充多个候补（根据新增的号源数量）
                            int slotsToFill = updateItem.getTotalSlots() - oldTotalSlots;
                            for (int i = 0; i < slotsToFill; i++) {
                                // 检查是否还有空位
                                Schedule refreshedSchedule = scheduleRepository.findById(updateItem.getScheduleId())
                                        .orElseThrow(() -> new RuntimeException("排班不存在"));
                                if (refreshedSchedule.getBookedSlots() < refreshedSchedule.getTotalSlots()) {
                                    waitlistService.createAppointmentFromWaitlist(updateItem.getScheduleId());
                                } else {
                                    System.out.println("号源已满，停止填充候补");
                                    break;
                                }
                            }
                        } catch (Exception e) {
                            System.err.println("批量更新：触发候补填充失败: " + e.getMessage());
                            e.printStackTrace();
                        }
                    }
                    
                    // 返回时使用动态统计的已预约数
                    ScheduleResponse response = ScheduleResponse.fromEntity(savedSchedule);
                    long actualBookedCount = appointmentRepository.countByScheduleAndStatusNotCancelled(savedSchedule);
                    response.setBookedSlots((int) actualBookedCount);
                    
                    return response;
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
        // 注意：患者预约界面需要使用数据库中的 bookedSlots（包含锁定的候补号源）
        return schedulePage.map(schedule -> {
            ScheduleResponse response = ScheduleResponse.fromEntity(schedule);
            // 直接使用数据库中的 bookedSlots（包含锁定的候补号源）
            response.setBookedSlots(schedule.getBookedSlots());
            return response;
        });
    }

    @Override
    @Transactional(readOnly = true)
    public List<WorkHoursResponse> getDoctorWorkHours(Integer doctorId, String startDate, String endDate) {
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
        Pageable pageable = PageRequest.of(0, 1000); // 获取所有数据
        Page<Schedule> schedulePage = scheduleRepository.findSchedulesByDoctorIdAndDateRange(
                doctorId, start, end, pageable);
        
        List<WorkHoursResponse> workHoursList = new ArrayList<>();
        
        // 按日期分组统计
        Map<String, List<Schedule>> schedulesByDate = schedulePage.getContent().stream()
                .collect(Collectors.groupingBy(s -> s.getScheduleDate().toString()));
        
        for (Map.Entry<String, List<Schedule>> entry : schedulesByDate.entrySet()) {
            String date = entry.getKey();
            List<Schedule> schedules = entry.getValue();
            
            // 按班段分组（上午/下午）
            Map<String, List<Schedule>> schedulesByShift = schedules.stream()
                    .collect(Collectors.groupingBy(s -> {
                        int hour = s.getSlot().getStartTime().getHour();
                        return hour < 12 ? "上午" : "下午";
                    }));
            
            for (Map.Entry<String, List<Schedule>> shiftEntry : schedulesByShift.entrySet()) {
                String shift = shiftEntry.getKey();
                List<Schedule> shiftSchedules = shiftEntry.getValue();
                
                WorkHoursResponse response = new WorkHoursResponse();
                response.setWorkDate(date);
                response.setSegmentLabel(shift);
                
                // 计算首诊和末诊时间
                String firstTime = shiftSchedules.stream()
                        .map(s -> s.getSlot().getStartTime().toString())
                        .min(String::compareTo)
                        .orElse("");
                String lastTime = shiftSchedules.stream()
                        .map(s -> s.getSlot().getEndTime().toString())
                        .max(String::compareTo)
                        .orElse("");
                
                response.setFirstCallDisplay(firstTime);
                response.setLastEndDisplay(lastTime);
                
                // 计算工时（简化计算：末诊时间 - 首诊时间）
                double hours = calculateHours(firstTime, lastTime);
                response.setRawHours(hours);
                response.setRegHours(hours + 0.5); // 加上缓冲时间
                
                // 统计接诊人次（已预约数量）
                int visitCount = shiftSchedules.stream()
                        .mapToInt(Schedule::getBookedSlots)
                        .sum();
                response.setVisitCount(visitCount);
                
                // 判断是否夜班（开始时间在18:00之后）
                boolean isNight = !firstTime.isEmpty() && Integer.parseInt(firstTime.split(":")[0]) >= 18;
                response.setNightFlag(isNight);
                
                // 诊室/地点
                String locations = shiftSchedules.stream()
                        .map(s -> s.getLocation().getLocationName())
                        .distinct()
                        .collect(Collectors.joining(", "));
                response.setLocations(locations);
                
                // 绩效点数（简化计算：工时 * 10）
                response.setPerformancePoints(response.getRegHours() * 10);
                
                workHoursList.add(response);
            }
        }
        
        // 按日期排序
        workHoursList.sort((a, b) -> b.getWorkDate().compareTo(a.getWorkDate()));
        
        return workHoursList;
    }
    
    private double calculateHours(String startTime, String endTime) {
        try {
            String[] startParts = startTime.split(":");
            String[] endParts = endTime.split(":");
            
            int startMinutes = Integer.parseInt(startParts[0]) * 60 + Integer.parseInt(startParts[1]);
            int endMinutes = Integer.parseInt(endParts[0]) * 60 + Integer.parseInt(endParts[1]);
            
            return (endMinutes - startMinutes) / 60.0;
        } catch (Exception e) {
            return 0.0;
        }
    }
}

