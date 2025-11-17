import request from '@/utils/request';
import { useDoctorStore } from '@/stores/doctorStore';

/**
 * 获取医生当日的患者列表（包含预约、病史等信息）
 * 这是一个假设的DCI接口，后端需要实现此接口
 * 它会根据医生的Token和所选日期，返回一个包含详细信息的患者列表
 *
 * @param {Object} params - 查询参数
 * @param {string} params.date - 查询日期 (YYYY-MM-DD)
 * @param {string} [params.query] - 搜索关键词 (姓名/手机号/身份证号)
 * @param {string} [params.sort] - 排序字段, e.g., 'appointmentNumber,asc'
 * @param {number} [params.page] - 页码 (从0开始)
 * @param {number} [params.size] - 每页大小
 */
export function getTodaysPatients(params) {
    // 假设后端提供了一个专门的接口来获取医生当天的患者
    // 这个接口返回的数据应该整合了 appointments, patients 和 patient_profiles
    return request({
        url: '/api/doctor/todays-appointments', // 假设的接口路径
        method: 'get',
        params
    });
}

/**
 * (备用) 根据ID获取患者的详细档案
 * @param {number} patientId
 */
export function getPatientProfile(patientId) {
    return request({
        url: `/api/patient-profiles/${patientId}`, // 路径基于您的表结构推断
        method: 'get'
    });
}