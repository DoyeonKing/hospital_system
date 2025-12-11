/**
 * 就医规范相关API接口
 */
import { get } from '../utils/request.js'

/**
 * 获取就医规范列表
 * @param {Object} params - 查询参数
 * @param {Number} params.page - 页码
 * @param {Number} params.pageSize - 每页数量
 * @param {String} params.category - 分类筛选
 * @param {String} params.status - 状态筛选
 */
export function getGuidelines(params = {}) {
	const requestParams = {
		page: params.page || 1,
		pageSize: params.pageSize || 10
	}
	
	// 只添加有值的参数
	if (params.category) {
		requestParams.category = params.category
	}
	if (params.status) {
		requestParams.status = params.status
	}
	
	return get('/api/medical-guidelines', requestParams)
}

/**
 * 获取启用状态的就医须知
 * 用于在患者端显示
 */
export async function getActiveNotice() {
	try {
		const response = await getGuidelines({
			category: '就医须知',
			status: 'active',
			page: 1,
			pageSize: 1
		})
		
		// 处理分页响应格式
		if (response && response.content && response.content.length > 0) {
			return response.content[0]
		}
		
		return null
	} catch (error) {
		console.error('获取就医须知失败:', error)
		return null
	}
}
