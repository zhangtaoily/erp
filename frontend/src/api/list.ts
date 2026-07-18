import { request } from './request'
import type { ListColumn, QueryField, QueryScheme, UserListSetting } from '@/types/bo'

export const listConfigApi = {
  columns: (boCode: string) => request.get<ListColumn[]>(`/bo/${boCode}/columns`),
  saveColumns: (boCode: string, columns: Partial<ListColumn>[]) =>
    request.put(`/bo/${boCode}/columns`, { columns }),
  queryFields: (boCode: string) => request.get<QueryField[]>(`/bo/${boCode}/query-fields`),
  saveQueryFields: (boCode: string, fields: Partial<QueryField>[]) =>
    request.put(`/bo/${boCode}/query-fields`, { fields })
}

// 查询方案
export const schemeApi = {
  list: (boCode: string) => request.get<QueryScheme[]>('/query-scheme', { params: { boCode } }),
  create: (data: Partial<QueryScheme>) => request.post<QueryScheme>('/query-scheme', data),
  update: (id: string, data: Partial<QueryScheme>) => request.put(`/query-scheme/${id}`, data),
  delete: (id: string) => request.delete(`/query-scheme/${id}`),
  setDefault: (id: string) => request.put(`/query-scheme/${id}/default`),
  favorite: (id: string, favorite: boolean) => request.put(`/query-scheme/${id}/favorite`, { favorite })
}

// 用户列设置（GAP-D09-002 / RISK-D09-003：列设置持久化到 user_list_setting.columns_json）
export const userListSettingApi = {
  get: (boCode: string) => request.get<UserListSetting>(`/user-list-setting`, { params: { boCode } }),
  save: (data: Partial<UserListSetting>) => request.post<UserListSetting>(`/user-list-setting`, data)
}

// 当前用户上下文（GAP-D09-005 / RISK-D09-002：移除硬编码 'u1'，从后端获取）
export const currentUserApi = {
  get: () => request.get<{ id: string; user_code: string; user_name: string; org_id: string }>(`/current-user`)
}
