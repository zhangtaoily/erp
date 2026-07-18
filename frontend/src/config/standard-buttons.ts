import type { ButtonDef, ButtonAvailability } from '@/types/bo'

// 标准按钮可用性矩阵（PRD 02.2.11）
// availability[0..4] 对应 0暂存 1已创建 2已提交 3已审核 4已驳回
const E: ButtonAvailability = 'enabled'   // 可用
const D: ButtonAvailability = 'disabled'  // 禁用
const H: ButtonAvailability = 'hidden'    // 隐藏

// 标准按钮定义 + 可用性矩阵（PRD 02.2.11）
export const standardButtons: ButtonDef[] = [
  { id: 'b1', bo_code: '*', button_code: 'add', button_name: '新增', icon: 'Plus', position: 'both', sort_index: 1, is_custom: false, need_confirm: false, availability: [E, E, E, E, E] },
  { id: 'b2', bo_code: '*', button_code: 'copy', button_name: '复制', icon: 'CopyDocument', position: 'both', sort_index: 2, is_custom: false, need_confirm: false, availability: [E, E, E, E, E] },
  { id: 'b3', bo_code: '*', button_code: 'draft', button_name: '暂存', icon: 'EditPen', position: 'form', sort_index: 3, is_custom: false, need_confirm: false, availability: [E, E, H, H, E] },
  { id: 'b4', bo_code: '*', button_code: 'save', button_name: '保存', icon: 'Folder', position: 'form', sort_index: 4, is_custom: false, need_confirm: false, availability: [E, E, H, H, E] },
  { id: 'b5', bo_code: '*', button_code: 'submit', button_name: '提交', icon: 'Promotion', position: 'form', sort_index: 5, is_custom: false, need_confirm: false, availability: [H, E, H, H, E] },
  { id: 'b6', bo_code: '*', button_code: 'audit', button_name: '审核', icon: 'CircleCheck', position: 'form', sort_index: 6, is_custom: false, need_confirm: false, availability: [H, H, E, H, H] },
  { id: 'b7', bo_code: '*', button_code: 'revoke', button_name: '撤销', icon: 'RefreshLeft', position: 'form', sort_index: 7, is_custom: false, need_confirm: true, availability: [H, H, E, E, H] },
  { id: 'b8', bo_code: '*', button_code: 'reject', button_name: '驳回', icon: 'CloseBold', position: 'form', sort_index: 8, is_custom: false, need_confirm: true, availability: [H, H, E, H, H] },
  { id: 'b9', bo_code: '*', button_code: 'delete', button_name: '删除', icon: 'Delete', position: 'both', sort_index: 9, is_custom: false, need_confirm: true, availability: [E, E, H, H, E] },
  { id: 'b10', bo_code: '*', button_code: 'close', button_name: '关闭', icon: 'Lock', position: 'both', sort_index: 10, is_custom: false, need_confirm: true, availability: [H, H, H, E, H] },
  { id: 'b11', bo_code: '*', button_code: 'cancel', button_name: '取消', icon: 'CircleClose', position: 'both', sort_index: 11, is_custom: false, need_confirm: true, availability: [H, H, H, E, H] },
  { id: 'b12', bo_code: '*', button_code: 'change', button_name: '变更', icon: 'Edit', position: 'both', sort_index: 12, is_custom: false, need_confirm: false, availability: [H, H, H, E, H] },
  { id: 'b13', bo_code: '*', button_code: 'push', button_name: '下推', icon: 'Download', position: 'both', sort_index: 13, is_custom: false, need_confirm: false, availability: [H, H, H, E, H] },
  { id: 'b14', bo_code: '*', button_code: 'trace', button_name: '联查', icon: 'Connection', position: 'both', sort_index: 14, is_custom: false, need_confirm: false, availability: [E, E, E, E, E] },
  { id: 'b15', bo_code: '*', button_code: 'print', button_name: '打印', icon: 'Printer', position: 'both', sort_index: 15, is_custom: false, need_confirm: false, availability: [H, E, E, E, E] }
]

// 导出：按钮可用性矩阵（行=按钮code，列=状态0-4）
export const buttonAvailabilityMatrix: Record<string, ButtonAvailability[]> = standardButtons.reduce(
  (acc, btn) => ({ ...acc, [btn.button_code]: btn.availability }),
  {} as Record<string, ButtonAvailability[]>
)

// 抑制未使用变量告警（D 预留给后续禁用态配置）
void D
