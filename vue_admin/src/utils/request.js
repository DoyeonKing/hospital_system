import axios from "axios";
import {ElMessage} from "element-plus";
import { getToken, removeToken } from './auth.js'
import router from '@/router'

// 云服务器IP地址（与数据库同一台服务器）
// const CLOUD_SERVER_IP = '123.249.30.241'  // 👈 云服务器配置（已注释）

const request = axios.create({
  // ✅ 本地开发模式：使用空字符串，让 Vite 代理处理请求（代理指向 localhost:8080）
  baseURL: ``,
  // 如果不想使用代理，可以直接设置 baseURL（取消注释下面一行，并注释掉上面一行）：
  // baseURL: import.meta.env.DEV ? 'http://localhost:8080' : 'http://localhost:8080',
  // 云服务器配置（已注释，如需切换回云服务器可取消注释）：
  // baseURL: 'http://123.249.30.241:8080',
  timeout: 30000  // 后台接口超时时间
})

// request 拦截器
// 可以自请求发送前对请求做一些处理
request.interceptors.request.use(config => {
  console.log('=== 请求拦截器 ===');
  console.log('请求URL:', config.baseURL + config.url);
  console.log('请求方法:', config.method);
  console.log('请求数据:', config.data);
  console.log('请求头（设置前）:', config.headers);
  
  // 确保 headers 对象存在
  if (!config.headers) {
    config.headers = {};
  }
  
  // 添加Token到请求头
  const token = getToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  
  // 如果是FormData类型，不设置Content-Type，让浏览器自动设置（包含boundary）
  // 否则，对于 POST/PUT/PATCH 请求，设置 Content-Type
  if (!(config.data instanceof FormData)) {
    if (config.data && (config.method === 'post' || config.method === 'put' || config.method === 'patch')) {
      config.headers['Content-Type'] = 'application/json;charset=utf-8';
    }
  }
  
  console.log('请求头（设置后）:', config.headers);
  console.log('================');
  
  return config
}, error => {
  return Promise.reject(error)
});

// response 拦截器
// 可以在接口响应后统一处理结果
request.interceptors.response.use(
  response => {
    if (response?.config?.responseType === 'blob') {
      return response.data;
    }

    let res = response.data;
    
    // 处理字符串响应
    if (typeof res === 'string') {
      try {
        res = res ? JSON.parse(res) : res;
      } catch (e) {
        // 如果解析失败，可能是错误消息，直接返回
        console.warn('无法解析字符串响应:', res);
        return res;
      }
    }

    // 深拷贝处理，避免响应式污染
    try {
        if (res && typeof res === 'object') {
             res = JSON.parse(JSON.stringify(res));
        }
    } catch (e) {
        console.error("Deep copy failed in request interceptor:", e);
    }

    return res;
  },
  error => {
    console.error('请求错误:', error);
    
    if (error.response) {
      const status = error.response.status;
      const data = error.response.data;
      
      // 处理401错误（Token无效或过期）
      if (status === 401 || (data && data.code === '401')) {
        removeToken()
        ElMessage.error('登录已过期，请重新登录')
        // 跳转到登录页
        if (router.currentRoute.value.path !== '/login') {
          router.push('/login')
        }
        return Promise.reject(new Error('Token已过期'))
      }
      
      if (status === 404) {
        ElMessage.error('未找到请求接口');
      } else if (status === 500) {
        ElMessage.error('系统异常，请查看后端控制台报错');
      } else if (status >= 400 && status < 500) {
        // 客户端错误，显示后端返回的错误信息
        const errorMsg = typeof data === 'string' ? data : (data?.message || data?.msg || '请求参数错误');
        ElMessage.error(errorMsg);
      } else {
        ElMessage.error('服务器错误');
      }
    } else if (error.request) {
      ElMessage.error('网络错误，请检查网络连接');
    } else {
      ElMessage.error(error.message || '请求失败');
    }
    
    return Promise.reject(error);
  }
)
//导出request
export default request