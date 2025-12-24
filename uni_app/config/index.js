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

// ==================== IP配置区域 ====================
// 请根据你的网络环境修改以下IP地址

// 电脑端（开发者工具）使用的IP - 保持不变
const DEVICE_IP = 'localhost' // 👈 开发者工具调试用这个（电脑端）

// 真机调试使用的局域网IP - 请修改为你的电脑IP
// 检测到的可用IP：
//   - 192.168.137.1 (可能是手机热点)
//   - 172.20.10.3 (可能是WiFi连接) ← 推荐使用这个！
//   - 172.22.48.1 (可能是其他网络)
//   - 26.206.1.21 (可能是虚拟网卡，不推荐)
const MOBILE_IP = '172.20.10.3' // 👈 真机调试时用这个（请修改为你的电脑IP）

// ==================== 运行模式切换 ====================
// 手动切换模式：
//   - 'auto': 自动检测（推荐）- 开发者工具用 localhost，真机用 MOBILE_IP
//   - 'device': 强制使用 DEVICE_IP（电脑端）
//   - 'mobile': 强制使用 MOBILE_IP（真机调试）
const RUN_MODE = 'auto' // 👈 修改这里来切换模式

// 获取当前使用的IP
function getCurrentIP() {
	if (RUN_MODE === 'device') {
		return DEVICE_IP
	} else if (RUN_MODE === 'mobile') {
		return MOBILE_IP
	} else {
		// auto 模式：自动检测环境
		// #ifdef MP-WEIXIN
		try {
			const systemInfo = uni.getSystemInfoSync()
			// 在开发者工具中，platform 通常是 'devtools'
			// 在真机上，platform 是 'ios' 或 'android'
			if (systemInfo.platform === 'devtools') {
				return DEVICE_IP
			} else {
				return MOBILE_IP
			}
		} catch (e) {
			// 如果获取失败，默认使用真机IP
			return MOBILE_IP
		}
		// #endif
		
		// #ifndef MP-WEIXIN
		// 非微信小程序环境（H5等），使用 localhost
		return DEVICE_IP
		// #endif
	}
}

// 当前使用的IP
const CURRENT_IP = getCurrentIP()

// 打印当前配置（方便调试）
console.log('🔧 API配置:', {
	模式: RUN_MODE,
	当前IP: CURRENT_IP,
	电脑端IP: DEVICE_IP,
	真机IP: MOBILE_IP,
	baseURL: `http://${CURRENT_IP}:8080`
})

// ==================== 开发环境配置 ====================
const development = {
	// 主后端服务（Spring Boot）- 自动根据环境切换IP
	baseURL: `http://${CURRENT_IP}:8080`,
	
	// AI 预问诊后端服务（Node.js）- 端口5000
	aiBaseURL: `http://${CURRENT_IP}:5000`
}

// ==================== 生产环境配置 ====================
// ⚠️ 发布体验版前，请修改以下配置为你的实际API域名
// 注意：必须使用 https:// 协议，且域名必须在微信公众平台配置
const production = {
	// 主后端服务（Spring Boot）- 改为你的实际API域名
	baseURL: 'https://your-production-api.com',  // 👈 发布体验版时修改这里
	
	// AI 预问诊后端服务（Node.js）- 改为你的实际AI服务域名
	aiBaseURL: 'https://your-ai-api.com'  // 👈 发布体验版时修改这里
}

// ==================== 环境切换 ====================
// 切换方式：
// 1. 开发环境：USE_PRODUCTION = false（默认）
// 2. 生产环境（体验版）：USE_PRODUCTION = true
// 
// 发布体验版步骤：
// 1. 修改上面的 production 配置为实际域名
// 2. 将 USE_PRODUCTION 改为 true
// 3. 重新编译并上传
const USE_PRODUCTION = false  // 👈 发布体验版时改为 true

// 当前使用的配置
const config = USE_PRODUCTION ? production : development

// 同时支持 default 和 named export
export default config
export { config }

