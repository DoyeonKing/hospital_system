package com.example.springboot.service;

import com.example.springboot.dto.schedule.ScheduleCreateRequest;
import com.example.springboot.dto.schedule.ScheduleResponse;
import com.example.springboot.dto.schedule.ScheduleUpdateRequest;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.Schedule;
import com.example.springboot.entity.TimeSlot;
import com.example.springboot.entity.enums.ScheduleStatus;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.DoctorRepository;
import com.example.springboot.repository.ScheduleRepository;
import com.example.springboot.repository.TimeSlotRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final DoctorRepository doctorRepository;
    private final TimeSlotRepository timeSlotRepository;
    private final DoctorService doctorService; // For converting doctor entity to DTO
    private final TimeSlotService timeSlotService; // For converting timeSlot entity to DTO

    @Autowired
    public ScheduleService(ScheduleRepository scheduleRepository,
                           DoctorRepository doctorRepository,
                           TimeSlotRepository timeSlotRepository,
                           DoctorService doctorService,
                           TimeSlotService timeSlotService) {
        this.scheduleRepository = scheduleRepository;
        this.doctorRepository = doctorRepository;
        this.timeSlotRepository = timeSlotRepository;
        this.doctorService = doctorService;
        this.timeSlotService = timeSlotService;
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponse> findAllSchedules() {
        return scheduleRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ScheduleResponse findScheduleById(Integer id) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + id));
        return convertToResponseDto(schedule);
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponse> findSchedulesByDoctorAndDateRange(Integer doctorId, LocalDate startDate, LocalDate endDate) {
        Doctor doctor = doctorRepository.findById(doctorId)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + doctorId));
        
        // 检查医生是否已删除
        if (doctor.getStatus() == DoctorStatus.deleted) {
            throw new BadRequestException("医生已删除，无法查询排班");
        }
        
        return scheduleRepository.findByDoctorAndScheduleDateBetween(doctor, startDate, endDate).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponse> findActiveSchedulesByDate(LocalDate date) {
        return scheduleRepository.findByScheduleDateAndStatus(date, ScheduleStatus.ACTIVE).stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ScheduleResponse createSchedule(ScheduleCreateRequest request) {
        Doctor doctor = doctorRepository.findById(request.getDoctorId())
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + request.getDoctorId()));
        TimeSlot timeSlot = timeSlotRepository.findById(request.getTimeSlotId())
                .orElseThrow(() -> new ResourceNotFoundException("TimeSlot not found with id " + request.getTimeSlotId()));

        // 检查排班是否重复
        if (scheduleRepository.findByDoctorAndScheduleDateAndTimeSlot(doctor, request.getScheduleDate(), timeSlot).isPresent()) {
            throw new BadRequestException("Schedule for this doctor, date, and time slot already exists.");
        }

        // 检查排班日期是否在过去
        if (request.getScheduleDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Cannot create a schedule for a past date.");
        }

        Schedule schedule = new Schedule();
        BeanUtils.copyProperties(request, schedule, "doctorId", "timeSlotId", "bookedSlots");
        schedule.setDoctor(doctor);
        schedule.setTimeSlot(timeSlot);
        schedule.setBookedSlots(0); // 新排班，已预约数为0

        return convertToResponseDto(scheduleRepository.save(schedule));
    }

    @Transactional
    public ScheduleResponse updateSchedule(Integer id, ScheduleUpdateRequest request) {
        Schedule existingSchedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule not found with id " + id));

        // 不能修改已过去的排班
        if (existingSchedule.getScheduleDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Cannot update a past schedule.");
        }

        if (request.getDoctorId() != null && !request.getDoctorId().equals(existingSchedule.getDoctor().getDoctorId())) {
            Doctor newDoctor = doctorRepository.findById(request.getDoctorId())
                    .orElseThrow(() -> new ResourceNotFoundException("New Doctor not found with id " + request.getDoctorId()));
            existingSchedule.setDoctor(newDoctor);
        }
        if (request.getScheduleDate() != null) existingSchedule.setScheduleDate(request.getScheduleDate());
        if (request.getTimeSlotId() != null && !request.getTimeSlotId().equals(existingSchedule.getTimeSlot().getSlotId())) {
            TimeSlot newTimeSlot = timeSlotRepository.findById(request.getTimeSlotId())
                    .orElseThrow(() -> new ResourceNotFoundException("New TimeSlot not found with id " + request.getTimeSlotId()));
            existingSchedule.setTimeSlot(newTimeSlot);
        }

        // 检查更新后的排班是否与现有排班冲突
        if (request.getDoctorId() != null || request.getScheduleDate() != null || request.getTimeSlotId() != null) {
            Doctor currentDoctor = existingSchedule.getDoctor();
            LocalDate currentDate = existingSchedule.getScheduleDate();
            TimeSlot currentTimeSlot = existingSchedule.getTimeSlot();

            if (scheduleRepository.findByDoctorAndScheduleDateAndTimeSlot(currentDoctor, currentDate, currentTimeSlot)
                    .filter(s -> !s.getScheduleId().equals(id)).isPresent()) {
                throw new BadRequestException("Updated schedule conflicts with an existing schedule.");
            }
        }

        if (request.getTotalSlots() != null) {
            if (request.getTotalSlots() < existingSchedule.getBookedSlots()) {
                throw new BadRequestException("Total slots cannot be less than already booked slots.");
            }
            existingSchedule.setTotalSlots(request.getTotalSlots());
        }
        if (request.getBookedSlots() != null) {
            if (request.getBookedSlots() > existingSchedule.getTotalSlots()) {
                throw new BadRequestException("Booked slots cannot exceed total slots.");
            }
            existingSchedule.setBookedSlots(request.getBookedSlots());
        }
        if (request.getFee() != null) existingSchedule.setFee(request.getFee());
        if (request.getStatus() != null) existingSchedule.setStatus(request.getStatus());
        if (request.getRemarks() != null) existingSchedule.setRemarks(request.getRemarks());

        return convertToResponseDto(scheduleRepository.save(existingSchedule));
    }

    @Transactional
    public void deleteSchedule(Integer id) {
        if (!scheduleRepository.existsById(id)) {
            throw new ResourceNotFoundException("Schedule not found with id " + id);
        }
        // TODO: Consider business logic for deleting schedules with existing appointments.
        // E.g., prevent deletion, or auto-cancel appointments and notify patients.
        scheduleRepository.deleteById(id);
    }

    public ScheduleResponse convertToResponseDto(Schedule schedule) {
        ScheduleResponse response = new ScheduleResponse();
        BeanUtils.copyProperties(schedule, response, "doctor", "timeSlot");
        response.setDoctor(doctorService.convertToResponseDto(schedule.getDoctor()));
        response.setTimeSlotId(schedule.getTimeSlot().getSlotId());
        response.setTimeSlotName(schedule.getTimeSlot().getSlotName());
        response.setStartTime(schedule.getTimeSlot().getStartTime());
        response.setEndTime(schedule.getTimeSlot().getEndTime());
        return response;
    }
}
