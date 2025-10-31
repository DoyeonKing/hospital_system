/**
 * 预约相关API接口
 */
import { get, post, put, del } from '../utils/request.js'

/**
 * 获取患者的所有预约
 * @param {Number} patientId - 患者ID
 */
export function getPatientAppointments(patientId) {
	return get(`/api/appointments/patient/${patientId}`)
}

/**
 * 获取患者即将就诊的预约
 * @param {Number} patientId - 患者ID
 */
export function getUpcomingAppointments(patientId) {
	return get(`/api/appointments/patient/${patientId}/upcoming`)
}

/**
 * 创建预约
 * @param {Object} data - 预约数据
 */
export function createAppointment(data) {
	return post('/api/appointments', data)
}

/**
 * 取消预约
 * @param {Number} appointmentId - 预约ID
 */
export function cancelAppointment(appointmentId) {
	return put(`/api/appointments/${appointmentId}/cancel`)
}

/**
 * 获取预约详情
 * @param {Number} appointmentId - 预约ID
 */
export function getAppointmentDetail(appointmentId) {
	return get(`/api/appointments/${appointmentId}`)
}
