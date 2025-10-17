import axios from "axios";
import {ElMessage} from "element-plus";

const request = axios.create({
  baseURL: 'http://localhost:8080',
  timeout: 30000  // 后台接口超时时间
})

// request 拦截器
// 可以自请求发送前对请求做一些处理
request.interceptors.request.use(config => {
  config.headers['Content-Type'] = 'application/json;charset=utf-8';
  return config
}, error => {
  return Promise.reject(error)
});

// response 拦截器
// 可以在接口响应后统一处理结果
request.interceptors.response.use(
  response => {
    let res = response.data;
    // 兼容服务端返回的字符串数据
    if (typeof res === 'string') {
      res = res ? JSON.parse(res) : res
    }

    // 【核心修复：在数据返回前进行深拷贝，阻止响应式污染】
    try {
        if (res && typeof res === 'object') {
             // 强制转换为纯净的 JavaScript 对象，解除所有引用
             res = JSON.parse(JSON.stringify(res));
        }
    } catch (e) {
        console.error("Deep copy failed in request interceptor:", e);
    }

    return res;
  },
  error => {
    if (error.response && error.response.status === 404) {
      ElMessage.error('未找到请求接口')
    } else if (error.response && error.response.status === 500) {
      ElMessage.error('系统异常，请查看后端控制台报错')
    } else {
      console.error(error.message)
      ElMessage.error(error.message || '请求失败，请检查网络');
    }
    return Promise.reject(error)
  }
)
//导出request
export default request