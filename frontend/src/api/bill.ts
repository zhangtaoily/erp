import { request } from './request'

// 单据运行时通用接口
export const billApi = {
  list: (boCode: string, params: any) => request.get<any>(`/bill/${boCode}/list`, { params }),
  detail: (boCode: string, id: string) => request.get<any>(`/bill/${boCode}/${id}`),
  save: (boCode: string, data: any) => request.post<any>(`/bill/${boCode}`, data),
  operate: (boCode: string, id: string, action: string, data?: any) =>
    request.post<any>(`/bill/${boCode}/${id}/${action}`, data),
  delete: (boCode: string, id: string) => request.delete(`/bill/${boCode}/${id}`)
}
