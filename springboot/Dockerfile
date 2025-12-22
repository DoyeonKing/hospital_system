# Spring Boot 应用 Dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build

# 设置工作目录
WORKDIR /app

# 复制所有文件
COPY pom.xml .
COPY src ./src

# 直接构建（Maven 会自动下载依赖）
RUN mvn clean package -DskipTests

# 运行阶段（使用 Debian 基础镜像，Alpine 缺少 deeplearning4j 需要的原生库）
FROM eclipse-temurin:21-jre

WORKDIR /app

# 创建必要的目录
RUN mkdir -p /app/uploads /app/images/doctors /app/models

# 从构建阶段复制 JAR 文件
COPY --from=build /app/target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动应用
ENTRYPOINT ["java", "-jar", "app.jar"]

