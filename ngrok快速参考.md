# ngrok发行小程序 - 快速参考

## ⚡ 5分钟快速开始

### 1. 注册并配置ngrok（2分钟）

```bash
# 1. 访问 https://ngrok.com/ 注册账号
# 2. 获取authtoken（在Dashboard）
# 3. 下载ngrok.exe
# 4. 配置authtoken
cd C:\ngrok
ngrok config add-authtoken 你的authtoken
```

### 2. 启动ngrok（1分钟）

```bash
# 确保Spring Boot在运行（localhost:8080）
cd C:\ngrok
ngrok http 8080

# 复制显示的HTTPS域名：https://xxxxx.ngrok-free.app
```

### 3. 配置小程序（1分钟）

编辑 `uni_app/config/index.js`：
```javascript
const production = {
    baseURL: 'https://xxxxx.ngrok-free.app',  // 👈 你的ngrok域名
    aiBaseURL: 'https://xxxxx.ngrok-free.app'
}
const USE_PRODUCTION = true  // 👈 改为 true
```

### 4. 编译上传（1分钟）

- HBuilderX：发行 → 小程序-微信
- 微信开发者工具：上传代码

### 5. 配置微信平台（1分钟）

- 登录：https://mp.weixin.qq.com/
- 开发 → 开发设置 → 服务器域名 → 添加ngrok域名
- 版本管理 → 选为体验版 → 添加体验者

---

## 📋 关键命令

```bash
# 配置ngrok
ngrok config add-authtoken YOUR_TOKEN

# 启动ngrok（8080是Spring Boot端口）
ngrok http 8080

# 查看ngrok状态（浏览器访问）
http://127.0.0.1:4040
```

---

## ⚠️ 重要提示

1. **ngrok必须一直运行**，关闭后域名无法访问
2. **每次启动域名可能不同**，需要重新配置
3. **免费版有连接数限制**，通常够用
4. **适合测试使用**，正式版建议购买域名

---

## 🔗 相关文档

- 完整详细方案：`使用ngrok发行小程序体验版完整方案.md`
- 最简单方案：`最简单免费域名方案.md`





