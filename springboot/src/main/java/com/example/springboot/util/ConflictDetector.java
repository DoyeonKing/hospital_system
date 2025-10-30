package com.example.springboot.util;

import com.example.springboot.dto.auto.ScheduleConflict;
import com.example.springboot.entity.Schedule;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ConflictDetector {

    public List<ScheduleConflict> detectConflicts(List<Schedule> newSchedules, List<Schedule> existingSchedules) {
        List<ScheduleConflict> conflicts = new ArrayList<>();
        List<Schedule> all = new ArrayList<>();
        all.addAll(newSchedules);
        all.addAll(existingSchedules);

        for (int i = 0; i < all.size(); i++) {
            for (int j = i + 1; j < all.size(); j++) {
                Schedule s1 = all.get(i);
                Schedule s2 = all.get(j);
                if (isTimeConflict(s1, s2)) {
                    ScheduleConflict c = new ScheduleConflict();
                    c.setType(ScheduleConflict.ConflictType.TIME_CONFLICT);
                    c.setDescription("医生在同一时间有多个排班");
                    c.setDoctorName(s1.getDoctor().getFullName());
                    c.setConflictDate(s1.getScheduleDate());
                    c.setTimeSlot(s1.getSlot().getSlotName());
                    c.setScheduleIds(Arrays.asList(s1.getScheduleId(), s2.getScheduleId()));
                    c.setSuggestion("请检查并删除重复排班");
                    conflicts.add(c);
                }
            }
        }

        return conflicts;
    }

    private boolean isTimeConflict(Schedule s1, Schedule s2) {
        return s1.getDoctor().getDoctorId().equals(s2.getDoctor().getDoctorId())
                && s1.getScheduleDate().equals(s2.getScheduleDate())
                && s1.getSlot().getSlotId().equals(s2.getSlot().getSlotId());
    }
}


