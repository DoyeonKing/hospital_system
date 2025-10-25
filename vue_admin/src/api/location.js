import request from '@/utils/request'

/**
 * 根据科室ID获取该科室下的办公地点名称列表
 * GET /api/locations/department/{departmentId}/names
 * @param {number} departmentId - 科室ID
 */
export function getLocationNamesByDepartmentId(departmentId) {
    return request({
        url: `/api/locations/department/${departmentId}/names`,
        method: 'get',
    });
}
