package com.example.springboot.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 原生库加载工具
 * 用于显式加载 ND4J 需要的原生库（OpenBLAS 等）
 */
public class NativeLibraryLoader {

    private static final Logger logger = LoggerFactory.getLogger(NativeLibraryLoader.class);
    private static boolean loaded = false;

    /**
     * 尝试加载原生库
     */
    public static boolean loadNativeLibraries() {
        if (loaded) {
            logger.debug("原生库已加载，跳过");
            return true;
        }

        logger.info("正在尝试加载 ND4J 原生库...");

        try {
            // 方法1：尝试显式加载 JavaCPP 的 Nd4jCpu 类（这会触发原生库加载）
            try {
                logger.debug("尝试加载 org.bytedeco.javacpp.Loader...");
                Class<?> loaderClass = Class.forName("org.bytedeco.javacpp.Loader");
                logger.debug("✅ JavaCPP Loader 类已找到");

                // 尝试加载 ND4J CPU 后端
                try {
                    logger.debug("尝试加载 org.nd4j.nativeblas.Nd4jCpu...");
                    Class<?> nd4jCpuClass = Class.forName("org.nd4j.nativeblas.Nd4jCpu");
                    Object loader = loaderClass.getMethod("load", Class.class).invoke(null, nd4jCpuClass);
                    logger.info("✅ 成功通过 JavaCPP 加载 ND4J 原生库");
                    loaded = true;
                    return true;
                } catch (Exception e) {
                    logger.debug("⚠️ 加载 Nd4jCpu 失败: {}", e.getMessage());
                }
            } catch (ClassNotFoundException e) {
                logger.warn("⚠️ 未找到 JavaCPP Loader 类，可能依赖未正确下载");
            }

            // 方法2：检查依赖是否在 classpath 中
            String classpath = System.getProperty("java.class.path");
            boolean hasNd4j = classpath != null && classpath.contains("nd4j-native");
            boolean hasOpenblas = classpath != null && classpath.contains("openblas");
            boolean hasJavacpp = classpath != null && classpath.contains("javacpp");

            logger.info("依赖检查:");
            logger.info("  - nd4j-native: {}", hasNd4j ? "✅" : "❌");
            logger.info("  - openblas: {}", hasOpenblas ? "✅" : "❌");
            logger.info("  - javacpp: {}", hasJavacpp ? "✅" : "❌");

            if (hasNd4j && hasOpenblas && hasJavacpp) {
                logger.info("✅ 所有必需依赖都在 classpath 中，JavaCPP 应该会自动加载");
                // JavaCPP 会在首次使用时自动加载，这里标记为已尝试
                loaded = true;
                return true;
            } else {
                logger.warn("⚠️ 缺少某些依赖，请运行: mvn clean install -U");
                return false;
            }

        } catch (Exception e) {
            logger.warn("⚠️ 加载原生库时出错: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * 检查 Visual C++ Redistributable 是否安装
     * （Windows 系统需要）
     */
    public static boolean checkVCRedist() {
        if (!System.getProperty("os.name").toLowerCase().contains("windows")) {
            return true; // 非 Windows 系统不需要
        }

        // 检查常见的 VCRedist 安装路径
        String[] possiblePaths = {
            "C:\\Windows\\System32\\vcruntime140.dll",
            "C:\\Windows\\System32\\msvcp140.dll",
            "C:\\Windows\\SysWOW64\\vcruntime140.dll"
        };

        for (String path : possiblePaths) {
            if (Files.exists(Paths.get(path))) {
                logger.debug("✅ 检测到 Visual C++ Redistributable: {}", path);
                return true;
            }
        }

        logger.warn("⚠️ 未检测到 Visual C++ Redistributable，可能需要安装");
        return false;
    }
}


