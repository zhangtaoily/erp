<template>
  <div class="list-query">
    <!-- 普通查询区 -->
    <div class="query-bar">
      <el-form :inline="true" :model="searchForm" size="small" class="query-form" @submit.prevent="onSearch">
        <el-form-item v-for="f in commonFields" :key="f.field_code" :label="f.field_name">
          <el-input
            v-if="isTextControl(f.ctrl_type)"
            v-model="searchForm[f.field_code]"
            placeholder="请输入"
            clearable
            style="width: 160px"
            @keyup.enter="onSearch"
          />
          <el-date-picker
            v-else-if="f.ctrl_type === 'date'"
            v-model="searchForm[f.field_code]"
            type="daterange"
            value-format="YYYY-MM-DD"
            range-separator="至"
            start-placeholder="开始"
            end-placeholder="结束"
            style="width: 240px"
          />
          <el-select
            v-else-if="f.ctrl_type === 'select'"
            v-model="searchForm[f.field_code]"
            placeholder="请选择"
            clearable
            style="width: 140px"
          >
            <el-option v-for="s in stateOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
          <el-input-number
            v-else
            v-model="searchForm[f.field_code]"
            placeholder="请输入"
            controls-position="right"
            style="width: 140px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch"><el-icon><Search /></el-icon>查询</el-button>
          <el-button @click="onReset">重置</el-button>
          <el-button link type="primary" @click="advancedVisible = true">
            <el-icon><Filter /></el-icon>高级查询
            <el-badge v-if="advancedConditions.length" is-dot class="adv-badge" />
          </el-button>
        </el-form-item>
      </el-form>
      <div class="query-tools">
        <el-select v-model="currentSchemeId" placeholder="查询方案" clearable size="small" style="width: 200px" @change="onApplyScheme">
          <el-option-group v-if="mySchemes.length" label="我的方案">
            <el-option v-for="s in mySchemes" :key="s.id" :label="s.scheme_name + (s.is_default ? '（默认）' : '')" :value="s.id">
              <span>{{ s.scheme_name }}</span>
              <el-icon v-if="s.is_favorite" style="color:#faad14"><Star /></el-icon>
            </el-option>
          </el-option-group>
          <el-option-group v-if="publicSchemes.length" label="公共方案">
            <el-option v-for="s in publicSchemes" :key="s.id" :label="s.scheme_name" :value="s.id" />
          </el-option-group>
        </el-select>
        <el-button size="small" @click="onSaveScheme"><el-icon><FolderAdd /></el-icon>保存方案</el-button>
        <!-- 列设置升级为完整弹窗（GAP-D09-002 / RISK-D09-003）-->
        <el-button size="small" @click="onOpenColumnDialog"><el-icon><Setting /></el-icon>列设置</el-button>
        <!-- 导出 Excel（GAP-D09-007 / GAP-D12-011，CSV 简化实现）-->
        <el-button size="small" @click="onExportCsv"><el-icon><Download /></el-icon>导出 Excel</el-button>
      </div>
    </div>

    <!-- 表格 -->
    <el-table
      ref="tableRef"
      :data="data"
      v-loading="loading"
      border
      size="small"
      row-key="id"
      height="100%"
      :summary-method="summaryMethod"
      :show-summary="hasSummary"
      @selection-change="onSelectionChange"
      @row-click="onRowClick"
      @sort-change="onSortChange"
    >
      <el-table-column v-if="selectable" type="selection" width="42" fixed="left" />
      <el-table-column type="index" label="#" width="50" fixed="left" />
      <el-table-column
        v-for="col in displayColumns"
        :key="col.field_code"
        :prop="col.field_code"
        :label="col.field_name"
        :width="col.column_width"
        :fixed="col.is_fixed === 'none' ? false : col.is_fixed"
        :sortable="true"
        resizable
        show-overflow-tooltip
      >
        <template #default="{ row }">
          <template v-if="col.field_code === 'pact_state'">
            <el-tag :type="pactStateType(row[col.field_code])" size="small" effect="light">
              {{ pactStateLabel(row[col.field_code]) }}
            </el-tag>
          </template>
          <template v-else-if="col.ctrl_type === 'amount'">
            <span class="cell-amount">{{ formatNumber(row[col.field_code]) }}</span>
          </template>
          <template v-else-if="col.ctrl_type === 'qty'">
            <span class="cell-qty">{{ formatNumber(row[col.field_code]) }}</span>
          </template>
          <template v-else-if="col.ctrl_type === 'date'">
            {{ formatDate(row[col.field_code]) }}
          </template>
          <template v-else-if="col.ctrl_type === 'datetime'">
            {{ formatDateTime(row[col.field_code]) }}
          </template>
          <template v-else-if="col.ctrl_type === 'checkbox'">
            <el-tag :type="row[col.field_code] ? 'success' : 'info'" size="small">
              {{ row[col.field_code] ? '是' : '否' }}
            </el-tag>
          </template>
          <template v-else>{{ row[col.field_code] ?? '' }}</template>
        </template>
      </el-table-column>
      <el-table-column v-if="showActionColumn" label="操作" width="120" fixed="right">
        <template #default="{ row }">
          <slot name="action" :row="row" />
        </template>
      </el-table-column>
      <template #empty>
        <el-empty description="暂无数据" :image-size="80" />
      </template>
    </el-table>

    <!-- 分页 -->
    <div class="query-pagination">
      <el-pagination
        v-model:current-page="pageNum"
        v-model:page-size="pageSize"
        :page-sizes="[20, 50, 100]"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        background
        size="small"
        @current-change="onPageChange"
        @size-change="onSizeChange"
      />
      <div v-if="selectedRows.length" class="selected-info">已选 {{ selectedRows.length }} 行</div>
    </div>

    <!-- 高级查询弹窗（支持多级括号嵌套 GAP-D09-001）-->
    <el-dialog v-model="advancedVisible" title="高级查询（支持多级括号嵌套）" width="820px" append-to-body>
      <div class="adv-query">
        <div class="adv-toolbar">
          <el-button size="small" type="primary" @click="onAddCondition()"><el-icon><Plus /></el-icon>添加条件</el-button>
          <el-button size="small" @click="onAddGroup()"><el-icon><Plus /></el-icon>添加分组</el-button>
          <el-button size="small" link type="danger" @click="advancedTree = null">清空</el-button>
          <span class="adv-tip">说明：分组对应括号「()」，可嵌套多层；分组内条件的与/或逻辑独立。</span>
        </div>
        <div class="adv-tree">
          <el-empty v-if="!advancedTree" description="点击添加条件或添加分组构建查询" :image-size="60" />
          <template v-else>
            <ConditionNode
              :node="advancedTree"
              :field-options="advancedFieldOptions"
              :state-options="stateOptions"
              :operators="QUERY_OPERATORS"
              :is-root="true"
              @remove="onRemoveRoot"
            />
          </template>
        </div>
      </div>
      <template #footer>
        <el-button @click="advancedVisible = false">取消</el-button>
        <el-button type="primary" @click="onAdvancedSearch">查询</el-button>
      </template>
    </el-dialog>

    <!-- 列设置完整弹窗（GAP-D09-002 / RISK-D09-003：含列宽/冻结/合计）-->
    <el-dialog v-model="columnDialogVisible" title="列设置（保存到 user_list_setting）" width="720px" append-to-body>
      <div class="col-dialog-toolbar">
        <el-button size="small" @click="onAddColumnSetting">添加列</el-button>
        <el-button size="small" link type="primary" @click="onResetColumns">恢复默认</el-button>
      </div>
      <el-table :data="columnSettings" size="small" border max-height="420">
        <el-table-column label="序号" type="index" width="55" />
        <el-table-column label="字段" min-width="160">
          <template #default="{ row }">
            <el-select v-model="row.field_code" size="small" filterable placeholder="选择字段" style="width:100%">
              <el-option v-for="c in allColumns" :key="c.field_code" :label="c.field_name + ' (' + c.field_code + ')'" :value="c.field_code" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="显示" width="60" align="center">
          <template #default="{ row }">
            <el-switch v-model="row.is_show" />
          </template>
        </el-table-column>
        <el-table-column label="列宽" width="100">
          <template #default="{ row }">
            <el-input-number v-model="row.column_width" :min="60" :max="500" :step="10" size="small" controls-position="right" style="width:100%" />
          </template>
        </el-table-column>
        <el-table-column label="冻结" width="100">
          <template #default="{ row }">
            <el-select v-model="row.is_fixed" size="small" style="width:100%">
              <el-option label="不冻结" value="none" />
              <el-option label="左冻结" value="left" />
              <el-option label="右冻结" value="right" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="合计" width="60" align="center">
          <template #default="{ row }">
            <el-switch v-model="row.is_sum" />
          </template>
        </el-table-column>
        <el-table-column label="平均" width="60" align="center">
          <template #default="{ row }">
            <el-switch v-model="row.is_avg" />
          </template>
        </el-table-column>
        <el-table-column label="排序" width="80">
          <template #default="{ row }">
            <el-input-number v-model="row.sort_index" :min="1" :step="1" size="small" controls-position="right" style="width:100%" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="70" fixed="right">
          <template #default="{ $index }">
            <el-button link type="danger" size="small" @click="columnSettings.splice($index, 1)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="columnDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSaveColumnSettings">保存到 user_list_setting</el-button>
      </template>
    </el-dialog>

    <!-- 保存方案弹窗 -->
    <el-dialog v-model="saveSchemeVisible" title="保存查询方案" width="420px" append-to-body>
      <el-form :model="schemeForm" label-width="90px" size="small">
        <el-form-item label="方案名称" required>
          <el-input v-model="schemeForm.scheme_name" placeholder="请输入方案名称" />
        </el-form-item>
        <el-form-item label="是否公共">
          <el-switch v-model="schemeForm.is_public" />
        </el-form-item>
        <el-form-item label="设为默认">
          <el-switch v-model="schemeForm.is_default" />
        </el-form-item>
        <el-form-item label="每页条数">
          <el-input-number v-model="schemeForm.page_size" :min="10" :max="500" :step="10" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="saveSchemeVisible = false">取消</el-button>
        <el-button type="primary" @click="onConfirmSaveScheme">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, defineComponent, h } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Delete, Star, FolderAdd, Setting, Filter, Search, Download } from '@element-plus/icons-vue'
import { listConfigApi, schemeApi, userListSettingApi, currentUserApi } from '@/api/list'
import { PACT_STATE_MAP, PACT_STATE_LIST, QUERY_OPERATORS } from '@/utils/enum'
import type { ListColumn, QueryField, QueryScheme, QueryCondition, ColumnSettingItem } from '@/types/bo'

const props = withDefaults(defineProps<{
  boCode: string
  columns?: ListColumn[]
  queryFields?: QueryField[]
  data?: any[]
  loading?: boolean
  total?: number
  mode?: 'config' | 'runtime'
  selectable?: boolean
  showActionColumn?: boolean
}>(), {
  data: () => [],
  loading: false,
  total: 0,
  mode: 'runtime',
  selectable: true,
  showActionColumn: true
})

const emit = defineEmits<{
  (e: 'search', conditions: QueryCondition[], pageNum: number, pageSize: number): void
  (e: 'sort', prop: string, order: string): void
  (e: 'select', rows: any[]): void
  (e: 'row-click', row: any): void
  (e: 'apply-scheme', scheme: QueryScheme): void
  (e: 'save-scheme', scheme: Partial<QueryScheme>): void
  (e: 'column-change', columns: ListColumn[]): void
}>()

const tableRef = ref()
const allColumns = ref<ListColumn[]>([])
const allQueryFields = ref<QueryField[]>([])
const schemes = ref<QueryScheme[]>([])
const searchForm = reactive<Record<string, any>>({})
// 旧扁平模式仍保留用于简单场景的回显
const advancedConditions = ref<QueryCondition[]>([])
// === D09 多级嵌套：条件树根节点（GAP-D09-001）===
const advancedTree = ref<QueryCondition | null>(null)
const advancedVisible = ref(false)
const visibleFieldCodes = ref<string[]>([])
const pageNum = ref(1)
const pageSize = ref(20)
const selectedRows = ref<any[]>([])
const currentSchemeId = ref('')
const saveSchemeVisible = ref(false)
const schemeForm = reactive({
  scheme_name: '',
  is_public: false,
  is_default: false,
  page_size: 20
})
// === 列设置弹窗（GAP-D09-002 / RISK-D09-003）===
const columnDialogVisible = ref(false)
const columnSettings = ref<ColumnSettingItem[]>([])
// 当前用户上下文（GAP-D09-005 / RISK-D09-002）
const currentUserId = ref('U1')  // 兜底默认值，将在 onMounted 中被后端覆盖

const stateOptions = PACT_STATE_LIST
const commonFields = computed(() => allQueryFields.value.filter(f => f.is_common))
const advancedFieldOptions = computed(() => allQueryFields.value.filter(f => f.is_advanced))
const mySchemes = computed(() => schemes.value.filter(s => !s.is_public))
const publicSchemes = computed(() => schemes.value.filter(s => s.is_public))

const displayColumns = computed(() =>
  allColumns.value
    .filter(c => visibleFieldCodes.value.includes(c.field_code))
    .sort((a, b) => a.sort_index - b.sort_index)
)

const hasSummary = computed(() => displayColumns.value.some(c => c.is_sum || c.is_avg))

function isTextControl(ct: string) {
  return ['text', 'ref', 'textarea'].includes(ct)
}

function pactStateType(state: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  return PACT_STATE_MAP[state]?.type || 'info'
}
function pactStateLabel(state: number) {
  return PACT_STATE_MAP[state]?.label || String(state ?? '')
}
function formatNumber(v: any) {
  if (v == null || v === '') return ''
  const n = Number(v)
  return isNaN(n) ? v : n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}
function formatDate(v: any) {
  if (!v) return ''
  return String(v).slice(0, 10)
}
function formatDateTime(v: any) {
  if (!v) return ''
  return String(v).slice(0, 16).replace('T', ' ')
}

function operatorsForField(fieldCode: string) {
  const f = allQueryFields.value.find(x => x.field_code === fieldCode)
  if (!f) return QUERY_OPERATORS
  return QUERY_OPERATORS.filter(o => f.operators.includes(o.value))
}
function getFieldControl(fieldCode: string) {
  return allQueryFields.value.find(x => x.field_code === fieldCode)?.ctrl_type || 'text'
}
function onCondFieldChange(cond: QueryCondition) {
  cond.operator = ''
  cond.value = ''
}

function summaryMethod({ columns, data }: { columns: any[]; data: any[] }) {
  return columns.map((col: any, idx: number) => {
    if (idx === 0) return '合计'
    const c = displayColumns.value.find(x => x.field_code === col.property)
    if (!c || !c.is_sum) return ''
    const total = data.reduce((sum, row) => {
      const v = Number(row[c.field_code])
      return isNaN(v) ? sum : sum + v
    }, 0)
    return c.ctrl_type === 'amount' ? formatNumber(total) : total
  })
}

function onSearch() {
  const conditions: QueryCondition[] = []
  Object.entries(searchForm).forEach(([field, value]) => {
    if (value != null && value !== '' && (!Array.isArray(value) || value.length)) {
      const f = allQueryFields.value.find(x => x.field_code === field)
      if (f && f.ctrl_type === 'date' && Array.isArray(value)) {
        conditions.push({ field_code: field, operator: 'between', value, logic: 'AND' })
      } else {
        conditions.push({ field_code: field, operator: f?.ctrl_type === 'select' ? 'eq' : 'like', value, logic: 'AND' })
      }
    }
  })
  pageNum.value = 1
  // 合并普通条件 + 高级查询条件树（扁平化后追加）
  const advFlat = advancedTree.value ? flattenConditions(advancedTree.value) : []
  emit('search', [...conditions, ...advFlat], pageNum.value, pageSize.value)
}

// === D09 多级嵌套：条件树扁平化（GAP-D09-001）===
// 将条件树递归扁平化为 QueryCondition[]，children/group_logic 转换为 group 括号分组
function flattenConditions(node: QueryCondition): QueryCondition[] {
  const result: QueryCondition[] = []
  if (node.group_type === 'group' && node.children?.length) {
    // 分组：开括号
    result.push({ field_code: '', operator: '', value: '', logic: node.group_logic || 'AND', group: 1 })
    node.children.forEach((child, idx) => {
      const flat = flattenConditions(child)
      flat.forEach((c, i) => {
        // 第一个子条件继承 group_logic，其余保留自身 logic
        if (idx === 0 && i === 0) c.logic = node.group_logic || 'AND'
        result.push(c)
      })
    })
    result.push({ field_code: '', operator: '', value: '', logic: 'AND', group: 2 })
  } else if (node.group_type === 'condition' || !node.group_type) {
    result.push({
      field_code: node.field_code,
      operator: node.operator,
      value: node.value,
      logic: node.logic || 'AND'
    })
  }
  return result
}

function onReset() {
  Object.keys(searchForm).forEach(k => delete searchForm[k])
  advancedConditions.value = []
  advancedTree.value = null
  pageNum.value = 1
  emit('search', [], pageNum.value, pageSize.value)
}

function onAdvancedSearch() {
  advancedVisible.value = false
  onSearch()
}

// === D09 嵌套条件操作（GAP-D09-001）===
// 在根级别添加条件：若根为空则创建为根；否则包裹为分组
function onAddCondition() {
  const newCond: QueryCondition = {
    field_code: '', operator: '', value: '', logic: 'AND', group_type: 'condition'
  }
  if (!advancedTree.value) {
    advancedTree.value = newCond
  } else {
    // 已有根节点：将其包裹为分组，再添加新条件
    const old = advancedTree.value
    advancedTree.value = {
      field_code: '', operator: '', value: '', logic: 'AND',
      group_type: 'group', group_logic: 'AND',
      children: [old, newCond]
    }
  }
}

function onAddGroup() {
  const newGroup: QueryCondition = {
    field_code: '', operator: '', value: '', logic: 'AND',
    group_type: 'group', group_logic: 'AND',
    children: [{ field_code: '', operator: '', value: '', logic: 'AND', group_type: 'condition' }]
  }
  if (!advancedTree.value) {
    advancedTree.value = newGroup
  } else {
    const old = advancedTree.value
    advancedTree.value = {
      field_code: '', operator: '', value: '', logic: 'AND',
      group_type: 'group', group_logic: 'AND',
      children: [old, newGroup]
    }
  }
}

function onRemoveRoot() {
  advancedTree.value = null
}

function onPageChange() {
  emit('search', buildCurrentConditions(), pageNum.value, pageSize.value)
}
function onSizeChange() {
  pageNum.value = 1
  emit('search', buildCurrentConditions(), pageNum.value, pageSize.value)
}
function buildCurrentConditions(): QueryCondition[] {
  const conds: QueryCondition[] = []
  Object.entries(searchForm).forEach(([field, value]) => {
    if (value != null && value !== '') {
      conds.push({ field_code: field, operator: 'like', value, logic: 'AND' })
    }
  })
  // 包含高级查询条件树
  const advFlat = advancedTree.value ? flattenConditions(advancedTree.value) : []
  return [...conds, ...advFlat]
}

function onSelectionChange(rows: any[]) {
  selectedRows.value = rows
  emit('select', rows)
}
function onRowClick(row: any) {
  emit('row-click', row)
}
function onSortChange({ prop, order }: { prop: string | null; order: string | null }) {
  emit('sort', prop || '', order || '')
}

function onApplyColumns() {
  const updated = allColumns.value.map(c => ({ ...c, is_show: visibleFieldCodes.value.includes(c.field_code) }))
  allColumns.value = updated
  emit('column-change', updated)
}

function onResetColumns() {
  // 恢复默认列设置
  columnSettings.value = allColumns.value.map(c => ({
    field_code: c.field_code,
    is_show: c.is_show,
    column_width: c.column_width,
    is_fixed: c.is_fixed,
    is_sum: c.is_sum,
    is_avg: c.is_avg,
    sort_index: c.sort_index
  }))
  visibleFieldCodes.value = allColumns.value.filter(c => c.is_show).map(c => c.field_code)
}

// === 列设置弹窗（GAP-D09-002 / RISK-D09-003）===
function onOpenColumnDialog() {
  // 初始化 columnSettings：从 allColumns 加载
  columnSettings.value = allColumns.value.map(c => ({
    field_code: c.field_code,
    is_show: visibleFieldCodes.value.includes(c.field_code) ? true : c.is_show,
    column_width: c.column_width,
    is_fixed: c.is_fixed,
    is_sum: c.is_sum,
    is_avg: c.is_avg,
    sort_index: c.sort_index
  }))
  columnDialogVisible.value = true
}

function onAddColumnSetting() {
  columnSettings.value.push({
    field_code: '', is_show: true, column_width: 120, is_fixed: 'none',
    is_sum: false, is_avg: false, sort_index: columnSettings.value.length + 1
  })
}

async function onSaveColumnSettings() {
  // 应用到本地 allColumns
  const updated: ListColumn[] = []
  allColumns.value.forEach(c => {
    const s = columnSettings.value.find(x => x.field_code === c.field_code)
    if (s) {
      updated.push({
        ...c,
        is_show: s.is_show,
        column_width: s.column_width || c.column_width,
        is_fixed: s.is_fixed || 'none',
        is_sum: !!s.is_sum,
        is_avg: !!s.is_avg,
        sort_index: s.sort_index || c.sort_index
      })
    } else {
      updated.push(c)
    }
  })
  allColumns.value = updated
  visibleFieldCodes.value = updated.filter(c => c.is_show).map(c => c.field_code)
  emit('column-change', updated)
  // 持久化到 user_list_setting.columns_json
  try {
    await userListSettingApi.save({
      user_id: currentUserId.value,
      bo_code: props.boCode,
      columns_json: JSON.stringify(columnSettings.value),
      page_size: pageSize.value
    })
    ElMessage.success('列设置已保存到 user_list_setting')
  } catch {
    ElMessage.warning('列设置应用成功，但持久化失败')
  }
  columnDialogVisible.value = false
}

// === 导出 Excel（GAP-D09-007 / GAP-D12-011，CSV 简化实现）===
function onExportCsv() {
  if (!props.data || !props.data.length) {
    ElMessage.warning('暂无数据可导出')
    return
  }
  const cols = displayColumns.value
  // 构建 CSV 内容
  const headers = cols.map(c => c.field_name).join(',')
  const rows = props.data.map(row =>
    cols.map(c => {
      const v = row[c.field_code]
      if (v == null) return ''
      const s = String(v).replace(/"/g, '""')
      // 含逗号/引号/换行的值加双引号包裹
      return /[",\n]/.test(s) ? `"${s}"` : s
    }).join(',')
  )
  // 加 BOM 头确保 Excel 正确识别 UTF-8
  const csv = '\ufeff' + [headers, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${props.boCode}_export_${new Date().toISOString().slice(0, 10)}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  ElMessage.success(`已导出 ${props.data.length} 行（CSV 格式）`)
}

function onApplyScheme(id: string) {
  const s = schemes.value.find(x => x.id === id)
  if (!s) return
  if (s.columns?.length) visibleFieldCodes.value = s.columns
  if (s.page_size) pageSize.value = s.page_size
  // 应用方案的条件到 advancedTree（包裹为根分组）
  if (s.conditions?.length) {
    advancedTree.value = {
      field_code: '', operator: '', value: '', logic: 'AND',
      group_type: 'group', group_logic: 'AND',
      children: s.conditions.map(c => ({ ...c, group_type: 'condition' as const }))
    }
  }
  emit('apply-scheme', s)
  emit('search', s.conditions || [], pageNum.value, pageSize.value)
}

function onSaveScheme() {
  const advFlat = advancedTree.value ? flattenConditions(advancedTree.value) : []
  if (!advFlat.length && !Object.keys(searchForm).length) {
    ElMessage.warning('请先设置查询条件')
    return
  }
  schemeForm.scheme_name = ''
  schemeForm.is_public = false
  schemeForm.is_default = false
  schemeForm.page_size = pageSize.value
  saveSchemeVisible.value = true
}

function onConfirmSaveScheme() {
  if (!schemeForm.scheme_name) {
    ElMessage.warning('请输入方案名称')
    return
  }
  const scheme: Partial<QueryScheme> = {
    scheme_name: schemeForm.scheme_name,
    bo_code: props.boCode,
    is_public: schemeForm.is_public,
    is_default: schemeForm.is_default,
    is_favorite: false,
    conditions: buildCurrentConditions(),
    columns: visibleFieldCodes.value,
    page_size: schemeForm.page_size,
    // === GAP-D09-005 / RISK-D09-002：user_id 从后端获取，移除硬编码 'u1' ===
    user_id: currentUserId.value
  }
  emit('save-scheme', scheme)
  saveSchemeVisible.value = false
  ElMessage.success('方案已保存')
  loadSchemes()
}

async function loadColumns() {
  if (props.columns?.length) {
    allColumns.value = props.columns
  } else {
    try {
      const res = await listConfigApi.columns(props.boCode)
      allColumns.value = res || []
    } catch { allColumns.value = [] }
  }
  visibleFieldCodes.value = allColumns.value.filter(c => c.is_show).map(c => c.field_code)
  // === 加载用户列设置（GAP-D09-002 / RISK-D09-003）===
  try {
    const userSetting = await userListSettingApi.get(props.boCode)
    if (userSetting && userSetting.columns_json) {
      const items: ColumnSettingItem[] = JSON.parse(userSetting.columns_json)
      // 应用到 allColumns
      allColumns.value = allColumns.value.map(c => {
        const s = items.find(x => x.field_code === c.field_code)
        return s ? {
          ...c,
          is_show: s.is_show,
          column_width: s.column_width || c.column_width,
          is_fixed: s.is_fixed || c.is_fixed,
          is_sum: !!s.is_sum,
          is_avg: !!s.is_avg,
          sort_index: s.sort_index || c.sort_index
        } : c
      })
      visibleFieldCodes.value = allColumns.value.filter(c => c.is_show).map(c => c.field_code)
      if (userSetting.page_size) pageSize.value = userSetting.page_size
    }
  } catch { /* 无用户设置时忽略 */ }
}

async function loadQueryFields() {
  if (props.queryFields?.length) {
    allQueryFields.value = props.queryFields
  } else {
    try {
      const res = await listConfigApi.queryFields(props.boCode)
      allQueryFields.value = res || []
    } catch { allQueryFields.value = [] }
  }
}

async function loadSchemes() {
  try {
    const res = await schemeApi.list(props.boCode)
    schemes.value = res || []
    const def = schemes.value.find(s => s.is_default)
    if (def) {
      currentSchemeId.value = def.id
      if (def.columns?.length) visibleFieldCodes.value = def.columns
      if (def.page_size) pageSize.value = def.page_size
    }
  } catch { schemes.value = [] }
}

watch(() => props.columns, (v) => {
  if (v?.length) {
    allColumns.value = v
    visibleFieldCodes.value = v.filter(c => c.is_show).map(c => c.field_code)
  }
})
watch(() => props.queryFields, (v) => { if (v?.length) allQueryFields.value = v })

onMounted(async () => {
  // === GAP-D09-005 / RISK-D09-002：从后端获取当前用户 user_id ===
  try {
    const u = await currentUserApi.get()
    if (u && u.id) currentUserId.value = u.id
  } catch { /* 失败时使用兜底默认值 */ }
  await Promise.all([loadColumns(), loadQueryFields(), loadSchemes()])
})

defineExpose({
  getConditions: buildCurrentConditions,
  getSelectedRows: () => selectedRows.value,
  clearSelection: () => tableRef.value?.clearSelection(),
  refresh: () => emit('search', buildCurrentConditions(), pageNum.value, pageSize.value)
})

// === D09 多级嵌套：递归条件节点组件（GAP-D09-001）===
// 使用 JSX-like 渲染函数定义内联组件
// 显式标注返回类型，避免循环类型推断
const ConditionNode: ReturnType<typeof defineComponent> = defineComponent({
  name: 'ConditionNode',
  props: {
    node: { type: Object as () => QueryCondition, required: true },
    fieldOptions: { type: Array as () => QueryField[], default: () => [] },
    stateOptions: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    isRoot: { type: Boolean, default: false }
  },
  emits: ['remove'],
  setup(props, { emit }) {
    function removeChild(idx: number) {
      if (props.node.children) {
        props.node.children.splice(idx, 1)
      }
    }
    function addChild(type: 'condition' | 'group') {
      if (!props.node.children) props.node.children = []
      if (type === 'condition') {
        props.node.children.push({ field_code: '', operator: '', value: '', logic: 'AND', group_type: 'condition' })
      } else {
        props.node.children.push({
          field_code: '', operator: '', value: '', logic: 'AND',
          group_type: 'group', group_logic: 'AND',
          children: [{ field_code: '', operator: '', value: '', logic: 'AND', group_type: 'condition' }]
        })
      }
    }
    function onCondFieldChange(node: QueryCondition) {
      node.operator = ''
      node.value = ''
    }
    function operatorsForField(fieldCode: string) {
      const f = props.fieldOptions.find(x => x.field_code === fieldCode)
      if (!f) return props.operators
      return props.operators.filter((o: any) => f.operators.includes(o.value))
    }
    function getFieldControl(fieldCode: string) {
      return props.fieldOptions.find(x => x.field_code === fieldCode)?.ctrl_type || 'text'
    }
    const renderNode = (node: QueryCondition, isRoot: boolean): any => {
      const isGroup = node.group_type === 'group' && node.children && node.children.length > 0
      if (isGroup) {
        const children = node.children!.map((child, idx) => {
          return h('div', { class: 'nested-child', key: idx }, [
            idx > 0 ? h('div', { class: 'child-logic-row' }, [
              h('span', { class: 'logic-divider' }, node.group_logic === 'AND' ? '且' : '或')
            ]) : null,
            h(ConditionNode as any, {
              node: child,
              fieldOptions: props.fieldOptions,
              stateOptions: props.stateOptions,
              operators: props.operators,
              isRoot: false,
              onRemove: () => removeChild(idx)
            })
          ])
        })
        return h('div', { class: 'group-node' }, [
          h('div', { class: 'group-header' }, [
            h('span', { class: 'group-bracket' }, '('),
            h('span', { class: 'group-label' }, '分组'),
            h('el-select' as any, {
              modelValue: node.group_logic,
              'onUpdate:modelValue': (v: any) => { node.group_logic = v },
              size: 'small',
              style: 'width:80px'
            }, () => [
              h('el-option' as any, { value: 'AND', label: '且(AND)' }),
              h('el-option' as any, { value: 'OR', label: '或(OR)' })
            ]),
            h('el-button' as any, {
              size: 'small', link: true, type: 'primary',
              onClick: () => addChild('condition')
            }, () => [h('el-icon' as any, () => h(Plus)), '条件']),
            h('el-button' as any, {
              size: 'small', link: true, type: 'primary',
              onClick: () => addChild('group')
            }, () => [h('el-icon' as any, () => h(Plus)), '子分组']),
            !isRoot ? h('el-button' as any, {
              size: 'small', link: true, type: 'danger',
              onClick: () => emit('remove')
            }, () => '删除分组') : null,
            h('span', { class: 'group-bracket' }, ')')
          ]),
          h('div', { class: 'group-body' }, children)
        ])
      }
      // 单条件渲染
      const ctrl = getFieldControl(node.field_code)
      const ops = operatorsForField(node.field_code)
      return h('div', { class: 'cond-row' }, [
        h('el-select' as any, {
          modelValue: node.field_code,
          'onUpdate:modelValue': (v: any) => { node.field_code = v; onCondFieldChange(node) },
          size: 'small', placeholder: '字段', style: 'width:150px'
        }, () => props.fieldOptions.map(f => h('el-option' as any, { key: f.field_code, label: f.field_name, value: f.field_code }))),
        h('el-select' as any, {
          modelValue: node.operator,
          'onUpdate:modelValue': (v: any) => { node.operator = v },
          size: 'small', placeholder: '运算符', style: 'width:110px'
        }, () => ops.map((o: any) => h('el-option' as any, { key: o.value, label: o.label, value: o.value }))),
        !['is_null', 'is_not_null'].includes(node.operator)
          ? (ctrl === 'date'
              ? h('el-date-picker' as any, {
                  modelValue: node.value,
                  'onUpdate:modelValue': (v: any) => { node.value = v },
                  type: node.operator === 'between' ? 'daterange' : 'date',
                  valueFormat: 'YYYY-MM-DD',
                  size: 'small', style: 'width:220px', placeholder: '选择日期'
                })
              : ctrl === 'select'
                ? h('el-select' as any, {
                    modelValue: node.value,
                    'onUpdate:modelValue': (v: any) => { node.value = v },
                    size: 'small', multiple: node.operator === 'in',
                    style: 'width:180px', placeholder: '选择'
                  }, () => props.stateOptions.map((s: any) => h('el-option' as any, { key: s.value, label: s.label, value: s.value })))
                : h('el-input' as any, {
                    modelValue: node.value,
                    'onUpdate:modelValue': (v: any) => { node.value = v },
                    size: 'small', style: 'width:180px', placeholder: '输入值'
                  }))
          : null,
        !isRoot ? h('el-button' as any, {
          size: 'small', link: true, type: 'danger',
          onClick: () => emit('remove')
        }, () => [h('el-icon' as any, () => h(Delete))]) : null
      ])
    }
    return () => renderNode(props.node, props.isRoot)
  }
})
</script>

<style scoped lang="scss">
.list-query {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #fff;
}
.query-bar {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 8px 12px;
  border-bottom: 1px solid #ebeef5;
  flex-wrap: wrap;
  gap: 8px;
}
.query-form {
  :deep(.el-form-item) { margin-bottom: 4px; margin-right: 8px; }
}
.query-tools {
  display: flex;
  gap: 6px;
  align-items: center;
  flex-shrink: 0;
}
.adv-badge { margin-left: 4px; }
:deep(.el-table) {
  flex: 1;
  .cell-amount { color: #1564ff; font-weight: 500; }
  .cell-qty { color: #333; }
}
.query-pagination {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 12px;
  border-top: 1px solid #ebeef5;
  gap: 12px;
}
.selected-info {
  color: #1564ff;
  font-size: 12px;
}
.col-setting {
  max-height: 320px;
  overflow: auto;
  .col-setting-title {
    font-weight: 600;
    margin-bottom: 8px;
    padding-bottom: 6px;
    border-bottom: 1px solid #ebeef5;
  }
  .col-setting-row { padding: 2px 0; }
  .col-setting-footer {
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px solid #ebeef5;
    display: flex;
    justify-content: flex-end;
    gap: 8px;
  }
}
.adv-query {
  .adv-toolbar {
    margin-bottom: 12px;
    display: flex;
    gap: 8px;
    align-items: center;
    flex-wrap: wrap;
    .adv-tip { font-size: 12px; color: #909399; margin-left: 8px; }
  }
  .adv-tree { display: flex; flex-direction: column; gap: 8px; min-height: 120px; }
  .group-node {
    border: 1px solid #d9ecff;
    border-radius: 4px;
    padding: 8px;
    background: #f5faff;
    .group-header {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-bottom: 8px;
      flex-wrap: wrap;
      .group-bracket { font-size: 18px; color: #1564ff; font-weight: 600; }
      .group-label { font-size: 12px; color: #1564ff; font-weight: 600; }
    }
    .group-body { display: flex; flex-direction: column; gap: 6px; padding-left: 16px; }
    .nested-child {
      .child-logic-row {
        margin: 4px 0;
        .logic-divider {
          display: inline-block;
          padding: 2px 8px;
          background: #e6f1ff;
          color: #1564ff;
          border-radius: 3px;
          font-size: 12px;
          font-weight: 600;
        }
      }
    }
  }
  .cond-row {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 6px;
    background: #fafafa;
    border-radius: 3px;
  }
}
.col-dialog-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
</style>
