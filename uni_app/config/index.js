/**
 * 应用配置文件
 */

// 开发环境配置
const development = {
	baseURL: 'http://localhost:8080', // 主后端服务（Spring Boot）
	aiBaseURL: 'http://localhost:3000' // AI 预问诊后端服务（Node.js）
}

// 生产环境配置
const production = {
	baseURL: 'https://your-production-api.com',
	aiBaseURL: 'https://your-ai-api.com'
}

// 当前使用的配置（开发阶段使用 development）
const config = development

// 同时支持 default 和 named export
export default config
export { config }

