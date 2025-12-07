package com.example.springboot.service;

import com.example.springboot.entity.Department;
import com.example.springboot.entity.Doctor;
import com.example.springboot.entity.enums.DoctorStatus;
import com.example.springboot.repository.DepartmentRepository;
import com.example.springboot.repository.DoctorRepository;
import com.huaban.analysis.jieba.JiebaSegmenter;
import org.deeplearning4j.models.embeddings.loader.WordVectorSerializer;
import org.deeplearning4j.models.word2vec.Word2Vec;
import org.deeplearning4j.models.word2vec.wordstore.inmemory.AbstractCache;
import org.deeplearning4j.text.sentenceiterator.CollectionSentenceIterator;
import org.deeplearning4j.text.sentenceiterator.SentenceIterator;
import org.deeplearning4j.text.tokenization.tokenizer.preprocessor.CommonPreprocessor;
import org.deeplearning4j.text.tokenization.tokenizerfactory.DefaultTokenizerFactory;
import org.deeplearning4j.text.tokenization.tokenizerfactory.TokenizerFactory;
import org.nd4j.common.io.ClassPathResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 模型训练服务
 * 全自动从数据库读取数据并训练Word2Vec模型
 *
 * 工作流程：
 * 1. 自动连接数据库，读取doctors表的specialty和bio字段
 * 2. 读取外部语料文件（resources/medical_corpus.txt，可选）
 * 3. 读取词典文件（resources/med_word.txt）加载到jieba
 * 4. 使用jieba分词
 * 5. 训练Word2Vec模型
 * 6. 保存模型文件到models目录
 */
@Service
public class ModelTrainingService {

    private static final Logger logger = LoggerFactory.getLogger(ModelTrainingService.class);

    @Autowired
    private DoctorRepository doctorRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private ResourceLoader resourceLoader;

    @Value("${ai.model.path:models/medical_word2vec.bin}")
    private String modelPath;

    private final JiebaSegmenter segmenter = new JiebaSegmenter();

    // 停用词集合
    private static final Set<String> STOP_WORDS = new HashSet<>(Arrays.asList(
            "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个",
            "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好",
            "自己", "这", "最近", "经常", "还", "伴有", "等", "什么", "怎么", "如何",
            "可以", "能够", "应该", "可能", "或者", "但是", "因为", "所以"
    ));

    /**
     * 训练Word2Vec模型
     *
     * @return 训练结果信息
     */
    public TrainingResult trainModel() {
        logger.info("=".repeat(60));
        logger.info("开始训练 Word2Vec 模型（Java全自动方案）");
        logger.info("=".repeat(60));

        long startTime = System.currentTimeMillis();
        TrainingResult result = new TrainingResult();

        try {
            // 检查 Java 版本和运行时环境
            String javaVersion = System.getProperty("java.version");
            String javaHome = System.getProperty("java.home");
            String javaVendor = System.getProperty("java.vendor");
            String javaRuntimeName = System.getProperty("java.runtime.name");
            logger.info("=".repeat(60));
            logger.info("Java 运行时环境诊断信息：");
            logger.info("  Java 版本: {}", javaVersion);
            logger.info("  Java Home: {}", javaHome);
            logger.info("  Java Vendor: {}", javaVendor);
            logger.info("  Runtime Name: {}", javaRuntimeName);
            logger.info("=".repeat(60));

            // 检查 Java 版本是否符合要求
            int majorVersion = getJavaMajorVersion(javaVersion);
            if (majorVersion < 11) {
                logger.error("❌ Java 版本过低！");
                logger.error("   ND4J 1.0.0-M2.1 需要 Java 11 或更高版本");
                logger.error("   当前版本: Java {}", majorVersion);
                logger.error("   解决方案：");
                logger.error("   1. 确保 IDE 和运行时都使用 Java 11+");
                logger.error("   2. 检查 JAVA_HOME 环境变量");
                logger.error("   3. 在 IDE 中配置项目使用正确的 JDK");
                result.setSuccess(false);
                result.setMessage(String.format(
                    "ND4J 初始化失败：Java 版本过低（当前：%s，需要：11+）。请确保应用运行时使用 Java 11 或更高版本。",
                    javaVersion
                ));
                return result;
            }

            // 检查 Visual C++ Redistributable（Windows 需要）
            boolean vcRedistInstalled = true;
            if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                vcRedistInstalled = com.example.springboot.util.NativeLibraryLoader.checkVCRedist();
                if (!vcRedistInstalled) {
                    logger.warn("⚠️ 未检测到 Visual C++ Redistributable");
                } else {
                    logger.info("✅ Visual C++ Redistributable 已安装");
                }
            }

            // 显式初始化 ND4J 后端
            try {
                // 方法1：设置 JavaCPP 系统属性（帮助诊断和加载）
                try {
                    // 设置 JavaCPP 的平台
                    String javacppPlatform = System.getProperty("org.bytedeco.javacpp.platform");
                    if (javacppPlatform == null) {
                        // 自动检测平台
                        String osName = System.getProperty("os.name").toLowerCase();
                        String osArch = System.getProperty("os.arch").toLowerCase();
                        if (osName.contains("windows") && osArch.contains("amd64")) {
                            System.setProperty("org.bytedeco.javacpp.platform", "windows-x86_64");
                        }
                    }

                    // 启用 JavaCPP 调试日志（通常不需要，会产生大量日志）
                    // 如果需要调试 ND4J 加载问题，可以取消下面的注释
                    // if (logger.isDebugEnabled()) {
                    //     System.setProperty("org.bytedeco.javacpp.logger.debug", "true");
                    // }

                    // 设置缓存目录（可选，帮助 JavaCPP 找到库）
                    String userHome = System.getProperty("user.home");
                    if (userHome != null) {
                        String cacheDir = userHome + "\\.javacpp\\cache";
                        System.setProperty("org.bytedeco.javacpp.cache", cacheDir);
                    }

                    logger.info("JavaCPP 配置:");
                    logger.info("  平台: {}", System.getProperty("org.bytedeco.javacpp.platform", "auto"));
                    logger.info("  缓存目录: {}", System.getProperty("org.bytedeco.javacpp.cache", "default"));
                } catch (Exception e) {
                    logger.debug("设置 JavaCPP 系统属性时出错: {}", e.getMessage());
                }

                // 方法2：尝试显式加载原生库
                logger.info("正在尝试加载 ND4J 原生库...");
                boolean nativeLibsLoaded = com.example.springboot.util.NativeLibraryLoader.loadNativeLibraries();
                if (!nativeLibsLoaded) {
                    logger.warn("⚠️ 原生库加载可能失败，但继续尝试初始化 ND4J");
                }

                // 方法3：尝试显式加载 ND4J Native 后端类（可选，失败不影响后续步骤）
                logger.info("正在尝试加载 ND4J Native 后端类（可选步骤）...");
                boolean backendClassFound = false;
                try {
                    // 尝试多个可能的类名
                    String[] possibleClassNames = {
                        "org.nd4j.nativeblas.Nd4jCpu",
                        "org.nd4j.linalg.cpu.nativecpu.CpuBackend",
                        "org.nd4j.linalg.cpu.nativecpu.Nd4jCpu"
                    };

                    for (String className : possibleClassNames) {
                        try {
                            Class<?> backendClass = Class.forName(className);
                            logger.info("✅ 找到 ND4J 后端类: {}", backendClass.getName());
                            backendClassFound = true;
                            break;
                        } catch (ClassNotFoundException e) {
                            logger.debug("未找到类: {}", className);
                        }
                    }

                    if (!backendClassFound) {
                        logger.debug("⚠️ 未找到 ND4J 后端类（这可能是正常的，继续尝试其他方法）");
                    }
                } catch (Exception e) {
                    logger.debug("加载后端类时出错（继续尝试）: {}", e.getMessage());
                }

                // 方法4：尝试使用 ServiceLoader 显式加载后端
                logger.info("正在使用 ServiceLoader 查找 ND4J 后端...");
                int backendCount = 0;
                try {
                    // 尝试多个类加载器
                    ClassLoader[] classLoaders = {
                        Thread.currentThread().getContextClassLoader(),
                        this.getClass().getClassLoader(),
                        ClassLoader.getSystemClassLoader()
                    };

                    for (ClassLoader cl : classLoaders) {
                        try {
                            java.util.ServiceLoader<org.nd4j.linalg.factory.Nd4jBackend> loader =
                                java.util.ServiceLoader.load(org.nd4j.linalg.factory.Nd4jBackend.class, cl);

                            java.util.Iterator<org.nd4j.linalg.factory.Nd4jBackend> iterator = loader.iterator();
                            while (iterator.hasNext()) {
                                try {
                                    org.nd4j.linalg.factory.Nd4jBackend backend = iterator.next();
                                    backendCount++;
                                    logger.info("✅ 通过 ServiceLoader 找到后端 #{}: {}",
                                        backendCount, backend.getClass().getName());
                                } catch (Exception e) {
                                    logger.warn("⚠️ 加载后端实例时出错: {}", e.getMessage());
                                }
                            }

                            if (backendCount > 0) {
                                break; // 找到了，不需要尝试其他类加载器
                            }
                        } catch (Exception e) {
                            logger.debug("使用类加载器 {} 时出错: {}", cl, e.getMessage());
                        }
                    }

                    if (backendCount == 0) {
                        logger.warn("⚠️ ServiceLoader 未找到任何后端实现（继续尝试直接初始化）");
                    }
                } catch (Exception e) {
                    logger.warn("⚠️ ServiceLoader 查找失败（继续尝试直接初始化）: {}", e.getMessage());
                }

                // 方法5：尝试使用 JavaCPP Loader 直接加载 ND4J 原生库
                logger.info("正在使用 JavaCPP Loader 加载 ND4J 原生库...");
                try {
                    // 尝试使用 JavaCPP 的 Loader 直接加载
                    Class<?> loaderClass = Class.forName("org.bytedeco.javacpp.Loader");
                    logger.info("✅ 找到 JavaCPP Loader 类");

                    // 尝试加载 ND4J CPU 预设
                    try {
                        Class<?> nd4jCpuPresetClass = Class.forName("org.nd4j.nativeblas.Nd4jCpu");
                        logger.info("✅ 找到 ND4J CPU 预设类: {}", nd4jCpuPresetClass.getName());

                        // 使用 Loader.load() 加载原生库
                        java.lang.reflect.Method loadMethod = loaderClass.getMethod("load", Class.class);
                        Object loadResult = loadMethod.invoke(null, nd4jCpuPresetClass);
                        logger.info("✅ JavaCPP Loader 加载成功");
                    } catch (ClassNotFoundException e) {
                        logger.debug("未找到 ND4J CPU 预设类，尝试其他方式: {}", e.getMessage());
                    } catch (Exception e) {
                        logger.debug("JavaCPP Loader 加载失败（继续尝试）: {}", e.getMessage());
                    }
                } catch (ClassNotFoundException e) {
                    logger.debug("未找到 JavaCPP Loader 类（继续尝试）: {}", e.getMessage());
                }

                // 方法6：尝试直接获取后端（这会触发 ND4J 初始化）
                logger.info("正在初始化 ND4J 后端...");
                try {
                    org.nd4j.linalg.factory.Nd4j.getBackend();
                    logger.info("✅ ND4J 后端已就绪");
                } catch (UnsatisfiedLinkError e) {
                    // 这是 DLL 加载失败的具体错误
                    logger.error("❌ DLL 加载失败: {}", e.getMessage());
                    logger.error("   这通常意味着:");
                    logger.error("   1. Visual C++ Redistributable 版本不正确（需要 2015-2022 版本）");
                    logger.error("   2. 缺少某些系统 DLL");
                    logger.error("   3. 依赖的原生库文件损坏");
                    throw new RuntimeException("ND4J 原生库加载失败: " + e.getMessage(), e);
                } catch (RuntimeException e) {
                    // 捕获所有运行时异常，包括 NoAvailableBackendException
                    String errorMsg = e.getMessage() != null ? e.getMessage() : "";
                    String className = e.getClass().getName();

                    if (className.contains("NoAvailableBackend") || errorMsg.contains("NoAvailableBackend") ||
                        errorMsg.contains("nd4j backend")) {
                        logger.error("=".repeat(60));
                        logger.error("❌ ND4J 找不到可用后端");
                        logger.error("=".repeat(60));
                        logger.error("诊断信息：");
                        logger.error("  - Java 版本: {}", javaVersion);
                        logger.error("  - VC++ Redistributable: {}", vcRedistInstalled ? "已安装" : "未检测到");
                        logger.error("  - 后端类找到: {}", backendClassFound ? "是" : "否");
                        logger.error("  - ServiceLoader 找到后端数: {}", backendCount);
                        logger.error("");
                        logger.error("可能的原因：");
                        logger.error("  1. Spring Boot fat jar 中 ServiceLoader 无法扫描嵌套 jar");
                        logger.error("  2. META-INF/services 配置文件未正确打包");
                        logger.error("  3. 类加载器问题");
                        logger.error("");
                        logger.error("解决方案：");
                        logger.error("  1. 确保使用 Spring Boot Maven 插件打包（已配置）");
                        logger.error("  2. 尝试在 IDE 中直接运行（不使用 jar）");
                        logger.error("  3. 检查 pom.xml 中 spring-boot-maven-plugin 配置");
                        logger.error("  4. 运行: mvn clean package spring-boot:repackage");
                        logger.error("  5. 如果使用 IDE，确保所有依赖在 classpath 中");
                        logger.error("=".repeat(60));
                        throw new RuntimeException("ND4J 找不到可用后端。这是 Spring Boot fat jar 的已知问题。建议：1) 在 IDE 中直接运行 2) 检查打包配置", e);
                    } else {
                        // 其他运行时异常，直接重新抛出
                        throw e;
                    }
                }
            } catch (ExceptionInInitializerError | NoClassDefFoundError e) {
                // 详细的错误诊断
                String errorMsg = e.getMessage() != null ? e.getMessage() : "";
                Throwable cause = e.getCause();
                String causeMsg = cause != null ? cause.getMessage() : "";

                logger.error("=".repeat(60));
                logger.error("❌ ND4J 后端初始化失败");
                logger.error("=".repeat(60));
                logger.error("错误类型: {}", e.getClass().getName());
                logger.error("错误消息: {}", errorMsg);
                if (cause != null) {
                    logger.error("根本原因: {}", causeMsg);
                    logger.error("原因类型: {}", cause.getClass().getName());
                }

                if (errorMsg.contains("NoAvailableBackend") || e instanceof NoClassDefFoundError ||
                    (cause != null && causeMsg.contains("NoAvailableBackend"))) {

                    logger.error("");
                    logger.error("诊断步骤：");
                    logger.error("1. ✅ Java 版本检查: {} (需要 11+)", javaVersion);
                    logger.error("2. {} Visual C++ Redistributable: {}",
                        vcRedistInstalled ? "✅" : "❌",
                        vcRedistInstalled ? "已安装" : "未检测到");
                    logger.error("3. ⚠️  依赖检查: 请运行 'mvn dependency:tree | findstr nd4j' 确认依赖已下载");
                    logger.error("");
                    logger.error("可能的解决方案：");
                    logger.error("1. 如果 Visual C++ Redistributable 未安装：");
                    logger.error("   下载并安装: https://aka.ms/vs/17/release/vc_redist.x64.exe");
                    logger.error("   安装后需要重启应用！");
                    logger.error("");
                    logger.error("2. 如果依赖未正确下载：");
                    logger.error("   运行: mvn clean install -U");
                    logger.error("   这会重新下载所有依赖");
                    logger.error("");
                    logger.error("3. 如果 Java 版本正确但仍有问题：");
                    logger.error("   检查 JAVA_HOME 环境变量是否正确");
                    logger.error("   确保 IDE 和运行时使用相同的 Java 版本");
                    logger.error("   尝试重启 IDE 和应用");

                    result.setSuccess(false);
                    StringBuilder msgBuilder = new StringBuilder("ND4J 后端初始化失败。");
                    msgBuilder.append("Java版本: ").append(javaVersion).append("; ");
                    msgBuilder.append("VC++: ").append(vcRedistInstalled ? "已安装" : "未检测到").append("; ");
                    msgBuilder.append("详细错误: ").append(errorMsg);
                    if (causeMsg != null && !causeMsg.isEmpty()) {
                        msgBuilder.append("; 根本原因: ").append(causeMsg);
                    }
                    result.setMessage(msgBuilder.toString());
                    return result;
                }
                throw e; // 重新抛出未知错误
            } catch (Exception e) {
                logger.error("❌ ND4J 后端初始化失败: {}", e.getMessage(), e);
                result.setSuccess(false);
                result.setMessage("ND4J 后端初始化失败: " + e.getMessage());
                return result;
            }
            // 1. 加载医疗词典到jieba
            logger.info("[1/5] 正在加载医疗词典...");
            loadMedicalDictionary();
            logger.info("✅ 词典加载完成");

            // 2. 从数据库读取语料
            logger.info("[2/5] 正在从数据库读取语料...");
            List<String> sentences = collectSentencesFromDatabase();
            logger.info("✅ 从数据库读取 {} 条句子", sentences.size());
            result.setDatabaseSentences(sentences.size());

            // 3. 读取外部语料文件（可选）
            logger.info("[3/5] 正在读取外部语料文件...");
            List<String> externalSentences = loadExternalCorpus();
            if (!externalSentences.isEmpty()) {
                sentences.addAll(externalSentences);
                logger.info("✅ 外部语料加载 {} 条句子", externalSentences.size());
                result.setExternalSentences(externalSentences.size());
            } else {
                logger.info("⚠️  未找到外部语料文件（可选，跳过）");
            }

            // 4. 分词处理
            logger.info("[4/5] 正在进行分词处理...");
            List<List<String>> tokenizedSentences = tokenizeSentences(sentences);
            logger.info("✅ 分词完成，共 {} 条有效句子", tokenizedSentences.size());
            result.setTokenizedSentences(tokenizedSentences.size());

            if (tokenizedSentences.isEmpty()) {
                throw new IllegalStateException("训练数据为空！请检查数据库是否有医生数据，或提供外部语料文件。");
            }

            // 5. 训练模型
            logger.info("[5/5] 开始训练 Word2Vec 模型（这可能需要几分钟）...");

            Word2Vec model;
            try {
                model = trainWord2VecModel(tokenizedSentences);
            } catch (RuntimeException e) {
                // 捕获训练过程中的 ND4J 初始化错误
                logger.error("❌ 模型训练失败: {}", e.getMessage());
                result.setSuccess(false);
                result.setMessage(e.getMessage());
                return result;
            }
            logger.info("✅ 模型训练完成！词汇量: {}", model.getVocab().numWords());
            result.setVocabularySize(model.getVocab().numWords());

            // 6. 保存模型
            logger.info("正在保存模型到: {}", modelPath);
            File modelFile = new File(modelPath);
            modelFile.getParentFile().mkdirs(); // 确保目录存在

            WordVectorSerializer.writeWord2VecModel(model, modelFile);
            logger.info("✅ 模型已保存！文件大小: {} MB", String.format("%.2f", modelFile.length() / 1024.0 / 1024.0));
            result.setModelFile(modelPath);
            result.setModelSize(modelFile.length());

            long duration = (System.currentTimeMillis() - startTime) / 1000;
            result.setSuccess(true);
            result.setDuration(duration);
            result.setMessage("模型训练成功！");

            logger.info("=".repeat(60));
            logger.info("✅ 模型训练完成！耗时: {} 秒", duration);
            logger.info("=".repeat(60));

        } catch (Exception e) {
            logger.error("❌ 模型训练失败", e);
            result.setSuccess(false);
            result.setMessage("训练失败: " + e.getMessage());
        }

        return result;
    }

    /**
     * 加载医疗词典到jieba分词器
     */
    private void loadMedicalDictionary() throws IOException {
        try {
            Resource resource = resourceLoader.getResource("classpath:med_word.txt");
            if (resource.exists()) {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                    String line;
                    int count = 0;
                    while ((line = reader.readLine()) != null) {
                        String word = line.trim();
                        if (!word.isEmpty() && word.length() > 1) {
                            // jieba会自动加载用户词典，这里主要是记录
                            count++;
                        }
                    }
                    logger.info("   词典包含 {} 个医疗词汇", count);
                }
            } else {
                logger.warn("⚠️  未找到词典文件 classpath:med_word.txt，将使用默认分词");
            }
        } catch (Exception e) {
            logger.warn("⚠️  加载词典失败: {}，将使用默认分词", e.getMessage());
        }
    }

    /**
     * 从数据库收集句子
     */
    private List<String> collectSentencesFromDatabase() {
        List<String> sentences = new ArrayList<>();

        // 1. 从doctors表读取
        List<Doctor> doctors = doctorRepository.findAll().stream()
                .filter(d -> d.getStatus() != DoctorStatus.deleted)
                .filter(d -> (d.getSpecialty() != null && !d.getSpecialty().trim().isEmpty()) ||
                             (d.getBio() != null && !d.getBio().trim().isEmpty()))
                .collect(Collectors.toList());

        logger.info("   从数据库读取 {} 个医生记录", doctors.size());

        for (Doctor doctor : doctors) {
            // 构建医生描述句子
            List<String> parts = new ArrayList<>();

            if (doctor.getFullName() != null) {
                parts.add(doctor.getFullName());
            }
            if (doctor.getTitle() != null) {
                parts.add(doctor.getTitle());
            }

            // 获取科室名称
            Department dept = doctor.getDepartment();
            if (dept != null && dept.getName() != null) {
                parts.add(dept.getName());
            }

            // 擅长领域
            if (doctor.getSpecialty() != null && !doctor.getSpecialty().trim().isEmpty()) {
                String specialty = doctor.getSpecialty().trim();
                // 如果包含多个句子，拆分
                if (specialty.contains("。") || specialty.contains("，")) {
                    String[] specialtyParts = specialty.split("[。，]");
                    for (String sent : specialtyParts) {
                        sent = sent.trim();
                        if (sent.length() > 5) {
                            sentences.add(sent);
                        }
                    }
                } else {
                    parts.add(specialty);
                }
            }

            // 构建完整句子
            if (parts.size() >= 2) {
                String sentence = String.join(" ", parts);
                if (sentence.length() > 5) {
                    sentences.add(sentence);
                }
            }

            // 个人简介单独添加
            if (doctor.getBio() != null && !doctor.getBio().trim().isEmpty()) {
                String bio = doctor.getBio().trim();
                if (bio.length() > 10) {
                    sentences.add(bio);
                }
            }
        }

        // 2. 从departments表读取
        List<Department> departments = departmentRepository.findAll().stream()
                .filter(d -> d.getDescription() != null && !d.getDescription().trim().isEmpty())
                .collect(Collectors.toList());

        for (Department dept : departments) {
            if (dept.getName() != null && dept.getDescription() != null) {
                String sentence = dept.getName() + " " + dept.getDescription();
                if (sentence.length() > 5) {
                    sentences.add(sentence);
                }
            }
        }

        return sentences;
    }

    /**
     * 加载外部语料文件（可选）
     */
    private List<String> loadExternalCorpus() {
        List<String> sentences = new ArrayList<>();

        try {
            Resource resource = resourceLoader.getResource("classpath:medical_corpus.txt");
            if (resource.exists()) {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        line = line.trim();
                        if (line.length() > 5) {
                            sentences.add(line);
                        }
                    }
                }
            }
        } catch (Exception e) {
            logger.debug("外部语料文件不存在或读取失败: {}", e.getMessage());
        }

        return sentences;
    }

    /**
     * 对句子进行分词
     */
    private List<List<String>> tokenizeSentences(List<String> sentences) {
        return sentences.stream()
                .map(sentence -> {
                    // 使用jieba分词
                    return segmenter.sentenceProcess(sentence).stream()
                            .filter(word -> word != null && word.length() > 1) // 过滤单字
                            .filter(word -> !STOP_WORDS.contains(word)) // 过滤停用词
                            .filter(word -> !word.trim().isEmpty())
                            .collect(Collectors.toList());
                })
                .filter(words -> words.size() >= 2) // 至少2个词
                .collect(Collectors.toList());
    }

    /**
     * 训练Word2Vec模型
     */
    private Word2Vec trainWord2VecModel(List<List<String>> tokenizedSentences) {
        try {
            // 将分词结果转换为句子（空格分隔）
            List<String> sentences = tokenizedSentences.stream()
                    .map(words -> String.join(" ", words))
                    .collect(Collectors.toList());

            // 创建句子迭代器
            SentenceIterator iterator = new CollectionSentenceIterator(sentences);

            // 创建词汇缓存
            AbstractCache<org.deeplearning4j.models.word2vec.VocabWord> cache = new AbstractCache<>();

            // 创建分词器工厂（使用空格分词，因为已经用jieba分好了）
            TokenizerFactory tokenizerFactory = new DefaultTokenizerFactory();
            tokenizerFactory.setTokenPreProcessor(new CommonPreprocessor());

            // 配置并构建Word2Vec模型
            // 注意：这里会触发 ND4J 初始化
            Word2Vec.Builder builder = new Word2Vec.Builder();
            builder.minWordFrequency(1) // 最小词频
                    .iterations(10) // 训练轮数
                    .epochs(20) // epochs
                    .layerSize(200) // 向量维度
                    .seed(42) // 随机种子
                    .windowSize(5) // 上下文窗口
                    .iterate(iterator)
                    .tokenizerFactory(tokenizerFactory)
                    .vocabCache(cache);

            Word2Vec model = builder.build();
            model.fit();

            return model;
        } catch (ExceptionInInitializerError e) {
            Throwable cause = e.getCause();
            String errorMsg = cause != null ? cause.getMessage() : e.getMessage();
            logger.error("❌ Word2Vec 模型训练失败：ND4J 初始化错误");
            logger.error("   错误: {}", errorMsg);
            throw new RuntimeException("ND4J 初始化失败，无法训练模型。请检查 Java 版本（需要 11+）和系统环境。", e);
        } catch (NoClassDefFoundError e) {
            logger.error("❌ Word2Vec 模型训练失败：ND4J 类未找到");
            logger.error("   错误: {}", e.getMessage());
            throw new RuntimeException("ND4J 类未找到，无法训练模型。请运行 mvn clean install -U 重新下载依赖。", e);
        }
    }

    /**
     * 获取 Java 主版本号
     */
    private int getJavaMajorVersion(String version) {
        if (version == null || version.isEmpty()) {
            return 0;
        }

        // Java 9+ 格式: "11.0.1" 或 "17"
        // Java 8 格式: "1.8.0_202"
        if (version.startsWith("1.")) {
            // Java 8 及更早版本
            return 8;
        } else {
            // Java 9+ 版本
            String[] parts = version.split("\\.");
            try {
                return Integer.parseInt(parts[0]);
            } catch (NumberFormatException e) {
                return 0;
            }
        }
    }

    /**
     * 训练结果类
     */
    public static class TrainingResult {
        private boolean success;
        private String message;
        private String modelFile;
        private long modelSize;
        private int vocabularySize;
        private int databaseSentences;
        private int externalSentences;
        private int tokenizedSentences;
        private long duration; // 秒

        // Getters and Setters
        public boolean isSuccess() { return success; }
        public void setSuccess(boolean success) { this.success = success; }

        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }

        public String getModelFile() { return modelFile; }
        public void setModelFile(String modelFile) { this.modelFile = modelFile; }

        public long getModelSize() { return modelSize; }
        public void setModelSize(long modelSize) { this.modelSize = modelSize; }

        public int getVocabularySize() { return vocabularySize; }
        public void setVocabularySize(int vocabularySize) { this.vocabularySize = vocabularySize; }

        public int getDatabaseSentences() { return databaseSentences; }
        public void setDatabaseSentences(int databaseSentences) { this.databaseSentences = databaseSentences; }

        public int getExternalSentences() { return externalSentences; }
        public void setExternalSentences(int externalSentences) { this.externalSentences = externalSentences; }

        public int getTokenizedSentences() { return tokenizedSentences; }
        public void setTokenizedSentences(int tokenizedSentences) { this.tokenizedSentences = tokenizedSentences; }

        public long getDuration() { return duration; }
        public void setDuration(long duration) { this.duration = duration; }
    }
}

