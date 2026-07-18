import { request } from './request'
import type { CodeRule } from '@/types/bo'

export const codeRuleApi = {
  list: (params?: any) => request.get<CodeRule[]>('/code-rule', { params }),
  detail: (id: string) => request.get<CodeRule>(`/code-rule/${id}`),
  create: (data: Partial<CodeRule>) => request.post<CodeRule>('/code-rule', data),
  update: (id: string, data: Partial<CodeRule>) => request.put(`/code-rule/${id}`, data),
  delete: (id: string) => request.delete(`/code-rule/${id}`),
  preview: (ruleId: string) => request.get<string>(`/code-rule/${ruleId}/preview`)
}
