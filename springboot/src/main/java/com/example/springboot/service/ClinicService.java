package com.example.springboot.service;

import com.example.springboot.dto.clinic.ClinicCreateRequest;
import com.example.springboot.dto.clinic.ClinicResponse;
import com.example.springboot.dto.clinic.ClinicUpdateRequest;
import com.example.springboot.entity.Clinic;
import com.example.springboot.exception.BadRequestException;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.ClinicRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ClinicService {

    private final ClinicRepository clinicRepository;

    @Autowired
    public ClinicService(ClinicRepository clinicRepository) {
        this.clinicRepository = clinicRepository;
    }

    @Transactional(readOnly = true)
    public List<ClinicResponse> findAllClinics() {
        return clinicRepository.findAll().stream()
                .map(this::convertToResponseDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ClinicResponse findClinicById(Integer id) {
        Clinic clinic = clinicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + id));
        return convertToResponseDto(clinic);
    }

    @Transactional
    public ClinicResponse createClinic(ClinicCreateRequest request) {
        if (clinicRepository.existsByName(request.getName())) {
            throw new BadRequestException("Clinic with name '" + request.getName() + "' already exists.");
        }
        Clinic clinic = new Clinic();
        BeanUtils.copyProperties(request, clinic);
        return convertToResponseDto(clinicRepository.save(clinic));
    }

    @Transactional
    public ClinicResponse updateClinic(Integer id, ClinicUpdateRequest request) {
        Clinic existingClinic = clinicRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Clinic not found with id " + id));

        if (request.getName() != null && !request.getName().equals(existingClinic.getName())) {
            if (clinicRepository.existsByName(request.getName())) {
                throw new BadRequestException("Clinic with name '" + request.getName() + "' already exists.");
            }
            existingClinic.setName(request.getName());
        }
        if (request.getProvince() != null) existingClinic.setProvince(request.getProvince());
        if (request.getCity() != null) existingClinic.setCity(request.getCity());
        if (request.getDistrict() != null) existingClinic.setDistrict(request.getDistrict());
        if (request.getDetailedAddress() != null) existingClinic.setDetailedAddress(request.getDetailedAddress());

        return convertToResponseDto(clinicRepository.save(existingClinic));
    }

    @Transactional
    public void deleteClinic(Integer id) {
        if (!clinicRepository.existsById(id)) {
            throw new ResourceNotFoundException("Clinic not found with id " + id);
        }
        clinicRepository.deleteById(id);
    }

    public ClinicResponse convertToResponseDto(Clinic clinic) {
        ClinicResponse response = new ClinicResponse();
        BeanUtils.copyProperties(clinic, response);
        return response;
    }
}
