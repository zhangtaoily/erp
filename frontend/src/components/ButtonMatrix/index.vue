<template>
  <div class="button-matrix">
    <div class="matrix-toolbar">
      <span class="matrix-title">按钮可用性矩阵</span>
      <div class="legend">
        <span v-for="opt in BUTTON_AVAIL_OPTIONS" :key="opt.value" class="legend-item">
          <el-tag :type="availTagType(opt.value as ButtonAvailability)" size="small" effect="dark">
            {{ opt.label }}
          </el-tag>
        </span>
        <span class="legend-tip">点击单元格循环切换</span>
      </div>
    </div>

    <!-- 叠加角色权限预览开关（GAP-D03-006 / RISK-D03-004 / PRD 04.4.3 F2.1.3）-->
    <div v-if="roleButtons && roleButtons.length" class="role-preview-bar">
      <el-switch v-model="previewRole" size="small" />
      <span class="preview-label">叠加角色权限预览</span>
      <el-select v-if="previewRole" v-model="selectedRoleId" size="small" style="width: 180px; margin-left: 8px">
        <el-option v-for="r in roleOptions" :key="r.role_id" :label="r.role_name" :value="r.role_id" />
      </el-select>
      <el-tag v-if="previewRole" size="small" type="warning" effect="plain" class="preview-tip">
        运行时实际档位 = 状态机允许 × 角色权限（取更严格者）
      </el-tag>
    </div>

    <el-table :data="innerButtons" border size="small" style="width: 100%">
      <el-table-column label="按钮" width="140" fixed prop="button_name">
        <template #default="{ row }">
          <div class="btn-cell">
            <el-icon v-if="row.icon"><component :is="row.icon" /></el-icon>
            <span>{{ row.button_name }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="编码" width="100" prop="button_code" />
      <el-table-column
        v-for="state in PACT_STATE_LIST"
        :key="state.value"
        :label="state.label"
        align="center"
        min-width="90"
      >
        <template #header>
          <div class="state-header">
            <el-tag :type="state.type" size="small" effect="plain">{{ state.label }}</el-tag>
            <span class="state-code">{{ state.value }}</span>
          </div>
        </template>
        <template #default="{ row, $index }">
          <div
            class="avail-cell"
            :class="`avail-${effectiveAvail(row as ButtonDef, state.value)}`"
            @click="onCellClick(row as ButtonDef, state.value, $index)"
          >
            <el-tag
              :type="availTagType(effectiveAvail(row as ButtonDef, state.value))"
              size="small"
              :effect="effectiveAvail(row as ButtonDef, state.value) === 'hidden' ? 'plain' : 'dark'"
            >
              {{ availLabel(effectiveAvail(row as ButtonDef, state.value)) }}
            </el-tag>
            <div v-if="previewRole && hasRoleDiff(row as ButtonDef, state.value)" class="diff-hint">
              配置:{{ availLabel(row.availability[state.value]) }}
            </div>
          </div>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { PACT_STATE_LIST, BUTTON_AVAIL_OPTIONS } from '@/utils/enum'
import type { ButtonDef, ButtonAvailability, RoleButton } from '@/types/bo'

const props = withDefaults(
  defineProps<{
    buttons: ButtonDef[]
    readonly?: boolean
    // 角色按钮权限（GAP-D03-006 / RISK-D03-004 / PRD 04.4.3）：用于叠加预览运行时实际档位
    roleButtons?: RoleButton[]
  }>(),
  { readonly: false, roleButtons: () => [] }
)

const emit = defineEmits<{
  (e: 'change', buttons: ButtonDef[]): void
}>()

const innerButtons = ref<ButtonDef[]>([])
const previewRole = ref(false)
const selectedRoleId = ref('')

function syncFromProps() {
  // 深拷贝，确保 availability 数组独立
  innerButtons.value = (props.buttons || []).map(b => ({
    ...b,
    availability: [...(b.availability || ['disabled', 'disabled', 'disabled', 'disabled', 'disabled'])]
  }))
}

watch(() => props.buttons, syncFromProps, { immediate: true, deep: false })
watch(() => props.roleButtons, () => {
  // 默认选中第一个角色
  if (props.roleButtons.length && !selectedRoleId.value) {
    selectedRoleId.value = props.roleButtons[0].role_id
  }
}, { immediate: true })

// 角色选项（去重；优先使用后端补的 role_name，无则回退 role_id）
const roleOptions = computed(() => {
  const map = new Map<string, string>()
  props.roleButtons.forEach(rb => {
    const name = (rb as RoleButton & { role_name?: string }).role_name || rb.role_id
    if (!map.has(rb.role_id)) map.set(rb.role_id, name)
  })
  return Array.from(map.entries()).map(([role_id, role_name]) => ({ role_id, role_name }))
})

// 4 档循环顺序
const CYCLE: ButtonAvailability[] = ['enabled', 'disabled', 'hidden', 'readonly']

// 严格度排序：hidden > disabled > readonly > enabled（取更严格者，PRD F2.1.3 三维矩阵）
const STRICTNESS: Record<ButtonAvailability, number> = {
  enabled: 0,
  readonly: 1,
  disabled: 2,
  hidden: 3
}

function onCellClick(row: ButtonDef, stateCode: number, _index: number) {
  if (props.readonly) return
  const cur = row.availability[stateCode] || 'disabled'
  const idx = CYCLE.indexOf(cur)
  const next = CYCLE[(idx + 1) % CYCLE.length]
  row.availability[stateCode] = next
  emit('change', innerButtons.value)
}

// 取角色对当前按钮的 control_level（sys_role_button.control_level，GAP-D03-006 / RISK-D03-004）
function roleControlLevel(buttonCode: string): ButtonAvailability | null {
  if (!previewRole.value || !selectedRoleId.value || !props.roleButtons.length) return null
  const rb = props.roleButtons.find(r => r.role_id === selectedRoleId.value && r.button_code === buttonCode)
  return rb?.perm || null
}

// 运行时实际档位 = 状态机允许 × 角色权限（取更严格者）
function effectiveAvail(row: ButtonDef, stateCode: number): ButtonAvailability {
  const matrixAvail = row.availability[stateCode] || 'disabled'
  if (!previewRole.value) return matrixAvail
  const roleAvail = roleControlLevel(row.button_code)
  if (!roleAvail) return matrixAvail
  return STRICTNESS[roleAvail] > STRICTNESS[matrixAvail] ? roleAvail : matrixAvail
}

// 配置与运行时是否不一致（用于显示 diff 提示）
function hasRoleDiff(row: ButtonDef, stateCode: number): boolean {
  const matrixAvail = row.availability[stateCode] || 'disabled'
  return effectiveAvail(row, stateCode) !== matrixAvail
}

function availLabel(a: ButtonAvailability) {
  return BUTTON_AVAIL_OPTIONS.find(o => o.value === a)?.label || a
}

function availTagType(a: ButtonAvailability): 'success' | 'info' | 'danger' | 'warning' {
  switch (a) {
    case 'enabled':
      return 'success'
    case 'disabled':
      return 'info'
    case 'hidden':
      return 'danger'
    case 'readonly':
      return 'warning'
    default:
      return 'info'
  }
}
</script>

<style scoped lang="scss">
.button-matrix {
  background: #fff;
}
.matrix-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  flex-wrap: wrap;
  gap: 8px;
}
.matrix-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}
.legend {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.legend-item {
  display: inline-flex;
}
.legend-tip {
  color: #909399;
  font-size: 12px;
  margin-left: 4px;
}
.role-preview-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  padding: 6px 10px;
  background: #f0f7ff;
  border: 1px dashed #1564ff;
  border-radius: 4px;
  flex-wrap: wrap;
  .preview-label {
    font-size: 12px;
    color: #1564ff;
    font-weight: 600;
  }
  .preview-tip {
    margin-left: auto;
  }
}
.btn-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}
.state-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.state-code {
  color: #c0c4cc;
  font-size: 11px;
}
.avail-cell {
  cursor: pointer;
  padding: 4px;
  border-radius: 3px;
  transition: background 0.15s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.avail-cell:hover {
  background: #f0f7ff;
}
.avail-enabled {
  background: rgba(82, 196, 26, 0.06);
}
.avail-disabled {
  background: rgba(144, 147, 153, 0.06);
}
.avail-hidden {
  background: rgba(245, 34, 45, 0.06);
  opacity: 0.65;
}
.avail-readonly {
  background: rgba(250, 173, 20, 0.06);
}
.diff-hint {
  font-size: 10px;
  color: #e6a23c;
  line-height: 1;
}
</style>
