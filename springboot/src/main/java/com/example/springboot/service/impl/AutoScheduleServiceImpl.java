package com.example.springboot.service.impl;

import com.example.springboot.dto.auto.*;
import com.example.springboot.dto.schedule.ScheduleResponse;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.LeaveRequest;
import com.example.springboot.entity.Location;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import com.example.springboot.repository.*;
import com.example.springboot.service.AutoScheduleService;
import com.example.springboot.util.ConflictDetector;
import com.example.springboot.util.ScheduleConstraintValidator;
import com.example.springboot.util.WorkloadCalculator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AutoScheduleServiceImpl implements AutoScheduleService {

    @Autowired private DoctorRepository doctorRepository;
    @Autowired private TimeSlotRepository timeSlotRepository;
    @Autowired private LocationRepository locationRepository;
    @Autowired private ScheduleRepository scheduleRepository;
    @Autowired private LeaveRequestRepository leaveRequestRepository;

    private final ScheduleConstraintValidator constraintValidator = new ScheduleConstraintValidator();
    private final WorkloadCalculator workloadCalculator = new WorkloadCalculator();
    private final ConflictDetector conflictDetector = new ConflictDetector();

    @Override
    @Transactional
    public AutoScheduleResponse autoGenerateSchedule(AutoScheduleRequest request) {
        long start = System.currentTimeMillis();

        List<Doctor> doctors = doctorRepository.findByDepartmentDepartmentId(request.getDepartmentId())
                .stream()
                .filter(d -> d.getStatus() != null && d.getStatus().name().equalsIgnoreCase("active"))
                .collect(Collectors.toList());
        List<TimeSlot> timeSlots = timeSlotRepository.findAll();
        List<Location> locations = locationRepository.findByDepartmentDepartmentId(request.getDepartmentId());
        List<Schedule> existing = scheduleRepository.findAll().stream()
                .filter(s -> !s.getScheduleDate().isBefore(request.getStartDate()) && !s.getScheduleDate().isAfter(request.getEndDate()))
                .collect(Collectors.toList());

        Map<Integer, List<LeaveRequest>> leaveMap = new HashMap<>();
        for (Doctor d : doctors) {
            leaveMap.put(d.getDoctorId(), leaveRequestRepository.findByDoctor(d));
        }

        List<Schedule> generated = new ArrayList<>();
        Map<Integer, Integer> workload = new HashMap<>();
        List<UnassignedSlot> unassigned = new ArrayList<>();

        LocalDate day = request.getStartDate();
        while (!day.isAfter(request.getEndDate())) {
            for (TimeSlot slot : timeSlots) {
                final LocalDate currentDay = day;
                final List<Schedule> occupied = mergeLists(existing, generated);
                List<Doctor> available = doctors.stream()
                        .filter(d -> constraintValidator.checkHardConstraints(
                                d, currentDay, slot, leaveMap, occupied, workload, request.getRules()))
                        .collect(Collectors.toList());

                if (available.isEmpty()) {
                    UnassignedSlot us = new UnassignedSlot();
                    us.setDate(currentDay);
                    us.setSlotId(slot.getSlotId());
                    us.setSlotName(slot.getSlotName());
                    us.setReason("无可用医生");
                    unassigned.add(us);
                    continue;
                }

                available.sort(Comparator.comparingInt(d -> workload.getOrDefault(d.getDoctorId(), 0)));
                Doctor selected = available.get(0);

                Location assigned = selectLocation(locations, currentDay, slot, occupied);
                if (assigned == null) {
                    UnassignedSlot us = new UnassignedSlot();
                    us.setDate(currentDay);
                    us.setSlotId(slot.getSlotId());
                    us.setSlotName(slot.getSlotName());
                    us.setReason("无可用诊室");
                    unassigned.add(us);
                    continue;
                }

                Schedule schedule = new Schedule();
                schedule.setDoctor(selected);
                schedule.setScheduleDate(currentDay);
                schedule.setSlot(slot);
                schedule.setLocation(assigned);
                schedule.setTotalSlots(Optional.ofNullable(request.getRules().getDefaultTotalSlots()).orElse(20));
                schedule.setBookedSlots(0);
                schedule.setFee(Optional.ofNullable(request.getRules().getDefaultFee()).orElse(new BigDecimal("5.00")));
                schedule.setStatus(ScheduleStatus.available);
                schedule.setRemarks("自动排班生成");

                generated.add(schedule);
                workload.merge(selected.getDoctorId(), 1, Integer::sum);
            }
            day = day.plusDays(1);
        }

        List<ScheduleConflict> conflicts = conflictDetector.detectConflicts(generated, existing);
        if (!Boolean.TRUE.equals(request.getPreviewOnly()) && conflicts.isEmpty()) {
            scheduleRepository.saveAll(generated);
        }

        Map<Integer, DoctorWorkload> distribution = workloadCalculator.calculateWorkloadDistribution(generated, doctors);
        ScheduleStatistics stats = buildStatistics(generated, request, doctors.size(), conflicts.size(), System.currentTimeMillis() - start);

        AutoScheduleResponse resp = new AutoScheduleResponse();
        resp.setSuccess(conflicts.isEmpty());
        if (doctors.isEmpty()) {
            resp.setMessage("科室下没有可用(Active)医生，无法生成排班");
        } else if (generated.isEmpty()) {
            resp.setMessage("所有时段均无可用医生，请检查医生状态/请假/已有排班");
        } else {
            resp.setMessage(conflicts.isEmpty() ? "自动排班生成成功" : "存在冲突，请先处理");
        }
        resp.setSchedules(generated.stream().map(ScheduleResponse::fromEntity).collect(Collectors.toList()));
        resp.setStatistics(stats);
        resp.setConflicts(conflicts);
        resp.setUnassignedSlots(unassigned);
        resp.setWorkloadDistribution(distribution);
        resp.setWarnings(Collections.emptyList());
        return resp;
    }

    private List<Schedule> mergeLists(List<Schedule> a, List<Schedule> b) {
        List<Schedule> all = new ArrayList<>(a);
        all.addAll(b);
        return all;
    }

    private Location selectLocation(List<Location> locations, LocalDate date, TimeSlot slot, List<Schedule> occupied) {
        for (Location l : locations) {
            boolean used = occupied.stream().anyMatch(s ->
                    s.getLocation().getLocationId().equals(l.getLocationId())
                            && s.getScheduleDate().equals(date)
                            && s.getSlot().getSlotId().equals(slot.getSlotId())
            );
            if (!used) return l;
        }
        return null;
    }

    private ScheduleStatistics buildStatistics(List<Schedule> generated, AutoScheduleRequest request, int doctorCount, int conflictCount, long ms) {
        ScheduleStatistics s = new ScheduleStatistics();
        s.setTotalSchedules(generated.size());
        s.setCoveredDays((int) generated.stream().map(Schedule::getScheduleDate).distinct().count());
        s.setDoctorsInvolved((int) generated.stream().map(sc -> sc.getDoctor().getDoctorId()).distinct().count());
        Map<Integer, Long> counts = generated.stream().collect(Collectors.groupingBy(sc -> sc.getDoctor().getDoctorId(), Collectors.counting()));
        int max = counts.values().stream().mapToInt(Long::intValue).max().orElse(0);
        int min = counts.values().stream().mapToInt(Long::intValue).min().orElse(0);
        double avg = counts.values().stream().mapToInt(Long::intValue).average().orElse(0);
        long totalDemand = daysBetween(request.getStartDate(), request.getEndDate()) * (long) timeSlotRepository.count();
        double coverage = totalDemand == 0 ? 0 : (double) generated.size() / totalDemand;
        s.setAverageWorkload(avg);
        s.setMaxWorkload(max);
        s.setMinWorkload(min);
        s.setCoverageRate(coverage);
        s.setConflictCount(conflictCount);
        s.setExecutionTime(ms);
        return s;
    }

    private int daysBetween(LocalDate start, LocalDate end) {
        int c = 0;
        LocalDate d = start;
        while (!d.isAfter(end)) { c++; d = d.plusDays(1); }
        return c;
    }
}


