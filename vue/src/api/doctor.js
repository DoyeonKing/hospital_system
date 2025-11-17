import request from '@/utils/request';

/**
 * 获取当前登录医生的详细个人资料
 * (假设后端提供了 /api/doctor/profile 接口，
 * 它会根据token自动返回当前医生的信息)
 */
export function getDoctorProfile() {
    return request({
        url: '/api/doctor/profile', // 假设后端获取个人资料的接口
        method: 'get'
    });
}

/**
 * 更新当前登录医生的个人资料
 * @param {Object} data - 包含要更新字段的对象
 * (e.g., { phoneNumber, bio, photoUrl })
 */
export function updateDoctorProfile(data) {
    return request({
        url: '/api/doctor/profile', // 假设后端更新个人资料的接口
        method: 'put',
        data: data
    });
}