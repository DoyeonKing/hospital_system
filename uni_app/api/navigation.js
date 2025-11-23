/**
 * 导航相关API接口
 */
import { get } from '../utils/request.js'

/**
 * 计算两点之间的最短路径
 * @param {Number} startNodeId - 起始节点ID
 * @param {Number} endNodeId - 目标节点ID
 * @param {Boolean} preferAccessible - 是否优先使用无障碍通道
 */
export async function getNavigationRoute(startNodeId, endNodeId, preferAccessible = false) {
	const response = await get(`/api/navigation/route`, {
		startNodeId,
		endNodeId,
		preferAccessible
	})
	return response
}

/**
 * 根据预约ID获取导航路径（从入口到诊室）
 * @param {Number} appointmentId - 预约ID
 */
export async function getRouteByAppointment(appointmentId) {
	const response = await get(`/api/navigation/route-by-appointment/${appointmentId}`)
	return response
}

/**
 * 获取指定楼层的地图数据
 * @param {Number} floorLevel - 楼层号
 */
export async function getFloorMap(floorLevel) {
	const response = await get(`/api/navigation/floor-map/${floorLevel}`)
	return response
}

/**
 * 搜索地点
 * @param {String} keyword - 关键词
 */
export async function searchNodes(keyword) {
	const response = await get(`/api/navigation/search`, {
		keyword
	})
	return response
}

/**
 * 获取所有入口节点（通常作为导航起点）
 */
export async function getEntranceNodes() {
	const response = await get(`/api/navigation/entrances`)
	return response
}

