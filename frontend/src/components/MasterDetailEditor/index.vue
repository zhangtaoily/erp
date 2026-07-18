<template>
  <div class="master-detail-editor" :class="`layout-${layout}`">
    <!-- ============ 堆叠布局：主表 / 子表 / 孙表 三段式（参考 sal-int-cont/form.vue）============ -->
    <template v-if="layout === 'stacked'">
      <!-- ① 主表（分组 tab 表单）-->
      <div class="stack-section main-section">
        <el-tabs type="border-card" class="master-tabs">
          <el-tab-pane
            v-for="group in mainGroups"
            :key="group"
            :label="group"
          >
            <el-form :model="formData" label-width="100px" :disabled="mode === 'view'" class="main-form">
              <el-row :gutter="16">
                <el-col
                  v-for="field in mainFieldsByGroup(group)"
                  :key="field.field_code"
                  :span="8"
                >
                  <el-form-item
                    :label="field.field_name"
                    :required="field.is_required"
                    v-if="!field.is_hidden || field.field_code === 'pact_state'"
                  >
                    <FieldControl
                      :field="field"
                      :model-value="formData[field.field_code]"
                      :disabled="field.is_system && mode === 'edit'"
                      @update:model-value="(v: any) => (formData[field.field_code] = v)"
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </el-tab-pane>
        </el-tabs>
      </div>

      <!-- ② 子表（页签表格）-->
      <div v-if="subEntities.length" class="stack-section sub-section">
        <el-tabs v-model="activeSubTab" type="border-card" class="sub-tabs">
          <el-tab-pane
            v-for="sub in subEntities"
            :key="sub.entity_code"
            :label="sub.entity_name"
            :name="sub.entity_code"
          >
            <div class="sub-toolbar">
              <el-button type="primary" size="small" @click="addSubRow(sub)" :disabled="mode === 'view'">
                <el-icon><Plus /></el-icon>新增行
              </el-button>
              <el-button size="small" @click="copySubRow(sub)" :disabled="mode === 'view' || !currentSubRow(sub)">复制行</el-button>
              <el-button size="small" @click="batchFill(sub)" :disabled="mode === 'view'">批量填充</el-button>
              <span class="sub-summary" v-for="s in getSubSummaries(sub)" :key="s.field_code">
                {{ s.field_name }}合计：{{ s.value }}
              </span>
            </div>
            <el-table
              :data="getSubData(sub.entity_code)"
              border
              size="small"
              highlight-current-row
              :row-class-name="rowClassName"
              height="260"
              @current-change="(row: any) => selectSubRow(sub, row)"
            >
              <el-table-column type="index" label="#" width="50" />
              <el-table-column
                v-for="f in sub.fields.filter((x: any) => !x.is_hidden)"
                :key="f.field_code"
                :prop="f.field_code"
                :label="f.field_name"
                :width="getColumnWidth(f)"
              >
                <template #default="{ row }">
                  <FieldControl
                    :field="f"
                    :model-value="row[f.field_code]"
                    :disabled="mode === 'view' || f.is_system"
                    size="small"
                    @update:model-value="(v: any) => { row[f.field_code] = v; onSubRowChange(sub, row, f) }"
                  />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="80" fixed="right" v-if="mode !== 'view'">
                <template #default="{ $index }">
                  <el-button text type="danger" size="small" @click.stop="deleteSubRow(sub, $index)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>
        </el-tabs>
      </div>

      <!-- ③ 孙表（页签表格，跟随子表选中行）-->
      <div v-if="currentGrandchildEntities.length" class="stack-section gc-section">
        <el-tabs v-model="activeGcTab" type="border-card" class="gc-tabs">
          <el-tab-pane
            v-for="gc in currentGrandchildEntities"
            :key="gc.entity_code"
            :label="gc.entity_name"
            :name="gc.entity_code"
          >
            <div class="gc-toolbar">
              <span class="gc-context">
                <el-icon><InfoFilled /></el-icon>
                <template v-if="currentSubRow(activeSubEntity)">
                  当前子表行：第 {{ getSelectedSubRowIndex(activeSubEntity) + 1 }} 行
                </template>
                <template v-else>
                  请在上方子表中选择一行后再维护{{ gc.entity_name }}
                </template>
              </span>
              <el-button
                type="primary"
                size="small"
                :disabled="mode === 'view' || !currentSubRow(activeSubEntity)"
                @click="addGrandchildRow(gc, currentSubRow(activeSubEntity))"
              >
                <el-icon><Plus /></el-icon>新增
              </el-button>
            </div>
            <el-table
              :data="getGrandchildData(gc, currentSubRow(activeSubEntity))"
              border
              size="small"
              height="200"
            >
              <el-table-column type="index" label="#" width="50" />
              <el-table-column
                v-for="f in gc.fields.filter((x: any) => !x.is_hidden)"
                :key="f.field_code"
                :prop="f.field_code"
                :label="f.field_name"
                :width="getColumnWidth(f)"
              >
                <template #default="{ row }">
                  <FieldControl
                    :field="f"
                    :model-value="row[f.field_code]"
                    :disabled="mode === 'view' || f.is_system"
                    size="small"
                    @update:model-value="(v: any) => (row[f.field_code] = v)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="80" fixed="right" v-if="mode !== 'view'">
                <template #default="{ $index }">
                  <el-button text type="danger" size="small" @click="deleteGrandchildRow(gc, currentSubRow(activeSubEntity)!, $index)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>
        </el-tabs>
      </div>
    </template>

    <!-- ============ 展开布局（孙表嵌在子表行内展开，用于表单设计器预览）============ -->
    <template v-else>
      <!-- 主表头 -->
      <div class="main-section">
        <div class="section-title">
          <el-icon><Document /></el-icon>
          <span>{{ mainEntity?.entity_name || '单据头' }}</span>
        </div>
        <el-form :model="formData" label-width="100px" :disabled="mode === 'view'" class="main-form">
          <el-row v-for="group in mainGroups" :key="group" :gutter="16">
            <div class="group-label">{{ group }}</div>
            <el-col v-for="field in mainFieldsByGroup(group)" :key="field.field_code" :span="8">
              <el-form-item
                :label="field.field_name"
                :required="field.is_required"
                v-if="!field.is_hidden || field.field_code === 'pact_state'"
              >
                <FieldControl
                  :field="field"
                  :model-value="formData[field.field_code]"
                  :disabled="field.is_system && mode === 'edit'"
                  @update:model-value="(v: any) => (formData[field.field_code] = v)"
                />
              </el-form-item>
            </el-col>
          </el-row>
        </el-form>
      </div>

      <!-- 子表页签（孙表作为展开行）-->
      <el-tabs v-if="subEntities.length" v-model="activeTab" class="sub-tabs" type="border-card">
        <el-tab-pane
          v-for="sub in subEntities"
          :key="sub.entity_code"
          :label="sub.entity_name"
          :name="sub.entity_code"
        >
          <div class="sub-toolbar">
            <el-button type="primary" size="small" @click="addSubRow(sub)" :disabled="mode === 'view'">
              <el-icon><Plus /></el-icon>新增行
            </el-button>
            <el-button size="small" @click="copySubRow(sub)" :disabled="mode === 'view' || !currentSubRow(sub)">复制行</el-button>
            <el-button size="small" @click="batchFill(sub)" :disabled="mode === 'view'">批量填充</el-button>
            <span class="sub-summary" v-for="s in getSubSummaries(sub)" :key="s.field_code">
              {{ s.field_name }}合计：{{ s.value }}
            </span>
          </div>
          <el-table
            :data="getSubData(sub.entity_code)"
            border
            size="small"
            :row-class-name="rowClassName"
            @row-click="(row: any) => selectSubRow(sub, row)"
            @selection-change="(sel: any) => onSubSelection(sub, sel)"
          >
            <el-table-column type="expand" v-if="getGrandchildEntities(sub.entity_code).length">
              <template #default="{ row }">
                <div class="grandchild-section">
                  <div v-for="gc in getGrandchildEntities(sub.entity_code)" :key="gc.entity_code">
                    <div class="gc-title">{{ gc.entity_name }}</div>
                    <div class="gc-toolbar">
                      <el-button size="small" @click="addGrandchildRow(gc, row)" :disabled="mode === 'view'">新增</el-button>
                    </div>
                    <el-table :data="getGrandchildData(gc, row)" border size="small" class="gc-table">
                      <el-table-column v-for="f in gc.fields.filter((x: any) => !x.is_hidden)" :key="f.field_code" :prop="f.field_code" :label="f.field_name" :width="getColumnWidth(f)">
                        <template #default="{ row: gcRow }">
                          <FieldControl
                            :field="f"
                            :model-value="gcRow[f.field_code]"
                            :disabled="mode === 'view' || f.is_system"
                            size="small"
                            @update:model-value="(v: any) => (gcRow[f.field_code] = v)"
                          />
                        </template>
                      </el-table-column>
                      <el-table-column label="操作" width="80" v-if="mode !== 'view'">
                        <template #default="{ $index }">
                          <el-button text type="danger" size="small" @click.stop="deleteGrandchildRow(gc, row, $index)">删除</el-button>
                        </template>
                      </el-table-column>
                    </el-table>
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column type="index" label="#" width="50" />
            <el-table-column
              v-for="f in sub.fields.filter((x: any) => !x.is_hidden)"
              :key="f.field_code"
              :prop="f.field_code"
              :label="f.field_name"
              :width="getColumnWidth(f)"
            >
              <template #default="{ row }">
                <FieldControl
                  :field="f"
                  :model-value="row[f.field_code]"
                  :disabled="mode === 'view' || f.is_system"
                  size="small"
                  @update:model-value="(v: any) => { row[f.field_code] = v; onSubRowChange(sub, row, f) }"
                />
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80" fixed="right" v-if="mode !== 'view'">
              <template #default="{ $index }">
                <el-button text type="danger" size="small" @click.stop="deleteSubRow(sub, $index)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { FormEntity, FormField } from '@/types/bo'
import FieldControl from './FieldControl.vue'

const props = withDefaults(defineProps<{
  entities: FormEntity[]
  modelValue: any
  mode?: 'view' | 'edit' | 'add'
  layout?: 'expand' | 'stacked'
}>(), {
  mode: 'edit',
  layout: 'expand'
})

const emit = defineEmits<{
  'update:modelValue': [data: any]
}>()

const formData = computed({
  get: () => props.modelValue || {},
  set: (val) => emit('update:modelValue', val)
})

const mainEntity = computed(() => props.entities.find(e => e.entity_type === 'main'))
const subEntities = computed(() => props.entities.filter(e => e.entity_type === 'sub'))
const activeTab = ref(subEntities.value[0]?.entity_code || '')
const activeSubTab = ref(subEntities.value[0]?.entity_code || '')

// 主表分组
const mainGroups = computed(() => {
  const groups: string[] = []
  mainEntity.value?.fields.forEach(f => {
    if (f.group_name && !groups.includes(f.group_name)) groups.push(f.group_name)
  })
  return groups.length ? groups : ['基本信息']
})

function mainFieldsByGroup(group: string): FormField[] {
  return (mainEntity.value?.fields || []).filter(f => (f.group_name || '基本信息') === group)
}

// 子表数据
function getSubData(entityCode: string): any[] {
  if (!formData.value[entityCode]) formData.value[entityCode] = []
  return formData.value[entityCode]
}

// 孙表实体
function getGrandchildEntities(parentCode: string): FormEntity[] {
  return props.entities.filter(e => e.entity_type === 'grandchild' && e.parent_entity_code === parentCode)
}

// 当前激活的子表实体（堆叠布局用）
const activeSubEntity = computed(() =>
  subEntities.value.find(s => s.entity_code === activeSubTab.value) || subEntities.value[0] || null
)

// 当前子表下的孙表实体（堆叠布局用）
const currentGrandchildEntities = computed(() => {
  if (!activeSubEntity.value) return []
  return getGrandchildEntities(activeSubEntity.value.entity_code)
})

const activeGcTab = ref('')

// 孙表数据：取挂在子表行上的数组
function getGrandchildData(gc: FormEntity, parentRow: any): any[] {
  if (!parentRow) return []
  if (!parentRow[gc.entity_code]) parentRow[gc.entity_code] = []
  return parentRow[gc.entity_code]
}

// 控件列宽（仅用于表格列宽，控件本身由 FieldControl 渲染）
function getColumnWidth(field: FormField): number {
  const map: Record<string, number> = {
    text: 140, textarea: 180, number: 120, date: 150, datetime: 170,
    select: 110, ref: 160, amount: 150, qty: 140, checkbox: 60, attachment: 200
  }
  return map[field.ctrl_type] || 140
}

// 子表选中行（每子表一个）
const selectedRows = ref<Record<string, any>>({})

function selectSubRow(sub: FormEntity, row: any) {
  if (!row) return
  selectedRows.value[sub.entity_code] = row
}

function currentSubRow(sub: FormEntity | null) {
  if (!sub) return null
  return selectedRows.value[sub.entity_code] || null
}

function getSelectedSubRowIndex(sub: FormEntity | null): number {
  if (!sub) return -1
  const row = currentSubRow(sub)
  if (!row) return -1
  return getSubData(sub.entity_code).findIndex((r: any) => r === row)
}

function onSubSelection(sub: FormEntity, sel: any[]) {
  if (sel.length) selectedRows.value[sub.entity_code] = sel[sel.length - 1]
}

function addSubRow(sub: FormEntity) {
  const newRow: any = { id: '', _tempId: Date.now() }
  sub.fields.forEach(f => {
    newRow[f.field_code] = f.default_value || (f.ctrl_type === 'checkbox' ? false : f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty' ? 0 : '')
  })
  // 孙表初始化
  getGrandchildEntities(sub.entity_code).forEach(gc => {
    newRow[gc.entity_code] = []
  })
  getSubData(sub.entity_code).push(newRow)
  // 堆叠布局：自动选中新增行
  selectedRows.value[sub.entity_code] = newRow
}

function copySubRow(sub: FormEntity) {
  const row = currentSubRow(sub)
  if (!row) return
  const copy = { ...row, id: '', _tempId: Date.now() }
  // 深拷贝孙表
  getGrandchildEntities(sub.entity_code).forEach(gc => {
    copy[gc.entity_code] = (row[gc.entity_code] || []).map((r: any) => ({ ...r, id: '' }))
  })
  getSubData(sub.entity_code).push(copy)
  selectedRows.value[sub.entity_code] = copy
}

function deleteSubRow(sub: FormEntity, index: number) {
  const data = getSubData(sub.entity_code)
  const deleted = data[index]
  data.splice(index, 1)
  // 若删除的是当前选中行，清空选中
  if (selectedRows.value[sub.entity_code] === deleted) {
    selectedRows.value[sub.entity_code] = null
  }
  // 重新汇总（删除行影响汇总值）
  recalcSubSummary(sub)
}

function batchFill(sub: FormEntity) {
  // 简化：用第一行的值填充所有行
  const data = getSubData(sub.entity_code)
  if (data.length < 2) return
  const first = data[0]
  data.slice(1).forEach(row => {
    sub.fields.filter(f => !f.is_system && f.ctrl_type !== 'checkbox').forEach(f => {
      row[f.field_code] = first[f.field_code]
    })
  })
}

// 孙表操作
function addGrandchildRow(gc: FormEntity, parentRow: any) {
  if (!parentRow) return
  if (!parentRow[gc.entity_code]) parentRow[gc.entity_code] = []
  const newRow: any = { id: '', _tempId: Date.now() }
  gc.fields.forEach(f => {
    newRow[f.field_code] = f.default_value || (f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty' ? 0 : '')
  })
  parentRow[gc.entity_code].push(newRow)
}

function deleteGrandchildRow(gc: FormEntity, parentRow: any, index: number) {
  if (!parentRow || !parentRow[gc.entity_code]) return
  parentRow[gc.entity_code].splice(index, 1)
}

// ============ 汇总规则配置驱动（GAP-D02-002 / RISK-D02-002）============
// 读取 FormField.summary_to 配置动态计算：子表字段 summary_to 指向主表汇总字段
// 移除硬编码 qty/price/amount/total_amount 字段名
interface SubSummary {
  field_code: string
  field_name: string
  target_field: string  // 主表汇总字段
  value: number
}

function getSubSummaries(sub: FormEntity): SubSummary[] {
  const result: SubSummary[] = []
  sub.fields.forEach(f => {
    if (f.summary_to) {
      const sum = getSubData(sub.entity_code).reduce((s, row) => s + (Number(row[f.field_code]) || 0), 0)
      result.push({
        field_code: f.field_code,
        field_name: f.field_name,
        target_field: f.summary_to,
        value: Math.round(sum * 100) / 100
      })
    }
  })
  return result
}

// 重新汇总：子表任意字段变更后调用
function recalcSubSummary(sub: FormEntity) {
  const sums = getSubSummaries(sub)
  sums.forEach(s => {
    formData.value[s.target_field] = s.value
  })
}

// ============ 计算规则配置驱动（GAP-D02-003 / RISK-D02-002）============
// 读取 FormField.formula 配置动态执行：简化支持 field1*field2 模式
// 移除硬编码 qty*price=amount
function executeFormula(row: any, fields: FormField[]) {
  fields.forEach(f => {
    if (!f.formula) return
    // 简化公式引擎：仅支持 a*b 模式（包含乘法），按需可扩展
    const expr = f.formula.trim()
    const mulMatch = expr.match(/^(\w+)\s*\*\s*(\w+)$/)
    if (mulMatch) {
      const a = Number(row[mulMatch[1]]) || 0
      const b = Number(row[mulMatch[2]]) || 0
      row[f.field_code] = Math.round(a * b * 100) / 100
      return
    }
    // 加法 a+b
    const addMatch = expr.match(/^(\w+)\s*\+\s*(\w+)$/)
    if (addMatch) {
      const a = Number(row[addMatch[1]]) || 0
      const b = Number(row[addMatch[2]]) || 0
      row[f.field_code] = Math.round((a + b) * 100) / 100
      return
    }
    // 减法 a-b
    const subMatch = expr.match(/^(\w+)\s*-\s*(\w+)$/)
    if (subMatch) {
      const a = Number(row[subMatch[1]]) || 0
      const b = Number(row[subMatch[2]]) || 0
      row[f.field_code] = Math.round((a - b) * 100) / 100
      return
    }
  })
}

function onSubRowChange(sub: FormEntity, row: any, _field: FormField) {
  // 1. 按配置重算公式（formula）字段
  executeFormula(row, sub.fields)
  // 2. 按配置重算汇总（summary_to）字段
  recalcSubSummary(sub)
}

function rowClassName({ row }: { row: any }) {
  const active = selectedRows.value[activeSubTab.value || activeTab.value]
  return active === row ? 'selected-row' : ''
}

// 切换子表 tab 时，自动选第一个孙表
watch(activeSubTab, () => {
  if (currentGrandchildEntities.value.length) {
    activeGcTab.value = currentGrandchildEntities.value[0].entity_code
  }
}, { immediate: true })
</script>

<style scoped lang="scss">
.master-detail-editor {
  background: #fff;
  padding: 12px;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 2px solid #1564ff;
}
.main-form {
  .group-label {
    width: 100%;
    font-size: 12px;
    color: #909399;
    margin: 8px 0 4px;
    padding-left: 8px;
    border-left: 3px solid #1564ff;
  }
}
.sub-tabs {
  margin-top: 12px;
}
.sub-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}
.sub-summary {
  margin-left: auto;
  color: #1564ff;
  font-weight: 600;
}
.grandchild-section {
  padding: 12px;
  background: #fafafa;
}
.gc-title {
  font-weight: 600;
  margin-bottom: 8px;
  font-size: 13px;
}
.gc-table {
  margin-bottom: 12px;
}
:deep(.selected-row) {
  background: #ecf5ff !important;
}

/* ============ 堆叠布局样式 ============ */
.layout-stacked {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.stack-section {
  :deep(.el-tabs--border-card) {
    box-shadow: none;
    border: 1px solid #ebeef5;
  }
  :deep(.el-tabs__header) {
    background: #fafafa;
  }
}
.master-tabs {
  .main-form {
    padding: 8px 4px 0;
  }
}
.gc-section {
  .gc-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
    .gc-context {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      color: #909399;
    }
  }
}
:deep(.el-table .current-row) {
  background: #ecf5ff !important;
}
</style>
