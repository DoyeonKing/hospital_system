package com.example.springboot.service;

import com.example.springboot.dto.patient.PatientResponse;
import com.example.springboot.entity.Patient;
import com.example.springboot.entity.PatientProfile;
import com.example.springboot.exception.ResourceNotFoundException;
import com.example.springboot.repository.PatientRepository;
import com.example.springboot.repository.PatientProfileRepository;
import com.example.springboot.util.PasswordEncoderUtil;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class PatientService {

    private final PatientRepository patientRepository;
    private final PatientProfileRepository patientProfileRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;

    @Autowired
    public PatientService(PatientRepository patientRepository, PatientProfileRepository patientProfileRepository, PasswordEncoderUtil passwordEncoderUtil) {
        this.patientRepository = patientRepository;
        this.patientProfileRepository = patientProfileRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
    }

    @Transactional(readOnly = true)
    public List<Patient> findAllPatients() {
        return patientRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Patient> findPatientById(Long id) {
        return patientRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Patient> findPatientByIdentifier(String identifier) {
        return patientRepository.findByIdentifier(identifier);
    }

    @Transactional
    public Patient createPatient(Patient patient) {
        patient.setPasswordHash(passwordEncoderUtil.encodePassword(patient.getPasswordHash()));
        return patientRepository.save(patient);
    }

    @Transactional
    public Patient updatePatient(Long id, Patient patientDetails) {
        Patient existingPatient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id " + id));

        existingPatient.setIdentifier(patientDetails.getIdentifier());
        existingPatient.setPatientType(patientDetails.getPatientType());
        if (patientDetails.getPasswordHash() != null && !patientDetails.getPasswordHash().isEmpty()) {
            existingPatient.setPasswordHash(passwordEncoderUtil.encodePassword(patientDetails.getPasswordHash()));
        }
        existingPatient.setFullName(patientDetails.getFullName());
        existingPatient.setPhoneNumber(patientDetails.getPhoneNumber());
        existingPatient.setStatus(patientDetails.getStatus());

        return patientRepository.save(existingPatient);
    }

    @Transactional
    public void deletePatient(Long id) {
        if (!patientRepository.existsById(id)) {
            throw new ResourceNotFoundException("Patient not found with id " + id);
        }
        patientRepository.deleteById(id);
    }

    @Transactional
    public PatientProfile savePatientProfile(PatientProfile patientProfile) {
        return patientProfileRepository.save(patientProfile);
    }

    public PatientResponse convertToResponseDto(Patient patient) {
        if (patient == null) {
            return null;
        }

        PatientResponse response = new PatientResponse();
        BeanUtils.copyProperties(patient, response);  // Copy properties from patient to response
        return response;
    }
}