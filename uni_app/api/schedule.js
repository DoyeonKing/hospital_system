/**
 * 排班相关API接口
 */
import { get, post } from '../utils/request.js'

/**
 * 获取今日可预约排班信息
 * @param {String} startDate - 开始日期 (YYYY-MM-DD)
 * @param {String} endDate - 结束日期 (YYYY-MM-DD)
 */
export function getTodaySchedules(startDate, endDate) {
	return get('/api/schedules', {
		startDate,
		endDate
	})
}

/**
 * 获取科室列表
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
 * @param {String} startDate - 开始日期
 * @param {String} endDate - 结束日期
 */
export function getSchedulesByDepartment(departmentId, startDate, endDate) {
	return get(`/api/schedules/department/${departmentId}`, {
		startDate,
		endDate
	})
}

/**
 * 获取时间段列表
 * @param {Number} scheduleId - 排班ID
 */
export function getTimeSlots(scheduleId) {
	return get(`/api/timeslots/schedule/${scheduleId}`)
}
