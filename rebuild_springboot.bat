@echo off
echo ========================================
echo 清理并重新编译 Spring Boot 项目
echo ========================================
cd springboot
echo.
echo [1/3] 清理 Maven 项目...
call mvn clean
echo.
echo [2/3] 重新编译项目...
call mvn compile
echo.
echo [3/3] 打包项目...
call mvn package -DskipTests
echo.
echo ========================================
echo 完成！现在请重新启动 Spring Boot 应用
echo ========================================
pause


