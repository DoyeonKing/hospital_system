package com.example.springboot.service.impl;

import com.example.springboot.dto.dashboard.*;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.enums.*;
import com.example.springboot.repository.*;
import com.example.springboot.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final DoctorRepository doctorRepository;
    private final DepartmentRepository departmentRepository;
    private final ScheduleRepository scheduleRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final PatientProfileRepository patientProfileRepository;

    @Override
    @Transactional(readOnly = true)
    public OverviewStatsResponse getOverviewStats() {
        OverviewStatsResponse response = new OverviewStatsResponse();
        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.atTime(LocalTime.MAX);
        
        System.out.println("=== Dashboard Stats Query ===");
        System.out.println("Today: " + today);
        System.out.println("Today Start: " + todayStart);
        System.out.println("Today End: " + todayEnd);

        // 1. 今日挂号量（问诊日期为今天的预约数，不是今天创建的预约数）
        long todayAppointments = appointmentRepository.countBySchedule_ScheduleDate(today);
        // 调试：查询今天创建的预约数量（用于对比）
        long todayCreatedAppointments = appointmentRepository.countByCreatedAtBetween(todayStart, todayEnd);
        System.out.println("今日挂号量（问诊日期为今天）: " + todayAppointments);
        System.out.println("今日创建的预约数（对比）: " + todayCreatedAppointments);
        response.setTodayAppointments(todayAppointments);

        // 2. 今日出诊医生数
        // 先查询排班列表用于调试
        List<Schedule> todaySchedules = scheduleRepository.findActiveSchedulesByDate(today);
        System.out.println("今日排班数量: " + todaySchedules.size());
        if (!todaySchedules.isEmpty()) {
            System.out.println("今日排班详情:");
            todaySchedules.forEach(s -> {
                System.out.println("  - 医生ID: " + (s.getDoctor() != null ? s.getDoctor().getDoctorId() : "NULL") + 
                                 ", 日期: " + s.getScheduleDate() + 
                                 ", 状态: " + s.getStatus());
            });
        }
        long activeDoctorsToday = scheduleRepository.countDistinctDoctorsByScheduleDate(today);
        System.out.println("今日出诊医生数: " + activeDoctorsToday);
        response.setActiveDoctorsToday(activeDoctorsToday);

        // 3. 当前候诊人数（已签到且未完成的总人数，不管日期）
        long pendingPatients = appointmentRepository.countCheckedInAndNotCompleted();
        // 调试：查询所有已签到的预约数（用于对比）
        long allCheckedInCount = appointmentRepository.countByStatusIn(Arrays.asList(AppointmentStatus.CHECKED_IN));
        System.out.println("当前候诊人数（已签到且未完成）: " + pendingPatients);
        System.out.println("所有已签到预约数（对比）: " + allCheckedInCount);
        response.setPendingPatients(pendingPatients);

        // 4. 累计注册用户（统计所有状态不是deleted的患者）
        // 使用自定义查询确保正确统计
        long totalPatients = patientRepository.countTotalActivePatients();
        // 调试：也查询总数和按状态统计
        long allPatientsCount = patientRepository.count();
        System.out.println("累计注册用户（非deleted）: " + totalPatients);
        System.out.println("所有患者总数: " + allPatientsCount);
        response.setTotalPatients(totalPatients);

        // 5. 近7天挂号趋势
        LocalDate sevenDaysAgo = today.minusDays(6);
        List<Map<String, Object>> trendData = appointmentRepository.countByDateRangeGroupByDate(
            sevenDaysAgo.atStartOfDay(), todayEnd
        );
        
        List<String> dates = new ArrayList<>();
        List<Integer> counts = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");
        
        for (int i = 0; i < 7; i++) {
            LocalDate date = sevenDaysAgo.plusDays(i);
            String dateStr = date.format(formatter);
            dates.add(dateStr);
            
            // 查找对应日期的数据
            Optional<Map<String, Object>> dayData = trendData.stream()
                .filter(d -> {
                    LocalDate dDate = ((java.sql.Date) d.get("date")).toLocalDate();
                    return dDate.equals(date);
                })
                .findFirst();
            
            counts.add(dayData.map(d -> ((Number) d.get("count")).intValue()).orElse(0));
        }
        
        response.setLast7DaysDates(dates);
        response.setLast7DaysCounts(counts);

        // 6. 支付状态分布
        List<Map<String, Object>> paymentStats = appointmentRepository.countByPaymentStatus();
        List<SimpleNameValue> paymentStatus = paymentStats.stream()
            .map(stat -> {
                SimpleNameValue item = new SimpleNameValue();
                PaymentStatus statusEnum = (PaymentStatus) stat.get("status");
                String statusName;
                if (statusEnum == null) {
                    statusName = "未知";
                } else {
                    switch (statusEnum) {
                        case paid -> statusName = "已支付";
                        case unpaid -> statusName = "待支付";
                        case refunded -> statusName = "退款";
                        default -> statusName = statusEnum.name();
                    }
                }
                item.setName(statusName);
                item.setValue(((Number) stat.get("count")).longValue());
                return item;
            })
            .collect(Collectors.toList());
        response.setPaymentStatus(paymentStatus);

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public DoctorsStatsResponse getDoctorsStats() {
        DoctorsStatsResponse response = new DoctorsStatsResponse();
        LocalDate today = LocalDate.now();

        // 1. 医生总数
        long totalDoctors = doctorRepository.countByStatusNot(DoctorStatus.deleted);
        response.setTotalDoctors(totalDoctors);

        // 2. 今日请假人数
        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.atTime(LocalTime.MAX);
        long todayLeaveCount = leaveRequestRepository.countByDateRangeAndStatus(
            todayStart, todayEnd, LeaveRequestStatus.APPROVED
        );
        response.setTodayLeaveCount(todayLeaveCount);

        // 3. 科室总数
        long totalDepartments = departmentRepository.count();
        response.setTotalDepartments(totalDepartments);

        // 4. 职称分布
        List<Map<String, Object>> titleStats = doctorRepository.countByTitleLevel();
        System.out.println("职称分布原始数据: " + titleStats);
        List<SimpleNameValue> titleDistribution = titleStats.stream()
            .map(stat -> {
                SimpleNameValue item = new SimpleNameValue();
                Integer level = (Integer) stat.get("level");
                String name = getTitleName(level);
                long count = ((Number) stat.get("count")).longValue();
                item.setName(name);
                item.setValue(count);
                System.out.println("职称分布 - Level: " + level + ", Name: " + name + ", Count: " + count);
                return item;
            })
            .collect(Collectors.toList());
        // 计算总数和百分比用于验证
        long totalTitleCount = titleDistribution.stream().mapToLong(SimpleNameValue::getValue).sum();
        System.out.println("职称分布总数: " + totalTitleCount);
        titleDistribution.forEach(item -> {
            double percentage = totalTitleCount > 0 ? (item.getValue() * 100.0 / totalTitleCount) : 0;
            System.out.println("  - " + item.getName() + ": " + item.getValue() + " (" + String.format("%.1f", percentage) + "%)");
        });
        response.setTitleDistribution(titleDistribution);

        // 5. 科室繁忙度 Top 5
        List<Map<String, Object>> departmentBusyStats = appointmentRepository.countByDepartmentTop5();
        List<SimpleNameValue> departmentBusy = departmentBusyStats.stream()
            .map(stat -> {
                SimpleNameValue item = new SimpleNameValue();
                item.setName((String) stat.get("name"));
                item.setValue(((Number) stat.get("count")).intValue());
                return item;
            })
            .collect(Collectors.toList());
        response.setDepartmentBusy(departmentBusy);

        // 6. 医生工作量 Top 5
        List<Map<String, Object>> doctorWorkloadStats = appointmentRepository.countByDoctorTop5();
        List<DoctorsStatsResponse.DoctorWorkloadItem> doctorWorkload = doctorWorkloadStats.stream()
            .map(stat -> {
                DoctorsStatsResponse.DoctorWorkloadItem item = new DoctorsStatsResponse.DoctorWorkloadItem();
                item.setName((String) stat.get("name"));
                item.setDepartment((String) stat.get("department"));
                item.setValue(((Number) stat.get("count")).longValue());
                return item;
            })
            .collect(Collectors.toList());
        response.setDoctorWorkload(doctorWorkload);

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public PatientsStatsResponse getPatientsStats(LocalDate startDate, LocalDate endDate) {
        PatientsStatsResponse response = new PatientsStatsResponse();
        LocalDate today = LocalDate.now();
        LocalDate firstDayOfMonth = today.withDayOfMonth(1);
        LocalDateTime monthStart = firstDayOfMonth.atStartOfDay();
        LocalDateTime todayEnd = today.atTime(LocalTime.MAX);

        // 1. 本月新增注册
        long monthlyNewRegistrations = patientRepository.countByCreatedAtBetween(monthStart, todayEnd);
        response.setMonthlyNewRegistrations(monthlyNewRegistrations);

        // 2. 师生比例系数（学生:教师，排除deleted状态的患者）
        long studentCount = patientRepository.countByStatusNotAndPatientType(PatientStatus.deleted, PatientType.student);
        long teacherCount = patientRepository.countByStatusNotAndPatientType(PatientStatus.deleted, PatientType.teacher);
        long staffCount = patientRepository.countByStatusNotAndPatientType(PatientStatus.deleted, PatientType.staff);
        System.out.println("人群比例计算 - 教师: " + teacherCount + ", 职工: " + staffCount + ", 学生: " + studentCount);
        String ratio = teacherCount + ":" + staffCount + ":" + studentCount;
        response.setTeacherStaffStudentRatio(ratio);

        // 3. 累计爽约次数
        long totalNoShows = patientProfileRepository.sumNoShowCount();
        response.setTotalNoShows(totalNoShows);

        // 4. 历史挂号/退号/退款统计
        long totalAppointments = appointmentRepository.count();
        long totalCancelledAppointments = appointmentRepository.countByStatus(AppointmentStatus.cancelled);
        long totalRefundedAppointments = appointmentRepository.countByPaymentStatus(PaymentStatus.refunded);
        response.setTotalAppointments(totalAppointments);
        response.setTotalCancelledAppointments(totalCancelledAppointments);
        response.setTotalRefundedAppointments(totalRefundedAppointments);

        // 5. 近30天用户增长趋势
        LocalDate thirtyDaysAgo = today.minusDays(29);
        List<Map<String, Object>> trendData = patientRepository.countByDateRangeGroupByDate(
            thirtyDaysAgo.atStartOfDay(), todayEnd
        );
        
        List<String> dates = new ArrayList<>();
        List<Integer> counts = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("M-d");
        
        for (int i = 0; i < 30; i++) {
            LocalDate date = thirtyDaysAgo.plusDays(i);
            String dateStr = date.format(formatter);
            dates.add(dateStr);
            
            Optional<Map<String, Object>> dayData = trendData.stream()
                .filter(d -> {
                    LocalDate dDate = ((java.sql.Date) d.get("date")).toLocalDate();
                    return dDate.equals(date);
                })
                .findFirst();
            
            counts.add(dayData.map(d -> ((Number) d.get("count")).intValue()).orElse(0));
        }
        
        response.setLast30DaysDates(dates);
        response.setLast30DaysCounts(counts);

        // 6. 患者类型构成
        List<SimpleNameValue> patientType = new ArrayList<>();
        SimpleNameValue teacher = new SimpleNameValue();
        teacher.setName("教师");
        teacher.setValue(teacherCount);
        patientType.add(teacher);
        
        SimpleNameValue staff = new SimpleNameValue();
        staff.setName("职工");
        staff.setValue(staffCount);
        patientType.add(staff);
        
        SimpleNameValue student = new SimpleNameValue();
        student.setName("学生");
        student.setValue(studentCount);
        patientType.add(student);
        response.setPatientType(patientType);

        // 7. 就诊时段热力图（按日期范围统计，如果未指定则统计所有数据）
        List<Map<String, Object>> timeSlotStats;
        if (startDate != null && endDate != null) {
            System.out.println("就诊时段热力图 - 日期范围: " + startDate + " 至 " + endDate);
            timeSlotStats = appointmentRepository.countByTimeSlotAndDateRange(startDate, endDate);
        } else {
            System.out.println("就诊时段热力图 - 统计所有历史数据");
            timeSlotStats = appointmentRepository.countByTimeSlot();
        }
        System.out.println("就诊时段热力图原始数据: " + timeSlotStats);
        List<PatientsStatsResponse.TimeSlotItem> timeSlotData = timeSlotStats.stream()
            .map(stat -> {
                PatientsStatsResponse.TimeSlotItem item = new PatientsStatsResponse.TimeSlotItem();
                String time = (String) stat.get("time");
                long count = ((Number) stat.get("count")).longValue();
                item.setTime(time);
                item.setCount(count);
                System.out.println("就诊时段 - " + time + ": " + count + " 个预约");
                return item;
            })
            .collect(Collectors.toList());
        System.out.println("就诊时段热力图总计: " + timeSlotData.stream().mapToLong(PatientsStatsResponse.TimeSlotItem::getCount).sum() + " 个预约");
        response.setTimeSlotData(timeSlotData);

        return response;
    }

    private String getTitleName(Integer level) {
        if (level == null) return "未知";
        return switch (level) {
            case 0 -> "主任医师";
            case 1 -> "副主任医师";
            case 2 -> "主治医师";
            case 3 -> "住院医师";
            default -> "未知";
        };
    }
}

