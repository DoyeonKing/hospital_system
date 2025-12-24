/**
 * 应用配置文件
 * 
 * ✅ 已配置为使用本地后端
 * 本地后端地址: localhost:8080
 * 如需切换到云服务器，请修改 LOCAL_IP 为 CLOUD_SERVER_IP
 */

// ==================== 云服务器配置 ====================
// 云服务器IP地址（与数据库同一台服务器）
const CLOUD_SERVER_IP = '123.249.30.241'

// ==================== 本地开发配置 ====================
const LOCAL_IP = 'localhost' // 本地开发使用

// ==================== 开发环境配置 ====================
const development = {
	// 主后端服务（Spring Boot）- 指向本地服务器
	baseURL: `http://${LOCAL_IP}:8080`,
	
	// AI 预问诊后端服务（Node.js）- 端口5000
	aiBaseURL: `http://${LOCAL_IP}:5000`
}

// 生产环境配置
const production = {
	baseURL: `http://${CLOUD_SERVER_IP}:8080`,
	aiBaseURL: `http://${CLOUD_SERVER_IP}:5000`
}

// 当前使用的配置（统一使用云服务器）
const config = development

// 打印当前配置（方便调试）
console.log('🔧 API配置:', {
	模式: '本地开发模式',
	后端地址: config.baseURL,
	AI后端地址: config.aiBaseURL,
	提示: '使用本地后端服务'
})

// ==================== 以下为旧的本地配置（已注释，如需切换回本地后端可取消注释） ====================
/*
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

// // ==================== IP配置区域 ====================
// // 请根据你的网络环境修改以下IP地址

// 电脑端（开发者工具）使用的IP - 保持不变
//const DEVICE_IP = 'localhost' // 👈 开发者工具调试用这个（电脑端）
const DEVICE_IP = '123.249.30.241'

// // 真机调试使用的局域网IP - 请修改为你的电脑IP
// // 检测到的可用IP：
// //   - 192.168.137.1 (可能是手机热点)
// //   - 172.20.10.3 (可能是WiFi连接) ← 推荐使用这个！
// //   - 172.22.48.1 (可能是其他网络)
// //   - 26.206.1.21 (可能是虚拟网卡，不推荐)
// const MOBILE_IP = '172.20.10.3' // 👈 真机调试时用这个（请修改为你的电脑IP）

// // ==================== 运行模式切换 ====================
// // 手动切换模式：
// //   - 'auto': 自动检测（推荐）- 开发者工具用 localhost，真机用 MOBILE_IP
// //   - 'device': 强制使用 DEVICE_IP（电脑端）
// //   - 'mobile': 强制使用 MOBILE_IP（真机调试）
// const RUN_MODE = 'auto' // 👈 修改这里来切换模式

// // 获取当前使用的IP
// function getCurrentIP() {
// 	if (RUN_MODE === 'device') {
// 		return DEVICE_IP
// 	} else if (RUN_MODE === 'mobile') {
// 		return MOBILE_IP
// 	} else {
// 		// auto 模式：自动检测环境
// 		// #ifdef MP-WEIXIN
// 		try {
// 			const systemInfo = uni.getSystemInfoSync()
// 			// 在开发者工具中，platform 通常是 'devtools'
// 			// 在真机上，platform 是 'ios' 或 'android'
// 			if (systemInfo.platform === 'devtools') {
// 				return DEVICE_IP
// 			} else {
// 				return MOBILE_IP
// 			}
// 		} catch (e) {
// 			// 如果获取失败，默认使用真机IP
// 			return MOBILE_IP
// 		}
// 		// #endif
		
// 		// #ifndef MP-WEIXIN
// 		// 非微信小程序环境（H5等），使用 localhost
// 		return DEVICE_IP
// 		// #endif
// 	}
// }

// // 当前使用的IP
// const CURRENT_IP = getCurrentIP()

// // 打印当前配置（方便调试）
// console.log('🔧 API配置:', {
// 	模式: RUN_MODE,
// 	当前IP: CURRENT_IP,
// 	电脑端IP: DEVICE_IP,
// 	真机IP: MOBILE_IP,
// 	baseURL: `http://${CURRENT_IP}:8080`
// })

// // ==================== 开发环境配置（旧版本 - 本地后端） ====================
// const development_old = {
// 	// 主后端服务（Spring Boot）- 自动根据环境切换IP
// 	baseURL: `http://${CURRENT_IP}:8080`,
	
// 	// AI 预问诊后端服务（Node.js）- 端口5000
// 	aiBaseURL: `http://${CURRENT_IP}:5000`
// }

// // 生产环境配置（旧版本）
// const production_old = {
// 	baseURL: 'https://your-production-api.com',
// 	aiBaseURL: 'https://your-ai-api.com'
// }

// 同时支持 default 和 named export
export default config
export { config }

