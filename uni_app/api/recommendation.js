/**
 * AI挂号助手相关API接口
 */
import { post } from '../utils/request.js'
import { processDoctorPhotoUrl } from '../utils/imageUtil.js'

/**
 * 根据症状描述推荐科室（第一步）
 * @param {String} symptomDescription - 症状描述
 * @param {Number} patientId - 患者ID（可选）
 */
export async function recommendDepartments(symptomDescription, patientId = null) {
	const requestData = {
		symptomDescription: symptomDescription
	}
	if (patientId) {
		requestData.patientId = patientId
	}
	
	const response = await post('/api/doctor-recommendations/departments', requestData)
	
	// 处理响应格式
	if (Array.isArray(response)) {
		return {
			code: '200',
			data: response
		}
	}
	if (response && response.code === '200' && response.data) {
		return response
	}
	return response
}

/**
 * 根据科室推荐医生和排班（第二步）
 * @param {Number} departmentId - 科室ID
 * @param {Array<String>} symptomKeywords - 症状关键词（可选）
 * @param {Number} patientId - 患者ID（可选）
 * @param {Number} topN - 返回Top-N个推荐（默认10）
 */
export async function recommendDoctorsByDepartment(departmentId, symptomKeywords = null, patientId = null, topN = 10) {
	const requestData = {
		departmentId: departmentId,
		topN: topN
	}
	if (patientId) {
		requestData.patientId = patientId
	}
	if (symptomKeywords && symptomKeywords.length > 0) {
		requestData.symptomKeywords = symptomKeywords
	}
	
	const response = await post('/api/doctor-recommendations/by-department', requestData)
	
	// 处理响应格式
	let doctorList = []
	if (Array.isArray(response)) {
		doctorList = response
	} else if (response && response.code === '200' && response.data) {
		doctorList = response.data
	} else if (response && response.data) {
		doctorList = Array.isArray(response.data) ? response.data : [response.data]
	}
	
	// 处理每个医生的photoUrl（将相对路径转换为完整URL）
	if (doctorList && doctorList.length > 0) {
		doctorList = doctorList.map(doctor => ({
			...doctor,
			photoUrl: processDoctorPhotoUrl(doctor.photoUrl)
		}))
	}
	
	if (Array.isArray(response)) {
		return doctorList
	}
	
	return {
		code: '200',
		data: doctorList
	}
}

