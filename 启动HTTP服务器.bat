@echo off
chcp 65001 >nul
echo ========================================
echo 启动HTTP服务器（用于打开HTML文件）
echo ========================================
echo.
echo 正在启动HTTP服务器...
echo 访问地址: http://localhost:8000
echo.
echo 打开以下页面进行测试：
echo   - http://localhost:8000/tools/qrcode_generator.html
echo   - http://localhost:8000/测试API连接.html
echo.
echo 按 Ctrl+C 停止服务器
echo ========================================
echo.

cd /d "%~dp0"
python -m http.server 8000

pause

