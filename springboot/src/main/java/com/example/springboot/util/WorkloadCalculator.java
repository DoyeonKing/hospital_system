package com.example.springboot.util;

import com.example.springboot.dto.auto.DoctorWorkload;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Schedule;

import java.time.LocalDate;
import java.util.*;

public class WorkloadCalculator {

    public Map<Integer, DoctorWorkload> calculateWorkloadDistribution(List<Schedule> schedules, List<Doctor> doctors) {
        Map<Integer, DoctorWorkload> distribution = new HashMap<>();

        for (Doctor doctor : doctors) {
            DoctorWorkload workload = new DoctorWorkload();
            workload.setDoctorId(doctor.getDoctorId());
            workload.setDoctorName(doctor.getFullName());
            workload.setTitle(doctor.getTitle());
            workload.setTotalShifts(0);
            workload.setWorkDays(0);
            workload.setScheduleDetails(new HashMap<>());
            distribution.put(doctor.getDoctorId(), workload);
        }

        Map<Integer, Set<LocalDate>> workDaysMap = new HashMap<>();
        for (Schedule schedule : schedules) {
            Integer doctorId = schedule.getDoctor().getDoctorId();
            DoctorWorkload workload = distribution.get(doctorId);
            if (workload == null) continue;

            workload.setTotalShifts(workload.getTotalShifts() + 1);
            workDaysMap.computeIfAbsent(doctorId, k -> new HashSet<>()).add(schedule.getScheduleDate());
            workload.getScheduleDetails().computeIfAbsent(schedule.getScheduleDate(), k -> new ArrayList<>())
                    .add(schedule.getSlot().getSlotName());
        }

        for (Map.Entry<Integer, Set<LocalDate>> entry : workDaysMap.entrySet()) {
            DoctorWorkload workload = distribution.get(entry.getKey());
            workload.setWorkDays(entry.getValue().size());
            workload.setMaxConsecutiveDays(calculateMaxConsecutiveDays(entry.getValue()));
        }

        return distribution;
    }

    private Integer calculateMaxConsecutiveDays(Set<LocalDate> workDays) {
        if (workDays.isEmpty()) return 0;
        List<LocalDate> sortedDays = new ArrayList<>(workDays);
        Collections.sort(sortedDays);

        int maxConsecutive = 1;
        int currentConsecutive = 1;
        for (int i = 1; i < sortedDays.size(); i++) {
            LocalDate prev = sortedDays.get(i - 1);
            LocalDate curr = sortedDays.get(i);
            if (curr.equals(prev.plusDays(1))) {
                currentConsecutive++;
                maxConsecutive = Math.max(maxConsecutive, currentConsecutive);
            } else {
                currentConsecutive = 1;
            }
        }
        return maxConsecutive;
    }
}


