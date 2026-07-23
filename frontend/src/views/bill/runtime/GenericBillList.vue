<template>
  <div class="generic-bill-list-page">
    <!-- 顶部工具栏 -->
    <div class="page-header panel-card">
      <BillToolbar
        :pact-state="1"
        position="list"
        :selected-count="selectedRows.length"
        @click="onToolbarClick"
      />
    </div>

    <!-- 查询区 -->
    <div class="query-bar panel-card">
      <el-form :inline="true" size="small">
        <!-- 常用查询字段：动态渲染 -->
        <el-form-item
          v-for="qf in commonQueryFields"
          :key="qf.field_code"
          :label="qf.field_name"
        >
          <!-- 单据状态 -->
          <el-select
            v-if="qf.field_code === 'pact_state' || qf.ctrl_type === 'select'"
            v-model="query[qf.field_code]"
            clearable
            :placeholder="'全部'"
            style="width:140px"
          >
            <el-option
              v-for="s in getEnumOptions(qf)"
              :key="s.value"
              :label="s.label"
              :value="s.value"
            />
          </el-select>
          <!-- 日期：支持 between 时用日期范围选择器 -->
          <el-date-picker
            v-else-if="qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime'"
            v-model="query[qf.field_code]"
            :type="hasBetweenOp(qf) ? 'daterange' : 'date'"
            value-format="YYYY-MM-DD"
            :range-separator="hasBetweenOp(qf) ? '至' : undefined"
            :start-placeholder="hasBetweenOp(qf) ? '开始日期' : undefined"
            :end-placeholder="hasBetweenOp(qf) ? '结束日期' : undefined"
            clearable
            :style="hasBetweenOp(qf) ? 'width:260px' : 'width:160px'"
          />
          <!-- 数值 / 金额 / 数量 -->
          <el-input-number
            v-else-if="qf.ctrl_type === 'number' || qf.ctrl_type === 'amount' || qf.ctrl_type === 'qty'"
            v-model="query[qf.field_code]"
            controls-position="right"
            style="width:160px"
          />
          <!-- 基础资料引用（ref）：下拉搜索选择 -->
          <el-select
            v-else-if="qf.ctrl_type === 'ref'"
            v-model="query[qf.field_code]"
            filterable
            remote
            :remote-method="(q: string) => loadRefOptions(qf, q)"
            :loading="refLoadingMap[qf.ref_bo_code || '']"
            clearable
            :placeholder="`选择${qf.field_name}`"
            style="width:200px"
            @visible-change="(v: boolean) => v && !refOptionsMap[qf.ref_bo_code || '']?.length && loadRefOptions(qf, '')"
          >
            <el-option
              v-for="opt in refOptionsMap[qf.ref_bo_code || ''] || []"
              :key="opt.value"
              :label="opt.label"
              :value="opt.value"
            />
          </el-select>
          <!-- 默认文本输入 -->
          <el-input
            v-else
            v-model="query[qf.field_code]"
            :placeholder="`${qf.field_name}模糊查`"
            clearable
            style="width:180px"
            @keyup.enter="onSearch"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
          <el-button v-if="advancedQueryFields.length" @click="showAdvanced = true">
            <el-icon><Search /></el-icon>高级查询
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 高级查询弹窗 -->
    <el-dialog v-model="showAdvanced" title="高级查询" width="600px" destroy-on-close>
      <el-form :model="advancedForm" label-width="100px" size="small">
        <el-form-item
          v-for="qf in advancedQueryFields"
          :key="qf.field_code"
          :label="qf.field_name"
        >
          <div style="display:flex;gap:8px;width:100%;flex-wrap:wrap">
            <el-select v-model="advancedForm[qf.field_code + '_op']" style="width:120px" @change="onAdvOpChange(qf)">
              <el-option
                v-for="op in availableOps(qf)"
                :key="op.value"
                :label="op.label"
                :value="op.value"
              />
            </el-select>
            <!-- between：两个输入框（日期/数值） -->
            <template v-if="advancedForm[qf.field_code + '_op'] === 'between'">
              <el-date-picker
                v-if="qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime'"
                v-model="advancedForm[qf.field_code]"
                type="date"
                value-format="YYYY-MM-DD"
                placeholder="开始日期"
                style="width:150px"
              />
              <el-input v-else v-model="advancedForm[qf.field_code]" placeholder="起始值" style="width:120px" />
              <span style="line-height:32px">—</span>
              <el-date-picker
                v-if="qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime'"
                v-model="advancedForm[qf.field_code + '_end']"
                type="date"
                value-format="YYYY-MM-DD"
                placeholder="结束日期"
                style="width:150px"
              />
              <el-input v-else v-model="advancedForm[qf.field_code + '_end']" placeholder="结束值" style="width:120px" />
            </template>
            <!-- is_null / is_not_null 不需要输入 -->
            <span v-else-if="['is_null','is_not_null'].includes(advancedForm[qf.field_code + '_op'])" style="line-height:32px;color:#909399">无需输入</span>
            <!-- 普通单值输入 -->
            <template v-else>
              <el-date-picker
                v-if="qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime'"
                v-model="advancedForm[qf.field_code]"
                type="date"
                value-format="YYYY-MM-DD"
                :placeholder="`请选择${qf.field_name}`"
                style="flex:1"
              />
              <el-input-number
                v-else-if="qf.ctrl_type === 'number' || qf.ctrl_type === 'amount' || qf.ctrl_type === 'qty'"
                v-model="advancedForm[qf.field_code]"
                controls-position="right"
                :placeholder="`请输入${qf.field_name}`"
                style="flex:1"
              />
              <el-select
                v-else-if="qf.field_code === 'pact_state' || qf.ctrl_type === 'select'"
                v-model="advancedForm[qf.field_code]"
                :placeholder="'全部'"
                style="flex:1"
              >
                <el-option v-for="s in getEnumOptions(qf)" :key="s.value" :label="s.label" :value="s.value" />
              </el-select>
              <!-- 基础资料引用 -->
              <el-select
                v-else-if="qf.ctrl_type === 'ref'"
                v-model="advancedForm[qf.field_code]"
                filterable
                remote
                :remote-method="(q: string) => loadRefOptions(qf, q)"
                :loading="refLoadingMap[qf.ref_bo_code || '']"
                clearable
                :placeholder="`选择${qf.field_name}`"
                style="flex:1"
                @visible-change="(v: boolean) => v && !refOptionsMap[qf.ref_bo_code || '']?.length && loadRefOptions(qf, '')"
              >
                <el-option
                  v-for="opt in refOptionsMap[qf.ref_bo_code || ''] || []"
                  :key="opt.value"
                  :label="opt.label"
                  :value="opt.value"
                />
              </el-select>
              <el-input
                v-else
                v-model="advancedForm[qf.field_code]"
                :placeholder="`请输入${qf.field_name}`"
                style="flex:1"
              />
            </template>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAdvanced = false">取消</el-button>
        <el-button type="primary" @click="onAdvancedSearch">查询</el-button>
      </template>
    </el-dialog>

    <!-- 表格 -->
    <div class="table-body panel-card">
      <el-table
        :data="tableData"
        border
        size="small"
        height="100%"
        highlight-current-row
        @row-click="onRowClick"
        @selection-change="onSelectionChange"
      >
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="#" width="50" />
        <el-table-column
          v-for="col in columns"
          :key="col.field_code + (col.entity_code || '')"
          :prop="fieldKey(col)"
          :label="columnLabel(col)"
          :width="col.column_width || 140"
          :fixed="col.is_fixed !== 'none' ? col.is_fixed : false"
          show-overflow-tooltip
        >
          <template #default="{ row }">
            <template v-if="col.field_code === 'pact_state' && !fieldPrefix(col.entity_code)">
              <el-tag size="small" :type="stateTagType(row.pact_state)" effect="dark">
                {{ stateLabel(row.pact_state) }}
              </el-tag>
            </template>
            <!-- ref 类型列优先显示后端补充的 _name 字段，没有时 fallback 到 ID -->
            <template v-else-if="col.ctrl_type === 'ref'">{{ row[fieldKey(col) + '_name'] ?? row[fieldKey(col)] }}</template>
            <!-- 布尔字段：0/1 → 否/是 -->
            <template v-else-if="col.ctrl_type === 'checkbox' || col.field_code === 'is_closed' || col.field_code === 'is_cancel'">{{ ['否','是'][Number(row[fieldKey(col)])] || row[fieldKey(col)] }}</template>
            <template v-else>{{ row[fieldKey(col)] }}</template>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination-bar panel-card">
      <el-pagination
        v-model:current-page="page.pageNum"
        v-model:page-size="page.pageSize"
        :page-sizes="[20, 50, 100, 200]"
        :total="page.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadData"
        @current-change="loadData"
      />
    </div>

    <!-- 下推对话框 -->
    <PushDialog
      v-model="pushVisible"
      :src-bo-code="boCode"
      :src-bill-id="pushBillId"
      @success="onPushSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import BillToolbar from '@/components/BillToolbar/index.vue'
import PushDialog from '@/components/PushDialog/index.vue'
import { billApi } from '@/api/bill'
import { listConfigApi } from '@/api/list'
import { entityApi } from '@/api/bo'
import { PACT_STATE_MAP, PACT_STATE_LIST, QUERY_OPERATORS } from '@/utils/enum'
import type { ListColumn, QueryField, FormEntity } from '@/types/bo'

const route = useRoute()
const router = useRouter()

const boCode = computed(() => String(route.params.boCode || ''))

const columns = ref<ListColumn[]>([])
const entities = ref<FormEntity[]>([])
const tableData = ref<any[]>([])
const selectedRows = ref<any[]>([])

// 下推对话框
const pushVisible = ref(false)
const pushBillId = ref<string>('')

// ========== 查询字段（动态加载） ==========
const queryFields = ref<QueryField[]>([])

/** 常用查询字段（is_common=1） */
const commonQueryFields = computed(() =>
  queryFields.value.filter(f => f.is_common).sort((a, b) => a.sort_index - b.sort_index)
)

/** 高级查询字段（is_advanced=1） */
const advancedQueryFields = computed(() =>
  queryFields.value.filter(f => f.is_advanced).sort((a, b) => a.sort_index - b.sort_index)
)

// ========== ref 类型字段下拉选项缓存 ==========
// key: ref_bo_code, value: [{value, label}]
const refOptionsMap = reactive<Record<string, { value: string | number; label: string }[]>>({})
const refLoadingMap = reactive<Record<string, boolean>>({})
const refOptionsLoaded = reactive<Record<string, boolean>>({})

/** 加载 ref 类型主数据下拉选项（带搜索过滤） */
async function loadRefOptions(qf: QueryField, keyword: string) {
  const refBo = qf.ref_bo_code
  if (!refBo) return
  // 已加载过全量，前端本地过滤
  if (refOptionsLoaded[refBo] && keyword) return
  refLoadingMap[refBo] = true
  try {
    const params: any = { pageSize: 200 }
    // 如果传了关键词，用 code 模糊查
    if (keyword) params.code = keyword
    const res = await billApi.list(refBo, params)
    const list: any[] = res?.list || []
    refOptionsMap[refBo] = list.map((r: any) => ({
      value: r.id,
      label: r.name || r.code || r.cn_name || `#${r.id}`
    }))
    if (!keyword) refOptionsLoaded[refBo] = true
  } catch {
    refOptionsMap[refBo] = []
  } finally {
    refLoadingMap[refBo] = false
  }
}

// 动态查询对象：新增字段时自动有响应式属性
const query = reactive<Record<string, any>>({})

// 高级查询弹窗
const showAdvanced = ref(false)
const advancedForm = reactive<Record<string, any>>({})

/** 判断字段是否支持 between 运算符 */
function hasBetweenOp(qf: QueryField): boolean {
  return parseOperators(qf).includes('between')
}

/** 初始化所有查询字段的 query 属性 */
function initQuery() {
  const keys = Object.keys(query)
  keys.forEach(k => delete query[k])
  for (const qf of queryFields.value) {
    query[qf.field_code] = hasBetweenOp(qf) && (qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime') ? [] : ''
  }
}

/** 高级查询表单：切换运算符时清空值 */
function onAdvOpChange(qf: QueryField) {
  advancedForm[qf.field_code] = ''
  advancedForm[qf.field_code + '_end'] = ''
}

/** 初始化高级查询表单默认值 */
function initAdvancedForm() {
  const keys = Object.keys(advancedForm)
  keys.forEach(k => delete advancedForm[k])
  for (const qf of queryFields.value) {
    advancedForm[qf.field_code] = ''
    const ops = parseOperators(qf)
    advancedForm[qf.field_code + '_op'] = qf.default_op || ops[0] || 'eq'
  }
}

/** 解析逗号分隔的运算符字符串为数组 */
function parseOperators(qf: QueryField): string[] {
  if (!qf.operators) return ['eq', 'like']
  if (Array.isArray(qf.operators)) return qf.operators as unknown as string[]
  return String(qf.operators).split(',').map((s: string) => s.trim()).filter(Boolean)
}

/** 获取字段支持的运算符选项 */
function availableOps(qf: QueryField) {
  const allowed = parseOperators(qf)
  return QUERY_OPERATORS.filter(op => allowed.includes(op.value))
}

/** 获取枚举选项（pact_state 用内置，select 类型暂兜底） */
function getEnumOptions(qf: QueryField) {
  if (qf.field_code === 'pact_state' || qf.enum_code === 'PACT_STATE') {
    return PACT_STATE_LIST
  }
  return []
}

/**
 * 根据列的 entity_code 获取结果集中的字段前缀。
 * 主表 → ""，子表 → "sub_"，孙表 → "grand_"
 * 后端 pageJoin 自动 JOIN 时，子表/孙表字段以 sub_/grand_ 前缀返回。
 */
function fieldPrefix(entityCode?: string): string {
  if (!entityCode) return ''
  const entity = entities.value.find(e => e.entity_code === entityCode)
  if (!entity) return ''
  if (entity.entity_type === 'main' || entity.entity_level === 0) return ''
  if (entity.entity_type === 'sub' || entity.entity_level === 1) return 'sub_'
  return 'grand_'
}

/** 列在结果集中的完整 key：前缀 + field_code */
function fieldKey(col: ListColumn): string {
  return fieldPrefix(col.entity_code) + col.field_code
}

/** 列标签：子表/孙表字段加"明细-"/"孙表-"前缀 */
function columnLabel(col: ListColumn): string {
  const prefix = fieldPrefix(col.entity_code)
  if (!prefix) return col.field_name
  if (prefix === 'sub_') return `明细-${col.field_name}`
  return `孙表-${col.field_name}`
}

const page = reactive({
  pageNum: 1,
  pageSize: 20,
  total: 0
})

const billTitle = computed(() => {
  const main = entities.value.find(e => e.entity_type === 'main')
  return main?.entity_name || boCode.value
})

function stateLabel(code: number): string {
  return PACT_STATE_MAP[code]?.label || String(code)
}

function stateTagType(code: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  return (PACT_STATE_MAP[code]?.type as any) || 'info'
}

async function loadColumns() {
  try {
    const cols = await listConfigApi.columns(boCode.value)
    columns.value = (cols || []).filter(c => c.is_show).sort((a, b) => a.sort_index - b.sort_index)
  } catch {
    columns.value = []
  }
  // 列表字段配置为空时，从实体元数据兜底取主表前 8 个非隐藏字段
  if (!columns.value.length) {
    if (!entities.value.length) {
      entities.value = await entityApi.list(boCode.value)
    }
    const main = entities.value.find(e => e.entity_type === 'main')
    if (main) {
      columns.value = main.fields
        .filter(f => !f.is_hidden)
        .slice(0, 8)
        .map((f, idx) => ({
          id: '',
          bo_code: boCode.value,
          field_code: f.field_code,
          field_name: f.field_name,
          ctrl_type: f.ctrl_type,
          is_show: true,
          is_fixed: 'none' as const,
          column_width: 140,
          sort_index: idx,
          is_sum: false,
          is_avg: false
        }))
    }
  }
}

/** 构建结构化查询条件数组 */
function buildConditions(extraParams?: Record<string, any>): any[] {
  const conditions: any[] = []
  const handled = new Set<string>()

  // 常用查询字段
  for (const qf of queryFields.value) {
    const v = query[qf.field_code]
    if (Array.isArray(v)) {
      // daterange 返回数组 [start, end]，生成 between 条件
      if (v.length === 2 && v[0] && v[1]) {
        conditions.push({
          field_code: qf.field_code,
          operator: 'between',
          value_start: v[0],
          value_end: v[1]
        })
      }
      handled.add(qf.field_code)
    } else if (v !== '' && v !== null && v !== undefined) {
      conditions.push({
        field_code: qf.field_code,
        operator: extraParams?.[qf.field_code + '_op'] || qf.default_op || 'eq',
        value: v
      })
      handled.add(qf.field_code)
    }
  }

  // 高级查询额外参数
  if (extraParams) {
    for (const qf of queryFields.value) {
      if (handled.has(qf.field_code)) continue
      const v = extraParams[qf.field_code]
      if (v !== '' && v !== null && v !== undefined) {
        const op = extraParams[qf.field_code + '_op'] || qf.default_op || 'eq'
        const cond: any = { field_code: qf.field_code, operator: op }
        if (op === 'between') {
          cond.value_start = v
          cond.value_end = extraParams[qf.field_code + '_end']
        } else {
          cond.value = v
        }
        conditions.push(cond)
      }
    }
  }

  return conditions
}

async function loadData(extraParams?: Record<string, any>) {
  try {
    const params: any = {
      conditions: buildConditions(extraParams),
      pageNum: page.pageNum,
      pageSize: page.pageSize
    }
    const res = await billApi.query(boCode.value, params)
    tableData.value = res?.list || []
    page.total = res?.total || 0
  } catch {
    tableData.value = []
    page.total = 0
  }
}

function onSearch() {
  page.pageNum = 1
  loadData()
}

function onReset() {
  for (const qf of queryFields.value) {
    query[qf.field_code] = hasBetweenOp(qf) && (qf.ctrl_type === 'date' || qf.ctrl_type === 'datetime') ? [] : ''
  }
  page.pageNum = 1
  loadData()
}

/** 高级查询：将高级查询表单值合并到 query 中执行 */
function onAdvancedSearch() {
  showAdvanced.value = false
  page.pageNum = 1
  const extra: Record<string, any> = {}
  for (const qf of queryFields.value) {
    const op = advancedForm[qf.field_code + '_op']
    if (op === 'between') {
      // 日期区间：value_start / value_end
      const start = advancedForm[qf.field_code]
      const end = advancedForm[qf.field_code + '_end']
      if (start !== '' && start !== null && start !== undefined) {
        extra[qf.field_code] = start
        extra[qf.field_code + '_op'] = op
        extra[qf.field_code + '_end'] = end
      }
    } else if (op === 'is_null' || op === 'is_not_null') {
      // 为空/不为空不需要值
      extra[qf.field_code] = ''
      extra[qf.field_code + '_op'] = op
    } else {
      const v = advancedForm[qf.field_code]
      if (v !== '' && v !== null && v !== undefined) {
        extra[qf.field_code] = v
        extra[qf.field_code + '_op'] = op
      }
    }
  }
  loadData(extra)
}

function onRowClick(row: any) {
  if (row?.id) {
    router.push(`/bill/${boCode.value}/${row.id}`)
  }
}

function onSelectionChange(sel: any[]) {
  selectedRows.value = sel
}

// 下推成功后刷新列表（已下推量回写）
function onPushSuccess() {
  loadData()
}

async function onToolbarClick(buttonCode: string) {
  switch (buttonCode) {
    case 'add':
      router.push(`/bill/${boCode.value}/new`)
      break
    case 'copy':
      if (selectedRows.value.length !== 1) {
        ElMessage.warning('请选择一行进行复制')
        return
      }
      router.push(`/bill/${boCode.value}/new?copyFrom=${selectedRows.value[0].id}`)
      break
    case 'delete':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择要删除的单据')
        return
      }
      ElMessage.info('批量删除功能待实现')
      break
    case 'trace':
      if (selectedRows.value.length !== 1) {
        ElMessage.warning('请选择一行进行联查')
        return
      }
      router.push(`/bill/${boCode.value}/${selectedRows.value[0].id}?tab=trace`)
      break
    case 'push':
      if (selectedRows.value.length !== 1) {
        ElMessage.warning('请选择一行进行下推')
        return
      }
      pushBillId.value = String(selectedRows.value[0].id)
      pushVisible.value = true
      break
    case 'print':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择要打印的单据')
        return
      }
      ElMessage.info(`打印功能待实现（选中 ${selectedRows.value.length} 条，请先在打印模板设计器配置模板）`)
      break
    default:
      ElMessage.info(`操作：${buttonCode}`)
  }
}

onMounted(async () => {
  if (!boCode.value) return
  // 加载实体元数据（用于标题与列表字段兜底）
  try {
    entities.value = await entityApi.list(boCode.value)
  } catch {
    // 忽略
  }
  // 加载查询字段配置（常用查询 / 高级查询）
  try {
    const qfs = await listConfigApi.queryFields(boCode.value)
    // 从实体元数据构建 field_code → {ctrl_type, ref_bo_code} 映射（后端 meta_query_field 表不存这些）
    const fieldMetaMap: Record<string, { ctrl_type: string; ref_bo_code?: string }> = {}
    for (const e of entities.value) {
      for (const f of (e.fields || [])) {
        if (f.field_code) {
          fieldMetaMap[f.field_code] = { ctrl_type: f.ctrl_type, ref_bo_code: f.ref_bo_code }
        }
      }
    }
    // normalize + 合并元数据
    queryFields.value = (Array.isArray(qfs) ? qfs : []).map((f: any) => ({
      ...f,
      is_common: !!f.is_common,
      is_advanced: !!f.is_advanced,
      operators: typeof f.operators === 'string' && f.operators
        ? f.operators.split(',').map((s: string) => s.trim()).filter(Boolean)
        : Array.isArray(f.operators) ? f.operators : [],
      ctrl_type: f.ctrl_type || fieldMetaMap[f.field_code]?.ctrl_type || 'text',
      ref_bo_code: f.ref_bo_code || fieldMetaMap[f.field_code]?.ref_bo_code
    }))
    initQuery()
    initAdvancedForm()
  } catch {
    queryFields.value = []
  }
  await loadColumns()
  await loadData()
})
</script>

<style scoped lang="scss">
.generic-bill-list-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  gap: 12px;
}
.page-header {
  display: flex;
  align-items: center;
  gap: 16px;
}
.query-bar {
  :deep(.el-form-item) {
    margin-bottom: 0;
  }
}
.table-body {
  flex: 1;
  overflow: auto;
  min-height: 0;
}
.pagination-bar {
  display: flex;
  justify-content: flex-end;
  padding: 8px;
}
</style>
