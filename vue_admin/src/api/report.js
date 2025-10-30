import request from '@/utils/request'

/**
 * 医生工时统计（后端聚合）
 * GET /api/reports/doctor-hours
 * params: { departmentId, startDate, endDate, doctorId?, groupBy?('doctor'|'doctor_date') }
 */
export function getDoctorHours(params) {
  return request({
    url: '/api/reports/doctor-hours',
    method: 'get',
    params
  })
}


