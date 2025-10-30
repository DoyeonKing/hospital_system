package com.example.springboot.util;

import com.example.springboot.dto.auto.ScheduleRules;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.LeaveRequest;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.DoctorStatus;
import com.example.springboot.entity.enums.LeaveRequestStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class ScheduleConstraintValidator {

    public boolean checkHardConstraints(
            Doctor doctor,
            LocalDate date,
            TimeSlot slot,
            Map<Integer, List<LeaveRequest>> leaveMap,
            List<Schedule> existingSchedules,
            Map<Integer, Integer> workloadMap,
            ScheduleRules rules) {

        if (hasTimeConflict(doctor, date, slot, existingSchedules)) {
            return false;
        }

        if (isOnLeave(doctor, date, leaveMap)) {
            return false;
        }

        if (!DoctorStatus.active.equals(doctor.getStatus())) {
            return false;
        }

        Integer currentWorkload = workloadMap.getOrDefault(doctor.getDoctorId(), 0);
        if (currentWorkload >= rules.getMaxShiftsPerDoctor()) {
            return false;
        }

        return true;
    }

    private boolean hasTimeConflict(
            Doctor doctor,
            LocalDate date,
            TimeSlot slot,
            List<Schedule> schedules) {
        return schedules.stream().anyMatch(s ->
                s.getDoctor().getDoctorId().equals(doctor.getDoctorId())
                        && s.getScheduleDate().equals(date)
                        && s.getSlot().getSlotId().equals(slot.getSlotId())
        );
    }

    private boolean isOnLeave(
            Doctor doctor,
            LocalDate date,
            Map<Integer, List<LeaveRequest>> leaveMap) {
        List<LeaveRequest> leaves = leaveMap.get(doctor.getDoctorId());
        if (leaves == null) return false;

        LocalDateTime checkDateTime = date.atStartOfDay();
        return leaves.stream()
                .filter(lr -> LeaveRequestStatus.APPROVED.equals(lr.getStatus()))
                .anyMatch(lr -> !checkDateTime.isBefore(lr.getStartTime()) && !checkDateTime.isAfter(lr.getEndTime()));
    }
}


