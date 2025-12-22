/**
 * Token管理工具
 */

const TOKEN_KEY = 'adminToken'

export function saveToken(token) {
  localStorage.setItem(TOKEN_KEY, token)
  console.log('[AUTH] Token已保存')
}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY)
}

export function removeToken() {
  localStorage.removeItem(TOKEN_KEY)
  console.log('[AUTH] Token已清除')
}

export function hasToken() {
  return getToken() !== null
}

