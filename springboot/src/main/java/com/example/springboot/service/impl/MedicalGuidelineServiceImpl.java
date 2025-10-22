package com.example.springboot.service.impl;

import com.example.springboot.dto.common.PageResponse;
import com.example.springboot.dto.guideline.MedicalGuidelineRequest;
import com.example.springboot.dto.guideline.MedicalGuidelineResponse;
import com.example.springboot.entity.MedicalGuideline;
import com.example.springboot.repository.MedicalGuidelineRepository;
import com.example.springboot.service.MedicalGuidelineService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class MedicalGuidelineServiceImpl implements MedicalGuidelineService {

    private final MedicalGuidelineRepository guidelineRepository;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<MedicalGuidelineResponse> getGuidelines(
            Integer page, Integer pageSize, String keyword, String category, String status) {

        Pageable pageable = PageRequest.of(page - 1, pageSize);
        Page<MedicalGuideline> guidelinePage;

        // 处理状态参数
        MedicalGuideline.GuidelineStatus guidelineStatus = null;
        if (status != null && !status.isEmpty()) {
            guidelineStatus = MedicalGuideline.GuidelineStatus.valueOf(status);
        }

        // 条件组合查询
        if (keyword != null && !keyword.isEmpty()) {
            if (category != null && !category.isEmpty() && guidelineStatus != null) {
                guidelinePage = guidelineRepository.findByTitleContainingAndCategoryAndStatus(
                        keyword, category, guidelineStatus, pageable);
            } else if (category != null && !category.isEmpty()) {
                guidelinePage = guidelineRepository.findByTitleContainingAndCategory(
                        keyword, category, pageable);
            } else if (guidelineStatus != null) {
                guidelinePage = guidelineRepository.findByTitleContainingAndStatus(
                        keyword, guidelineStatus, pageable);
            } else {
                guidelinePage = guidelineRepository.findByTitleContaining(keyword, pageable);
            }
        } else {
            // 无关键词时查询所有
            guidelinePage = guidelineRepository.findAll(pageable);
        }

        // 转换为响应DTO
        PageResponse<MedicalGuidelineResponse> response = new PageResponse<>();
        response.setContent(guidelinePage.getContent().stream()
                .map(this::convertToResponse)
                .toList());
        response.setCurrentPage(page);
        response.setPageSize(pageSize);
        response.setTotalElements(guidelinePage.getTotalElements());
        response.setTotalPages(guidelinePage.getTotalPages());

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public MedicalGuidelineResponse getGuidelineById(Integer id) {
        MedicalGuideline guideline = guidelineRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("就医规范不存在"));
        return convertToResponse(guideline);
    }

    @Override
    @Transactional
    public MedicalGuidelineResponse createGuideline(MedicalGuidelineRequest request) {
        MedicalGuideline guideline = new MedicalGuideline();
        guideline.setTitle(request.getTitle());
        guideline.setContent(request.getContent());
        guideline.setCategory(request.getCategory());
        guideline.setStatus(request.getStatus());
        guideline.setCreatedBy(request.getCreatedBy());

        MedicalGuideline saved = guidelineRepository.save(guideline);
        return convertToResponse(saved);
    }

    @Override
    @Transactional
    public MedicalGuidelineResponse updateGuideline(Integer id, MedicalGuidelineRequest request) {
        MedicalGuideline guideline = guidelineRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("就医规范不存在"));

        guideline.setTitle(request.getTitle());
        guideline.setContent(request.getContent());
        guideline.setCategory(request.getCategory());
        guideline.setStatus(request.getStatus());

        MedicalGuideline updated = guidelineRepository.save(guideline);
        return convertToResponse(updated);
    }

    @Override
    @Transactional
    public void deleteGuideline(Integer id) {
        if (!guidelineRepository.existsById(id)) {
            throw new RuntimeException("就医规范不存在");
        }
        guidelineRepository.deleteById(id);
    }

    // 实体转DTO
    private MedicalGuidelineResponse convertToResponse(MedicalGuideline guideline) {
        MedicalGuidelineResponse response = new MedicalGuidelineResponse();
        response.setGuidelineId(guideline.getGuidelineId());
        response.setTitle(guideline.getTitle());
        response.setContent(guideline.getContent());
        response.setCategory(guideline.getCategory());
        response.setStatus(guideline.getStatus());
        response.setCreatedBy(guideline.getCreatedBy());
        response.setCreatedAt(guideline.getCreatedAt());
        response.setUpdatedAt(guideline.getUpdatedAt());
        return response;
    }
}