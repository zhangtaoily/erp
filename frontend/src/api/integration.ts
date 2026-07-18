import { request } from './request'
import type { Attachment, ImportTask, ApiLog, BillLink, ChangeLog } from '@/types/bo'

// 附件
export const attachmentApi = {
  list: (billType: string, billId: string) =>
    request.get<Attachment[]>(`/attachment/list`, { params: { billType, billId } }),
  upload: (billType: string, billId: string, data: FormData) =>
    request.post<Attachment>(`/attachment/upload`, data),
  delete: (id: string) => request.delete(`/attachment/${id}`)
}

// 导入任务
export const importApi = {
  list: (params?: any) => request.get<any>('/import-task/list', { params }),
  template: (templateCode: string) =>
    request.get(`/import-task/template/${templateCode}`),
  upload: (data: FormData) => request.post<ImportTask>('/import-task/upload', data),
  detail: (id: string) => request.get<ImportTask>(`/import-task/${id}`)
}

// API 日志
export const apiLogApi = {
  list: (params?: any) => request.get<any>('/api-log/list', { params }),
  detail: (id: string) => request.get<ApiLog>(`/api-log/${id}`)
}

// 单据联查
export const billTraceApi = {
  upstream: (billType: string, billId: string) =>
    request.get<BillLink[]>(`/bill/trace/upstream`, { params: { billType, billId } }),
  downstream: (billType: string, billId: string) =>
    request.get<BillLink[]>(`/bill/trace/downstream`, { params: { billType, billId } })
}

// 变更历史
export const changeLogApi = {
  list: (billType: string, billId: string) =>
    request.get<ChangeLog[]>(`/bill/change-log`, { params: { billType, billId } })
}
