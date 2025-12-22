/**
 * Token管理工具
 * 统一管理Token的存储、获取和清除
 */

const TOKEN_KEYS = {
  patient: 'patientToken',
  doctor: 'doctorToken',
  admin: 'adminToken'
}

/**
 * 保存Token
 * @param {String} token Token字符串
 * @param {String} userType 用户类型：patient/doctor/admin
 */
export function saveToken(token, userType = 'patient') {
  const key = TOKEN_KEYS[userType] || TOKEN_KEYS.patient
  uni.setStorageSync(key, token)
  console.log(`[AUTH] Token已保存 - 用户类型: ${userType}`)
}

/**
 * 获取Token
 * @param {String} userType 用户类型：patient/doctor/admin
 * @returns {String|null} Token字符串，如果不存在则返回null
 */
export function getToken(userType = 'patient') {
  const key = TOKEN_KEYS[userType] || TOKEN_KEYS.patient
  const token = uni.getStorageSync(key)
  return token || null
}

/**
 * 清除Token
 * @param {String} userType 用户类型：patient/doctor/admin
 */
export function removeToken(userType = 'patient') {
  const key = TOKEN_KEYS[userType] || TOKEN_KEYS.patient
  uni.removeStorageSync(key)
  console.log(`[AUTH] Token已清除 - 用户类型: ${userType}`)
}

/**
 * 清除所有Token（退出登录时使用）
 */
export function clearAllTokens() {
  Object.values(TOKEN_KEYS).forEach(key => {
    uni.removeStorageSync(key)
  })
  console.log('[AUTH] 所有Token已清除')
}

/**
 * 检查Token是否存在
 * @param {String} userType 用户类型
 * @returns {Boolean}
 */
export function hasToken(userType = 'patient') {
  return getToken(userType) !== null
}

