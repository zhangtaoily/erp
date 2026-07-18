<template>
  <div class="m-bill-view">
    <!-- 单据选择 -->
    <div class="bill-selector">
      <el-select v-model="billId" placeholder="选择销售订单" @change="loadBill">
        <el-option v-for="o in orderOptions" :key="o.id" :label="o.bill_no + ' - ' + o.cust_name" :value="o.id" />
      </el-select>
    </div>

    <div v-loading="loading">
      <template v-if="bill">
        <!-- 单据头部卡片 -->
        <el-card class="bill-head-card" shadow="hover">
          <div class="bill-status-row">
            <span class="bill-code">{{ bill.bill_no }}</span>
            <el-tag :type="pactStateType(bill.pact_state) || 'info'" effect="dark">{{ pactStateLabel(bill.pact_state) }}</el-tag>
          </div>
          <div class="cust-name">{{ bill.cust_name }}</div>
          <div class="bill-meta">
            <div class="meta-row"><span class="label">订单日期</span><span>{{ bill.order_date }}</span></div>
            <div class="meta-row"><span class="label">交货日期</span><span>{{ bill.delivery_date }}</span></div>
            <div class="meta-row"><span class="label">业务员</span><span>{{ bill.salesman_name }}</span></div>
            <div class="meta-row"><span class="label">组织</span><span>{{ bill.org_name }}</span></div>
          </div>
          <div class="amount-block">
            <div class="amount-label">总金额</div>
            <div class="amount-value">¥{{ Number(bill.total_amount).toLocaleString() }}</div>
            <div class="amount-sub">总数量：{{ bill.total_qty }}</div>
          </div>
        </el-card>

        <!-- 明细列表 -->
        <div class="goods-section">
          <div class="section-title">订单明细（{{ bill.goods?.length || 0 }} 条）</div>
          <el-card v-for="g in bill.goods" :key="g.id" class="goods-card" shadow="hover">
            <div class="goods-head">
              <span class="goods-name">{{ g.mat_name }}</span>
            </div>
            <div class="goods-spec">规格：{{ g.spec }}</div>
            <div class="goods-row">
              <div class="goods-item">
                <span class="label">数量</span>
                <span class="value">{{ g.qty }} {{ g.unit }}</span>
              </div>
              <div class="goods-item">
                <span class="label">单价</span>
                <span class="value">¥{{ g.price }}</span>
              </div>
              <div class="goods-item">
                <span class="label">金额</span>
                <span class="value amount">¥{{ Number(g.amount).toLocaleString() }}</span>
              </div>
            </div>
            <div class="goods-progress">
              <span class="label">已出库</span>
              <el-progress :percentage="outPercent(g)" :stroke-width="8" :status="g.out_qty >= g.qty ? 'success' : ''" />
              <span class="progress-text">{{ g.out_qty }}/{{ g.qty }}</span>
            </div>
          </el-card>
        </div>
      </template>
      <el-empty v-else-if="!loading" description="请选择订单" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { request } from '@/api/request'

interface GoodsItem {
  id: string; mat_name: string; spec: string; qty: number; unit: string;
  price: number; amount: number; out_qty: number
}
interface BillDetail {
  id: string; bill_no: string; cust_name: string; order_date: string; delivery_date: string;
  salesman_name: string; org_name: string; total_amount: number; total_qty: number;
  pact_state: number; goods?: GoodsItem[]
}

const loading = ref(false)
const billId = ref('1')
const bill = ref<BillDetail | null>(null)
const orderOptions = ref<{ id: string; bill_no: string; cust_name: string }[]>([])

function pactStateLabel(s: number) {
  const m: Record<number, string> = { 0: '暂存', 1: '已创建', 2: '已提交', 3: '已审核', 4: '已驳回' }
  return m[s] || String(s)
}
function pactStateType(s: number): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<number, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    0: 'info', 1: '', 2: 'warning', 3: 'success', 4: 'danger'
  }
  return m[s] || 'info'
}
function outPercent(g: GoodsItem) {
  if (!g.qty) return 0
  return Math.min(100, Math.round((g.out_qty / g.qty) * 100))
}

async function loadOrders() {
  const res: any = await request.get('/bill/sal_order/list', { params: { pageSize: 50 } })
  orderOptions.value = (res.list || []).map((o: any) => ({ id: o.id, bill_no: o.bill_no, cust_name: o.cust_name }))
}

async function loadBill() {
  if (!billId.value) return
  loading.value = true
  try {
    bill.value = await request.get(`/bill/sal_order/${billId.value}`) as any
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await loadOrders()
  loadBill()
})
</script>

<style scoped lang="scss">
.m-bill-view { padding: 12px; }
.bill-selector { margin-bottom: 12px; }
.bill-head-card {
  margin-bottom: 12px;
  :deep(.el-card__body) { padding: 14px; }
}
.bill-status-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  .bill-code { font-size: 16px; font-weight: 600; color: #1564ff; }
}
.cust-name {
  font-size: 15px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
}
.bill-meta {
  .meta-row {
    display: flex;
    font-size: 13px;
    padding: 2px 0;
    .label { width: 70px; color: #909399; }
  }
}
.amount-block {
  margin-top: 10px;
  padding: 10px;
  background: linear-gradient(135deg, #e9f1ff 0%, #f5f7fa 100%);
  border-radius: 6px;
  text-align: center;
  .amount-label { font-size: 12px; color: #909399; }
  .amount-value { font-size: 22px; font-weight: 700; color: #1564ff; margin: 2px 0; }
  .amount-sub { font-size: 12px; color: #606266; }
}
.goods-section {
  .section-title {
    font-size: 14px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 8px;
    padding-left: 8px;
    border-left: 3px solid #1564ff;
  }
}
.goods-card {
  margin-bottom: 10px;
  :deep(.el-card__body) { padding: 12px; }
}
.goods-head {
  .goods-name { font-size: 14px; font-weight: 600; color: #303133; }
}
.goods-spec { font-size: 12px; color: #909399; margin: 4px 0 8px; }
.goods-row {
  display: flex;
  justify-content: space-between;
  .goods-item {
    text-align: center;
    .label { display: block; font-size: 11px; color: #909399; }
    .value { font-size: 14px; font-weight: 600; color: #303133; }
    .value.amount { color: #f5222d; }
  }
}
.goods-progress {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  font-size: 12px;
  .label { color: #909399; flex-shrink: 0; }
  .progress-text { color: #606266; flex-shrink: 0; }
  :deep(.el-progress) { flex: 1; }
}
</style>
