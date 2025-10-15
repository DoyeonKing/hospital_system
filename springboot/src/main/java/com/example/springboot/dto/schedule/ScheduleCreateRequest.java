package com.example.springboot.dto.schedule;

import com.example.springboot.entity.enums.ScheduleStatus;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class ScheduleCreateRequest {
    @NotNull(message = "医生ID不能为空")
    private Integer doctorId;

    @NotNull(message = "排班日期不能为空")
    @FutureOrPresent(message = "排班日期不能早于今天")
    private LocalDate scheduleDate;

    @NotNull(message = "时间段ID不能为空")
    private Integer timeSlotId;

    @NotNull(message = "总号源数不能为空")
    @Min(value = 0, message = "总号源数不能小于0")
    private Integer totalSlots;

    @NotNull(message = "挂号费用不能为空")
    @Min(value = 0, message = "挂号费用不能小于0")
    private BigDecimal fee;

    @NotNull(message = "排班状态不能为空")
    private ScheduleStatus status;

    private String remarks;
}
