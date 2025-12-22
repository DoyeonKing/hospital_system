/**
 * 图片URL处理工具
 * 用于处理后端返回的相对路径图片URL，转换为完整的服务器URL
 */
import config from '../config/index.js'

/**
 * 处理图片URL
 * 如果是相对路径（以 / 开头），拼接baseURL
 * 如果是完整URL（http:// 或 https:// 开头），直接返回
 * 如果为空或无效，返回默认头像
 * 
 * @param {String} imageUrl - 图片URL（可能是相对路径或完整URL）
 * @param {String} defaultUrl - 默认图片URL（可选）
 * @returns {String} 处理后的完整图片URL
 */
export function processImageUrl(imageUrl, defaultUrl = null) {
	// 如果为空或无效，返回默认头像
	if (!imageUrl || imageUrl.trim() === '') {
		return defaultUrl || 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png'
	}

	const url = imageUrl.trim()

	// 如果已经是完整URL（http:// 或 https:// 开头），直接返回
	if (url.startsWith('http://') || url.startsWith('https://')) {
		return url
	}

	// 如果是相对路径（以 / 开头），拼接baseURL
	if (url.startsWith('/')) {
		// 移除开头的 /，然后拼接
		const path = url.substring(1)
		return `${config.baseURL}/${path}`
	}

	// 如果是其他格式，尝试拼接baseURL
	return `${config.baseURL}/${url}`
}

/**
 * 处理医生头像URL
 * @param {String} photoUrl - 医生头像URL
 * @returns {String} 处理后的完整URL
 */
export function processDoctorPhotoUrl(photoUrl) {
	return processImageUrl(photoUrl, 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png')
}







