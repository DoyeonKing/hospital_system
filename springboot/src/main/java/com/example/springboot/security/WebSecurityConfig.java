package com.example.springboot.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;

@Configuration
@EnableWebSecurity
public class WebSecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 1. 禁用 CSRF
                .csrf(AbstractHttpConfigurer::disable)

                // 2. 启用 CORS 配置，并使用下面定义的 corsConfigurationSource() Bean
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // 3. 授权配置
                .authorizeHttpRequests(authorize -> authorize

                        // 明确放行所有 OPTIONS 请求 (CORS Preflight Request)
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // 允许所有 /api/** 路径
                        .requestMatchers("/api/**").permitAll()

                        // 允许 Swagger 访问
                        .requestMatchers("/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()

                        // 暂时允许所有其他请求，生产环境需要更严格的认证
                        .anyRequest().permitAll()
                );

        return http.build();
    }

    // 4. CORS 配置源 Bean (关键修改)
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // 💡 使用allowedOriginPatterns支持通配符和null origin
        // 这样可以同时支持HTTP服务器和file://协议打开的HTML文件
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "http://localhost:*",      // 允许所有localhost端口
            "http://127.0.0.1:*",      // 允许所有127.0.0.1端口
            "null"                      // 允许file://协议（浏览器发送null作为origin）
        ));

        // 允许常用方法 (GET, POST, PUT, DELETE, OPTIONS)
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));

        // 允许所有请求头
        configuration.setAllowedHeaders(Arrays.asList("*"));

        // 允许发送 Cookie 或认证信息
        // 注意：使用allowedOriginPatterns时，可以设置allowCredentials为true
        configuration.setAllowCredentials(true);

        // 暴露响应头（允许前端访问）
        configuration.setExposedHeaders(Arrays.asList("*"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        // 对所有路径生效
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
