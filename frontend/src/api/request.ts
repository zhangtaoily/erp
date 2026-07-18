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
service.interceptors.response.use(
  (response) => {
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
