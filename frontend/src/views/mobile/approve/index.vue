<template>
  <div class="m-approve">
    <!-- 统计 -->
    <div class="approve-stat">
      <span class="stat-text">待审批 <b>{{ list.length }}</b> 条</span>
    </div>

    <!-- 审批列表 -->
    <div v-if="list.length" class="approve-list">
      <el-card v-for="item in list" :key="item.id" class="approve-card" shadow="hover" @click="onOpenDetail(item)">
        <div class="card-head">
          <el-tag size="small" :type="billTag(item.bill_type) || 'info'" effect="dark">{{ billLabel(item.bill_type) }}</el-tag>
          <span class="bill-code">{{ item.bill_code }}</span>
        </div>
        <div class="card-title">{{ item.title }}</div>
        <div class="card-summary">{{ item.summary }}</div>
        <div class="card-foot">
          <span class="applicant">申请人：{{ item.applicant }}</span>
          <span v-if="item.amount > 0" class="amount">¥{{ item.amount.toLocaleString() }}</span>
        </div>
        <div class="card-time">{{ item.submit_time }}</div>
      </el-card>
    </div>
    <el-empty v-else description="暂无待审批单据" />

    <!-- 审批弹窗 -->
    <el-dialog v-model="detailVisible" title="审批处理" width="92%" append-to-body>
      <div v-if="current" class="detail-content">
        <div class="detail-row"><span class="label">单据编号</span><span class="value">{{ current.bill_code }}</span></div>
        <div class="detail-row"><span class="label">单据类型</span><span class="value">{{ billLabel(current.bill_type) }}</span></div>
        <div class="detail-row"><span class="label">标题</span><span class="value">{{ current.title }}</span></div>
        <div class="detail-row"><span class="label">摘要</span><span class="value">{{ current.summary }}</span></div>
        <div class="detail-row"><span class="label">申请人</span><span class="value">{{ current.applicant }}</span></div>
        <div v-if="current.amount > 0" class="detail-row"><span class="label">金额</span><span class="value amount">¥{{ current.amount.toLocaleString() }}</span></div>
        <div class="detail-row"><span class="label">提交时间</span><span class="value">{{ current.submit_time }}</span></div>
        <el-divider />
        <div class="opinion-section">
          <div class="label">审批意见</div>
          <el-input v-model="opinion" type="textarea" :rows="3" placeholder="请输入审批意见（驳回时必填）" />
        </div>
      </div>
      <template #footer>
        <el-button @click="detailVisible = false">取消</el-button>
        <el-button type="danger" @click="onReject">驳回</el-button>
        <el-button type="success" @click="onApprove">批准</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api/request'

interface ApproveItem {
  id: string
  bill_type: string
  bill_code: string
  title: string
  applicant: string
  amount: number
  submit_time: string
  status: string
  summary: string
}

const list = ref<ApproveItem[]>([])
const detailVisible = ref(false)
const current = ref<ApproveItem | null>(null)
const opinion = ref('')

function billLabel(t: string) {
  const m: Record<string, string> = { sal_order: '销售订单', pur_order: '采购订单', mfg_order: '生产订单' }
  return m[t] || t
}
function billTag(t: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = { sal_order: '', pur_order: 'warning', mfg_order: 'info' }
  return m[t] || 'info'
}

async function loadData() {
  list.value = await request.get('/approve/list') as any
}

function onOpenDetail(item: ApproveItem) {
  current.value = item
  opinion.value = ''
  detailVisible.value = true
}

async function onApprove() {
  if (!current.value) return
  await request.post(`/approve/${current.value.id}/approve`, { opinion: opinion.value })
  ElMessage.success('已批准')
  detailVisible.value = false
  loadData()
}

async function onReject() {
  if (!current.value) return
  if (!opinion.value) {
    ElMessage.warning('驳回时请填写审批意见')
    return
  }
  await request.post(`/approve/${current.value.id}/reject`, { opinion: opinion.value })
  ElMessage.success('已驳回')
  detailVisible.value = false
  loadData()
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.m-approve {
  padding: 12px;
}
.approve-stat {
  padding: 10px 12px;
  background: #e9f1ff;
  border-radius: 6px;
  margin-bottom: 12px;
  .stat-text {
    font-size: 14px;
    color: #1564ff;
    b { font-size: 18px; margin: 0 4px; }
  }
}
.approve-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.approve-card {
  cursor: pointer;
  :deep(.el-card__body) { padding: 12px; }
}
.card-head {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
  .bill-code { font-size: 13px; color: #606266; font-weight: 600; }
}
.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 4px;
}
.card-summary {
  font-size: 13px;
  color: #606266;
  margin-bottom: 6px;
}
.card-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #909399;
  .amount { color: #f5222d; font-size: 14px; font-weight: 600; }
}
.card-time {
  font-size: 11px;
  color: #c0c4cc;
  margin-top: 4px;
}
.detail-content {
  .detail-row {
    display: flex;
    padding: 6px 0;
    font-size: 14px;
    .label { width: 80px; color: #909399; flex-shrink: 0; }
    .value { color: #303133; }
    .value.amount { color: #f5222d; font-weight: 600; }
  }
}
.opinion-section {
  .label { font-size: 14px; font-weight: 600; margin-bottom: 8px; }
}
</style>
