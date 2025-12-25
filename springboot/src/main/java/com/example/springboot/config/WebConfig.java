package com.example.springboot.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// WebConfig.java（新建或修改现有配置类）
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir:images/doctors/}")
    private String uploadDir;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                // 假设前端通过80端口访问，后端通过其他端口
                .allowedOrigins(
                        "http://123.249.30.241",
                        "http://123.249.30.241:80",
                        "http://localhost"
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 映射本地文件夹到URL路径
        registry.addResourceHandler("/images/doctors/**")
                .addResourceLocations("file:" + uploadDir);

        // 如果需要，保留原有的 images 映射
        registry.addResourceHandler("/images/**")
                .addResourceLocations("file:images/");
        
        // 添加请假证明文件的映射（简单方式）
        registry.addResourceHandler("/api/files/leave-proofs/**")
                .addResourceLocations("file:uploads/leave-proofs/");
        
        // 添加身份证明材料的映射（简单方式，参考医生照片）
        registry.addResourceHandler("/api/files/identity-proofs/**")
                .addResourceLocations("file:uploads/identity-proofs/");
    }
}