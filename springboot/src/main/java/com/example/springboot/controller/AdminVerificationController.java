package com.example.springboot.controller;

import com.example.springboot.common.Result;
import com.example.springboot.dto.verification.VerificationReviewRequest;
import com.example.springboot.dto.verification.VerificationResponse;
import com.example.springboot.service.PatientService;
import com.example.springboot.security.JwtTokenProvider;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 管理员身份验证审核控制器
 */
@RestController
@RequestMapping("/api/admin/verifications")
public class AdminVerificationController {

    @Autowired
    private PatientService patientService;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    /**
     * 获取待审核的身份验证申请列表
     * URL: GET /api/admin/verifications/pending
     */
    @GetMapping("/pending")
    public ResponseEntity<Result> getPendingVerifications() {
        try {
            List<VerificationResponse> verifications = patientService.getPendingVerifications();
            return ResponseEntity.ok(Result.success(verifications));
        } catch (Exception e) {
            return ResponseEntity.ok(Result.error("500", "获取待审核列表失败：" + e.getMessage()));
        }
    }

    /**
     * 获取所有身份验证申请（包括已审核的）
     * URL: GET /api/admin/verifications
     */
    @GetMapping
    public ResponseEntity<Result> getAllVerifications() {
        try {
            List<VerificationResponse> verifications = patientService.getAllVerifications();
            return ResponseEntity.ok(Result.success(verifications));
        } catch (Exception e) {
            return ResponseEntity.ok(Result.error("500", "获取审核列表失败：" + e.getMessage()));
        }
    }

    /**
     * 审核身份验证申请
     * URL: POST /api/admin/verifications/{verificationId}/review
     */
    @PostMapping("/{verificationId}/review")
    public ResponseEntity<Result> reviewVerification(
            @PathVariable Long verificationId,
            @Valid @RequestBody VerificationReviewRequest request,
            HttpServletRequest httpRequest) {
        try {
            // 从JWT Token中获取管理员ID
            String authHeader = httpRequest.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return ResponseEntity.ok(Result.error("401", "未授权，请先登录"));
            }
            
            String token = authHeader.substring(7);
            if (!jwtTokenProvider.validateToken(token)) {
                return ResponseEntity.ok(Result.error("401", "Token无效"));
            }
            
            Integer adminId = jwtTokenProvider.getUserIdFromToken(token).intValue();
            
            patientService.reviewIdentityVerification(
                verificationId, 
                adminId, 
                request.getApproved(), 
                request.getRejectionReason()
            );
            
            return ResponseEntity.ok(Result.success("审核成功"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.ok(Result.error("400", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.ok(Result.error("500", "审核失败：" + e.getMessage()));
        }
    }
}

