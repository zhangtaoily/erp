import { request } from './request'
import type { Org, SysUser, Role, RoleButton, DataPermissionRule, FieldPermission, SysDept, SysUserOrg } from '@/types/bo'

export const orgApi = {
  tree: () => request.get<Org[]>('/org/tree'),
  create: (data: Partial<Org>) => request.post<Org>('/org', data),
  update: (id: string, data: Partial<Org>) => request.put(`/org/${id}`, data),
  delete: (id: string) => request.delete(`/org/${id}`)
}

// 部门管理（PRD 04.2，sys_dept 独立管理页面 GAP-D11-004）
export const deptApi = {
  list: (params?: any) => request.get<SysDept[]>('/dept/list', { params }),
  create: (data: Partial<SysDept>) => request.post<SysDept>('/dept', data),
  update: (id: string, data: Partial<SysDept>) => request.put(`/dept/${id}`, data),
  delete: (id: string) => request.delete(`/dept/${id}`)
}

export const userApi = {
  list: (params?: any) => request.get<any>('/user/list', { params }),
  create: (data: Partial<SysUser>) => request.post<SysUser>('/user', data),
  update: (id: string, data: Partial<SysUser>) => request.put(`/user/${id}`, data),
  delete: (id: string) => request.delete(`/user/${id}`)
}

// 用户多组织归属（PRD 04.1.4，sys_user_org GAP-D11-001 / RISK-D11-002）
export const userOrgApi = {
  list: (userId: string) => request.get<SysUserOrg[]>(`/user/${userId}/orgs`),
  save: (userId: string, orgs: Partial<SysUserOrg>[]) =>
    request.put(`/user/${userId}/orgs`, { orgs })
}

export const roleApi = {
  list: () => request.get<Role[]>('/role/list'),
  create: (data: Partial<Role>) => request.post<Role>('/role', data),
  update: (id: string, data: Partial<Role>) => request.put(`/role/${id}`, data),
  delete: (id: string) => request.delete(`/role/${id}`),
  buttons: (roleId: string) => request.get<RoleButton[]>(`/role/${roleId}/buttons`),
  saveButtons: (roleId: string, buttons: RoleButton[]) =>
    request.put(`/role/${roleId}/buttons`, { buttons }),
  // 按 bo_code 查询所有角色的按钮权限（GAP-D03-006 / RISK-D03-004：按钮矩阵叠加预览用）
  buttonsByBo: (boCode: string) => request.get<(RoleButton & { role_name?: string })[]>(`/bo/${boCode}/role-buttons`)
}

export const dataPermApi = {
  list: (roleId: string) => request.get<DataPermissionRule[]>(`/role/${roleId}/data-perm`),
  save: (roleId: string, rules: Partial<DataPermissionRule>[]) =>
    request.put(`/role/${roleId}/data-perm`, { rules })
}

export const fieldPermApi = {
  list: (roleId: string, boCode: string) =>
    request.get<FieldPermission[]>(`/role/${roleId}/field-perm`, { params: { boCode } }),
  save: (roleId: string, boCode: string, perms: FieldPermission[]) =>
    request.put(`/role/${roleId}/field-perm`, { boCode, perms })
}
