package com.example.springboot.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;

/**
 * ND4J 后端初始化配置
 * 注意：ND4J 会在首次使用时自动初始化，不需要在 @PostConstruct 中强制初始化
 * 如果强制初始化失败会导致应用无法启动，因此改为延迟初始化
 */
@Configuration
public class Nd4jConfig {

    private static final Logger logger = LoggerFactory.getLogger(Nd4jConfig.class);

    /**
     * 延迟初始化 ND4J（在实际使用时才初始化）
     * 这样可以避免应用启动时因为 ND4J 初始化失败而无法启动
     */
    public static void ensureInitialized() {
        try {
            org.nd4j.linalg.factory.Nd4j.getBackend();
            logger.debug("✅ ND4J 后端已就绪");
        } catch (Exception e) {
            logger.warn("⚠️ ND4J 后端未就绪，将使用降级模式: {}", e.getMessage());
        }
    }
}

