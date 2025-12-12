package com.example.springboot.dto.fee;

import lombok.Data;
import java.math.BigDecimal;

/**
 * 费用详情DTO
 * 包含原价、报销比例、报销金额、实际应付费用等信息
 */
@Data
public class FeeDetailDTO {
    private BigDecimal originalFee;        // 原价（挂号费）
    private BigDecimal reimbursementRate;  // 报销比例（如0.95表示95%）
    private BigDecimal reimbursementAmount; // 报销金额
    private BigDecimal actualFee;          // 实际应付费用
    private String patientType;            // 患者类型（用于显示）
    
    public FeeDetailDTO() {}
    
    public FeeDetailDTO(BigDecimal originalFee, BigDecimal reimbursementRate, 
                       BigDecimal reimbursementAmount, BigDecimal actualFee, String patientType) {
        this.originalFee = originalFee;
        this.reimbursementRate = reimbursementRate;
        this.reimbursementAmount = reimbursementAmount;
        this.actualFee = actualFee;
        this.patientType = patientType;
    }
}

