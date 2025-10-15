package com.example.springboot.dto.schedule;

import com.example.springboot.entity.enums.ScheduleStatus;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Min;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class ScheduleUpdateRequest {
    private Integer doctorId;

    @FutureOrPresent(message = "排班日期不能早于今天")
    private LocalDate scheduleDate;

    private Integer timeSlotId;

    @Min(value = 0, message = "总号源数不能小于0")
    private Integer totalSlots;

    @Min(value = 0, message = "已预约数不能小于0")
    private Integer bookedSlots; // 谨慎修改，通常由系统自动更新

    @Min(value = 0, message = "挂号费用不能小于0")
    private BigDecimal fee;

    private ScheduleStatus status;

    private String remarks;
}
