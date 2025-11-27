/**
 * 院内导航相关 API
 */
import { get, post } from '../utils/request.js'

/**
 * 获取两节点之间的导航路径
 * @param {Number} startNodeId
 * @param {Number} endNodeId
 * @param {Boolean} preferAccessible 是否优先走无障碍通道
 */
export function getNavigationRoute(startNodeId, endNodeId, preferAccessible = false) {
	return get('/api/navigation/route', {
		startNodeId,
		endNodeId,
		preferAccessible
	})
}

/**
 * 根据预约ID获取导航路径
 * @param {Number} appointmentId
 */
export function getRouteByAppointment(appointmentId) {
	return get(`/api/navigation/route-by-appointment/${appointmentId}`)
}

/**
 * 搜索院内地点
 * @param {String} keyword
 */
export function searchNodes(keyword) {
	return get('/api/navigation/search', { keyword })
}

/**
 * 获取入口节点（默认起点）
 */
export function getEntranceNodes() {
	return get('/api/navigation/entrances')
}

/**
 * 获取指定楼层的地图数据
 * @param {String} building 建筑名称
 * @param {Number} floorLevel 楼层号
 */
export function getFloorMap(building, floorLevel) {
	return get(`/api/navigation/floor-map/${building}/${floorLevel}`)
}

/**
 * 根据预约ID获取导航信息
 * @param {Number} appointmentId 预约ID
 */
export function getNavigationInfoByAppointment(appointmentId) {
	return get(`/api/navigation/info-by-appointment/${appointmentId}`)
}

/**
 * 根据诊室ID获取导航信息
 * @param {Number} locationId 诊室ID
 */
export function getNavigationInfoByLocation(locationId) {
	return get(`/api/navigation/info-by-location/${locationId}`)
}

/**
 * 手动选择位置（确认位置）
 * @param {Number} nodeId 节点ID
 */
export function confirmLocation(nodeId) {
	return post('/api/navigation/confirm-location', { nodeId })
}

/**
 * 扫描定位二维码
 * @param {String} qrCode 二维码内容
 */
export function scanLocation(qrCode) {
	return post('/api/navigation/location-scan', { qrCode })
}

/**
 * 从当前位置导航到目标节点
 * @param {String} qrCode 定位二维码
 * @param {Number} targetNodeId 目标节点
 * @param {Boolean} preferAccessible
 */
export function navigateFromLocation(qrCode, targetNodeId, preferAccessible = false) {
	return post('/api/navigation/navigate-from-location', {
		qrCode,
		targetNodeId,
		preferAccessible
	})
}








