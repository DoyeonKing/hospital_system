# IP配置使用说明

## 📋 配置文件位置
`uni_app/config/index.js`

## 🎯 三种运行模式

### 1. **auto 模式（自动检测）** - 推荐 ⭐
```javascript
const RUN_MODE = 'auto'
```
- **开发者工具**：自动使用 `localhost`
- **真机调试**：自动使用 `MOBILE_IP`（你的局域网IP）
- **优点**：无需手动切换，自动适配环境

### 2. **device 模式（电脑端）**
```javascript
const RUN_MODE = 'device'
```
- 强制使用 `localhost`
- 适用于：在微信开发者工具中测试

### 3. **mobile 模式（真机调试）**
```javascript
const RUN_MODE = 'mobile'
```
- 强制使用 `MOBILE_IP`
- 适用于：真机调试时

## 🔧 配置步骤

### 步骤1：获取你的电脑IP地址

**Windows系统：**
```bash
# 方法1：命令行
ipconfig
# 查找 "IPv4 地址"，通常是 192.168.x.x 或 172.20.x.x

# 方法2：PowerShell
ipconfig | findstr /i "IPv4"
```

**Mac/Linux系统：**
```bash
ifconfig
# 查找 inet 地址
```

### 步骤2：修改配置文件

打开 `uni_app/config/index.js`，找到以下部分：

```javascript
// 真机调试使用的局域网IP
const MOBILE_IP = '172.20.10.3' // 👈 修改为你的电脑IP
```

**示例：**
- 如果你的IP是 `192.168.1.100`，则改为：
  ```javascript
  const MOBILE_IP = '192.168.1.100'
  ```

### 步骤3：选择运行模式

```javascript
const RUN_MODE = 'auto' // 👈 推荐使用 auto
```

## 📱 真机调试设置

### 微信开发者工具设置

1. 打开微信开发者工具
2. 点击右上角 **详情**
3. 选择 **本地设置**
4. **勾选** "不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"

### 确保网络连接

1. ✅ 手机和电脑连接**同一个WiFi**
2. ✅ 电脑防火墙允许8080和5000端口
3. ✅ 后端服务正在运行（Spring Boot在8080端口）

## 🧪 测试连接

### 在开发者工具中测试
1. 设置 `RUN_MODE = 'auto'` 或 `'device'`
2. 编译运行
3. 查看控制台，应该看到：
   ```
   🔧 API配置: {
     模式: 'auto',
     当前IP: 'localhost',
     baseURL: 'http://localhost:8080'
   }
   ```

### 在真机上测试
1. 设置 `RUN_MODE = 'auto'` 或 `'mobile'`
2. 确保 `MOBILE_IP` 已设置为你的电脑IP
3. 编译并上传到真机
4. 查看控制台，应该看到：
   ```
   🔧 API配置: {
     模式: 'auto',
     当前IP: '172.20.10.3',
     baseURL: 'http://172.20.10.3:8080'
   }
   ```

## 🔍 常见问题

### Q1: 真机无法连接后端？
- ✅ 检查手机和电脑是否在同一WiFi
- ✅ 检查 `MOBILE_IP` 是否正确
- ✅ 检查电脑防火墙是否允许8080端口
- ✅ 在手机浏览器访问 `http://你的IP:8080` 测试连接

### Q2: 开发者工具可以，真机不行？
- ✅ 确保已勾选"不校验合法域名"
- ✅ 检查 `MOBILE_IP` 配置是否正确
- ✅ 尝试使用 `RUN_MODE = 'mobile'` 强制使用真机IP

### Q3: 如何快速切换？
- **电脑端测试**：`RUN_MODE = 'device'`
- **真机测试**：`RUN_MODE = 'mobile'`
- **自动切换**：`RUN_MODE = 'auto'`（推荐）

## 📝 配置示例

### 示例1：自动模式（推荐）
```javascript
const DEVICE_IP = 'localhost'
const MOBILE_IP = '172.20.10.3'  // 你的电脑IP
const RUN_MODE = 'auto'  // 自动切换
```

### 示例2：手动切换
```javascript
// 电脑端测试时
const RUN_MODE = 'device'

// 真机调试时
const RUN_MODE = 'mobile'
```

## 🎉 完成！

配置完成后，系统会自动根据运行环境选择合适的IP地址，无需每次手动修改！

