package com.example.springboot.service.impl;

import com.example.springboot.config.SmsConfig;
import com.example.springboot.service.SmsService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/**
 * 短信服务实现类
 * 支持多种短信平台，通过HTTP API调用
 */
@Service
public class SmsServiceImpl implements SmsService {

    private static final Logger logger = LoggerFactory.getLogger(SmsServiceImpl.class);

    private final SmsConfig smsConfig;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public SmsServiceImpl(SmsConfig smsConfig, RestTemplate restTemplate) {
        this.smsConfig = smsConfig;
        this.restTemplate = restTemplate;
    }

    @Override
    public boolean sendSms(String phoneNumber, String message) {
        // 如果未启用短信服务，只记录日志
        if (smsConfig.getEnabled() == null || !smsConfig.getEnabled()) {
            logger.info("[短信模拟] 发送短信到 {}，内容：{}", phoneNumber, message);
            return true;
        }

        // 验证手机号格式（简单验证，11位数字）
        if (phoneNumber == null || !phoneNumber.matches("^1[3-9]\\d{9}$")) {
            logger.error("手机号格式错误：{}", phoneNumber);
            return false;
        }

        try {
            String provider = smsConfig.getProvider() != null ? smsConfig.getProvider() : "custom";
            
            switch (provider.toLowerCase()) {
                case "juhe":
                    return sendSmsByJuhe(phoneNumber, message);
                case "twilio":
                    return sendSmsByTwilio(phoneNumber, message);
                case "custom":
                default:
                    return sendSmsByCustom(phoneNumber, message);
            }
        } catch (Exception e) {
            logger.error("发送短信失败 - 手机号：{}，错误：{}", phoneNumber, e.getMessage(), e);
            return false;
        }
    }

    @Override
    public boolean sendSmsWithTemplate(String phoneNumber, String templateCode, String... params) {
        // 如果有模板ID配置，使用模板发送
        if (smsConfig.getTemplateId() != null && !smsConfig.getTemplateId().isEmpty()) {
            // 根据平台要求格式化模板参数
            // 这里简化处理，实际使用时需要根据具体平台调整
            String message = buildTemplateMessage(smsConfig.getTemplateId(), params);
            return sendSms(phoneNumber, message);
        }
        
        // 否则使用普通短信发送
        if (params != null && params.length > 0) {
            String message = String.join("，", params);
            return sendSms(phoneNumber, message);
        }
        
        return false;
    }

    /**
     * 通过聚合数据平台发送短信
     * ⚠️ 注意：聚合数据仅支持企业用户，个人用户无法使用
     * 此方法保留用于企业用户，个人用户请使用 custom 方式
     */
    private boolean sendSmsByJuhe(String phoneNumber, String message) {
        try {
            String apiKey = smsConfig.getJuhe().getAppKey();
            if (apiKey == null || apiKey.isEmpty()) {
                logger.error("聚合数据API Key未配置");
                return false;
            }

            String url = "http://v.juhe.cn/sms/send";
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("mobile", phoneNumber);
            params.add("tpl_id", smsConfig.getJuhe().getTemplateId() != null ? 
                       smsConfig.getJuhe().getTemplateId() : "模板ID");
            params.add("tpl_value", "#code#=" + message); // 根据实际模板调整
            params.add("key", apiKey);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(params, headers);

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, request, String.class);
            
            // 解析响应
            JsonNode jsonNode = objectMapper.readTree(response.getBody());
            int errorCode = jsonNode.path("error_code").asInt();
            
            if (errorCode == 0) {
                logger.info("聚合数据短信发送成功 - 手机号：{}", phoneNumber);
                return true;
            } else {
                String errorMsg = jsonNode.path("reason").asText();
                logger.error("聚合数据短信发送失败 - 手机号：{}，错误码：{}，错误信息：{}", 
                            phoneNumber, errorCode, errorMsg);
                return false;
            }
        } catch (Exception e) {
            logger.error("聚合数据短信发送异常 - 手机号：{}，错误：{}", phoneNumber, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 通过Twilio平台发送短信
     * 支持个人用户，全球知名平台
     * 注意：需要国际格式手机号（中国手机号需要加 +86）
     */
    private boolean sendSmsByTwilio(String phoneNumber, String message) {
        try {
            String accountSid = smsConfig.getTwilio().getAccountSid();
            String authToken = smsConfig.getTwilio().getAuthToken();
            String fromNumber = smsConfig.getTwilio().getFromNumber();
            
            // 调试日志（检查配置是否正确读取）- 使用INFO级别确保能看到
            logger.info("=== Twilio配置检查 ===");
            logger.info("Account SID: {}", accountSid != null ? accountSid : "NULL");
            logger.info("Auth Token: {}", authToken != null && authToken.length() > 4 ? authToken.substring(0, 4) + "***" : "NULL");
            logger.info("From Number: {}", fromNumber != null ? fromNumber : "NULL");
            logger.info("===================");
            
            if (accountSid == null || accountSid.isEmpty() ||
                authToken == null || authToken.isEmpty() ||
                fromNumber == null || fromNumber.isEmpty()) {
                logger.error("Twilio配置不完整 - Account SID: {}, Auth Token: {}, From Number: {}", 
                            accountSid != null ? accountSid : "null",
                            authToken != null ? "***" : "null",
                            fromNumber != null ? fromNumber : "null");
                return false;
            }
            
            // 额外验证：检查Account SID格式（Twilio的Account SID通常以AC开头）
            if (!accountSid.startsWith("AC")) {
                logger.warn("Account SID格式异常，通常应该以AC开头，当前值: {}", accountSid);
            }

            // Twilio需要国际格式手机号
            String formattedPhone;
            if (phoneNumber.startsWith("+")) {
                formattedPhone = phoneNumber;
            } else if (phoneNumber.startsWith("86")) {
                formattedPhone = "+" + phoneNumber;
            } else {
                formattedPhone = "+86" + phoneNumber; // 中国手机号加+86
            }

            String url = String.format("https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json", accountSid);
            
            // Twilio使用Basic Auth
            String auth = accountSid + ":" + authToken;
            String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes(StandardCharsets.UTF_8));
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Authorization", "Basic " + encodedAuth);
            
            MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
            params.add("From", fromNumber);
            params.add("To", formattedPhone);
            params.add("Body", message);
            
            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(params, headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, request, String.class);
            
            // 解析响应
            String responseBody = response.getBody();
            logger.info("Twilio短信API响应 - 手机号：{}，响应：{}", phoneNumber, responseBody);
            
            if (response.getStatusCode().is2xxSuccessful() && responseBody != null) {
                JsonNode jsonNode = objectMapper.readTree(responseBody);
                String status = jsonNode.path("status").asText();
                if ("queued".equals(status) || "sent".equals(status) || "delivered".equals(status)) {
                    logger.info("Twilio短信发送成功 - 手机号：{}", phoneNumber);
                    return true;
                } else {
                    String errorMsg = jsonNode.path("message").asText();
                    logger.error("Twilio短信发送失败 - 手机号：{}，状态：{}，错误：{}", 
                                phoneNumber, status, errorMsg);
                    return false;
                }
            } else {
                logger.error("Twilio短信发送失败 - 手机号：{}，HTTP状态：{}", 
                            phoneNumber, response.getStatusCode());
                return false;
            }
        } catch (Exception e) {
            logger.error("Twilio短信发送异常 - 手机号：{}，错误：{}", phoneNumber, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 通过自定义HTTP API发送短信（通用方式）
     * 适用于大多数HTTP API短信平台
     */
    private boolean sendSmsByCustom(String phoneNumber, String message) {
        try {
            String apiUrl = smsConfig.getApiUrl();
            String apiKey = smsConfig.getApiKey();
            
            if (apiUrl == null || apiUrl.isEmpty()) {
                logger.error("短信API地址未配置");
                return false;
            }
            
            if (apiKey == null || apiKey.isEmpty()) {
                logger.error("短信API密钥未配置");
                return false;
            }

            // 构建请求参数（根据平台要求调整参数名）
            Map<String, String> params = new HashMap<>();
            params.put("mobile", phoneNumber);
            params.put("content", message);
            params.put("key", apiKey); // 根据平台调整为 apiKey、appKey、accessKey 等
            
            // 如果有签名配置，添加签名
            if (smsConfig.getSign() != null && !smsConfig.getSign().isEmpty()) {
                params.put("sign", smsConfig.getSign());
            }

            // 发送POST请求
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
            MultiValueMap<String, String> formParams = new LinkedMultiValueMap<>();
            params.forEach(formParams::add);
            
            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(formParams, headers);
            ResponseEntity<String> response = restTemplate.exchange(apiUrl, HttpMethod.POST, request, String.class);
            
            // 解析响应（根据平台响应格式调整）
            String responseBody = response.getBody();
            logger.info("短信API响应 - 手机号：{}，响应：{}", phoneNumber, responseBody);
            
            // 简单判断：如果响应包含"success"或"成功"等关键词，认为发送成功
            // 实际使用时需要根据平台的具体响应格式解析
            if (responseBody != null && 
                (responseBody.toLowerCase().contains("success") || 
                 responseBody.contains("成功") ||
                 responseBody.contains("\"code\":0") ||
                 responseBody.contains("\"status\":\"success\""))) {
                logger.info("短信发送成功 - 手机号：{}", phoneNumber);
                return true;
            } else {
                logger.warn("短信发送可能失败 - 手机号：{}，响应：{}", phoneNumber, responseBody);
                return false;
            }
        } catch (Exception e) {
            logger.error("自定义API短信发送异常 - 手机号：{}，错误：{}", phoneNumber, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 构建模板消息（简化处理）
     */
    private String buildTemplateMessage(String templateId, String... params) {
        // 这里简化处理，实际使用时需要根据平台模板要求格式化
        if (params == null || params.length == 0) {
            return "";
        }
        return String.join("，", params);
    }
}

