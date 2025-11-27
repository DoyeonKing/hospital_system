/**
 * 地图相关API
 */
import { get } from '../utils/request.js'

/**
 * 获取地图配置
 * @returns {Promise} 地图配置数据（包含网格和所有节点）
 */
export async function getMapConfig() {
	return await get('/api/map/config')
}

/**
 * 根据诊室ID获取目标节点坐标
 * @param {Number} locationId 诊室ID
 * @returns {Promise} 目标节点信息
 */
export async function getTargetNode(locationId) {
	return await get(`/api/map/target/${locationId}`)
}




