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
        // 💡 后端通常需要大写的 ASC/DESC 或全小写 asc/desc
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
 * 更新科室信息
 * PUT /api/departments
 * 接收 DepartmentDTO (包含 id, name, parentDepartmentName, description)
 */
export function updateDepartment(departmentData) {
    return request({
        url: '/api/departments',
        method: 'put', // 使用 PUT 方法更新资源
        data: departmentData, // 将数据放在请求体中
    });
}

/**
 * 删除指定ID的科室
 * DELETE /api/departments/{id}
 */
export function deleteDepartment(id) {
    return request({
        url: `/api/departments/${id}`, // 使用模板字符串拼接ID
        method: 'delete',
    });
}