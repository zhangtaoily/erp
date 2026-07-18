<template>
  <el-select
    :model-value="modelValue"
    :disabled="disabled"
    filterable
    clearable
    placeholder="请选择业务对象"
    :loading="loading"
    @visible-change="onVisibleChange"
    @change="onChange"
    @clear="onClear"
    style="width: 100%"
  >
    <el-option
      v-for="bo in list"
      :key="bo.bo_code"
      :label="`${bo.bo_name} (${bo.bo_code})`"
      :value="bo.bo_code"
    >
      <div class="bo-option">
        <span class="bo-name">{{ bo.bo_name }}</span>
        <el-tag size="small" :type="boTypeTag(bo.bo_type)" effect="plain" class="bo-type-tag">
          {{ boTypeLabel(bo.bo_type) }}
        </el-tag>
        <span class="bo-code">{{ bo.bo_code }}</span>
      </div>
    </el-option>
  </el-select>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { boApi } from '@/api/bo'
import { BO_TYPE_OPTIONS } from '@/utils/enum'
import type { BusinessObject, BoType } from '@/types/bo'

const props = withDefaults(
  defineProps<{
    modelValue?: string
    boType?: BoType
    disabled?: boolean
  }>(),
  { modelValue: '', disabled: false }
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'change', bo: BusinessObject | null): void
}>()

const list = ref<BusinessObject[]>([])
const loading = ref(false)
const loaded = ref(false)

async function loadList() {
  loading.value = true
  try {
    const res: any = await boApi.list({ bo_type: props.boType, pageSize: 200 })
    list.value = res?.list || res || []
    loaded.value = true
  } catch (e) {
    list.value = []
  } finally {
    loading.value = false
  }
}

function onVisibleChange(visible: boolean) {
  if (visible && !loaded.value) loadList()
}

function onChange(val: string) {
  emit('update:modelValue', val || '')
  const bo = val ? list.value.find(b => b.bo_code === val) || null : null
  emit('change', bo)
}

function onClear() {
  emit('update:modelValue', '')
  emit('change', null)
}

function boTypeLabel(t: BoType) {
  return BO_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}

function boTypeTag(t: BoType): 'primary' | 'success' | 'warning' | 'info' {
  if (t === 'bill') return 'primary'
  if (t === 'master') return 'success'
  return 'warning'
}

watch(() => props.boType, () => {
  loaded.value = false
  loadList()
})

onMounted(loadList)
</script>

<style scoped lang="scss">
.bo-option {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}
.bo-name {
  flex: 1;
}
.bo-type-tag {
  flex-shrink: 0;
}
.bo-code {
  color: #909399;
  font-size: 12px;
  flex-shrink: 0;
}
</style>
