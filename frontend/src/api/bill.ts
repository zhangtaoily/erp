import { request } from './request'

// 单据运行时通用接口
export const billApi = {
  /** 列表查询（GET，兼容旧版扁平参数），用于简单查询场景（如加载 ref 选项） */
  list: (boCode: string, params: any) => request.get<any>(`/bill/${boCode}/list`, { params }),

  /** 列表查询（POST，结构化 conditions 数组），支持运算符选择和日期区间 */
  query: (boCode: string, params: any) => {
    const conditions = buildConditions(params)
    return request.post<any>(`/bill/${boCode}/list`, {
      conditions,
      pageNum: params.pageNum || 1,
      pageSize: params.pageSize || 20
    })
  },

  detail: (boCode: string, id: string) => request.get<any>(`/bill/${boCode}/${id}`),
  save: (boCode: string, data: any) => request.post<any>(`/bill/${boCode}`, data),
  operate: (boCode: string, id: string, action: string, data?: any) =>
    request.post<any>(`/bill/${boCode}/${id}/${action}`, data),
  delete: (boCode: string, id: string) => request.delete(`/bill/${boCode}/${id}`)
}

/** 将参数转换为 conditions 数组（兼容 old flat params 和 new conditions） */
function buildConditions(params: any): any[] {
  // 如果已包含 conditions 数组，直接使用
  if (Array.isArray(params.conditions)) return params.conditions
  // 旧版扁平参数：{ code: "0007", pact_state: 1 } → [{ field_code: "code", operator: "like", value: "0007" }, ...]
  const conditions: any[] = []
  const skipKeys = new Set(['pageNum', 'pageSize', 'expand', 'orderBy'])
  for (const key of Object.keys(params)) {
    if (skipKeys.has(key) || key.endsWith('_op')) continue
    const v = params[key]
    if (v === '' || v === null || v === undefined) continue
    // 如果值是 {op, value} 结构化对象，直接展开
    if (typeof v === 'object' && v !== null && 'op' in v) {
      conditions.push({
        field_code: key,
        operator: v.op,
        value: v.value,
        value_start: v.value_start,
        value_end: v.value_end
      })
    } else {
      // 扁平值：使用 op 参数或默认 eq
      const op = params[key + '_op'] || 'eq'
      conditions.push({ field_code: key, operator: op, value: v })
    }
  }
  return conditions
}
