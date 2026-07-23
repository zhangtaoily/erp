<template>
  <!-- ============ 控件映射（PRD 01.3.5 控件类型映射表，GAP-D02-001 / RISK-D02-001）============ -->
  <!-- text/textarea → el-input -->
  <el-input
    v-if="field.ctrl_type === 'text'"
    :model-value="modelValue"
    :placeholder="field.placeholder || `请输入${field.field_name}`"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: string) => emit('update:modelValue', v)"
  />
  <el-input
    v-else-if="field.ctrl_type === 'textarea'"
    :model-value="modelValue"
    type="textarea"
    :placeholder="field.placeholder || `请输入${field.field_name}`"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: string) => emit('update:modelValue', v)"
  />

  <!-- number → el-input-number -->
  <el-input-number
    v-else-if="field.ctrl_type === 'number'"
    :model-value="modelValue"
    :disabled="isDisabled"
    :precision="field.data_precision"
    :size="size"
    controls-position="right"
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  />

  <!-- date → el-date-picker -->
  <el-date-picker
    v-else-if="field.ctrl_type === 'date'"
    :model-value="modelValue"
    type="date"
    value-format="YYYY-MM-DD"
    :placeholder="field.placeholder || '选择日期'"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  />

  <!-- datetime → el-date-picker type=datetime -->
  <el-date-picker
    v-else-if="field.ctrl_type === 'datetime'"
    :model-value="modelValue"
    type="datetime"
    value-format="YYYY-MM-DD HH:mm:ss"
    :placeholder="field.placeholder || '选择日期时间'"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  />

  <!-- select → el-select（枚举下拉）-->
  <el-select
    v-else-if="field.ctrl_type === 'select'"
    :model-value="modelValue"
    :placeholder="field.placeholder || '请选择'"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  >
    <el-option v-for="opt in getEnumOptions(field)" :key="opt.value" :label="opt.label" :value="opt.value" />
  </el-select>

  <!-- ref → el-select 下拉（基础资料引用，GAP-D02-001）；禁用时由 isDisabled 控制统一禁用样式 -->
  <el-select
    v-else-if="field.ctrl_type === 'ref'"
    :model-value="modelValue"
    :placeholder="field.placeholder || `请选择${field.field_name}`"
    :disabled="isDisabled"
    :size="size"
    filterable
    clearable
    :loading="refLoading"
    @visible-change="onRefVisibleChange"
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  >
    <el-option
      v-for="opt in refOptions"
      :key="opt.value"
      :label="opt.label"
      :value="opt.value"
    />
  </el-select>

  <!-- amount → el-input-number + 币别后缀（GAP-D02-001）-->
  <div v-else-if="field.ctrl_type === 'amount'" class="amount-control">
    <el-input-number
      :model-value="modelValue"
      :disabled="isDisabled"
      :precision="field.data_scale ?? 2"
      :size="size"
      controls-position="right"
      @update:model-value="(v: any) => emit('update:modelValue', v)"
    />
    <span class="currency-suffix">{{ currencySymbol }}</span>
  </div>

  <!-- qty → el-input-number + 单位后缀（GAP-D02-001）-->
  <div v-else-if="field.ctrl_type === 'qty'" class="qty-control">
    <el-input-number
      :model-value="modelValue"
      :disabled="isDisabled"
      :precision="field.data_scale ?? 4"
      :size="size"
      controls-position="right"
      @update:model-value="(v: any) => emit('update:modelValue', v)"
    />
    <span class="unit-suffix">{{ unitText }}</span>
  </div>

  <!-- checkbox → el-checkbox -->
  <el-checkbox
    v-else-if="field.ctrl_type === 'checkbox'"
    :model-value="!!modelValue"
    :disabled="isDisabled"
    :size="size"
    @update:model-value="(v: any) => emit('update:modelValue', v)"
  />

  <!-- attachment → AttachmentUpload 组件（GAP-D02-001，简化为上传按钮 + 文件计数）-->
  <div v-else-if="field.ctrl_type === 'attachment'" class="attachment-control">
    <el-upload
      :show-file-list="false"
      :auto-upload="true"
      :http-request="(opts: any) => mockUpload(opts, field)"
      multiple
    >
      <el-button :size="size" :disabled="isDisabled" type="primary" plain>
        <el-icon><Upload /></el-icon>上传附件
      </el-button>
    </el-upload>
    <span v-if="attachmentList.length" class="att-count">{{ attachmentList.length }} 个文件</span>
  </div>

  <!-- 兜底：el-input -->
  <el-input
    v-else
    :model-value="modelValue"
    :placeholder="field.placeholder || `请输入${field.field_name}`"
    :disabled="isDisabled"
    :size="size"
    clearable
    @update:model-value="(v: string) => emit('update:modelValue', v)"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch, onBeforeUnmount } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload } from '@element-plus/icons-vue'
import { PACT_STATE_LIST } from '@/utils/enum'
import { billApi } from '@/api/bill'
import type { FormField } from '@/types/bo'

const props = withDefaults(defineProps<{
  field: FormField
  modelValue: any
  disabled?: boolean
  size?: 'small' | 'default' | 'large'
  // 可选：从外层 form 传入币别 / 单位值（用于 amount/qty 后缀联动）
  currency?: string
  unit?: string
}>(), {
  disabled: false,
  size: 'default',
  currency: '',
  unit: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: any]
}>()

// 合并外部 disabled 与字段元数据 is_readonly
const isDisabled = computed(() => props.disabled || !!props.field.is_readonly)

// ============ 枚举选项（select 控件）============
function getEnumOptions(field: FormField) {
  // 单据状态枚举：enum_code='PACT_STATE' 或 field_code='pact_state'（元数据可能未设 enum_code）
  if (field.enum_code === 'PACT_STATE' || field.field_code === 'pact_state') {
    return PACT_STATE_LIST
  }
  // 简化：未识别的枚举返回示例选项
  return [
    { value: 'kg', label: '公斤' },
    { value: '筒', label: '筒' },
    { value: '箱', label: '箱' }
  ]
}

// ============ 基础资料引用下拉（ref 控件）共享缓存 ============
// 同一个 ref_bo_code 在一个页面内可能被多个 FieldControl 使用（如多个 ref 字段），
// 用全局缓存避免重复请求；同时记录 in-flight Promise 防止并发重复请求。
interface RefCacheEntry {
  options: { value: string | number; label: string }[]
  loaded: boolean
}
const refCache = new Map<string, RefCacheEntry>()
const refLoadingMap = new Map<string, Promise<void>>()

async function loadRefBoOptions(refBoCode: string): Promise<RefCacheEntry> {
  const cached = refCache.get(refBoCode)
  if (cached?.loaded) return cached
  if (refLoadingMap.has(refBoCode)) {
    await refLoadingMap.get(refBoCode)
    return refCache.get(refBoCode)!
  }
  const promise = (async () => {
    try {
      const res: any = await billApi.list(refBoCode, { pageSize: 200 })
      const list: any[] = res?.list || res || []
      const options = list.map(r => ({
        value: r.id,      // 保持原始类型，与 modelValue 一致
        label: r.name || r.code || `#${r.id}`
      }))
      refCache.set(refBoCode, { options, loaded: true })
    } catch {
      refCache.set(refBoCode, { options: [], loaded: true })
    } finally {
      refLoadingMap.delete(refBoCode)
    }
  })()
  refLoadingMap.set(refBoCode, promise)
  await promise
  return refCache.get(refBoCode)!
}

// 当前字段的本地视图（从共享缓存读取）
const refOptions = ref<{ value: string | number; label: string }[]>([])
const refLoading = ref(false)
let cancelled = false

async function loadRefOptions() {
  if (!props.field.ref_bo_code) {
    refOptions.value = []
    return
  }
  refLoading.value = true
  try {
    const entry = await loadRefBoOptions(props.field.ref_bo_code)
    if (cancelled) return
    refOptions.value = entry.options
  } finally {
    if (!cancelled) refLoading.value = false
  }
}

function onRefVisibleChange(visible: boolean) {
  if (visible && !refOptions.value.length) loadRefOptions()
}

// ref_bo_code 变更时（含首次）加载选项，比 onMounted 更早触发
watch(() => props.field.ref_bo_code, () => {
  refOptions.value = []
  loadRefOptions()
}, { immediate: true })

// 组件卸载时标记取消，避免卸载后还写入 ref（防止内存泄漏）
onBeforeUnmount(() => {
  cancelled = true
})

// ============ amount 币别后缀（GAP-D02-001）============
const currencySymbol = computed(() => {
  const c = props.currency || props.field.default_value || ''
  // 简化币别映射
  const map: Record<string, string> = {
    CNY: '¥', USD: '$', EUR: '€', GBP: '£', JPY: '¥'
  }
  return map[c] || (c ? c + ' ' : '¥')
})

// ============ qty 单位后缀（GAP-D02-001）============
const unitText = computed(() => {
  return props.unit || ''
})

// ============ attachment 上传（简化 mock，GAP-D02-001）============
const attachmentList = ref<{ name: string; size: number }[]>([])

async function mockUpload(options: any, _field: FormField) {
  // 简化：原型阶段直接 push 文件信息，不调真实 API
  attachmentList.value.push({
    name: options.file?.name || 'file',
    size: options.file?.size || 0
  })
  ElMessage.success(`${options.file?.name || '文件'} 上传成功`)
}
</script>

<style scoped lang="scss">
.attachment-control {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  .att-count {
    color: #1564ff;
    font-size: 12px;
  }
}
.amount-control, .qty-control {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  width: 100%;
}
.currency-suffix, .unit-suffix {
  color: #909399;
  font-size: 12px;
  white-space: nowrap;
}
</style>
