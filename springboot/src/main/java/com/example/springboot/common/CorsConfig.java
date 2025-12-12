package com.example.springboot.common;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * 跨域配置
 * 注意：此配置已被 WebSecurityConfig 中的 CORS 配置替代
 * 保留此类但禁用，避免配置冲突
 */
@Configuration
public class CorsConfig {

    // 已禁用，使用 WebSecurityConfig 中的 CORS 配置
    // @Bean
    // public CorsFilter corsFilter() {
    //     UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    //     CorsConfiguration corsConfiguration = new CorsConfiguration();
    //     corsConfiguration.addAllowedOrigin("*");
    //     corsConfiguration.addAllowedHeader("*");
    //     corsConfiguration.addAllowedMethod("*");
    //     source.registerCorsConfiguration("/**", corsConfiguration);
    //     return new CorsFilter(source);
    // }
}