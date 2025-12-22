package com.example.springboot.util;

import com.example.springboot.entity.enums.PatientType;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * 费用计算工具类
 * 用于计算挂号费的报销比例和实际应付金额
 */
public class FeeCalculator {
    
    // 报销比例常量
    private static final BigDecimal STUDENT_REIMBURSEMENT_RATE = new BigDecimal("0.95"); // 学生95%
    private static final BigDecimal TEACHER_REIMBURSEMENT_RATE = new BigDecimal("0.90"); // 教师90%
    private static final BigDecimal STAFF_REIMBURSEMENT_RATE = new BigDecimal("0.00"); // 其他员工0%
    
    /**
     * 计算实际应付费用（考虑报销比例）
     * @param originalFee 原价
     * @param patientType 患者类型
     * @return 实际应付费用
     */
    public static BigDecimal calculateActualFee(BigDecimal originalFee, PatientType patientType) {
        if (originalFee == null || originalFee.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal reimbursementRate = getReimbursementRate(patientType);
        // 实际应付 = 原价 * (1 - 报销比例)
        BigDecimal actualFee = originalFee.multiply(
            BigDecimal.ONE.subtract(reimbursementRate)
        );
        
        // 保留2位小数，四舍五入
        return actualFee.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * 获取报销比例
     * @param patientType 患者类型
     * @return 报销比例（0-1之间）
     */
    public static BigDecimal getReimbursementRate(PatientType patientType) {
        if (patientType == null) {
            return BigDecimal.ZERO;
        }
        
        return switch (patientType) {
            case student -> STUDENT_REIMBURSEMENT_RATE;
            case teacher -> TEACHER_REIMBURSEMENT_RATE;
            case staff -> STAFF_REIMBURSEMENT_RATE;
        };
    }
    
    /**
     * 获取报销金额
     * @param originalFee 原价
     * @param patientType 患者类型
     * @return 报销金额
     */
    public static BigDecimal calculateReimbursementAmount(BigDecimal originalFee, PatientType patientType) {
        if (originalFee == null || originalFee.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal reimbursementRate = getReimbursementRate(patientType);
        BigDecimal reimbursementAmount = originalFee.multiply(reimbursementRate);
        
        return reimbursementAmount.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * 获取患者类型的中文名称
     * @param patientType 患者类型
     * @return 中文名称
     */
    public static String getPatientTypeName(PatientType patientType) {
        if (patientType == null) {
            return "患者";
        }
        
        return switch (patientType) {
            case student -> "学生";
            case teacher -> "教师";
            case staff -> "职工";
        };
    }
}

