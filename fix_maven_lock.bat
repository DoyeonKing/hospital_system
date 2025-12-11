@echo off
echo ========================================
echo Maven 锁文件清理工具
echo ========================================
echo.

echo [1/4] 检查 Java 进程...
tasklist | findstr /i "java.exe"
if %errorlevel% == 0 (
    echo 发现 Java 进程正在运行，建议先关闭 IDE 和所有 Java 程序
    pause
)

echo.
echo [2/4] 查找 Maven 本地仓库位置...
if exist "%USERPROFILE%\.m2\repository" (
    echo Maven 仓库位置: %USERPROFILE%\.m2\repository
) else (
    echo 未找到 Maven 本地仓库，可能使用自定义位置
    echo 请手动检查 IDE 中配置的 Maven 仓库路径
)

echo.
echo [3/4] 清理锁文件...
if exist "%USERPROFILE%\.m2\repository\.locks" (
    echo 删除 .locks 目录...
    rmdir /s /q "%USERPROFILE%\.m2\repository\.locks"
    echo 锁文件已清理
) else (
    echo 未找到 .locks 目录
)

echo.
echo [4/4] 查找其他可能的锁文件...
for /r "%USERPROFILE%\.m2\repository" %%f in (*.lock) do (
    echo 发现锁文件: %%f
    del /f /q "%%f"
    echo 已删除: %%f
)

echo.
echo ========================================
echo 清理完成！
echo ========================================
echo.
echo 下一步操作：
echo 1. 重新打开 IDE
echo 2. 在 IDE 中右键 pom.xml，选择 "Maven" -^> "Reload Project"
echo 3. 或者在 Maven 工具窗口中点击刷新按钮
echo.
pause

