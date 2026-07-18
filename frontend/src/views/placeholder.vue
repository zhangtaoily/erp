<template>
  <div class="placeholder-page">
    <el-result icon="info" :title="title" :sub-title="`路由：${$route.fullPath}`">
      <template #extra>
        <el-tag type="info">该页面待后续阶段实现</el-tag>
        <p class="placeholder-tip">依据 PRD 01-平台基座搭建，本占位页将在对应开发阶段替换为实际功能。</p>
      </template>
    </el-result>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const title = computed(() => (route.meta.title as string) || '页面')
</script>

<style scoped lang="scss">
.placeholder-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fff;
}
.placeholder-tip {
  color: #909399;
  font-size: 12px;
  margin-top: 12px;
}
</style>
