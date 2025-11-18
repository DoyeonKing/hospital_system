import request from '@/utils/request';

/**
 * 获取当前医生所有的休假申请记录
 * (假设后端提供了 /api/doctor/leave-requests 接口)
 */
export function getMyLeaveRequests() {
    return request({
        url: '/api/doctor/leave-requests', // 假设后端接口
        method: 'get',
        params: { page: 0, size: 100 } // 获取最近100条
    });
}

/**
 * 医生提交一个新的休假申请
 * @param {Object} data
 * (e.g., { requestType: 'SICK_LEAVE', startDate, endDate, reason })
 */
export function createLeaveRequest(data) {
    return request({
        url: '/api/doctor/leave-requests', // 假设后端接口
        method: 'post',
        data: data
    });
}

/**
 * 医生撤销一个*待审批*的休假申请
 * @param {number} leaveId
 */
export function cancelLeaveRequest(leaveId) {
    return request({
        url: `/api/doctor/leave-requests/${leaveId}/cancel`, // 假设后端接口
        method: 'put'
    });
}