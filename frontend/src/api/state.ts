import { request } from './request'
import type { StateNode, StateTransition, ButtonDef, PushRule } from '@/types/bo'

export const stateApi = {
  // 状态机
  nodes: (boCode: string) => request.get<StateNode[]>(`/bo/${boCode}/states`),
  transitions: (boCode: string) => request.get<StateTransition[]>(`/bo/${boCode}/transitions`),
  // 状态节点 CRUD（GAP-D03-001/002）
  saveNode: (data: Partial<StateNode>) => request.post<StateNode>('/state-node', data),
  updateNode: (id: string, data: Partial<StateNode>) => request.put(`/state-node/${id}`, data),
  deleteNode: (id: string) => request.delete(`/state-node/${id}`),
  // 节点位置持久化（GAP-D03-004 / RISK-D03-003）
  saveNodePosition: (id: string, pos_x: number, pos_y: number) =>
    request.put(`/state-node/${id}/position`, { pos_x, pos_y }),
  // 流转 CRUD
  saveTransition: (data: Partial<StateTransition>) => request.post<StateTransition>('/transition', data),
  updateTransition: (id: string, data: Partial<StateTransition>) =>
    request.put(`/transition/${id}`, data),
  deleteTransition: (id: string) => request.delete(`/transition/${id}`),
  // 业务操作日志（GAP-D03-007）
  opLogs: (boCode: string) => request.get<any[]>(`/bo/${boCode}/op-logs`)
}

// 按钮
export const buttonApi = {
  list: (boCode: string) => request.get<ButtonDef[]>(`/bo/${boCode}/buttons`),
  create: (data: Partial<ButtonDef>) => request.post<ButtonDef>('/button', data),
  update: (id: string, data: Partial<ButtonDef>) => request.put(`/button/${id}`, data),
  delete: (id: string) => request.delete(`/button/${id}`)
}

// 下推规则
export const pushRuleApi = {
  list: (params?: any) => request.get<PushRule[]>('/push-rule', { params }),
  detail: (id: string) => request.get<PushRule>(`/push-rule/${id}`),
  create: (data: Partial<PushRule>) => request.post<PushRule>('/push-rule', data),
  update: (id: string, data: Partial<PushRule>) => request.put(`/push-rule/${id}`, data),
  delete: (id: string) => request.delete(`/push-rule/${id}`)
}

// 打印模板
export const printApi = {
  list: (boCode: string) => request.get<any[]>(`/bo/${boCode}/print-templates`),
  save: (data: any) => request.post<any>('/print-template', data),
  delete: (id: string) => request.delete(`/print-template/${id}`)
}
