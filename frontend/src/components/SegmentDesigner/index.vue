<template>
  <div class="segment-designer">
    <!-- 段类型选择 -->
    <div class="seg-toolbar">
      <span class="toolbar-label">添加段：</span>
      <el-button
        v-for="opt in SEGMENT_TYPE_OPTIONS"
        :key="opt.value"
        size="small"
        :type="segBtnType(opt.value)"
        plain
        @click="onAddSegment(opt.value as SegmentType)"
      >
        <el-icon><component :is="segIcon(opt.value)" /></el-icon>
        {{ opt.label }}
      </el-button>
      <div class="toolbar-tip">
        <el-icon><InfoFilled /></el-icon>
        <span>拖拽段卡片可调整顺序</span>
      </div>
    </div>

    <!-- 段列表 -->
    <div class="seg-list-wrap">
      <VueDraggable
        v-model="innerSegments"
        :animation="150"
        handle=".seg-drag-handle"
        class="seg-list"
        :class="{ empty: innerSegments.length === 0 }"
        @end="onSortEnd"
      >
        <div v-for="(seg, idx) in innerSegments" :key="seg.id" class="seg-card">
          <div class="seg-drag-handle" title="拖拽排序">
            <el-icon><Rank /></el-icon>
          </div>
          <div class="seg-index">{{ idx + 1 }}</div>
          <div class="seg-type">
            <el-tag :type="segTagType(seg.type)" size="small" effect="dark">
              <el-icon style="vertical-align: middle"><component :is="segIcon(seg.type)" /></el-icon>
              {{ segTypeLabel(seg.type) }}
            </el-tag>
          </div>
          <div class="seg-props">
            <!-- prefix / fixed：文本值 -->
            <template v-if="seg.type === 'prefix' || seg.type === 'fixed'">
              <el-input
                v-model="seg.value"
                size="small"
                placeholder="段值"
                style="width: 120px"
                @input="onSegChange"
              />
            </template>
            <!-- date：日期格式 -->
            <template v-else-if="seg.type === 'date'">
              <el-select
                v-model="seg.format"
                size="small"
                style="width: 130px"
                @change="onSegChange"
              >
                <el-option label="yyyyMMdd" value="yyyyMMdd" />
                <el-option label="yyyyMM" value="yyyyMM" />
                <el-option label="yyyy" value="yyyy" />
              </el-select>
            </template>
            <!-- serial：流水位数 -->
            <template v-else-if="seg.type === 'serial'">
              <el-input-number
                v-model="seg.digits"
                size="small"
                :min="1"
                :max="10"
                controls-position="right"
                style="width: 110px"
                @change="onSegChange"
              />
              <span class="prop-hint">位</span>
            </template>
            <!-- variable：变量编码 -->
            <template v-else-if="seg.type === 'variable'">
              <el-input
                v-model="seg.var_code"
                size="small"
                placeholder="变量编码"
                style="width: 140px"
                @input="onSegChange"
              />
            </template>
          </div>
          <div class="seg-preview">{{ renderSegment(seg) || '—' }}</div>
          <div class="seg-actions">
            <el-button type="danger" link size="small" @click="onDeleteSegment(idx)">
              <el-icon><Delete /></el-icon>
            </el-button>
          </div>
        </div>
      </VueDraggable>
      <el-empty
        v-if="innerSegments.length === 0"
        description="点击上方按钮添加段定义"
        :image-size="50"
      />
    </div>

    <!-- 实时预览 -->
    <div class="seg-preview-bar">
      <div class="preview-label">
        <el-icon><View /></el-icon>
        <span>生成编号预览：</span>
      </div>
      <div class="preview-code">{{ previewCode || '（请添加段定义）' }}</div>
      <el-button link type="primary" size="small" @click="copyPreview" :disabled="!previewCode">
        <el-icon><CopyDocument /></el-icon>复制
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { VueDraggable } from 'vue-draggable-plus'
import { SEGMENT_TYPE_OPTIONS } from '@/utils/enum'
import type { CodeSegment, SegmentType } from '@/types/bo'
import dayjs from 'dayjs'

export interface PreviewContext {
  prefix?: string
  date?: string // ISO 日期字符串
  serial?: number // 当前流水号
  variables?: Record<string, string>
}

const props = withDefaults(
  defineProps<{
    modelValue?: CodeSegment[]
    previewContext?: PreviewContext
  }>(),
  { modelValue: () => [], previewContext: () => ({}) }
)

const emit = defineEmits<{
  (e: 'update:modelValue', segments: CodeSegment[]): void
  (e: 'preview', code: string): void
}>()

const innerSegments = ref<CodeSegment[]>([])

function syncFromProps() {
  innerSegments.value = (props.modelValue || []).map(s => ({ ...s }))
}

watch(() => props.modelValue, syncFromProps, { immediate: true, deep: false })

function segTypeLabel(t: SegmentType) {
  return SEGMENT_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}

function segTagType(t: SegmentType): 'primary' | 'success' | 'warning' | 'info' | 'danger' {
  const map: Record<string, 'primary' | 'success' | 'warning' | 'info' | 'danger'> = {
    prefix: 'primary',
    date: 'success',
    serial: 'warning',
    fixed: 'info',
    variable: 'danger'
  }
  return map[t] || 'info'
}

function segBtnType(t: string): 'primary' | 'success' | 'warning' | 'info' | 'danger' {
  return segTagType(t as SegmentType)
}

function segIcon(t: string) {
  const map: Record<string, string> = {
    prefix: 'Flag',
    date: 'Calendar',
    serial: 'List',
    fixed: 'Lock',
    variable: 'EditPen'
  }
  return map[t] || 'Document'
}

function onAddSegment(type: SegmentType) {
  const seg: CodeSegment = {
    id: `seg_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    rule_id: '',
    type: type,
    value: type === 'prefix' ? 'PO' : type === 'fixed' ? 'FX' : undefined,
    format: type === 'date' ? 'yyyyMMdd' : undefined,
    digits: type === 'serial' ? 4 : undefined,
    var_code: type === 'variable' ? 'var1' : undefined,
    sort: innerSegments.value.length + 1
  }
  innerSegments.value.push(seg)
  onSegChange()
}

function onDeleteSegment(idx: number) {
  innerSegments.value.splice(idx, 1)
  onSegChange()
}

function onSortEnd() {
  innerSegments.value.forEach((s, i) => (s.sort = i + 1))
  onSegChange()
}

function onSegChange() {
  emit('update:modelValue', innerSegments.value)
  emit('preview', previewCode.value)
}

// 渲染单个段
function renderSegment(seg: CodeSegment): string {
  const ctx = props.previewContext || {}
  switch (seg.type) {
    case 'prefix':
    case 'fixed':
      return seg.value || ''
    case 'date': {
      const fmt = seg.format || 'yyyyMMdd'
      const dateStr = ctx.date || new Date().toISOString()
      const d = dayjs(dateStr)
      // 转换 Java 风格格式为 dayjs 格式
      const dayjsFmt = fmt
        .replace('yyyy', 'YYYY')
        .replace('MM', 'MM')
        .replace('dd', 'DD')
      return d.format(dayjsFmt)
    }
    case 'serial': {
      const digits = seg.digits || 4
      const num = ctx.serial ?? 1
      return String(num).padStart(digits, '0')
    }
    case 'variable': {
      const code = seg.var_code || ''
      return ctx.variables?.[code] ?? `\${${code}}`
    }
    default:
      return ''
  }
}

const previewCode = computed(() =>
  innerSegments.value.map(s => renderSegment(s)).join('')
)

function copyPreview() {
  if (!previewCode.value) return
  navigator.clipboard
    .writeText(previewCode.value)
    .then(() => ElMessage.success('已复制：' + previewCode.value))
    .catch(() => ElMessage.warning('复制失败，请手动选择'))
}
</script>

<style scoped lang="scss">
.segment-designer {
  background: #fff;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
}
.seg-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  flex-wrap: wrap;
}
.toolbar-label {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}
.toolbar-tip {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: auto;
  color: #909399;
  font-size: 12px;
}
.seg-list-wrap {
  padding: 8px;
  min-height: 120px;
  flex: 1;
}
.seg-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.seg-list.empty {
  display: none;
}
.seg-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  background: #fff;
  transition: box-shadow 0.15s, border-color 0.15s;
}
.seg-card:hover {
  border-color: #1564ff;
  box-shadow: 0 1px 4px rgba(21, 100, 255, 0.12);
}
.seg-drag-handle {
  cursor: move;
  color: #c0c4cc;
  padding: 2px;
  display: flex;
  align-items: center;
}
.seg-drag-handle:hover {
  color: #1564ff;
}
.seg-index {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: #1564ff;
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.seg-type {
  flex-shrink: 0;
  width: 80px;
}
.seg-props {
  display: flex;
  align-items: center;
  gap: 6px;
}
.prop-hint {
  font-size: 12px;
  color: #909399;
}
.seg-preview {
  flex: 1;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 13px;
  color: #1564ff;
  background: #f0f7ff;
  padding: 4px 8px;
  border-radius: 3px;
  min-width: 80px;
  text-align: center;
}
.seg-actions {
  flex-shrink: 0;
}
.seg-preview-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-top: 1px solid #e4e7ed;
  background: linear-gradient(90deg, #f0f7ff 0%, #fff 100%);
}
.preview-label {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  flex-shrink: 0;
}
.preview-code {
  flex: 1;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 16px;
  font-weight: 700;
  color: #1564ff;
  letter-spacing: 1px;
}
</style>
