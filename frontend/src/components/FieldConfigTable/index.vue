<template>
  <div class="field-config-table">
    <div class="table-toolbar">
      <el-button type="primary" size="small" @click="onAddField" :disabled="readonly">
        <el-icon><Plus /></el-icon>新增字段
      </el-button>
      <el-button type="success" size="small" @click="onSave" :disabled="readonly">
        <el-icon><Check /></el-icon>保存
      </el-button>
      <div class="toolbar-tip">
        <el-icon><InfoFilled /></el-icon>
        <span>拖拽行首图标可调整字段顺序，字段类型变更将自动联动控件类型</span>
      </div>
    </div>

    <el-table
      ref="tableRef"
      :data="innerFields"
      border
      size="small"
      row-key="id"
      style="width: 100%"
      :max-height="maxHeight"
    >
      <el-table-column width="40" align="center">
        <template #default>
          <el-icon class="drag-handle"><Rank /></el-icon>
        </template>
      </el-table-column>
      <el-table-column type="index" label="#" width="50" align="center" />
      <el-table-column label="字段编码" width="160" prop="field_code">
        <template #default="{ row }">
          <el-input
            v-model="row.field_code"
            size="small"
            :disabled="readonly || row.is_system"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="字段名称" width="140" prop="field_name">
        <template #default="{ row }">
          <el-input
            v-model="row.field_name"
            size="small"
            :disabled="readonly"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="字段类型" width="120" prop="field_type">
        <template #default="{ row }">
          <el-select
            v-model="row.field_type"
            size="small"
            :disabled="readonly"
            @change="(v: any) => onFieldTypeChange(row as FormField, v)"
            style="width: 100%"
          >
            <el-option
              v-for="opt in FIELD_TYPE_OPTIONS"
              :key="opt.value"
              :label="opt.label"
              :value="opt.value"
            />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="控件类型" width="120" prop="ctrl_type">
        <template #default="{ row }">
          <el-tag size="small" effect="plain" type="info">
            {{ controlLabel(row.ctrl_type) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="长度" width="90" prop="data_length">
        <template #default="{ row }">
          <el-input-number
            v-model="row.data_length"
            size="small"
            :min="0"
            :disabled="readonly || !supportsLength(row.field_type)"
            controls-position="right"
            style="width: 100%"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="必填" width="60" align="center" prop="is_required">
        <template #default="{ row }">
          <el-checkbox
            v-model="row.is_required"
            :disabled="readonly || row.is_system"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="隐藏" width="60" align="center" prop="is_hidden">
        <template #default="{ row }">
          <el-checkbox
            v-model="row.is_hidden"
            :disabled="readonly"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="默认值" width="120" prop="default_value">
        <template #default="{ row }">
          <el-input
            v-model="row.default_value"
            size="small"
            :disabled="readonly"
            placeholder="—"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="分组" width="100" prop="group_name">
        <template #default="{ row }">
          <el-input
            v-model="row.group_name"
            size="small"
            :disabled="readonly"
            placeholder="—"
            @change="onChange"
          />
        </template>
      </el-table-column>
      <el-table-column label="操作" width="80" align="center" fixed="right">
        <template #default="{ row, $index }">
          <el-button
            type="danger"
            link
            size="small"
            :disabled="readonly || row.is_system"
            @click="onDeleteField(row as FormField, $index)"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useDraggable } from 'vue-draggable-plus'
import {
  FIELD_TYPE_OPTIONS,
  CONTROL_TYPE_OPTIONS,
  FIELD_TYPE_CONTROL_MAP
} from '@/utils/enum'
import type { FormField, FieldType } from '@/types/bo'

const props = withDefaults(
  defineProps<{
    fields: FormField[]
    entityCode?: string
    readonly?: boolean
    maxHeight?: number | string
  }>(),
  { entityCode: '', readonly: false, maxHeight: 480 }
)

const emit = defineEmits<{
  (e: 'save', fields: FormField[]): void
  (e: 'change', fields: FormField[]): void
}>()

const tableRef = ref()
const innerFields = ref<FormField[]>([])

function syncFromProps() {
  innerFields.value = (props.fields || []).map(f => ({ ...f }))
}

watch(() => props.fields, syncFromProps, { immediate: true, deep: false })

function onChange() {
  emit('change', innerFields.value)
}

function controlLabel(ct: string) {
  return CONTROL_TYPE_OPTIONS.find(o => o.value === ct)?.label || ct
}

function supportsLength(ft: FieldType) {
  return ['text'].includes(ft)
}

function onFieldTypeChange(row: FormField, val: FieldType) {
  const mapped = FIELD_TYPE_CONTROL_MAP[val]
  if (mapped) row.ctrl_type = mapped as any
  if (!supportsLength(val)) row.data_length = undefined
  onChange()
}

function onAddField() {
  const idx = innerFields.value.length + 1
  const newField: FormField = {
    id: `f_new_${Date.now()}`,
    entity_code: props.entityCode,
    field_code: `field_${idx}`,
    field_name: `新字段${idx}`,
    field_type: 'text',
    ctrl_type: 'text',
    data_length: 100,
    is_required: false,
    is_system: false,
    is_hidden: false,
    sort_index: innerFields.value.length + 1
  }
  innerFields.value.push(newField)
  onChange()
}

function onDeleteField(row: FormField, index: number) {
  if (row.is_system) {
    ElMessage.warning('系统字段不可删除')
    return
  }
  ElMessageBox.confirm(`确定删除字段「${row.field_name}」吗？`, '提示', { type: 'warning' })
    .then(() => {
      innerFields.value.splice(index, 1)
      onChange()
      ElMessage.success('删除成功')
    })
    .catch(() => {})
}

function onSave() {
  innerFields.value.forEach((f, i) => (f.sort_index = i + 1))
  emit('save', innerFields.value)
  ElMessage.success('保存成功')
}

onMounted(() => {
  // 在 el-table 渲染后挂载拖拽到 tbody
  nextTick(() => {
    const tbody = document.querySelector(
      '.field-config-table .el-table__body-wrapper tbody'
    ) as HTMLElement | null
    if (!tbody) return
    try {
      useDraggable(tbody, innerFields, {
        animation: 150,
        handle: '.drag-handle',
        onEnd: () => onChange()
      })
    } catch (e) {
      // 拖拽初始化失败不影响表格基础功能
      console.warn('[FieldConfigTable] 拖拽初始化失败', e)
    }
  })
})
</script>

<style scoped lang="scss">
.field-config-table {
  background: #fff;
}
.table-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.toolbar-tip {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: auto;
  color: #909399;
  font-size: 12px;
}
.drag-handle {
  cursor: move;
  color: #c0c4cc;
}
.drag-handle:hover {
  color: #1564ff;
}
:deep(.el-table) {
  .el-input,
  .el-input-number,
  .el-select {
    width: 100%;
  }
}
</style>
