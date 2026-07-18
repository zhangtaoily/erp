<template>
  <div class="bill-trace-tree">
    <div class="trace-header">
      <span class="trace-title">单据联查追溯</span>
      <el-radio-group v-model="curDirection" size="small" @change="loadData">
        <el-radio-button value="up">上查（来源）</el-radio-button>
        <el-radio-button value="down">下查（下游）</el-radio-button>
      </el-radio-group>
    </div>

    <div v-if="loading" class="trace-loading">
      <el-icon class="is-loading"><Loading /></el-icon>
      <span>加载追溯链...</span>
    </div>
    <el-empty v-else-if="!treeData.length" description="无关联单据" :image-size="60" />
    <el-tree
      v-else
      :data="treeData"
      node-key="id"
      default-expand-all
      :expand-on-click-node="false"
    >
      <template #default="{ data }">
        <span class="trace-node" @click="onNodeClick(data)">
          <el-icon class="trace-icon"><Link /></el-icon>
          <el-tag size="small" :type="billTypeTag(data.bill_type) || 'info'" effect="plain">{{ billTypeLabel(data.bill_type) }}</el-tag>
          <span class="bill-code">{{ data.bill_code }}</span>
          <span class="bill-qty">数量：{{ data.qty }}</span>
          <el-tag v-if="data.depth >= 4" size="small" type="danger" effect="plain">深度上限</el-tag>
        </span>
      </template>
    </el-tree>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { Loading, Link } from '@element-plus/icons-vue'
import { billTraceApi } from '@/api/integration'
import type { BillLink } from '@/types/bo'

const props = defineProps<{
  billType: string
  billId: string
  direction?: 'up' | 'down'
}>()

const emit = defineEmits<{
  (e: 'click', node: TraceNode): void
}>()

interface TraceNode {
  id: string
  bill_type: string
  bill_code: string
  bill_id: string
  qty: number
  depth: number
  children?: TraceNode[]
}

const treeData = ref<TraceNode[]>([])
const curDirection = ref<'up' | 'down'>(props.direction || 'down')
const loading = ref(false)

// 递归深度上限（GAP-D04-003 / PRD 02.4.3：限深度 5 防止无限递归）
const MAX_DEPTH = 5

const BILL_TYPE_MAP: Record<string, { label: string; tag: '' | 'success' | 'warning' | 'info' | 'danger' }> = {
  sal_order: { label: '销售订单', tag: '' },
  sal_out_stock: { label: '销售出库', tag: 'success' },
  pur_order: { label: '采购订单', tag: 'warning' },
  pur_in_stock: { label: '采购入库', tag: 'success' },
  mfg_order: { label: '生产订单', tag: 'info' },
  mfg_in_stock: { label: '完工入库', tag: 'success' },
  mat_pick: { label: '领料单', tag: 'warning' },
  sal_int_cont: { label: '意向合同', tag: 'danger' },
  ar_bill: { label: '应收单', tag: 'info' },
  ap_bill: { label: '应付单', tag: 'info' },
  sal_invoice: { label: '销售发票', tag: 'danger' }
}

function billTypeLabel(t: string) {
  return BILL_TYPE_MAP[t]?.label || t
}
function billTypeTag(t: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  return BILL_TYPE_MAP[t]?.tag || 'info'
}

// 递归构建追溯树：从当前单据出发，按 direction 递归查询关联单据，限深度 5
async function buildTree(
  billType: string,
  billId: string,
  direction: 'up' | 'down',
  depth: number,
  visited: Set<string>
): Promise<TraceNode[]> {
  if (depth >= MAX_DEPTH) return []
  // 防环：用 type+id 标记已访问节点，避免循环引用导致无限递归
  const visitKey = `${billType}:${billId}`
  if (visited.has(visitKey)) return []
  visited.add(visitKey)

  let links: BillLink[] = []
  try {
    links = direction === 'up'
      ? await billTraceApi.upstream(billType, billId)
      : await billTraceApi.downstream(billType, billId)
  } catch {
    links = []
  }

  const nodes: TraceNode[] = []
  for (const l of links) {
    const isUp = direction === 'up'
    const childBillType = isUp ? l.src_bill_type : l.target_bill_type
    const childBillId = isUp ? l.src_bill_id : l.target_bill_id
    const childBillCode = isUp ? l.src_bill_code : l.target_bill_code
    const childVisitKey = `${childBillType}:${childBillId}`
    // 子节点已访问则不展开（避免循环）
    if (visited.has(childVisitKey)) {
      nodes.push({
        id: l.id, bill_type: childBillType, bill_code: childBillCode,
        bill_id: childBillId, qty: l.qty, depth
      })
      continue
    }
    const children = await buildTree(childBillType, childBillId, direction, depth + 1, visited)
    nodes.push({
      id: l.id,
      bill_type: childBillType,
      bill_code: childBillCode,
      bill_id: childBillId,
      qty: l.qty,
      depth,
      children: children.length ? children : undefined
    })
  }
  return nodes
}

async function loadData() {
  if (!props.billType || !props.billId) return
  loading.value = true
  try {
    treeData.value = await buildTree(props.billType, props.billId, curDirection.value, 0, new Set<string>())
  } finally {
    loading.value = false
  }
}

function onNodeClick(node: TraceNode) {
  emit('click', node)
}

watch(() => [props.billType, props.billId], loadData)
watch(() => props.direction, (v) => { if (v) { curDirection.value = v; loadData() } })
onMounted(loadData)
</script>

<style scoped lang="scss">
.bill-trace-tree {
  .trace-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 12px;
  }
  .trace-title {
    font-size: 13px;
    font-weight: 600;
  }
  .trace-loading {
    display: flex;
    align-items: center;
    gap: 6px;
    color: #909399;
    font-size: 12px;
    padding: 16px 0;
  }
  .trace-node {
    display: flex;
    align-items: center;
    gap: 6px;
    cursor: pointer;
    flex: 1;
    padding-right: 8px;
    .trace-icon { color: #1564ff; }
    .bill-code { font-weight: 600; }
    .bill-qty { color: #909399; font-size: 12px; margin-left: auto; }
    &:hover { color: #1564ff; }
  }
}
</style>
