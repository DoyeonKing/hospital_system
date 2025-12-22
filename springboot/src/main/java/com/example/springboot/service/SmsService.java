package com.example.springboot.service;

/**
 * 短信服务接口
 * 支持多种短信平台（通过HTTP API调用）
 */
public interface SmsService {
    
    /**
     * 发送短信
     * @param phoneNumber 手机号码（11位，如：13800138000）
     * @param message 短信内容
     * @return 发送结果（true=成功，false=失败）
     */
    boolean sendSms(String phoneNumber, String message);
    
    /**
     * 发送短信（带模板）
     * @param phoneNumber 手机号码
     * @param templateCode 模板ID
     * @param params 模板参数（根据平台要求格式化）
     * @return 发送结果
     */
    boolean sendSmsWithTemplate(String phoneNumber, String templateCode, String... params);
}

