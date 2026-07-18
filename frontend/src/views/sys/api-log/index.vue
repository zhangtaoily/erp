<template>
  <div class="al-page page-container">
    <!-- 筛选栏 -->
    <div class="panel-card filter-bar">
      <el-form :inline="true" size="small">
        <el-form-item label="API分类">
          <el-select v-model="query.category" clearable placeholder="全部" style="width:140px" @change="onSearch">
            <el-option v-for="c in categories" :key="c.value" :label="c.label" :value="c.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px" @change="onSearch">
            <el-option label="成功" value="success" />
            <el-option label="失败" value="fail" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width:340px"
            @change="onDateChange"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <div class="stat-cards">
      <div class="stat-card panel-card">
        <div class="stat-label">总调用数</div>
        <div class="stat-value">{{ stat.total }}</div>
      </div>
      <div class="stat-card panel-card">
        <div class="stat-label">成功</div>
        <div class="stat-value success">{{ stat.success }}</div>
      </div>
      <div class="stat-card panel-card">
        <div class="stat-label">失败</div>
        <div class="stat-value danger">{{ stat.fail }}</div>
      </div>
      <div class="stat-card panel-card">
        <div class="stat-label">平均耗时</div>
        <div class="stat-value">{{ stat.avgDuration }}ms</div>
      </div>
    </div>

    <!-- 日志列表 -->
    <div class="panel-card table-panel">
      <el-table :data="tableData" size="small" border stripe v-loading="loading" @row-click="onRowClick">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column label="分类" width="80">
          <template #default="{ row }">
            <el-tag size="small" :type="categoryTag(row.category) || 'info'">{{ categoryLabel(row.category) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="endpoint" label="端点" min-width="220" show-overflow-tooltip />
        <el-table-column prop="method" label="方法" width="70">
          <template #default="{ row }">
            <el-tag size="small" :type="methodTag(row.method) || 'info'" effect="plain">{{ row.method }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="耗时" width="90" align="right">
          <template #default="{ row }">
            <span :class="{ 'slow-warn': row.duration > 1000 }">{{ row.duration }}ms</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="70">
          <template #default="{ row }">
            <el-tag :type="row.status === 'success' ? 'success' : 'danger'" size="small">{{ row.status === 'success' ? '成功' : '失败' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="时间" width="160" />
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click.stop="onDetail(row as any)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </div>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="接口日志详情" width="720px" append-to-body>
      <el-descriptions v-if="currentLog" :column="2" border size="small">
        <el-descriptions-item label="分类">{{ categoryLabel(currentLog.category) }}</el-descriptions-item>
        <el-descriptions-item label="方法">{{ currentLog.method }}</el-descriptions-item>
        <el-descriptions-item label="端点" :span="2">{{ currentLog.endpoint }}</el-descriptions-item>
        <el-descriptions-item label="耗时">{{ currentLog.duration }}ms</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="currentLog.status === 'success' ? 'success' : 'danger'" size="small">{{ currentLog.status === 'success' ? '成功' : '失败' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="时间" :span="2">{{ currentLog.create_time }}</el-descriptions-item>
        <el-descriptions-item v-if="currentLog.error_msg" label="错误信息" :span="2">
          <span class="error-msg">{{ currentLog.error_msg }}</span>
        </el-descriptions-item>
      </el-descriptions>
      <div v-if="currentLog" class="json-section">
        <div class="json-title">请求体</div>
        <pre class="json-box">{{ formatJson(currentLog.request_body) }}</pre>
      </div>
      <div v-if="currentLog" class="json-section">
        <div class="json-title">响应体</div>
        <pre class="json-box" :class="{ 'json-error': currentLog.status === 'fail' }">{{ formatJson(currentLog.response_body) }}</pre>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { apiLogApi } from '@/api/integration'
import type { ApiLog } from '@/types/bo'

const loading = ref(false)
const tableData = ref<ApiLog[]>([])
const total = ref(0)
const detailVisible = ref(false)
const currentLog = ref<ApiLog | null>(null)
const dateRange = ref<[string, string] | null>(null)

const query = reactive({
  category: '', status: '', start_time: '', end_time: '',
  pageNum: 1, pageSize: 10
})

const categories = [
  { value: 'wf', label: '工作流(WF)' },
  { value: 'mes', label: '制造执行(MES)' },
  { value: 'qms', label: '质量管理(QMS)' },
  { value: 'report', label: '报表(REPORT)' },
  { value: 'tax', label: '税务(TAX)' },
  { value: 'bank', label: '银行(BANK)' },
  { value: 'other', label: '其他(OTHER)' }
]

function categoryLabel(c: string) {
  return categories.find(x => x.value === c)?.label || c
}
function categoryTag(c: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    wf: '', mes: 'success', qms: 'warning', report: 'info', tax: 'danger', bank: 'danger', other: 'info'
  }
  return m[c] || 'info'
}
function methodTag(m: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const map: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    GET: 'info', POST: 'success', PUT: 'warning', DELETE: 'danger'
  }
  return map[m] || 'info'
}

const stat = computed(() => {
  const all = tableData.value
  const success = all.filter(l => l.status === 'success').length
  const fail = all.filter(l => l.status === 'fail').length
  const totalDur = all.reduce((s, l) => s + l.duration, 0)
  return {
    total: total.value, success, fail,
    avgDuration: all.length ? Math.round(totalDur / all.length) : 0
  }
})

async function loadData() {
  loading.value = true
  try {
    const res: any = await apiLogApi.list(query)
    tableData.value = res.list || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

function onSearch() {
  query.pageNum = 1
  loadData()
}
function onReset() {
  query.category = ''
  query.status = ''
  query.start_time = ''
  query.end_time = ''
  dateRange.value = null
  query.pageNum = 1
  loadData()
}
function onDateChange(val: [string, string] | null) {
  if (val) {
    query.start_time = val[0]
    query.end_time = val[1]
  } else {
    query.start_time = ''
    query.end_time = ''
  }
}

function onRowClick(row: ApiLog) {
  onDetail(row)
}

async function onDetail(row: ApiLog) {
  currentLog.value = await apiLogApi.detail(row.id)
  detailVisible.value = true
}

function formatJson(str?: string) {
  if (!str) return '(空)'
  try {
    return JSON.stringify(JSON.parse(str), null, 2)
  } catch {
    return str
  }
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.al-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.filter-bar { padding: 12px 12px 0; }
.stat-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.stat-card {
  padding: 12px 16px;
  .stat-label { font-size: 12px; color: #909399; }
  .stat-value {
    font-size: 22px;
    font-weight: 600;
    margin-top: 4px;
    &.success { color: #52c41a; }
    &.danger { color: #f5222d; }
  }
}
.table-panel { padding: 12px; flex: 1; }
.pagination-bar { margin-top: 12px; display: flex; justify-content: flex-end; }
.slow-warn { color: #faad14; font-weight: 600; }
.error-msg { color: #f5222d; }
.json-section { margin-top: 12px; }
.json-title { font-size: 13px; font-weight: 600; margin-bottom: 6px; }
.json-box {
  background: #f5f7fa;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 10px;
  font-size: 12px;
  max-height: 200px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-all;
  margin: 0;
  &.json-error { background: #fef0f0; border-color: #fbc4c4; color: #f5222d; }
}
</style>
