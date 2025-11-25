import request from '@/utils/request';

/**
 * 获取所有请假申请 (管理员用)
 */
export function getAllLeaveRequests() {
    return request({
        url: '/api/leave-requests',
        method: 'get'
    });
}

/**
 * 根据状态获取请假申请
 * @param {string} status - 状态 (PENDING/APPROVED/REJECTED)
 */
export function getLeaveRequestsByStatus(status) {
    return request({
        url: `/api/leave-requests/status/${status}`,
        method: 'get'
    });
}

/**
 * 审批休假申请
 * @param {number} requestId - 申请ID
 * @param {number} approverId - 审批人ID
 * @param {string} comments - 审批意见 (可选)
 */
export function approveLeaveRequest(requestId, approverId, comments = '') {
    return request({
        url: `/api/leave-requests/${requestId}/approve`,
        method: 'put',
        params: {
            approverId,
            comments
        }
    });
}

/**
 * 拒绝休假申请
 * @param {number} requestId - 申请ID
 * @param {number} approverId - 审批人ID
 * @param {string} comments - 拒绝理由 (可选)
 */
export function rejectLeaveRequest(requestId, approverId, comments = '') {
    return request({
        url: `/api/leave-requests/${requestId}/reject`,
        method: 'put',
        params: {
            approverId,
            comments
        }
    });
}
