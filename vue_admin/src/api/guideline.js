import request from '@/utils/request'

/**
 * 获取就医规范列表（分页）
 */
export function getGuidelines(params) {
  return request({
    url: '/api/medical-guidelines',
    method: 'get',
    params: {
      page: params.page || 1,
      pageSize: params.pageSize || 10,
      keyword: params.keyword || undefined,
      category: params.category || undefined,
      status: params.status || undefined
    }
  })
}

/**
 * 获取规范详情
 */
export function getGuidelineById(id) {
  return request({
    url: `/api/medical-guidelines/${id}`,
    method: 'get'
  })
}

/**
 * 创建规范
 */
export function createGuideline(data) {
  return request({
    url: '/api/medical-guidelines',
    method: 'post',
    data: {
      title: data.title,
      content: data.content,
      category: data.category,
      status: data.status,
      createdBy: data.createdBy
    }
  })
}

/**
 * 更新规范
 */
export function updateGuideline(id, data) {
  return request({
    url: `/api/medical-guidelines/${id}`,
    method: 'put',
    data: {
      title: data.title,
      content: data.content,
      category: data.category,
      status: data.status
    }
  })
}

/**
 * 删除规范
 */
export function deleteGuideline(id) {
  return request({
    url: `/api/medical-guidelines/${id}`,
    method: 'delete'
  })
}

