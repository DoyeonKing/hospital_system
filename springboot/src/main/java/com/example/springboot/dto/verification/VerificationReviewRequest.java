package com.example.springboot.dto.verification;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 身份验证审核请求DTO
 */
@Data
public class VerificationReviewRequest {
    @NotNull(message = "审核结果不能为空")
    private Boolean approved; // true=通过, false=拒绝

    private String rejectionReason; // 拒绝原因（拒绝时必填）
}

