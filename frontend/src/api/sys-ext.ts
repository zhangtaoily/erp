import { request } from './request'
import type {
  SecurityPolicy,
  WfInstance,
  StorageConfig,
  ApiAuthConfig,
  ImportTemplate
} from '@/types/bo'

// ============ 登录安全（PRD 04.6 GAP-D11-006 / RISK-D11-004）============
export const securityApi = {
  getPolicy: () => request.get<SecurityPolicy>('/security/policy'),
  savePolicy: (data: Partial<SecurityPolicy>) => request.put<SecurityPolicy>('/security/policy', data),
  auditLogs: (params?: any) => request.get<any>('/security/audit-logs', { params })
}

// ============ 工作流实例（PRD 07.4 GAP-D12-007 / RISK-D12-002）============
export const wfInstanceApi = {
  list: (params?: any) => request.get<any>('/wf-instance/list', { params }),
  detail: (id: string) => request.get<WfInstance>(`/wf-instance/${id}`),
  submit: (data: Partial<WfInstance>) => request.post<WfInstance>('/wf-instance/submit', data),
  callback: (id: string, data: { status: WfInstance['status']; remark?: string }) =>
    request.post(`/wf-instance/${id}/callback`, data)
}

// ============ 附件存储配置（PRD 07.1.3 GAP-D12-003/006 / RISK-D12-003）============
export const storageApi = {
  list: () => request.get<StorageConfig[]>('/storage/list'),
  active: () => request.get<StorageConfig | null>('/storage/active'),
  create: (data: Partial<StorageConfig>) => request.post<StorageConfig>('/storage', data),
  update: (id: string, data: Partial<StorageConfig>) => request.put(`/storage/${id}`, data),
  activate: (id: string) => request.post(`/storage/${id}/activate`),
  delete: (id: string) => request.delete(`/storage/${id}`)
}

// ============ API 鉴权配置（PRD 07.5 GAP-D12-008/009/010 / RISK-D12-005）============
export const apiAuthApi = {
  list: () => request.get<ApiAuthConfig[]>('/api-auth/list'),
  create: (data: Partial<ApiAuthConfig>) => request.post<ApiAuthConfig>('/api-auth', data),
  update: (id: string, data: Partial<ApiAuthConfig>) => request.put(`/api-auth/${id}`, data),
  delete: (id: string) => request.delete(`/api-auth/${id}`),
  idempotentRecords: (params?: any) => request.get<any>('/api-auth/idempotent-records', { params })
}

// ============ 导入模板配置（PRD 07.3.7 GAP-D12-012 / RISK-D12-006）============
export const importTemplateApi = {
  list: (params?: any) => request.get<any>('/import-template/list', { params }),
  detail: (id: string) => request.get<ImportTemplate>(`/import-template/${id}`),
  create: (data: Partial<ImportTemplate>) => request.post<ImportTemplate>('/import-template', data),
  update: (id: string, data: Partial<ImportTemplate>) => request.put(`/import-template/${id}`, data),
  delete: (id: string) => request.delete(`/import-template/${id}`)
}
