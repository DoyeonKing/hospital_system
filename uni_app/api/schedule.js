/**
 * 排班相关API接口
 */
import { get, post } from '../utils/request.js'
import { adaptSchedule } from '../utils/dataAdapter.js'

/**
 * 获取今日可预约排班信息
 * @param {String} startDate - 开始日期 (YYYY-MM-DD)
 * @param {String} endDate - 结束日期 (YYYY-MM-DD)
 */
export async function getTodaySchedules(startDate, endDate) {
	const response = await get('/api/schedules', {
		startDate,
		endDate
	})
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptSchedule(response.data)
		}
	}
	return response
}

/**
 * 获取科室树形结构
 */
export function getDepartmentTree() {
	return get('/api/departments/tree')
}

/**
 * 获取科室列表（分页）
 */
export function getDepartments() {
	return get('/api/departments')
}

/**
 * 获取热门科室
 */
export function getPopularDepartments() {
	return get('/api/departments/popular')
}

/**
 * 根据科室ID获取排班信息
 * @param {Number} departmentId - 科室ID
 * @param {String} startDate - 开始日期 (可选)
 * @param {String} endDate - 结束日期 (可选)
 */
export async function getSchedulesByDepartment(departmentId, startDate, endDate) {
	// 后端返回 Page<ScheduleResponse>，需要提取 content
	const response = await get('/api/schedules', {
		departmentId,
		startDate,
		endDate
	})
	
	console.log('获取科室排班响应:', response)
	
	// 处理返回的 Page 格式：Spring Boot 的 Page 格式
	if (response.content && Array.isArray(response.content)) {
		return {
			...response,
			data: adaptSchedule(response.content)
		}
	}
	
	// 兼容可能的其他格式
	if (Array.isArray(response)) {
		return adaptSchedule(response)
	}
	
	// 都不匹配，返回原数据
	return response
}

/**
 * 获取时间段列表
 * @param {Number} scheduleId - 排班ID
 */
export function getTimeSlots(scheduleId) {
	return get(`/api/timeslots/schedule/${scheduleId}`)
}

/**
 * 根据科室ID获取医生列表
 * @param {Number} departmentId - 科室ID
 */
export function getDoctorsByDepartment(departmentId) {
	return get(`/api/departments/${departmentId}/doctors`)
}

/**
 * 获取单个医生详细信息
 * @param {Number} doctorId - 医生ID
 */
export function getDoctorById(doctorId) {
	return get(`/api/doctors/${doctorId}`)
}

/**
 * 获取单个排班详情
 * @param {Number} scheduleId - 排班ID
 */
export function getScheduleById(scheduleId) {
	return get(`/api/schedules/${scheduleId}`)
}

