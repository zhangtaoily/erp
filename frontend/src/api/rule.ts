import { request } from './request'
import type { EntityRule, WritebackRule } from '@/types/bo'

export const entityRuleApi = {
  list: (boCode: string) => request.get<EntityRule[]>(`/bo/${boCode}/entity-rules`),
  detail: (id: string) => request.get<EntityRule>(`/entity-rule/${id}`),
  create: (data: Partial<EntityRule>) => request.post<EntityRule>('/entity-rule', data),
  update: (id: string, data: Partial<EntityRule>) => request.put(`/entity-rule/${id}`, data),
  delete: (id: string) => request.delete(`/entity-rule/${id}`),
  validate: (expr: string) => request.post<{ valid: boolean; error?: string }>('/entity-rule/validate', { expr })
}

export const writebackApi = {
  list: (params?: any) => request.get<WritebackRule[]>('/writeback-rule', { params }),
  detail: (id: string) => request.get<WritebackRule>(`/writeback-rule/${id}`),
  create: (data: Partial<WritebackRule>) => request.post<WritebackRule>('/writeback-rule', data),
  update: (id: string, data: Partial<WritebackRule>) => request.put(`/writeback-rule/${id}`, data),
  delete: (id: string) => request.delete(`/writeback-rule/${id}`)
}
