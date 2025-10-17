import request from '@/utils/request'; // 假设这是您的 axios 封装

/**
 * 获取科室分页列表
 * GET /api/departments
 * 接收查询参数 queryDTO，返回 PageDepartmentResponseDTO
 */
export function getDepartmentPage(query) {
    // 1. 构造后端需要的参数
    const params = {
        name: query.name,
        description: query.description,
        // 💡 重点：后端分页 page 通常从 0 开始，前端的 currentPage 从 1 开始，所以需要 -1
        page: query.page - 1,
        size: query.size,
        sortBy: query.sortBy,
        // 💡 后端通常需要大写的 ASC/DESC 或全小写 asc/desc，具体看您的后端要求
        sortOrder: query.sortOrder === 'descending' ? 'DESC' : 'ASC',
    };

    // 2. 发起 GET 请求
    return request({
        url: '/api/departments', // 您的接口路径
        method: 'get',
        params: params, // 将参数放在 params 中，axios 会自动添加到 URL Query String
    });
}

/**
 * 新增科室信息
 * POST /api/departments
 * 接收 DepartmentCreationDTO (包含 name, parentDepartmentName, description)
 */
export function createDepartment(departmentData) {
    return request({
        url: '/api/departments',
        method: 'post', // 使用 POST 方法新增资源
        data: departmentData, // 将数据放在请求体中
    });
}

/**
 * 获取指定科室下的所有医生列表
 * GET /api/departments/{departmentId}/doctors
 * 返回 DepartmentDoctorsResponseDTO
 */
export function getDepartmentDoctors(departmentId) {
    return request({
        url: `/api/departments/${departmentId}/doctors`,
        method: 'get',
    });
}
/**
 * 为指定科室添加新成员
 * POST /api/departments/{departmentId}/members
 * @param {string|number} departmentId - 科室的ID
 * @param {object} memberData - 要添加的成员信息 (例如 { identifier, fullName, title })
 */
export function addDepartmentMember(departmentId, memberData) {
    return request({
        url: `/api/departments/${departmentId}/members`,
        method: 'post',
        data: memberData, // 将成员信息放在请求体中
    });
}

/**
 * 【新增】从指定科室删除一个成员
 * DELETE /api/departments/{departmentId}/members/{identifier}
 * @param {string|number} departmentId - 科室的ID
 * @param {string} memberIdentifier - 要删除的成员的ID (医生工号)
 */
export function deleteDepartmentMember(departmentId, memberIdentifier) {
    return request({
        url: `/api/departments/${departmentId}/members/${memberIdentifier}`,
        method: 'delete',
    });
}
/**
 * 更新科室信息 (根据图片接口)
 * PUT /api/departments/description
 * 接收 DepartmentUpdateDTO (包含 departmentId, name, description, parentDepartmentName)
 * ⚠️ 注意：此处假设请求体需要包含 departmentId，但图片示例中未列出。
 */
export function updateDepartmentDescription(departmentData) {
    return request({
        // 接口路径根据图片 URL 确定
        url: '/api/departments/description',
        method: 'put', // 使用 PUT 方法进行更新
        data: departmentData, // 将更新数据放在请求体中
    });
}

/**
 * 【新增】删除科室 (根据图片接口 DELETE /api/departments/{name})
 * @param {string} departmentName - 要删除的科室名称
 */
export function deleteDepartmentByName(departmentName) {
    return request({
        url: `/api/departments/${departmentName}`, // 路径参数是科室名称
        method: 'delete', // 使用 DELETE 方法删除资源
    });
}