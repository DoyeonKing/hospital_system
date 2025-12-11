import request from '@/utils/request'

/**
 * 获取运营总览统计数据
 */
export function getOverviewStats() {
  return request({
    url: '/api/dashboard/overview',
    method: 'get'
  })
}

/**
 * 获取医生资源分析统计数据
 */
export function getDoctorsStats() {
  return request({
    url: '/api/dashboard/doctors',
    method: 'get'
  })
}

/**
 * 获取患者群体画像统计数据
 * @param {string} startDate 起始日期（可选，格式：yyyy-MM-dd）
 * @param {string} endDate 结束日期（可选，格式：yyyy-MM-dd）
 */
export function getPatientsStats(startDate, endDate) {
  const params = {}
  if (startDate) {
    params.startDate = startDate
  }
  if (endDate) {
    params.endDate = endDate
  }
  return request({
    url: '/api/dashboard/patients',
    method: 'get',
    params
  })
}

