package com.example.springboot.service; // 包名调整

import com.example.springboot.dto.doctor.DoctorResponse;
import com.example.springboot.entity.Doctor;         // 导入路径调整
import com.example.springboot.exception.ResourceNotFoundException; // 导入路径调整
import com.example.springboot.repository.DoctorRepository;     // 导入路径调整
import com.example.springboot.util.PasswordEncoderUtil;         // 导入路径调整
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class DoctorService {

    private final DoctorRepository doctorRepository;
    private final PasswordEncoderUtil passwordEncoderUtil;

    @Autowired
    public DoctorService(DoctorRepository doctorRepository, PasswordEncoderUtil passwordEncoderUtil) {
        this.doctorRepository = doctorRepository;
        this.passwordEncoderUtil = passwordEncoderUtil;
    }

    @Transactional(readOnly = true)
    public List<Doctor> findAllDoctors() {
        return doctorRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Optional<Doctor> findDoctorById(Integer id) {
        return doctorRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public Optional<Doctor> findDoctorByIdentifier(String identifier) {
        return doctorRepository.findByIdentifier(identifier);
    }

    @Transactional
    public Doctor createDoctor(Doctor doctor) {
        doctor.setPasswordHash(passwordEncoderUtil.encodePassword(doctor.getPasswordHash()));
        return doctorRepository.save(doctor);
    }

    @Transactional
    public Doctor updateDoctor(Integer id, Doctor doctorDetails) {
        Doctor existingDoctor = doctorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor not found with id " + id));

        // Update fields
        existingDoctor.setClinic(doctorDetails.getClinic());
        existingDoctor.setDepartment(doctorDetails.getDepartment());
        existingDoctor.setIdentifier(doctorDetails.getIdentifier());
        if (doctorDetails.getPasswordHash() != null && !doctorDetails.getPasswordHash().isEmpty()) {
            existingDoctor.setPasswordHash(passwordEncoderUtil.encodePassword(doctorDetails.getPasswordHash()));
        }
        existingDoctor.setFullName(doctorDetails.getFullName());
        existingDoctor.setPhoneNumber(doctorDetails.getPhoneNumber());
        existingDoctor.setTitle(doctorDetails.getTitle());
        existingDoctor.setSpecialty(doctorDetails.getSpecialty());
        existingDoctor.setBio(doctorDetails.getBio());
        existingDoctor.setPhotoUrl(doctorDetails.getPhotoUrl());
        existingDoctor.setStatus(doctorDetails.getStatus());

        return doctorRepository.save(existingDoctor);
    }

    @Transactional
    public void deleteDoctor(Integer id) {
        if (!doctorRepository.existsById(id)) {
            throw new ResourceNotFoundException("Doctor not found with id " + id);
        }
        doctorRepository.deleteById(id);
    }

    public DoctorResponse convertToResponseDto(Doctor doctor) {
        if (doctor == null) {
            return null;
        }

        DoctorResponse response = new DoctorResponse();
        BeanUtils.copyProperties(doctor, response);
        return response;
    }
}
