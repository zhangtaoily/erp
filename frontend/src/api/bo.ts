import { request } from './request'
import type { BusinessObject, FormEntity, FormField } from '@/types/bo'

// 业务对象
export const boApi = {
  list: (params?: any) => request.get<any>('/bo/list', { params }),
  detail: (boCode: string) => request.get<BusinessObject>(`/bo/${boCode}`),
  create: (data: Partial<BusinessObject>) => request.post<BusinessObject>('/bo', data),
  update: (boCode: string, data: Partial<BusinessObject>) => request.put(`/bo/${boCode}`, data),
  toggleStatus: (boCode: string, status: number) => request.put(`/bo/${boCode}/status`, { status })
}

// 实体
export const entityApi = {
  list: (boCode: string) => request.get<FormEntity[]>(`/bo/${boCode}/entities`),
  // 按业务对象汇总所有实体（主表/子表/孙表）字段，用于字段权限等场景动态加载（GAP-D11-007 / RISK-D11-003）
  fields: async (boCode: string): Promise<FormField[]> => {
    const entities = await request.get<FormEntity[]>(`/bo/${boCode}/entities`)
    return (entities || []).flatMap(e => e.fields || [])
  },
  create: (data: Partial<FormEntity>) => request.post<FormEntity>('/entity', data),
  update: (id: string, data: Partial<FormEntity>) => request.put(`/entity/${id}`, data),
  delete: (id: string) => request.delete(`/entity/${id}`)
}

// 字段
// entity_code 在不同 bo_code 下可能重复（如 SAL_INT_CONT 和 SAL_QUOTE 都有 goods 子表），
// 所有接口必须用 bo_code + entity_code 联合定位，避免数据串号
export const fieldApi = {
  list: (boCode: string, entityCode: string) =>
    request.get<FormField[]>(`/bo/${boCode}/entity/${entityCode}/fields`),
  create: (data: Partial<FormField>) => request.post<FormField>('/field', data),
  update: (id: string, data: Partial<FormField>) => request.put(`/field/${id}`, data),
  delete: (id: string) => request.delete(`/field/${id}`),
  batchSave: (boCode: string, entityCode: string, fields: Partial<FormField>[]) =>
    request.post(`/bo/${boCode}/entity/${entityCode}/fields/batch`, { fields })
}

// 表单布局元数据（meta_form_layout 持久化，对应 PRD 5.2.10 + 1.1.4）
export interface FormLayout {
  id: string
  bo_code: string
  layout_code?: string
  layout_name?: string
  layout_json: string
  is_default: 0 | 1
  version: number
  create_by?: string
  create_time?: string
}

export const formLayoutApi = {
  // 获取默认布局
  getDefault: (boCode: string) => request.get<FormLayout | null>(`/form-layout/${boCode}`),
  // 列出业务对象所有布局版本
  list: (boCode: string) => request.get<FormLayout[]>(`/form-layout/${boCode}/list`),
  // 保存（新增）布局
  save: (data: Partial<FormLayout>) => request.post<FormLayout>('/form-layout', data),
  // 更新布局
  update: (id: string, data: Partial<FormLayout>) => request.put(`/form-layout/${id}`, data)
}
