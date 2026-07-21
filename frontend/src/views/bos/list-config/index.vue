<template>
  <div class="list-config-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:240px" @change="onBoChange" />
      </div>
      <div class="header-right">
        <el-button
          type="primary"
          size="small"
          :disabled="!boCode || activeTab === 'columns' ? !columns.length : !queryFields.length"
          @click="onSave"
        >
          <el-icon><Check /></el-icon>保存
        </el-button>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body panel-card">
      <el-empty v-if="!boCode" description="请先选择业务对象" :image-size="80" />

      <el-tabs v-else v-model="activeTab" class="config-tabs">
        <!-- Tab 1：展示字段 -->
        <el-tab-pane name="columns">
          <template #label>
            <span>展示字段 <el-badge :value="columns.length" class="tab-badge" type="primary" /></span>
          </template>

          <div class="tab-toolbar">
            <span class="tab-tip">
              <el-icon><InfoFilled /></el-icon>
              拖动首列手柄调整顺序；勾选「显示」控制列默认展示，「合计/平均」用于数值列。
            </span>
          </div>

          <el-table
            ref="columnTableRef"
            :data="columns"
            size="small"
            border
            row-key="id"
            v-loading="loadingColumns"
            empty-text="暂无字段配置"
          >
            <el-table-column label="" width="44" align="center">
              <template #default>
                <el-icon class="drag-handle"><Rank /></el-icon>
              </template>
            </el-table-column>
            <el-table-column prop="field_code" label="字段编码" width="140" show-overflow-tooltip />
            <el-table-column prop="field_name" label="字段名称" width="140" show-overflow-tooltip />
            <el-table-column prop="entity_code" label="所属实体" width="130" show-overflow-tooltip>
              <template #default="{ row }">
                <el-tag size="small" effect="plain" :type="entityTagType(row.entity_code)">
                  {{ entityNameMap[row.entity_code] || row.entity_code || '主表' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="ctrl_type" label="控件类型" width="110">
              <template #default="{ row }">
                <el-tag size="small" effect="plain">{{ controlLabel(row.ctrl_type) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="is_show" label="显示" width="60" align="center">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_show" />
              </template>
            </el-table-column>
            <el-table-column prop="is_fixed" label="冻结" width="100">
              <template #default="{ row }">
                <el-select v-model="row.is_fixed" size="small" style="width:100%">
                  <el-option label="不冻结" value="none" />
                  <el-option label="左侧" value="left" />
                  <el-option label="右侧" value="right" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column prop="column_width" label="列宽" width="110">
              <template #default="{ row }">
                <el-input-number
                  v-model="row.column_width"
                  :min="60"
                  :max="500"
                  :step="10"
                  controls-position="right"
                  size="small"
                  style="width:100%"
                />
              </template>
            </el-table-column>
            <el-table-column prop="sort_index" label="顺序" width="70" align="center" />
            <el-table-column prop="is_sum" label="合计" width="60" align="center">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_sum" />
              </template>
            </el-table-column>
            <el-table-column prop="is_avg" label="平均" width="60" align="center">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_avg" />
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- Tab 2：查询字段 -->
        <el-tab-pane name="query">
          <template #label>
            <span>查询字段 <el-badge :value="queryFields.length" class="tab-badge" type="primary" /></span>
          </template>

          <div class="tab-toolbar">
            <span class="tab-tip">
              <el-icon><InfoFilled /></el-icon>
              「常用」显示在列表普通查询区，「高级」显示在高级查询弹窗；为字段配置支持的运算符。
            </span>
          </div>

          <el-table
            :data="queryFields"
            size="small"
            border
            row-key="id"
            v-loading="loadingQuery"
            empty-text="暂无查询字段配置"
          >
            <el-table-column prop="field_code" label="字段编码" width="140" show-overflow-tooltip />
            <el-table-column prop="field_name" label="字段名称" width="140" show-overflow-tooltip />
            <el-table-column prop="entity_code" label="所属实体" width="130" show-overflow-tooltip>
              <template #default="{ row }">
                <el-tag size="small" effect="plain" :type="entityTagType(row.entity_code)">
                  {{ entityNameMap[row.entity_code] || row.entity_code || '主表' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="ctrl_type" label="控件类型" width="110">
              <template #default="{ row }">
                <el-tag size="small" effect="plain">{{ controlLabel(row.ctrl_type) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="is_common" label="常用" width="60" align="center">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_common" />
              </template>
            </el-table-column>
            <el-table-column prop="is_advanced" label="高级" width="60" align="center">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_advanced" />
              </template>
            </el-table-column>
            <el-table-column prop="operators" label="支持运算符" min-width="280">
              <template #default="{ row }">
                <el-select
                  v-model="row.operators"
                  multiple
                  collapse-tags
                  collapse-tags-tooltip
                  size="small"
                  placeholder="选择运算符"
                  style="width:100%"
                >
                  <el-option
                    v-for="op in QUERY_OPERATORS"
                    :key="op.value"
                    :label="op.label"
                    :value="op.value"
                  />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column prop="sort_index" label="顺序" width="70" align="center" />
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Check, InfoFilled, Rank } from '@element-plus/icons-vue'
import { useDraggable } from 'vue-draggable-plus'
import BoPicker from '@/components/BoPicker/index.vue'
import { listConfigApi } from '@/api/list'
import { entityApi } from '@/api/bo'
import { CONTROL_TYPE_OPTIONS, QUERY_OPERATORS } from '@/utils/enum'
import type { ListColumn, QueryField, FormEntity } from '@/types/bo'

const boCode = ref('')
const activeTab = ref<'columns' | 'query'>('columns')

const columns = ref<ListColumn[]>([])
const queryFields = ref<QueryField[]>([])
const entities = ref<FormEntity[]>([])
const loadingColumns = ref(false)
const loadingQuery = ref(false)

/** entity_code → 实体名称映射（如 sal_int_cont → "单据头"，sal_int_cont_goods → "明细"） */
const entityNameMap = computed(() => {
  const m: Record<string, string> = {}
  for (const e of entities.value) {
    let label = e.entity_name || e.entity_code
    if (e.entity_type === 'main' || e.entity_level === 0) label = `主表-${label}`
    else if (e.entity_type === 'sub' || e.entity_level === 1) label = `明细-${label}`
    else label = `孙表-${label}`
    m[e.entity_code] = label
  }
  return m
})

/** 根据 entity_code 返回 tag 类型（主表 primary / 子表 success / 孙表 warning） */
function entityTagType(entityCode?: string): 'primary' | 'success' | 'warning' | 'info' {
  if (!entityCode) return 'primary'
  const entity = entities.value.find(e => e.entity_code === entityCode)
  if (!entity) return 'info'
  if (entity.entity_type === 'main' || entity.entity_level === 0) return 'primary'
  if (entity.entity_type === 'sub' || entity.entity_level === 1) return 'success'
  return 'warning'
}

const columnTableRef = ref<any>(null)
const columnTbody = ref<HTMLElement | null>(null)
let dragAttached = false

// immediate: false 避免在 setup 阶段 columnTbody 为 null 时初始化 Sortable 抛异常
// 改为在 attachDraggable() 中设置 columnTbody 后手动调用 start()
const { start: startDrag } = useDraggable(columnTbody, columns, {
  handle: '.drag-handle',
  animation: 150,
  ghostClass: 'drag-ghost',
  immediate: false,
  onEnd: () => reindexColumns()
})

function controlLabel(ct: string) {
  return CONTROL_TYPE_OPTIONS.find(o => o.value === ct)?.label || ct
}

function reindexColumns() {
  columns.value.forEach((c, i) => (c.sort_index = i + 1))
}

async function onBoChange() {
  if (!boCode.value) {
    columns.value = []
    queryFields.value = []
    entities.value = []
    return
  }
  // 加载实体元数据（用于显示字段所属实体）
  try {
    entities.value = await entityApi.list(boCode.value)
  } catch {
    entities.value = []
  }
  await Promise.all([loadColumns(), loadQueryFields()])
  await nextTick()
  attachDraggable()
}

async function loadColumns() {
  loadingColumns.value = true
  try {
    const res = await listConfigApi.columns(boCode.value)
    columns.value = (res || []).sort((a, b) => a.sort_index - b.sort_index)
  } catch {
    columns.value = []
  } finally {
    loadingColumns.value = false
  }
}

async function loadQueryFields() {
  loadingQuery.value = true
  try {
    const res = await listConfigApi.queryFields(boCode.value)
    queryFields.value = (res || []).sort((a, b) => a.sort_index - b.sort_index)
  } catch {
    queryFields.value = []
  } finally {
    loadingQuery.value = false
  }
}

function attachDraggable() {
  // 拖拽挂载到 el-table 的 tbody，切换业务对象时 el-table 复用同一 tbody，仅需挂载一次
  if (dragAttached) return
  nextTick(() => {
    const el = columnTableRef.value?.$el as HTMLElement | undefined
    const tbody = el?.querySelector('.el-table__body-wrapper tbody') as HTMLElement | null
    if (tbody) {
      columnTbody.value = tbody
      startDrag(tbody)
      dragAttached = true
    }
  })
}

async function onSave() {
  if (activeTab.value === 'columns') {
    reindexColumns()
    try {
      await listConfigApi.saveColumns(boCode.value, columns.value)
      ElMessage.success('展示字段配置已保存')
    } catch {
      ElMessage.error('保存失败')
    }
  } else {
    queryFields.value.forEach((f, i) => (f.sort_index = i + 1))
    try {
      await listConfigApi.saveQueryFields(boCode.value, queryFields.value)
      ElMessage.success('查询字段配置已保存')
    } catch {
      ElMessage.error('保存失败')
    }
  }
}

watch(boCode, () => {
  dragAttached = false
})
</script>

<style scoped lang="scss">
.list-config-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.header-label {
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
}
.main-body {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
}
.config-tabs {
  height: 100%;
}
.tab-badge {
  margin-left: 4px;
  :deep(.el-badge__content) {
    height: 16px;
    line-height: 16px;
    padding: 0 4px;
    font-size: 11px;
  }
}
.tab-toolbar {
  margin-bottom: 10px;
}
.tab-tip {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #606266;
  background: #ecf5ff;
  padding: 6px 10px;
  border-radius: 4px;
  .el-icon { color: #1564ff; }
}
.drag-handle {
  cursor: grab;
  color: #909399;
  font-size: 16px;
  &:hover { color: #1564ff; }
  &:active { cursor: grabbing; }
}
:deep(.drag-ghost) {
  opacity: 0.6;
  background: #ecf5ff !important;
}
</style>
