@echo off
chcp 65001 >nul
echo ========================================
echo 真机调试网络问题 - 完整诊断工具
echo ========================================
echo.

echo [1] 检查后端服务...
netstat -ano | findstr :8080 | findstr LISTENING
if %errorlevel% == 0 (
    echo ✓ 后端服务正在运行
) else (
    echo ✗ 后端服务未运行！请先启动SpringBoot
    pause
    exit
)

echo.
echo [2] 检查IP地址...
echo 你的电脑IP地址：
ipconfig | findstr /i "IPv4"

echo.
echo [3] 检查防火墙状态...
netsh advfirewall show allprofiles state | findstr "状态"
echo.
echo 如果显示"开启"，可能需要添加防火墙规则
echo.

echo [4] 测试本地连接...
echo 正在测试 localhost:8080...
curl -s -o nul -w "HTTP状态码: %%{http_code}\n" http://localhost:8080 --max-time 5
if %errorlevel% == 0 (
    echo ✓ 本地连接正常
) else (
    echo ✗ 本地连接失败，后端可能有问题
)

echo.
echo [5] 解决方案：
echo.
echo 方案A：临时关闭防火墙测试
echo   1. 控制面板 → Windows Defender 防火墙
echo   2. 启用或关闭 Windows Defender 防火墙
echo   3. 临时关闭（仅测试）
echo.
echo 方案B：添加防火墙规则
echo   1. 控制面板 → Windows Defender 防火墙 → 高级设置
echo   2. 入站规则 → 新建规则
echo   3. 选择"端口" → TCP → 8080
echo   4. 允许连接
echo.
echo 方案C：使用内网穿透工具（如果以上都不行）
echo   推荐使用：ngrok 或 frp
echo.

pause


