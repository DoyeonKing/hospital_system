package com.example.springboot.task;

import com.example.springboot.service.AppointmentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 自动检测爽约定时任务
 * 每天执行两次：
 * 1. 13:00 - 检查上午时段的爽约
 * 2. 19:00 - 检查下午时段的爽约
 * 
 * 标记爽约后会自动触发黑名单检查（爽约3次自动加入黑名单）
 */
@Component
public class NoShowDetectionTask {

    private static final Logger logger = LoggerFactory.getLogger(NoShowDetectionTask.class);

    private final AppointmentService appointmentService;

    @Autowired
    public NoShowDetectionTask(AppointmentService appointmentService) {
        this.appointmentService = appointmentService;
    }

    /**
     * 13:00检查爽约（检查上午时段）
     */
    @Scheduled(cron = "0 0 13 * * ?") // 每天13:00执行
    public void checkNoShowAt13() {
        try {
            logger.info("开始执行13:00自动检测爽约任务（检查上午时段）");
            int count = appointmentService.autoMarkNoShowAppointments();
            logger.info("13:00自动检测爽约任务执行完成，共标记 {} 条爽约记录", count);
        } catch (Exception e) {
            logger.error("13:00自动检测爽约任务执行失败", e);
        }
    }

    /**
     * 19:00检查爽约（检查下午时段）
     */
    @Scheduled(cron = "0 0 19 * * ?") // 每天19:00执行
    public void checkNoShowAt19() {
        try {
            logger.info("开始执行19:00自动检测爽约任务（检查下午时段）");
            int count = appointmentService.autoMarkNoShowAppointments();
            logger.info("19:00自动检测爽约任务执行完成，共标记 {} 条爽约记录", count);
        } catch (Exception e) {
            logger.error("19:00自动检测爽约任务执行失败", e);
        }
    }
}

