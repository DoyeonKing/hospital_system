package com.example.springboot.service;

import com.example.springboot.dto.auto.AutoScheduleRequest;
import com.example.springboot.dto.auto.AutoScheduleResponse;

public interface AutoScheduleService {
    AutoScheduleResponse autoGenerateSchedule(AutoScheduleRequest request);
}


