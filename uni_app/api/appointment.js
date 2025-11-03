/**
 * 预约相关API接口
 */
import { get, post, put, del } from '../utils/request.js'
import { adaptAppointmentList, adaptAppointment, adaptAppointmentDetail, adaptWaitlistList, adaptWaitlist } from '../utils/dataAdapter.js'

/**
 * 获取患者的所有预约
 * @param {Number} patientId - 患者ID
 */
export async function getPatientAppointments(patientId) {
	const response = await get(`/api/appointments/patient/${patientId}`)
	if (response.code === '200' && response.data) {
		// 转换数据格式
		return {
			...response,
			data: adaptAppointmentList(response.data)
		}
	}
	return response
}

/**
 * 获取患者即将就诊的预约
 * @param {Number} patientId - 患者ID
 */
export async function getUpcomingAppointments(patientId) {
	const response = await get(`/api/appointments/patient/${patientId}/upcoming`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointmentList(response.data)
		}
	}
	return response
}

/**
 * 创建预约
 * @param {Object} data - 预约数据
 */
export async function createAppointment(data) {
	const response = await post('/api/appointments', data)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointment(response.data)
		}
	}
	return response
}

/**
 * 取消预约
 * @param {Number} appointmentId - 预约ID
 */
export async function cancelAppointment(appointmentId) {
	const response = await put(`/api/appointments/${appointmentId}/cancel`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointment(response.data)
		}
	}
	return response
}

/**
 * 获取预约详情
 * @param {Number} appointmentId - 预约ID
 */
export async function getAppointmentDetail(appointmentId) {
	const response = await get(`/api/appointments/${appointmentId}`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointmentDetail(response.data)
		}
	}
	return response
}

/**
 * 更新预约支付状态
 * @param {Number} appointmentId - 预约ID
 * @param {Object} data - 支付数据
 */
export async function updateAppointmentPayment(appointmentId, data) {
	const response = await put(`/api/appointments/${appointmentId}`, data)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointment(response.data)
		}
	}
	return response
}

/**
 * 支付挂号费用
 * @param {Number} appointmentId - 预约ID
 * @param {Object} paymentData - 支付信息
 */
export async function payForAppointment(appointmentId, paymentData) {
	const response = await post(`/api/appointments/${appointmentId}/pay`, paymentData)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointment(response.data)
		}
	}
	return response
}

/**
 * 候补相关API接口
 */

/**
 * 获取患者的所有候补记录
 * @param {Number} patientId - 患者ID
 */
export async function getPatientWaitlist(patientId) {
	const response = await get(`/api/waitlist/patient/${patientId}`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptWaitlistList(response.data)
		}
	}
	return response
}

/**
 * 获取候补详情
 * @param {Number} waitlistId - 候补ID
 */
export async function getWaitlistDetail(waitlistId) {
	const response = await get(`/api/waitlist/${waitlistId}`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptWaitlist(response.data)
		}
	}
	return response
}

/**
 * 创建候补申请
 * @param {Object} data - 候补数据
 */
export async function createWaitlist(data) {
	const response = await post('/api/waitlist', data)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptWaitlist(response.data)
		}
	}
	return response
}

/**
 * 取消候补
 * @param {Number} waitlistId - 候补ID
 */
export async function cancelWaitlist(waitlistId) {
	const response = await put(`/api/waitlist/${waitlistId}/cancel`)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptWaitlist(response.data)
		}
	}
	return response
}

/**
 * 支付候补费用（候补转正式预约）
 * @param {Number} waitlistId - 候补ID
 * @param {Object} paymentData - 支付信息
 */
export async function payForWaitlist(waitlistId, paymentData) {
	const response = await post(`/api/waitlist/${waitlistId}/pay`, paymentData)
	if (response.code === '200' && response.data) {
		return {
			...response,
			data: adaptAppointment(response.data)
		}
	}
	return response
}