<template>
  <div class="sal-order-list-page">
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
        <el-form-item label="单据编号">
          <el-input
            v-model="query.bill_no"
            placeholder="编号模糊查"
            clearable
            style="width:180px"
            @keyup.enter="onSearch"
          />
        </el-form-item>
        <el-form-item label="客户名称">
          <el-input
            v-model="query.cust_name"
            placeholder="客户模糊查"
            clearable
            style="width:180px"
            @keyup.enter="onSearch"
          />
        </el-form-item>
        <el-form-item label="单据状态">
          <el-select
            v-model="query.pact_state"
            clearable
            placeholder="全部"
            style="width:140px"
          >
            <el-option
              v-for="s in PACT_STATE_LIST"
              :key="s.value"
              :label="s.label"
              :value="s.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="订单日期">
          <el-date-picker
            v-model="query.dateRange"
            type="daterange"
            value-format="YYYY-MM-DD"
            range-separator="至"
            start-placeholder="开始"
            end-placeholder="结束"
            style="width:240px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="onSearch">查询</el-button>
          <el-button :icon="RefreshLeft" @click="onReset">重置</el-button>
          <el-button link type="primary" @click="advancedVisible = true">
            <el-icon><Filter /></el-icon>高级查询
            <el-badge v-if="advancedConditions.length" is-dot class="adv-dot" />
          </el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表区 -->
    <div class="table-panel panel-card">
      <el-table
        :data="tableData"
        border
        size="small"
        row-key="id"
        v-loading="loading"
        show-summary
        :summary-method="getSummaries"
        @selection-change="onSelectionChange"
        @row-click="onRowClick"
        height="100%"
      >
        <el-table-column type="selection" width="42" fixed="left" />
        <el-table-column type="index" label="#" width="50" fixed="left" />
        <el-table-column label="单据编号" width="160" fixed="left" prop="bill_no">
          <template #default="{ row }">
            <el-button link type="primary" size="small" class="code-link" @click.stop="goDetail(row as any)">
              {{ row.bill_no }}
            </el-button>
          </template>
        </el-table-column>
        <el-table-column label="订单日期" width="110" prop="order_date" />
        <el-table-column label="客户名称" min-width="140" prop="cust_name" show-overflow-tooltip />
        <el-table-column label="总数量" width="100" align="right" prop="total_qty">
          <template #default="{ row }">
            <span class="cell-qty">{{ formatQty(row.total_qty) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="总金额" width="120" align="right" prop="total_amount">
          <template #default="{ row }">
            <span class="cell-amount">{{ formatNumber(row.total_amount) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="业务员" width="90" prop="salesman_name" />
        <el-table-column label="单据状态" width="90" align="center" prop="pact_state">
          <template #default="{ row }">
            <el-tag :type="pactStateType(row.pact_state)" size="small" effect="light">
              {{ pactStateLabel(row.pact_state) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="已关闭" width="70" align="center" prop="is_closed">
          <template #default="{ row }">
            <el-tag :type="row.is_closed ? 'success' : 'info'" size="small" effect="plain">
              {{ row.is_closed ? '已关闭' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="已取消" width="70" align="center" prop="is_cancel">
          <template #default="{ row }">
            <el-tag :type="row.is_cancel ? 'danger' : 'info'" size="small" effect="plain">
              {{ row.is_cancel ? '已取消' : '否' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="150" prop="create_time" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click.stop="goDetail(row as any)">查看</el-button>
            <el-button link type="danger" size="small" @click.stop="onRowDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination-bar panel-card">
      <el-pagination
        v-model:current-page="query.pageNum"
        v-model:page-size="query.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        background
        @size-change="onSizeChange"
        @current-change="onPageChange"
      />
    </div>

    <!-- 高级查询弹窗 -->
    <el-dialog v-model="advancedVisible" title="高级查询" width="780px" append-to-body destroy-on-close>
      <div class="adv-query">
        <div class="adv-toolbar">
          <el-button size="small" type="primary" @click="onAddCondition"><el-icon><Plus /></el-icon>添加条件</el-button>
          <el-button size="small" @click="onAddGroup"><el-icon><Plus /></el-icon>添加分组</el-button>
          <el-button size="small" link type="danger" @click="advancedConditions = []">清空</el-button>
        </div>
        <div class="adv-list">
          <div v-for="(cond, idx) in advancedConditions" :key="idx" class="adv-row">
            <el-select v-model="cond.logic" size="small" style="width:80px" :disabled="idx === 0">
              <el-option value="AND" label="且" />
              <el-option value="OR" label="或" />
            </el-select>
            <span v-if="cond.group === 1" class="group-bracket">(</span>
            <el-select
              v-model="cond.field_code"
              size="small"
              placeholder="选择字段"
              style="width:150px"
              @change="onCondFieldChange(cond)"
            >
              <el-option
                v-for="f in advFields"
                :key="f.value"
                :label="f.label"
                :value="f.value"
              />
            </el-select>
            <el-select
              v-model="cond.operator"
              size="small"
              placeholder="运算符"
              style="width:110px"
            >
              <el-option
                v-for="op in operatorsForField(cond.field_code)"
                :key="op.value"
                :label="op.label"
                :value="op.value"
              />
            </el-select>
            <template v-if="!['is_null', 'is_not_null'].includes(cond.operator)">
              <el-date-picker
                v-if="getFieldType(cond.field_code) === 'date'"
                v-model="cond.value"
                :type="cond.operator === 'between' ? 'daterange' : 'date'"
                value-format="YYYY-MM-DD"
                size="small"
                style="width:220px"
                placeholder="选择日期"
              />
              <el-select
                v-else-if="getFieldType(cond.field_code) === 'select'"
                v-model="cond.value"
                size="small"
                :multiple="cond.operator === 'in'"
                style="width:180px"
                placeholder="选择"
              >
                <el-option
                  v-for="s in PACT_STATE_LIST"
                  :key="s.value"
                  :label="s.label"
                  :value="s.value"
                />
              </el-select>
              <el-input
                v-else
                v-model="cond.value"
                size="small"
                style="width:180px"
                placeholder="输入值"
              />
            </template>
            <span v-if="cond.group === 2" class="group-bracket">)</span>
            <el-button size="small" link type="danger" @click="advancedConditions.splice(idx, 1)">
              <el-icon><Delete /></el-icon>
            </el-button>
          </div>
          <el-empty v-if="!advancedConditions.length" description="点击添加条件构建查询" :image-size="60" />
        </div>
        <!-- 已应用的查询条件摘要 -->
        <div v-if="appliedConditions.length" class="applied-summary">
          <el-divider content-position="left">已应用条件</el-divider>
          <el-tag
            v-for="(c, i) in appliedConditions"
            :key="i"
            closable
            size="small"
            class="applied-tag"
            @close="removeAppliedCondition(i)"
          >
            {{ c.label }}
          </el-tag>
        </div>
      </div>
      <template #footer>
        <el-button @click="advancedVisible = false">取消</el-button>
        <el-button type="primary" @click="onAdvancedSearch">查询</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, RefreshLeft, Filter, Plus, Delete } from '@element-plus/icons-vue'
import BillToolbar from '@/components/BillToolbar/index.vue'
import { billApi } from '@/api/bill'
import { PACT_STATE_MAP, PACT_STATE_LIST } from '@/utils/enum'

const router = useRouter()

const query = reactive({
  bill_no: '',
  cust_name: '',
  pact_state: undefined as number | undefined,
  dateRange: [] as string[],
  pageNum: 1,
  pageSize: 20
})

const tableData = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const selectedRows = ref<any[]>([])

// ============ 高级查询 ============
interface AdvCondition {
  logic: 'AND' | 'OR'
  field_code: string
  operator: string
  value: any
  group: 0 | 1 | 2  // 0=普通, 1=分组开始, 2=分组结束
}

const advancedVisible = ref(false)
const advancedConditions = ref<AdvCondition[]>([])
const appliedConditions = ref<{ label: string; condition: AdvCondition }[]>([])

// 高级查询可用字段
const advFields = [
  { value: 'bill_no', label: '单据编号', type: 'text' },
  { value: 'cust_name', label: '客户名称', type: 'text' },
  { value: 'order_date', label: '订单日期', type: 'date' },
  { value: 'total_qty', label: '总数量', type: 'number' },
  { value: 'total_amount', label: '总金额', type: 'number' },
  { value: 'salesman_name', label: '业务员', type: 'text' },
  { value: 'pact_state', label: '单据状态', type: 'select' },
  { value: 'is_closed', label: '已关闭', type: 'select' },
  { value: 'is_cancel', label: '已取消', type: 'select' },
  { value: 'create_time', label: '创建时间', type: 'date' }
]

// 运算符定义
const ALL_OPERATORS = [
  { value: 'eq', label: '等于' },
  { value: 'ne', label: '不等于' },
  { value: 'like', label: '包含' },
  { value: 'not_like', label: '不包含' },
  { value: 'gt', label: '大于' },
  { value: 'gte', label: '大于等于' },
  { value: 'lt', label: '小于' },
  { value: 'lte', label: '小于等于' },
  { value: 'between', label: '介于' },
  { value: 'in', label: '属于' },
  { value: 'is_null', label: '为空' },
  { value: 'is_not_null', label: '不为空' }
]

function operatorsForField(fieldCode: string) {
  const field = advFields.find(f => f.value === fieldCode)
  if (!field) return ALL_OPERATORS
  switch (field.type) {
    case 'text':
      return ALL_OPERATORS.filter(o => ['eq', 'ne', 'like', 'not_like', 'in', 'is_null', 'is_not_null'].includes(o.value))
    case 'number':
      return ALL_OPERATORS.filter(o => ['eq', 'ne', 'gt', 'gte', 'lt', 'lte', 'between', 'is_null', 'is_not_null'].includes(o.value))
    case 'date':
      return ALL_OPERATORS.filter(o => ['eq', 'gt', 'gte', 'lt', 'lte', 'between', 'is_null', 'is_not_null'].includes(o.value))
    case 'select':
      return ALL_OPERATORS.filter(o => ['eq', 'ne', 'in', 'is_null', 'is_not_null'].includes(o.value))
    default:
      return ALL_OPERATORS
  }
}

function getFieldType(fieldCode: string): string {
  return advFields.find(f => f.value === fieldCode)?.type || 'text'
}

function onCondFieldChange(cond: AdvCondition) {
  const ops = operatorsForField(cond.field_code)
  if (!ops.find(o => o.value === cond.operator)) {
    cond.operator = ops[0]?.value || 'eq'
  }
  cond.value = ''
}

function onAddCondition() {
  advancedConditions.value.push({
    logic: advancedConditions.value.length === 0 ? 'AND' : 'AND',
    field_code: '',
    operator: 'eq',
    value: '',
    group: 0
  })
}

function onAddGroup() {
  advancedConditions.value.push({
    logic: 'AND',
    field_code: '',
    operator: 'eq',
    value: '',
    group: 1  // 分组开始
  })
  advancedConditions.value.push({
    logic: 'AND',
    field_code: '',
    operator: 'eq',
    value: '',
    group: 2  // 分组结束
  })
}

function buildConditionLabel(c: AdvCondition): string {
  const field = advFields.find(f => f.value === c.field_code)
  const op = ALL_OPERATORS.find(o => o.value === c.operator)
  const fieldName = field?.label || c.field_code
  const opLabel = op?.label || c.operator
  if (['is_null', 'is_not_null'].includes(c.operator)) {
    return `${fieldName} ${opLabel}`
  }
  return `${fieldName} ${opLabel} ${c.value}`
}

function onAdvancedSearch() {
  // 过滤掉无效条件和空分组
  const valid = advancedConditions.value.filter(c => c.field_code && (c.group > 0 || c.value !== '' || ['is_null', 'is_not_null'].includes(c.operator)))
  if (!valid.length) {
    ElMessage.warning('请至少添加一个有效查询条件')
    return
  }
  appliedConditions.value = valid
    .filter(c => c.group === 0)
    .map(c => ({ label: buildConditionLabel(c), condition: c }))
  advancedVisible.value = false
  query.pageNum = 1
  loadData()
}

function removeAppliedCondition(idx: number) {
  appliedConditions.value.splice(idx, 1)
  // 同步从 advancedConditions 中移除
  const cond = appliedConditions.value[idx]
  if (cond) {
    const advIdx = advancedConditions.value.findIndex(c => c === cond.condition)
    if (advIdx > -1) advancedConditions.value.splice(advIdx, 1)
  }
  query.pageNum = 1
  loadData()
}

// ============ 数据加载 ============
function formatNumber(v: any) {
  if (v == null || v === '') return ''
  const n = Number(v)
  return isNaN(n) ? v : n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function formatQty(v: any) {
  if (v == null || v === '') return ''
  const n = Number(v)
  return isNaN(n) ? v : n.toLocaleString('zh-CN')
}

function pactStateType(s: number) {
  return PACT_STATE_MAP[s]?.type || 'info'
}

function pactStateLabel(s: number) {
  return PACT_STATE_MAP[s]?.label || ''
}

async function loadData() {
  loading.value = true
  try {
    const params: Record<string, any> = {
      bill_no: query.bill_no,
      cust_name: query.cust_name,
      pact_state: query.pact_state,
      pageNum: query.pageNum,
      pageSize: query.pageSize
    }
    // 日期范围
    if (query.dateRange && query.dateRange.length === 2) {
      params.date_start = query.dateRange[0]
      params.date_end = query.dateRange[1]
    }
    // 高级查询条件
    if (appliedConditions.value.length) {
      params.advanced = appliedConditions.value.map(a => ({
        logic: a.condition.logic,
        field_code: a.condition.field_code,
        operator: a.condition.operator,
        value: a.condition.value
      }))
    }
    const res = await billApi.list('sal_order', params)
    tableData.value = res?.list || []
    total.value = res?.total || 0
  } catch {
    tableData.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function onSearch() {
  query.pageNum = 1
  loadData()
}

function onReset() {
  query.bill_no = ''
  query.cust_name = ''
  query.pact_state = undefined
  query.dateRange = []
  query.pageNum = 1
  advancedConditions.value = []
  appliedConditions.value = []
  loadData()
}

function onSizeChange() {
  query.pageNum = 1
  loadData()
}

function onPageChange() {
  loadData()
}

function onSelectionChange(rows: any[]) {
  selectedRows.value = rows
}

function onRowClick(row: any) {
  goDetail(row)
}

function goDetail(row: any) {
  router.push('/bill/sal_order/' + row.id)
}

function onToolbarClick(code: string) {
  switch (code) {
    case 'add':
      router.push('/bill/sal_order/new')
      break
    case 'delete':
      onBatchDelete()
      break
    case 'copy':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择单据')
        return
      }
      router.push('/bill/sal_order/new?copyFrom=' + selectedRows.value[0].id)
      break
    case 'trace':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择单据')
        return
      }
      goDetail(selectedRows.value[0])
      break
    case 'print':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择单据')
        return
      }
      ElMessage.info('打印功能开发中')
      break
    case 'push':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择单据')
        return
      }
      ElMessage.info('请在单据详情页执行下推')
      break
    case 'close':
    case 'cancel':
    case 'change':
      if (!selectedRows.value.length) {
        ElMessage.warning('请选择单据')
        return
      }
      ElMessage.info(`请在单据详情页执行「${code}」操作`)
      break
    default:
      ElMessage.info(`操作：${code}`)
  }
}

async function onRowDelete(row: any) {
  try {
    await ElMessageBox.confirm(
      `确认删除销售订单「${row.bill_no}」？`,
      '提示',
      { type: 'warning' }
    )
  } catch {
    return
  }
  try {
    await billApi.delete('sal_order', row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    ElMessage.error('删除失败')
  }
}

async function onBatchDelete() {
  if (!selectedRows.value.length) {
    ElMessage.warning('请选择要删除的单据')
    return
  }
  try {
    await ElMessageBox.confirm(
      `确认删除选中的 ${selectedRows.value.length} 条单据？`,
      '提示',
      { type: 'warning' }
    )
  } catch {
    return
  }
  try {
    for (const r of selectedRows.value) {
      await billApi.delete('sal_order', r.id)
    }
    ElMessage.success(`已删除 ${selectedRows.value.length} 条单据`)
    selectedRows.value = []
    loadData()
  } catch {
    ElMessage.error('批量删除失败')
    loadData()
  }
}

function getSummaries({ columns, data }: { columns: any[]; data: any[] }) {
  return columns.map((col: any, idx: number) => {
    if (idx === 1) return '合计'
    const prop = col.property
    if (prop === 'total_qty') {
      const sum = data.reduce((s, r) => s + (Number(r.total_qty) || 0), 0)
      return formatQty(sum)
    }
    if (prop === 'total_amount') {
      const sum = data.reduce((s, r) => s + (Number(r.total_amount) || 0), 0)
      return formatNumber(sum)
    }
    return ''
  })
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.sal-order-list-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  padding: 0;
  overflow: hidden;
}
.page-header :deep(.bill-toolbar) {
  border-bottom: none;
}
.query-bar {
  padding: 10px 16px;
}
.query-bar :deep(.el-form--inline .el-form-item) {
  margin-bottom: 0;
}
.adv-dot {
  margin-left: 4px;
}
.table-panel {
  flex: 1;
  padding: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-panel :deep(.el-table) {
  flex: 1;
}
.code-link {
  font-weight: 600;
  padding: 0;
}
.cell-amount {
  color: #1564ff;
  font-weight: 600;
}
.cell-qty {
  color: #303133;
}
.pagination-bar {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 16px;
}

/* 高级查询弹窗 */
.adv-query {
  .adv-toolbar {
    display: flex;
    gap: 8px;
    margin-bottom: 12px;
  }
  .adv-list {
    min-height: 120px;
  }
  .adv-row {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 8px;
    flex-wrap: wrap;
  }
  .group-bracket {
    font-size: 18px;
    font-weight: 700;
    color: #1564ff;
    padding: 0 2px;
  }
  .applied-summary {
    margin-top: 12px;
    .applied-tag {
      margin: 0 6px 6px 0;
    }
  }
}
</style>
