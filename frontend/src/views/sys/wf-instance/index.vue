<template>
  <div class="wf-page">
    <!-- 筛选栏 -->
    <div class="panel-card search-bar">
      <el-form :inline="true" size="small">
        <el-form-item label="单据类型">
          <el-select v-model="query.bill_type" clearable placeholder="全部" style="width:140px" @change="onSearch">
            <el-option v-for="b in billTypes" :key="b.value" :label="b.label" :value="b.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:120px" @change="onSearch">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" clearable placeholder="单据号/实例号/请求号" style="width:220px" @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表 -->
    <div class="panel-card table-panel">
      <div class="panel-header">
        <span class="panel-title">工作流实例列表</span>
        <el-button type="primary" size="small" @click="onSimulateCallback">模拟回调</el-button>
      </div>
      <div class="table-body">
        <el-table :data="tableData" size="small" border stripe v-loading="loading">
          <el-table-column type="index" label="#" width="45" />
          <el-table-column label="实例号" width="160">
            <template #default="{ row }">
              <span class="mono">{{ row.instance_id }}</span>
            </template>
          </el-table-column>
          <el-table-column label="请求号" width="160">
            <template #default="{ row }">
              <span class="mono">{{ row.request_id || '-' }}</span>
            </template>
          </el-table-column>
          <el-table-column label="单据类型" width="100">
            <template #default="{ row }">{{ billTypeLabel(row.bill_type) }}</template>
          </el-table-column>
          <el-table-column prop="bill_code" label="单据编号" width="150" />
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="statusTag(row.status) || 'info'" size="small">{{ statusLabel(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="current_node" label="当前节点" width="130" />
          <el-table-column prop="approver" label="当前审批人" width="100" />
          <el-table-column prop="submit_by" label="提交人" width="90" />
          <el-table-column prop="submit_time" label="提交时间" width="160" />
          <el-table-column prop="callback_time" label="回调时间" width="160">
            <template #default="{ row }">{{ row.callback_time || '-' }}</template>
          </el-table-column>
          <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
          <el-table-column label="操作" width="130" fixed="right">
            <template #default="{ row }">
              <el-button v-if="row.status === 'approving'" link type="success" size="small" @click="onCallback(row as any, 'approved')">通过</el-button>
              <el-button v-if="row.status === 'approving'" link type="danger" size="small" @click="onCallback(row as any, 'rejected')">驳回</el-button>
              <el-button v-if="row.status === 'approving'" link type="warning" size="small" @click="onCallback(row as any, 'canceled')">取消</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
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
      <div class="wf-tip">
        <el-icon><InfoFilled /></el-icon>
        <span>说明：单据提交时若状态机 need_wf=true，将调用外部工作流推送 API（wf_push_api）启动流程；外部系统审批完成后回调 ERP 接口（wf_callback_url）更新单据 pact_state。本页用于监控实例状态与手动模拟回调。</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'
import { wfInstanceApi } from '@/api/sys-ext'
import type { WfInstance } from '@/types/bo'

const loading = ref(false)
const tableData = ref<WfInstance[]>([])
const total = ref(0)

const query = reactive({
  bill_type: '' as string,
  status: '' as string,
  keyword: '',
  pageNum: 1,
  pageSize: 10
})

const billTypes = [
  { value: 'sal_order', label: '销售订单' },
  { value: 'pur_order', label: '采购订单' },
  { value: 'mfg_order', label: '生产订单' }
]
function billTypeLabel(c: string) {
  return billTypes.find(b => b.value === c)?.label || c
}

const statusOptions = [
  { value: 'approving', label: '审批中' },
  { value: 'approved', label: '已通过' },
  { value: 'rejected', label: '已驳回' },
  { value: 'canceled', label: '已取消' }
]
function statusLabel(s: string) {
  return statusOptions.find(x => x.value === s)?.label || s
}
function statusTag(s: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    approving: 'warning', approved: 'success', rejected: 'danger', canceled: 'info'
  }
  return m[s] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    const res: any = await wfInstanceApi.list(query)
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
  query.bill_type = ''
  query.status = ''
  query.keyword = ''
  query.pageNum = 1
  loadData()
}

async function onCallback(row: WfInstance, status: WfInstance['status']) {
  const action = statusLabel(status)
  try {
    await ElMessageBox.confirm(`确认模拟外部工作流回调：将单据「${row.bill_code}」标记为「${action}」？`, '提示', { type: 'warning' })
  } catch { return }
  await wfInstanceApi.callback(row.id, { status, remark: `手动模拟回调：${action}` })
  ElMessage.success('回调已处理')
  loadData()
}

function onSimulateCallback() {
  const pending = tableData.value.filter(w => w.status === 'approving')
  if (!pending.length) {
    ElMessage.info('当前列表无审批中的实例')
    return
  }
  ElMessage.info(`当前列表有 ${pending.length} 个审批中的实例，点击对应行的「通过/驳回/取消」可模拟回调`)
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.wf-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.search-bar { padding: 12px 12px 0; }
.table-panel {
  padding: 12px;
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-body {
  flex: 1;
  overflow: auto;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title { font-size: 14px; font-weight: 600; }
.mono { font-family: Consolas, Monaco, monospace; font-size: 12px; color: #1564ff; }
.pagination-bar { margin-top: 12px; display: flex; justify-content: flex-end; }
.wf-tip {
  margin-top: 12px;
  padding: 8px 12px;
  background: #ecf5ff;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  display: flex;
  gap: 6px;
  align-items: flex-start;
  .el-icon { color: #1564ff; margin-top: 2px; }
}
</style>
