/**
 * 应用配置文件
 * 
 * ⚠️ 真机调试必读：
 * 1. 手机无法访问 localhost，必须改为电脑的局域网IP
 * 2. 获取IP方法：
 *    - Windows: 运行 ipconfig，查看"IPv4 地址"
 *    - Mac/Linux: 运行 ifconfig，查看 inet 地址
 * 3. 确保手机和电脑连接同一个WiFi
 * 4. 确保后端服务正在运行（springboot在8080端口）
 * 
 * 常见IP格式：192.168.x.x 或 10.x.x.x
 */

// ⚠️ 真机调试：请修改为你的电脑局域网IP地址
// 检测到的IP地址：
//   - 192.168.137.1 (可能是手机热点)
//   - 172.20.10.3 (可能是WiFi连接) ← 试试这个！
//   - 26.206.1.21 (可能是虚拟网卡)

// ⚠️ 重要：根据你的网络环境选择正确的IP
// 
// 检测到的IP地址：
//   1. 192.168.137.1 - 手机热点（如果电脑连接手机热点用这个）
//   2. 172.20.10.3 - WiFi连接（如果手机和电脑在同一WiFi用这个）
//   3. 26.206.1.21 - 虚拟网卡（通常不用）

// ⚠️ 重要：根据调试方式选择IP
// 
// 1. 微信开发者工具调试（推荐）：使用 localhost
//    - 优点：不需要配置域名，直接可用
//    - 缺点：只能在开发者工具中使用，真机无法访问
// 
// 2. 真机调试：使用局域网IP（如 172.20.10.3）
//    - 优点：可以在真机上测试
//    - 缺点：需要在开发者工具中关闭域名校验
//    - 设置：微信开发者工具 → 详情 → 本地设置 → 勾选"不校验合法域名"
//
// 3. 如何获取局域网IP：
//    - Windows: 打开 cmd，运行 ipconfig，查看"IPv4 地址"
//    - 通常是 192.168.x.x 或 172.20.x.x

// 当前使用：开发者工具调试（使用 localhost）
const LOCAL_IP = 'localhost' // 👈 开发者工具调试用这个

// 如果需要真机调试，改为局域网IP，例如：
// const LOCAL_IP = '172.20.10.3' // 👈 真机调试时用这个

// 开发环境配置
const development = {
	// 开发者工具调试使用 localhost，真机调试使用局域网IP
	baseURL: `http://${LOCAL_IP}:8080`, // 主后端服务（Spring Boot）
	
	aiBaseURL: 'http://localhost:3000' // AI 预问诊后端服务（Node.js）
}

// 生产环境配置
const production = {
	baseURL: 'https://your-production-api.com',
	aiBaseURL: 'https://your-ai-api.com'
}

// 当前使用的配置
const config = development

// 同时支持 default 和 named export
export default config
export { config }

