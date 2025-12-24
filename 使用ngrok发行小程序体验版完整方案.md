# 使用ngrok发行小程序体验版 - 完整详细方案

## 📋 方案概述

本方案将指导你使用ngrok免费域名，完成小程序体验版的发行，让其他人可以体验你的小程序。

**预计时间**：15-20分钟  
**难度**：⭐⭐（简单）  
**费用**：完全免费

---

## 🎯 第一步：安装和配置ngrok

### 1.1 注册ngrok账号

1. **访问ngrok官网**
   - 打开浏览器，访问：https://ngrok.com/
   - 点击右上角 **"Sign up"** 或 **"Get Started for Free"**

2. **注册账号**
   - 输入邮箱地址（建议使用常用邮箱）
   - 设置密码
   - 点击 **"Sign up"**
   - 去邮箱验证（点击验证链接）

3. **登录账号**
   - 验证后返回ngrok网站
   - 使用邮箱和密码登录

### 1.2 获取Authtoken

1. **进入Dashboard**
   - 登录后，会自动进入Dashboard
   - 或点击左侧菜单的 **"Your Authtoken"**

2. **复制Authtoken**
   - 你会看到一个类似这样的token：
     ```
     2abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
     ```
   - **复制这个token，保存好**（后面要用）

### 1.3 下载ngrok

1. **进入下载页面**
   - 在Dashboard点击 **"Download"** 或 **"Get Started"**
   - 或访问：https://ngrok.com/download

2. **选择Windows版本**
   - 选择 **Windows** 版本
   - 下载 `ngrok.exe` 文件

3. **解压文件**
   - 将 `ngrok.exe` 解压到一个固定文件夹
   - 建议路径：`C:\ngrok\ngrok.exe`
   - 或 `D:\tools\ngrok\ngrok.exe`
   - **记住这个路径！**

### 1.4 配置ngrok

1. **打开命令行**
   - 按 `Win + R`，输入 `cmd`，回车
   - 或按 `Win + X`，选择"Windows PowerShell"

2. **进入ngrok文件夹**
   ```bash
   cd C:\ngrok
   ```
   （替换成你的实际路径）

3. **配置Authtoken**
   ```bash
   ngrok config add-authtoken 你的authtoken
   ```
   （把"你的authtoken"替换成第1.2步复制的token）

4. **验证配置**
   - 如果显示 "Authtoken saved" 或类似提示，说明配置成功
   - 如果报错，检查token是否正确复制

---

## 🚀 第二步：启动ngrok并获取域名

### 2.1 确保Spring Boot运行

1. **检查Spring Boot是否运行**
   - 打开你的Spring Boot项目
   - 确保服务在 `localhost:8080` 运行
   - 可以在浏览器访问 `http://localhost:8080/swagger-ui.html` 测试

2. **如果没运行，启动它**
   ```bash
   # 在Spring Boot项目目录
   cd springboot
   mvn spring-boot:run
   ```
   或使用IDE运行

### 2.2 启动ngrok

1. **打开新的命令行窗口**
   - 保持Spring Boot运行
   - 打开新的命令行窗口

2. **进入ngrok文件夹**
   ```bash
   cd C:\ngrok
   ```

3. **启动ngrok**
   ```bash
   ngrok http 8080
   ```

4. **查看输出**
   - ngrok会显示类似这样的信息：
     ```
     Session Status                online
     Account                       your-email@example.com
     Version                       3.x.x
     Region                        United States (us)
     Latency                       45ms
     Web Interface                 http://127.0.0.1:4040
     Forwarding                    https://xxxxx.ngrok-free.app -> http://localhost:8080
     
     Connections                   ttl     opn     rt1     rt5     p50     p90
                                   0       0       0.00    0.00    0.00    0.00
     ```

5. **复制HTTPS域名**
   - 找到 `Forwarding` 这一行
   - 复制 `https://xxxxx.ngrok-free.app` 这个域名
   - **这就是你的免费域名！保存好！**

### 2.3 测试域名访问

1. **在浏览器测试**
   - 打开浏览器
   - 访问：`https://xxxxx.ngrok-free.app/swagger-ui.html`
   - 如果能打开，说明域名配置成功

2. **如果无法访问**
   - 检查Spring Boot是否在运行
   - 检查ngrok是否正常运行
   - 检查防火墙设置

---

## 📱 第三步：配置小程序代码

### 3.1 修改API配置

1. **打开配置文件**
   - 找到文件：`uni_app/config/index.js`
   - 用编辑器打开

2. **修改生产环境配置**
   ```javascript
   // ==================== 生产环境配置 ====================
   const production = {
       // 主后端服务（Spring Boot）- 改为你的ngrok域名
       baseURL: 'https://xxxxx.ngrok-free.app',  // 👈 替换成你的ngrok域名
       
       // AI 预问诊后端服务（Node.js）- 如果有，也改为ngrok域名
       aiBaseURL: 'https://xxxxx.ngrok-free.app'  // 👈 如果有AI服务，也改这里
   }
   
   // ==================== 环境切换 ====================
   const USE_PRODUCTION = true  // 👈 改为 true，使用生产环境
   ```

3. **保存文件**

### 3.2 检查其他配置

1. **检查manifest.json**
   - 确认 `appid` 正确：`wx163a1fc0af4eee09`
   - 确认其他配置正常

2. **检查project.config.json**
   - 确认 `appid` 正确

---

## 🔧 第四步：编译小程序

### 4.1 使用HBuilderX编译

1. **打开HBuilderX**
   - 打开HBuilderX编辑器
   - 打开 `uni_app` 项目文件夹

2. **检查项目**
   - 确认项目可以正常打开
   - 确认没有明显的错误

3. **编译为微信小程序**
   - 点击菜单：**发行** → **小程序-微信**
   - 或使用快捷键：`Ctrl + Shift + P`，输入"发行"
   - 选择 **小程序-微信（仅适用于uni-app）**

4. **等待编译完成**
   - 编译过程可能需要1-3分钟
   - 编译完成后会自动打开微信开发者工具
   - 编译产物在：`uni_app/unpackage/dist/build/mp-weixin/`

### 4.2 如果编译失败

1. **检查错误信息**
   - 查看控制台错误提示
   - 根据错误信息修复

2. **常见问题**
   - 语法错误：检查代码语法
   - 依赖问题：运行 `npm install`
   - 配置错误：检查配置文件

---

## 📤 第五步：上传到微信

### 5.1 使用微信开发者工具

1. **打开微信开发者工具**
   - 如果编译后自动打开，直接使用
   - 如果没有，手动打开微信开发者工具

2. **导入项目**
   - 项目目录：选择 `uni_app/unpackage/dist/build/mp-weixin/`
   - AppID：`wx163a1fc0af4eee09`
   - 项目名称：医院系统（或自定义）

3. **测试功能**
   - 在开发者工具中测试主要功能
   - 确认API请求正常
   - 查看控制台是否有错误

### 5.2 上传代码

1. **点击上传按钮**
   - 在微信开发者工具顶部工具栏
   - 点击 **"上传"** 按钮

2. **填写版本信息**
   ```
   版本号：1.0.0（或自定义）
   项目备注：体验版-使用ngrok域名（或自定义）
   ```

3. **确认上传**
   - 点击 **"上传"**
   - 等待上传完成（通常几秒钟）

---

## 🌐 第六步：配置微信公众平台

### 6.1 配置服务器域名

1. **登录微信公众平台**
   - 访问：https://mp.weixin.qq.com/
   - 使用小程序管理员账号登录

2. **进入开发设置**
   - 点击左侧菜单：**开发** → **开发管理** → **开发设置**
   - 或直接访问：https://mp.weixin.qq.com/wxopen/devprofile?action=get_setting

3. **配置服务器域名**
   - 找到 **服务器域名** 部分
   - 点击 **"修改"** 按钮

4. **添加域名**
   - 在 **request合法域名** 中添加：
     ```
     https://xxxxx.ngrok-free.app
     ```
   - （替换成你的实际ngrok域名）
   - **注意**：只填写域名部分，不要带路径

5. **保存配置**
   - 点击 **"保存并提交"**
   - 等待审核（通常几分钟）

### 6.2 设置为体验版

1. **进入版本管理**
   - 点击左侧菜单：**版本管理**
   - 或访问：https://mp.weixin.qq.com/wxopen/devprofile?action=get_version_list

2. **找到开发版本**
   - 在 **开发版本** 列表中
   - 找到刚才上传的版本

3. **设置为体验版**
   - 点击版本右侧的 **"选为体验版"** 按钮
   - 确认后，该版本会出现在 **体验版** 列表中

### 6.3 添加体验者

1. **添加体验者**
   - 在 **体验版** 中
   - 点击 **"体验成员"** 或 **"添加体验者"**

2. **输入微信号**
   - 输入体验者的微信号（不是昵称！）
   - 点击 **"添加"**

3. **体验者扫码**
   - 体验者用微信扫描体验版二维码
   - 或在微信中搜索小程序名称进入

---

## ✅ 第七步：测试和验证

### 7.1 测试小程序功能

1. **自己先测试**
   - 用微信扫描体验版二维码
   - 测试主要功能：
     - 登录功能
     - 挂号功能
     - 查看预约
     - 其他核心功能

2. **检查API请求**
   - 查看小程序控制台
   - 确认API请求正常
   - 确认没有网络错误

### 7.2 让体验者测试

1. **分享体验版**
   - 在版本管理页面
   - 复制体验版二维码
   - 发送给体验者

2. **收集反馈**
   - 让体验者测试功能
   - 收集问题和建议

---

## 🔄 第八步：保持ngrok运行

### 8.1 重要提示

⚠️ **ngrok必须一直运行，否则域名无法访问！**

### 8.2 保持运行的方法

1. **保持命令行窗口打开**
   - 不要关闭运行ngrok的命令行窗口
   - 可以最小化到后台

2. **或者写个启动脚本**

   创建文件 `start-ngrok.bat`：
   ```batch
   @echo off
   cd C:\ngrok
   ngrok http 8080
   pause
   ```
   
   双击运行即可

3. **设置开机自启（可选）**
   - 将启动脚本放到启动文件夹
   - 或使用任务计划程序

### 8.3 如果ngrok断开

1. **重新启动ngrok**
   ```bash
   cd C:\ngrok
   ngrok http 8080
   ```

2. **获取新域名**
   - 如果域名变了，需要：
     - 重新配置小程序代码
     - 重新编译上传
     - 重新配置微信公众平台域名

---

## 📋 完整操作检查清单

### 准备阶段
- [ ] 已注册ngrok账号
- [ ] 已获取authtoken
- [ ] 已下载ngrok.exe
- [ ] 已配置authtoken
- [ ] Spring Boot已运行在8080端口

### ngrok配置
- [ ] 已启动ngrok
- [ ] 已获取HTTPS域名
- [ ] 已测试域名可以访问

### 小程序配置
- [ ] 已修改config/index.js为ngrok域名
- [ ] 已设置USE_PRODUCTION = true
- [ ] 已编译小程序
- [ ] 已上传到微信

### 微信平台配置
- [ ] 已在微信公众平台配置服务器域名
- [ ] 已设置为体验版
- [ ] 已添加体验者

### 测试验证
- [ ] 已测试小程序功能正常
- [ ] 已让体验者测试
- [ ] ngrok保持运行

---

## ❓ 常见问题解决

### Q1: ngrok启动后域名每次都不一样？

**A**: 
- 免费版确实会变
- 每次启动后：
  1. 重新配置小程序代码
  2. 重新编译上传
  3. 重新配置微信公众平台域名
- 或者升级到付费版（可以固定域名）

### Q2: ngrok显示"Tunnel session failed"？

**A**: 
- 检查网络连接
- 检查authtoken是否正确配置
- 尝试重新配置authtoken
- 检查防火墙设置

### Q3: 小程序无法访问API？

**A**: 
- 检查ngrok是否在运行
- 检查Spring Boot是否在运行
- 检查微信公众平台域名配置是否正确
- 检查小程序代码中的域名是否正确

### Q4: 微信公众平台提示"域名配置失败"？

**A**: 
- 确认域名格式正确（只填域名，不带https://）
- 确认域名可以正常访问
- 等待几分钟后重试（DNS可能未生效）

### Q5: 体验者无法打开小程序？

**A**: 
- 确认已添加为体验者
- 确认输入的微信号正确（不是昵称）
- 确认小程序已设置为体验版
- 让体验者删除旧版本后重新扫码

### Q6: ngrok连接数限制？

**A**: 
- 免费版有连接数限制
- 如果达到限制，等待一段时间或升级付费版
- 通常测试使用不会达到限制

---

## 💡 优化建议

### 1. 固定域名（付费版）

如果经常使用，可以考虑：
- 升级ngrok付费版（约$8/月）
- 可以固定域名，不需要每次重新配置

### 2. 使用脚本自动化

可以写脚本自动：
- 启动Spring Boot
- 启动ngrok
- 获取域名并更新配置

### 3. 监控ngrok状态

- 访问 `http://127.0.0.1:4040` 查看ngrok状态
- 可以看到请求日志和统计信息

---

## 🎯 总结

使用ngrok发行小程序体验版的完整流程：

1. ✅ 安装配置ngrok（5分钟）
2. ✅ 启动ngrok获取域名（1分钟）
3. ✅ 配置小程序代码（2分钟）
4. ✅ 编译上传小程序（5分钟）
5. ✅ 配置微信公众平台（5分钟）
6. ✅ 测试验证（5分钟）

**总时间**：约20-30分钟  
**费用**：完全免费  
**难度**：简单

---

## 📞 需要帮助？

如果遇到问题：
1. 查看ngrok官方文档：https://ngrok.com/docs
2. 查看微信小程序文档：https://developers.weixin.qq.com/miniprogram/dev/framework/
3. 检查本文档的"常见问题"部分

祝你发行成功！🎉



