<template>
  <div class="m-stock">
    <!-- 搜索框 -->
    <div class="search-box">
      <el-input v-model="keyword" placeholder="搜索物料编码/名称" clearable @input="onSearch" @keyup.enter="onSearch">
        <template #prefix><el-icon><Search /></el-icon></template>
      </el-input>
    </div>

    <!-- 仓库筛选 -->
    <div class="warehouse-filter">
      <el-radio-group v-model="warehouse" size="small" @change="loadStock">
        <el-radio-button value="">全部</el-radio-button>
        <el-radio-button value="原料仓">原料仓</el-radio-button>
        <el-radio-button value="辅料仓">辅料仓</el-radio-button>
        <el-radio-button value="成品仓">成品仓</el-radio-button>
      </el-radio-group>
    </div>

    <!-- Tab 切换 -->
    <el-tabs v-model="activeTab" class="stock-tabs">
      <el-tab-pane label="即时库存" name="stock">
        <div v-if="stockList.length" class="stock-list">
          <el-card v-for="item in stockList" :key="item.id" class="stock-card" shadow="hover" @click="onViewBatch(item)">
            <div class="card-head">
              <span class="mat-name">{{ item.mat_name }}</span>
              <span class="mat-code">{{ item.mat_code }}</span>
            </div>
            <div class="card-spec">规格：{{ item.spec }}</div>
            <div class="card-body">
              <div class="qty-block">
                <div class="qty-label">现存量</div>
                <div class="qty-value">{{ item.qty }} <span class="unit">{{ item.unit }}</span></div>
              </div>
              <div class="qty-block available">
                <div class="qty-label">可用量</div>
                <div class="qty-value">{{ item.available_qty }} <span class="unit">{{ item.unit }}</span></div>
              </div>
            </div>
            <div class="card-foot">
              <el-tag size="small" type="info" effect="plain">{{ item.warehouse }}</el-tag>
              <span class="batch-no">批号：{{ item.batch_no }}</span>
            </div>
          </el-card>
        </div>
        <el-empty v-else description="无库存数据" />
      </el-tab-pane>
      <el-tab-pane label="批次查询" name="batch">
        <div v-if="batchList.length" class="batch-list">
          <el-card v-for="b in batchList" :key="b.id" class="batch-card" shadow="hover">
            <div class="batch-head">
              <span class="batch-no">{{ b.batch_no }}</span>
              <el-tag size="small" :type="b.status === '可用' ? 'success' : 'danger'">{{ b.status }}</el-tag>
            </div>
            <div class="batch-mat">{{ b.mat_name }}</div>
            <div class="batch-row">
              <span>仓库：{{ b.warehouse }}</span>
              <span>数量：{{ b.qty }}</span>
            </div>
            <div class="batch-row">
              <span>入库日期：{{ b.in_date }}</span>
            </div>
          </el-card>
        </div>
        <el-empty v-else description="请点击库存卡片查看批次" />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { request } from '@/api/request'

interface StockItem {
  id: string; mat_code: string; mat_name: string; spec: string;
  warehouse: string; batch_no: string; qty: number; unit: string; available_qty: number
}
interface BatchItem {
  id: string; mat_code: string; mat_name: string; batch_no: string;
  warehouse: string; qty: number; in_date: string; status: string
}

const keyword = ref('')
const warehouse = ref('')
const activeTab = ref('stock')
const stockList = ref<StockItem[]>([])
const batchList = ref<BatchItem[]>([])

async function loadStock() {
  stockList.value = await request.get('/stock/list', { params: { keyword: keyword.value, warehouse: warehouse.value } }) as any
}

function onSearch() {
  loadStock()
}

async function onViewBatch(item: StockItem) {
  activeTab.value = 'batch'
  batchList.value = await request.get('/stock/batch', { params: { mat_code: item.mat_code } }) as any
}

onMounted(loadStock)
</script>

<style scoped lang="scss">
.m-stock { padding: 12px; }
.search-box { margin-bottom: 10px; }
.warehouse-filter { margin-bottom: 12px; overflow-x: auto; }
.stock-tabs { :deep(.el-tabs__content) { overflow: auto; } }
.stock-list, .batch-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.stock-card, .batch-card {
  cursor: pointer;
  :deep(.el-card__body) { padding: 12px; }
}
.card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  .mat-name { font-size: 15px; font-weight: 600; color: #303133; }
  .mat-code { font-size: 12px; color: #909399; }
}
.card-spec { font-size: 13px; color: #606266; margin-bottom: 8px; }
.card-body {
  display: flex;
  gap: 12px;
  margin-bottom: 8px;
  .qty-block {
    flex: 1;
    padding: 8px;
    background: #f5f7fa;
    border-radius: 4px;
    .qty-label { font-size: 12px; color: #909399; }
    .qty-value { font-size: 18px; font-weight: 600; color: #303133; margin-top: 2px; }
    .unit { font-size: 12px; color: #909399; font-weight: normal; }
    &.available .qty-value { color: #52c41a; }
  }
}
.card-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  .batch-no { font-size: 12px; color: #909399; }
}
.batch-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  .batch-no { font-size: 15px; font-weight: 600; color: #1564ff; }
}
.batch-mat { font-size: 14px; color: #303133; margin-bottom: 6px; }
.batch-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #606266;
  margin-bottom: 4px;
}
</style>
