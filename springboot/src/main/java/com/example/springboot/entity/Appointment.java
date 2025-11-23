package com.example.springboot.entity; // 包名调整

import com.example.springboot.entity.enums.AppointmentStatus; // 导入路径调整
import com.example.springboot.entity.enums.PaymentStatus;     // 导入路径调整
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 预约挂号表
 */
@Entity
@Table(name = "appointments")
@Data
public class Appointment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer appointmentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient; // 患者ID

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id", nullable = false)
    private Schedule schedule; // 排班ID

    @Column(name = "appointment_number")
    private Integer appointmentNumber; // 就诊序号

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AppointmentStatus status; // 预约状态

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false)
    private PaymentStatus paymentStatus; // 支付状态

    @Column(name = "payment_method", length = 50)
    private String paymentMethod; // 支付方式

    @Column(name = "transaction_id")
    private String transactionId; // 支付流水号

    @Column(name = "check_in_time")
    private LocalDateTime checkInTime; // 现场签到时间

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt; // 预约生成时间

    @Column(name = "updated_at")
    private LocalDateTime updatedAt; // 最后更新时间（status变为completed时由触发器自动更新）
}
