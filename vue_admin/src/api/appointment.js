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

