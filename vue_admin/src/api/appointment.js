import request from '@/utils/request';

/**
 * 患者扫码签到
 * @param {Object} data - { qrToken }
 */
export async function checkInAppointment(data) {
    return await request({
        url: '/api/appointments/check-in',
        method: 'POST',
        data
    });
}

/**
 * 获取预约二维码Token（用于测试）
 * @param {Number} appointmentId - 预约ID
 */
export async function getAppointmentQrCode(appointmentId) {
    return await request({
        url: `/api/appointments/${appointmentId}/qr-code`,
        method: 'GET'
    });
}

/**
 * 清除预约签到时间（管理员功能）
 * @param {Number} appointmentId - 预约ID
 */
export async function clearCheckIn(appointmentId) {
    return await request({
        url: `/api/appointments/${appointmentId}/check-in`,
        method: 'DELETE'
    });
}

/**
 * 获取叫号队列（已签到但未就诊的预约列表）
 * @param {Number} scheduleId - 排班ID
 */
export async function getCallQueue(scheduleId) {
    return await request({
        url: `/api/appointments/schedule/${scheduleId}/call-queue`,
        method: 'GET'
    });
}

/**
 * 获取下一个应该叫号的预约
 * @param {Number} scheduleId - 排班ID
 */
export async function getNextAppointmentToCall(scheduleId) {
    return await request({
        url: `/api/appointments/schedule/${scheduleId}/next-to-call`,
        method: 'GET'
    });
}

/**
 * 执行叫号
 * @param {Number} appointmentId - 预约ID
 */
export async function callAppointment(appointmentId) {
    return await request({
        url: `/api/appointments/${appointmentId}/call`,
        method: 'POST'
    });
}

/**
 * 过号后重新签到
 * @param {Number} appointmentId - 预约ID
 */
export async function recheckInAfterMissedCall(appointmentId) {
    return await request({
        url: `/api/appointments/${appointmentId}/recheck-in`,
        method: 'POST'
    });
}

