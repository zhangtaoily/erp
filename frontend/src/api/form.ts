import { request } from './request'
import type { FormPlugin, ClassPluginMeta } from '@/types/bo'

export const formApi = {
  // 表单元数据
  getMeta: (boCode: string) => request.get<any>(`/form/${boCode}/meta`),
  saveMeta: (boCode: string, data: any) => request.put(`/form/${boCode}/meta`, data),
  preview: (boCode: string, mode: 'view' | 'edit' | 'add') =>
    request.get<any>(`/form/${boCode}/preview`, { params: { mode } }),
  // 批量保存字段元数据（按 bo_code + entity_code 联合定位）
  batchSaveFields: (boCode: string, entityCode: string, fields: any[]) =>
    request.post(`/bo/${boCode}/entity/${entityCode}/fields/batch`, { fields })
}

// 插件
export const pluginApi = {
  list: (boCode: string) => request.get<FormPlugin[]>(`/form/${boCode}/plugins`),
  create: (data: Partial<FormPlugin>) => request.post<FormPlugin>('/plugin', data),
  update: (id: string, data: Partial<FormPlugin>) => request.put(`/plugin/${id}`, data),
  delete: (id: string) => request.delete(`/plugin/${id}`),
  toggleStatus: (id: string, status: number) => request.put(`/plugin/${id}/status`, { status }),
  // 反射扫描 .class/.jar 元数据（自描述模型：自动识别基类与参数结构，对应 PRD 06 6.2.4.1）
  // boCode 用于 @FormParam.key 字段存在性校验（RISK-D05-002）
  getClassMeta: (fileName: string, boCode?: string) =>
    request.get<ClassPluginMeta>(`/plugin/class-meta`, { params: { file: fileName, boCode } })
}
