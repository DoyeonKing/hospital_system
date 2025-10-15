package com.example.springboot.entity; // 包名调整

import com.example.springboot.entity.enums.ScheduleStatus; // 导入路径调整
import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 医生排班表
 */
@Entity
@Table(name = "schedules", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"doctor_id", "schedule_date", "slot_id"})
})
@Data
public class Schedule {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer scheduleId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id", nullable = false)
    private Doctor doctor; // 医生ID

    @Column(name = "schedule_date", nullable = false)
    private LocalDate scheduleDate; // 出诊日期

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "slot_id", nullable = false)
    private TimeSlot timeSlot; // 时间段ID

    @Column(name = "total_slots", nullable = false)
    private Integer totalSlots; // 总号源数

    @Column(name = "booked_slots", nullable = false)
    private Integer bookedSlots = 0; // 已预约数

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal fee; // 挂号费用

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ScheduleStatus status; // 排班状态

    private String remarks; // 特别的排班要求或备注信息
}
