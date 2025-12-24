package com.example.springboot.security;

import com.example.springboot.common.Result;
import com.example.springboot.repository.AdminRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

/**
 * JWT认证过滤器
 * 在请求到达Controller之前验证Token
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Autowired
    private JwtTokenProvider jwtTokenProvider;
    
    @Autowired
    private AdminRepository adminRepository;
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                    HttpServletResponse response, 
                                    FilterChain filterChain) 
            throws ServletException, IOException {
        
        // 获取Authorization请求头
        String authHeader = request.getHeader("Authorization");
        
        // 如果请求头为空或不以Bearer开头，直接放行（由Spring Security处理）
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        
        // 提取Token
        String token = authHeader.substring(7);
        
        try {
            // 验证Token
            if (jwtTokenProvider.validateToken(token) && !jwtTokenProvider.isTokenExpired(token)) {
                // 从Token中提取用户信息
                String identifier = jwtTokenProvider.getIdentifierFromToken(token);
                String userType = jwtTokenProvider.getUserTypeFromToken(token);
                Long userId = jwtTokenProvider.getUserIdFromToken(token);
                
                // 创建权限列表
                List<SimpleGrantedAuthority> authorities = new ArrayList<>();
                // 添加角色
                authorities.add(new SimpleGrantedAuthority("ROLE_" + userType.toUpperCase()));
                
                // 🔥 如果是管理员，加载其权限
                if ("admin".equalsIgnoreCase(userType) && userId != null) {
                    try {
                        Set<String> permissions = adminRepository.findPermissionNamesByAdminId(userId.intValue());
                        if (permissions != null && !permissions.isEmpty()) {
                            // 将权限添加到authorities（权限名称直接使用，不加ROLE_前缀）
                            for (String permission : permissions) {
                                authorities.add(new SimpleGrantedAuthority(permission));
                            }
                            System.out.println("JwtAuthenticationFilter: 为管理员 " + identifier + " 加载了 " + permissions.size() + " 个权限: " + permissions);
                        }
                    } catch (Exception e) {
                        System.err.println("JwtAuthenticationFilter: 加载管理员权限失败: " + e.getMessage());
                        // 即使权限加载失败，也继续处理请求，但只有角色权限
                    }
                }
                
                // 创建认证对象
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(
                        identifier, 
                        null, 
                        authorities
                    );
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                
                // 设置到SecurityContext
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } else {
                // Token无效或过期，返回401
                sendErrorResponse(response, "Token无效或已过期");
                return;
            }
        } catch (Exception e) {
            // Token解析失败，返回401
            sendErrorResponse(response, "Token解析失败: " + e.getMessage());
            return;
        }
        
        filterChain.doFilter(request, response);
    }
    
    private void sendErrorResponse(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json;charset=UTF-8");
        
        Result result = Result.error("401", message);
        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(result));
    }
}

