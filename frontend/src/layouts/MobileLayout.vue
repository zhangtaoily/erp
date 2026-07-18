<template>
  <div class="mobile-layout">
    <div class="mobile-header">
      <span class="mobile-title">{{ route.meta.title || 'E-ERP' }}</span>
    </div>
    <div class="mobile-body">
      <router-view />
    </div>
    <div class="mobile-tabbar">
      <div
        v-for="tab in tabs"
        :key="tab.path"
        class="tab-item"
        :class="{ active: route.path === tab.path }"
        @click="router.push(tab.path)"
      >
        <el-icon><component :is="tab.icon" /></el-icon>
        <span>{{ tab.title }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const tabs = [
  { path: '/m/approve', title: '审批', icon: 'Check' },
  { path: '/m/stock', title: '库存', icon: 'Box' },
  { path: '/m/bill-view', title: '单据', icon: 'Document' },
  { path: '/m/message', title: '消息', icon: 'Bell' }
]
</script>

<style scoped lang="scss">
.mobile-layout {
  height: 100vh;
  max-width: 420px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  background: #f5f7fa;
  position: relative;
  border-left: 1px solid #e4e7ed;
  border-right: 1px solid #e4e7ed;
}
.mobile-header {
  height: 44px;
  background: linear-gradient(90deg, #1564ff 0%, #0f4ecc 100%);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 600;
}
.mobile-body {
  flex: 1;
  overflow: auto;
}
.mobile-tabbar {
  height: 52px;
  background: #fff;
  border-top: 1px solid #e4e7ed;
  display: flex;
}
.tab-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: #909399;
  cursor: pointer;
  gap: 2px;
  .el-icon {
    font-size: 18px;
  }
  &.active {
    color: #1564ff;
  }
}
</style>
