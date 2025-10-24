import request from '@/utils/request'

/**
 * 获取排班列表（按科室和时间范围）
 * @param {Object} params - 查询参数
 * @param {Number} params.departmentId - 科室ID
 * @param {String} params.startDate - 开始日期 (格式: YYYY-MM-DD)
 * @param {String} params.endDate - 结束日期 (格式: YYYY-MM-DD)
 */
export function getSchedules(params) {
  console.log('=== API层请求参数 ===');
  console.log('接收到的参数:', params);
  console.log('发送的请求参数:', {
    departmentId: params.departmentId,
    startDate: params.startDate,
    endDate: params.endDate
  });
  console.log('请求配置:', {
    url: '/api/schedules',
    method: 'get',
    params: {
      departmentId: params.departmentId,
      startDate: params.startDate,
      endDate: params.endDate
    }
  });
  console.log('==================');
  
  return request({
    url: '/api/schedules',
    method: 'get',
    params: {
      departmentId: params.departmentId,
      startDate: params.startDate,
      endDate: params.endDate
    }
  })
}

/**
 * 批量更新排班（号源限额和费用）
 * @param {Object} data - 更新数据
 * @param {Array} data.updates - 更新列表
 * @param {Number} data.updates[].scheduleId - 排班ID
 * @param {Number} data.updates[].totalSlots - 号源限额
 * @param {Number} data.updates[].fee - 挂号费用
 */
export function batchUpdateSchedules(data) {
  return request({
    url: '/api/schedules/batch-update',
    method: 'put',
    data: {
      updates: data.updates.map(item => ({
        scheduleId: item.scheduleId,
        totalSlots: item.totalSlots,
        fee: item.fee
      }))
    }
  })
}

/**
 * 单个更新排班（可选，如果需要单个更新接口）
 * @param {Number} scheduleId - 排班ID
 * @param {Object} data - 更新数据
 */
export function updateSchedule(scheduleId, data) {
  return request({
    url: `/api/schedules/${scheduleId}`,
    method: 'put',
    data: {
      totalSlots: data.totalSlots,
      fee: data.fee
    }
  })
}

/**
 * 获取单个排班详情
 * @param {Number} scheduleId - 排班ID
 */
export function getScheduleById(scheduleId) {
  return request({
    url: `/api/schedules/${scheduleId}`,
    method: 'get'
  })
}

/**
 * 创建排班
 * @param {Object} data - 排班数据
 */
export function createSchedule(data) {
  return request({
    url: '/api/schedules',
    method: 'post',
    data
  })
}

/**
 * 删除排班
 * @param {Number} scheduleId - 排班ID
 */
export function deleteSchedule(scheduleId) {
  return request({
    url: `/api/schedules/${scheduleId}`,
    method: 'delete'
  })
}

