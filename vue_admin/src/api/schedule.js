import request from '@/utils/request'

/**
 * 创建排班
 * POST /api/schedules/create
 * @param {Object} scheduleData - 排班数据
 * @param {number} scheduleData.doctorId - 医生ID
 * @param {string} scheduleData.scheduleDate - 出诊日期 (YYYY-MM-DD)
 * @param {number} scheduleData.slotId - 时间段ID
 * @param {number} scheduleData.locationId - 就诊地点ID
 * @param {number} [scheduleData.totalSlots=10] - 总号源数
 * @param {number} [scheduleData.fee=5.00] - 挂号费
 * @param {string} [scheduleData.remarks] - 备注信息
 */
export function createSchedule(scheduleData) {
    return request({
        url: '/api/schedules/create',
        method: 'post',
        data: scheduleData
    });
}

/**
 * 获取排班列表
 * GET /api/schedules
 * @param {Object} params - 查询参数
 * @param {string} [params.startDate] - 开始日期
 * @param {string} [params.endDate] - 结束日期
 * @param {number} [params.page=0] - 页码
 * @param {number} [params.size=10] - 每页大小
 */
export function getSchedules(params = {}) {
    return request({
        url: '/api/schedules',
        method: 'get',
        params: params
    });
}

/**
 * 获取排班详情
 * GET /api/schedules/{id}
 * @param {number} scheduleId - 排班ID
 */
export function getScheduleById(scheduleId) {
    return request({
        url: `/api/schedules/${scheduleId}`,
        method: 'get'
    });
}

/**
 * 更新排班
 * PUT /api/schedules/{id}
 * @param {number} scheduleId - 排班ID
 * @param {Object} updateData - 更新数据
 * @param {number} [updateData.totalSlots] - 总号源数
 * @param {number} [updateData.fee] - 挂号费
 */
export function updateSchedule(scheduleId, updateData) {
    return request({
        url: `/api/schedules/${scheduleId}`,
        method: 'put',
        data: updateData
    });
}

/**
 * 批量更新排班
 * PUT /api/schedules/batch-update
 * @param {Object} batchData - 批量更新数据
 * @param {Array} batchData.updates - 更新项列表
 * @param {number} batchData.updates[].scheduleId - 排班ID
 * @param {number} [batchData.updates[].totalSlots] - 总号源数
 * @param {number} [batchData.updates[].fee] - 挂号费
 */
export function batchUpdateSchedules(batchData) {
    return request({
        url: '/api/schedules/batch-update',
        method: 'put',
        data: batchData
    });
}

/**
 * 删除排班
 * DELETE /api/schedules/{id}
 * @param {number} scheduleId - 排班ID
 */
export function deleteSchedule(scheduleId) {
    return request({
        url: `/api/schedules/${scheduleId}`,
        method: 'delete'
    });
}