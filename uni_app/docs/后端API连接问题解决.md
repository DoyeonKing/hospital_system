# 🔧 后端API连接问题解决方案

## ❌ 问题描述

你看到的错误信息：
```
GET http://localhost:8080/api/waitlist/patient/13 
net::ERR_CONNECTION_REFUSED
```

**原因：** 前端正在尝试连接后端服务器，但后端 Spring Boot 服务没有运行。

---

## ✅ 解决方案

### 方案 1：暂时禁用自动API检查（推荐用于前端测试）

我已经帮你修改了 `App.vue`，暂时禁用了自动检查候补通知的功能。现在前端可以正常运行，不会因为后端未启动而报错。

**优点：**
- ✅ 可以专注测试前端地图功能
- ✅ 不会有错误提示干扰
- ✅ 不影响其他功能

**恢复方法：**
当后端启动后，取消 `App.vue` 中的注释即可：
```javascript
// 取消注释这两行
this.startWaitlistNotificationCheck()
```

---

### 方案 2：启动后端服务器（完整功能）

如果你需要测试完整的应用功能，需要启动后端服务器：

#### 步骤 1：检查后端项目

```bash
cd E:\hospital_system\springboot
```

#### 步骤 2：启动后端服务

**方式 A：使用IDE（推荐）**
- 打开 IntelliJ IDEA 或 Eclipse
- 导入 `springboot` 项目
- 找到主类（通常包含 `@SpringBootApplication`）
- 运行主类

**方式 B：使用Maven**
```bash
cd E:\hospital_system\springboot
mvn spring-boot:run
```

**方式 C：使用命令行**
```bash
cd E:\hospital_system\springboot
java -jar target/your-app.jar
```

#### 步骤 3：确认后端运行

在浏览器访问：`http://localhost:8080/api/health` 或查看控制台输出

#### 步骤 4：测试前端

后端启动后，前端就能正常调用API了。

---

### 方案 3：修改API配置（如果需要）

如果后端运行在不同的地址或端口，修改 `uni_app/config/index.js`：

```javascript
const development = {
	baseURL: 'http://localhost:8080'  // 修改为你的后端地址
}
```

---

## 🎯 当前状态

✅ **我已经帮你：**
- 暂时禁用了自动API检查
- 修改了错误处理，失败时不会显示错误
- 前端现在可以正常运行测试地图功能

---

## 📝 测试地图功能（不受影响）

现在你可以正常测试地图功能：

1. **访问地图示例页面**：`pages/navigation/MapExample`
2. **测试定位功能**：点击"获取当前位置"
3. **测试地图交互**：拖动、缩放地图

**这些功能不依赖后端API，可以正常使用！** ✅

---

## 🔄 后续步骤

### 当你需要测试完整功能时：

1. **启动后端服务器**
2. **取消注释 App.vue 中的代码**：
   ```javascript
   this.startWaitlistNotificationCheck()
   ```
3. **重新编译前端项目**

### 当你只想测试地图功能时：

- **不需要做任何事情**，直接测试即可！

---

## ❓ 常见问题

### Q1: 这些错误会影响地图功能吗？

**答：** 不会！地图功能是纯前端的，不依赖后端API。我已经禁用了自动API检查，所以不会有错误干扰。

### Q2: 后端必须运行吗？

**答：** 
- **测试地图功能**：不需要后端
- **测试完整应用**：需要后端

### Q3: 如何知道后端是否运行？

**答：** 
- 在浏览器访问：`http://localhost:8080`
- 查看控制台是否有错误
- 检查后端项目是否在运行

### Q4: 如何修改后端地址？

**答：** 修改 `uni_app/config/index.js` 中的 `baseURL`

---

## 🎉 总结

**现在你可以：**
- ✅ 正常测试地图功能
- ✅ 不会看到API连接错误
- ✅ 专注前端功能测试

**当你需要完整功能时：**
- 启动后端服务器
- 恢复API检查代码

**就这么简单！** 🚀



