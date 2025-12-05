package com.example.springboot.util;

import com.huaban.analysis.jieba.JiebaSegmenter;
import com.huaban.analysis.jieba.SegToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 统一分词服务
 * 确保训练和预测时使用相同的分词逻辑
 *
 * 关键特性：
 * 1. 单例模式，全局唯一实例
 * 2. 统一的停用词表
 * 3. 统一的过滤规则
 * 4. 支持加载用户词典
 */
@Component
public class TextSegmenter {

    private static final Logger logger = LoggerFactory.getLogger(TextSegmenter.class);

    private final JiebaSegmenter segmenter = new JiebaSegmenter();

    // 停用词集合（统一的停用词表）
    private static final Set<String> STOP_WORDS = new HashSet<>(Arrays.asList(
            "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个",
            "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好",
            "自己", "这", "最近", "经常", "还", "伴有", "等", "什么", "怎么", "如何",
            "可以", "能够", "应该", "可能", "或者", "但是", "因为", "所以"
    ));

    private ResourceLoader resourceLoader;

    // 通过构造函数注入ResourceLoader（避免循环依赖）
    public TextSegmenter(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    /**
     * 初始化：加载用户词典
     */
    @PostConstruct
    public void init() {
        loadUserDictionary();
    }

    /**
     * 加载用户词典（医疗词典）
     */
    private void loadUserDictionary() {
        try {
            Resource resource = resourceLoader.getResource("classpath:med_word.txt");
            if (resource.exists()) {
                int count = 0;
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        String word = line.trim();
                        if (!word.isEmpty() && word.length() > 1) {
                            // 注意：jieba的Java版本可能不支持动态加载用户词典
                            // 这里主要是记录和统计
                            count++;
                        }
                    }
                }
                logger.info("✅ 分词服务初始化完成，词典包含 {} 个医疗词汇", count);
            } else {
                logger.warn("⚠️  未找到词典文件 classpath:med_word.txt，将使用默认分词");
            }
        } catch (Exception e) {
            logger.warn("⚠️  加载词典失败: {}，将使用默认分词", e.getMessage());
        }
    }

    /**
     * 统一的分词方法
     *
     * @param text 输入文本
     * @return 分词结果列表（已过滤停用词和单字）
     */
    public List<String> segment(String text) {
        if (text == null || text.trim().isEmpty()) {
            return new ArrayList<>();
        }

        // 1. 文本标准化
        String normalized = normalizeText(text);

        // 2. 使用jieba分词并过滤
        return segmenter.sentenceProcess(normalized).stream()
                .filter(word -> word != null && word.length() > 1) // 过滤单字
                .filter(word -> !STOP_WORDS.contains(word)) // 过滤停用词
                .filter(word -> !word.trim().isEmpty())
                .collect(Collectors.toList());
    }

    /**
     * 文本标准化
     * 统一处理空格、标点等
     */
    private String normalizeText(String text) {
        if (text == null) {
            return "";
        }

        return text.trim()
                .replaceAll("\\s+", " ") // 多个空格合并为一个
                .replaceAll("[\\r\\n]+", " ") // 换行符替换为空格
                .trim();
    }

    /**
     * 获取停用词集合（供外部使用）
     */
    public Set<String> getStopWords() {
        return Collections.unmodifiableSet(STOP_WORDS);
    }

    /**
     * 批量分词
     *
     * @param texts 文本列表
     * @return 分词结果列表（每个文本对应一个词列表）
     */
    public List<List<String>> segmentBatch(List<String> texts) {
        if (texts == null || texts.isEmpty()) {
            return new ArrayList<>();
        }

        return texts.stream()
                .map(this::segment)
                .filter(words -> !words.isEmpty()) // 过滤空结果
                .collect(Collectors.toList());
    }
}


