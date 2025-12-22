package com.example.springboot.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * 短信服务配置类
 * 支持通过 application.yml 配置短信平台信息
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "sms")
public class SmsConfig {
    
    /**
     * 是否启用短信服务（false时只记录日志，不发送真实短信）
     */
    private Boolean enabled = false;
    
    /**
     * 短信平台类型：
     * - juhe（聚合数据，仅企业用户）
     * - custom（自定义HTTP API，推荐个人用户）
     * - twilio（Twilio平台，支持个人用户）
     * ⚠️ 注意：聚合数据仅支持企业用户，个人用户请使用 custom 或 twilio
     */
    private String provider = "custom";
    
    /**
     * API地址（自定义平台时使用）
     * 个人用户推荐使用支持个人的短信平台，通过HTTP API接入
     */
    private String apiUrl;
    
    /**
     * API密钥/AppKey
     */
    private String apiKey;
    
    /**
     * API密钥2/AppSecret（部分平台需要）
     */
    private String apiSecret;
    
    /**
     * 短信签名（部分平台需要）
     */
    private String sign;
    
    /**
     * 短信模板ID（使用模板发送时）
     */
    private String templateId;
    
    /**
     * 聚合数据平台专用配置
     * ⚠️ 注意：聚合数据仅支持企业用户，个人用户无法使用
     */
    private JuheConfig juhe = new JuheConfig();
    
    /**
     * Twilio平台专用配置
     * 支持个人用户，全球知名平台
     */
    private TwilioConfig twilio = new TwilioConfig();
    
    @Data
    public static class JuheConfig {
        /**
         * 聚合数据API Key
         */
        private String appKey;
        
        /**
         * 聚合数据模板ID
         */
        private String templateId;
    }
    
    @Data
    public static class TwilioConfig {
        /**
         * Twilio Account SID
         */
        private String accountSid;
        
        /**
         * Twilio Auth Token
         */
        private String authToken;
        
        /**
         * Twilio 发送方号码（需要从Twilio获取）
         */
        private String fromNumber;
    }
}

