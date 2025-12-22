package com.example.springboot.security;

import com.example.springboot.common.Constants;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT Token生成和验证工具类
 */
@Component
public class JwtTokenProvider {
    
    private final SecretKey secretKey;
    private final long expirationTime;
    
    public JwtTokenProvider() {
        // 从常量读取密钥和过期时间
        String secret = Constants.JWT_SECRET;
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationTime = Constants.JWT_EXPIRATION_SECONDS * 1000; // 转换为毫秒
    }
    
    /**
     * 生成Token
     * @param identifier 用户标识符
     * @param userType 用户类型（patient/doctor/admin）
     * @param userId 用户ID
     * @return JWT Token字符串
     */
    public String generateToken(String identifier, String userType, Long userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expirationTime);
        
        Map<String, Object> claims = new HashMap<>();
        claims.put("userType", userType);
        claims.put("userId", userId);
        
        return Jwts.builder()
                .subject(identifier)
                .claims(claims)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(secretKey)
                .compact();
    }
    
    /**
     * 从Token中获取用户标识符
     */
    public String getIdentifierFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return claims.getSubject();
    }
    
    /**
     * 从Token中获取用户类型
     */
    public String getUserTypeFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        return (String) claims.get("userType");
    }
    
    /**
     * 从Token中获取用户ID
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = getClaimsFromToken(token);
        Object userId = claims.get("userId");
        if (userId instanceof Integer) {
            return ((Integer) userId).longValue();
        }
        return (Long) userId;
    }
    
    /**
     * 验证Token是否有效
     */
    public boolean validateToken(String token) {
        try {
            getClaimsFromToken(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
    
    /**
     * 检查Token是否过期
     */
    public boolean isTokenExpired(String token) {
        try {
            Claims claims = getClaimsFromToken(token);
            Date expiration = claims.getExpiration();
            return expiration.before(new Date());
        } catch (JwtException e) {
            return true;
        }
    }
    
    /**
     * 从Token中解析Claims
     */
    private Claims getClaimsFromToken(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}

