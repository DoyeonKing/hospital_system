/**
 * uni-app 网络请求封装
 * 统一处理请求和响应
 */
import config from '../config/index.js'

/**
 * 获取API基础URL
 */
function getBaseURL() {
	return config.baseURL
}

/**
 * 封装的request方法
 * @param {Object} options 请求配置
 * @returns {Promise}
 */
function request(options) {
	return new Promise((resolve, reject) => {
		const fullUrl = getBaseURL() + options.url
		console.log(`[REQUEST] ${options.method || 'GET'} ${fullUrl}`)
		console.log('[REQUEST] 请求参数:', options.data || {})
		
		uni.request({
			url: fullUrl,
			method: options.method || 'GET',
			data: options.data || {},
			header: {
				'Content-Type': 'application/json',
				// 如果有token，自动添加到请求头
				...(options.header || {}),
				...getAuthHeader()
			},
			success: (res) => {
				console.log(`[RESPONSE] ${options.method || 'GET'} ${fullUrl}`)
				console.log('[RESPONSE] 状态码:', res.statusCode)
				console.log('[RESPONSE] 响应数据:', res.data)
				console.log('[RESPONSE] 响应数据类型:', typeof res.data, '是否为数组:', Array.isArray(res.data))
				
				// 统一处理响应
				if (res.statusCode === 200) {
					// 后端返回的数据格式：
					// 1. 标准格式：{ code, msg, data }
					// 2. 简单格式：{ message } 或 { error }
					// 3. Spring Boot ResponseEntity: 直接返回数据（可能是数组或对象）
					resolve(res.data)
				} else if (res.statusCode === 400) {
					// 400 Bad Request - 业务逻辑错误
					// 后端返回 {"error": "..."}
					resolve(res.data)
				} else {
					console.error('[RESPONSE] 非200状态码:', res.statusCode, res.data)
					uni.showToast({
						title: '请求失败',
						icon: 'none'
					})
					reject(res)
				}
			},
			fail: (err) => {
				console.error('[REQUEST] 请求失败:', err)
				console.error('[REQUEST] 失败URL:', fullUrl)
				// 不显示toast，让调用方处理错误
				reject(err)
			}
		})
	})
}

/**
 * 获取认证header
 */
function getAuthHeader() {
	const token = uni.getStorageSync('patientToken')
	if (token) {
		return {
			'Authorization': 'Bearer ' + token
		}
	}
	return {}
}

/**
 * GET请求
 */
export function get(url, data = {}) {
	return request({
		url,
		method: 'GET',
		data
	})
}

/**
 * POST请求
 */
export function post(url, data = {}) {
	return request({
		url,
		method: 'POST',
		data
	})
}

/**
 * PUT请求
 */
export function put(url, data = {}) {
	return request({
		url,
		method: 'PUT',
		data
	})
}

/**
 * DELETE请求
 */
export function del(url, data = {}) {
	return request({
		url,
		method: 'DELETE',
		data
	})
}

export default request

