import axios, { type AxiosRequestConfig, type AxiosResponse } from 'axios'

const service = axios.create({
  baseURL: '/api',
  timeout: 15000
})

/** camelCase → snake_case 转换：后端返回驼峰，前端统一用下划线 */
function toSnakeCase(key: string): string {
  return key.replace(/([A-Z])/g, '_$1').toLowerCase()
}

function toSnakeKeys(obj: any): any {
  if (Array.isArray(obj)) return obj.map(toSnakeKeys)
  if (obj !== null && typeof obj === 'object') {
    const result: Record<string, any> = {}
    for (const key of Object.keys(obj)) {
      result[toSnakeCase(key)] = toSnakeKeys(obj[key])
    }
    return result
  }
  return obj
}

// 请求拦截器 - 自动携带 JWT
service.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器 - 统一处理 {code,message,data}
let redirecting = false
service.interceptors.response.use(
  (response) => {
    // 成功响应说明 token 有效，重置跳转标志（避免首次 403 后 redirecting 卡住导致后续不再跳转登录页）
    redirecting = false
    const res = response.data
    if (res && typeof res === 'object' && 'code' in res) {
      if (res.code != 0) {
        return Promise.reject(new Error(res.message || 'Error'))
      }
      return toSnakeKeys(res.data)
    }
    return res
  },
  (error) => {
    // 401/403：token 失效或未登录，清理并跳转登录页（避免重复跳转）
    const status = error?.response?.status
    if ((status === 401 || status === 403) && !redirecting) {
      redirecting = true
      localStorage.removeItem('token')
      const current = window.location.pathname + window.location.search
      if (!current.startsWith('/login')) {
        window.location.href = '/login?redirect=' + encodeURIComponent(current)
      }
    }
    return Promise.reject(error)
  }
)

export default service

// 通用请求方法
export const request = {
  get<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return service.get(url, config) as unknown as Promise<T>
  },
  post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return service.post(url, data, config) as unknown as Promise<T>
  },
  put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    return service.put(url, data, config) as unknown as Promise<T>
  },
  delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return service.delete(url, config) as unknown as Promise<T>
  }
}
