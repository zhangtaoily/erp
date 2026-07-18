<template>
  <div class="change-history">
    <div class="history-header">
      <span class="history-title">变更历史</span>
      <el-tag v-if="logs.length" size="small" type="info">共 {{ logs.length }} 条变更</el-tag>
    </div>
    <el-empty v-if="!logs.length" description="暂无变更记录" :image-size="60" />
    <el-timeline v-else>
      <el-timeline-item
        v-for="log in logs"
        :key="log.id"
        :timestamp="log.change_time"
        placement="top"
        :type="log.change_state === 1 ? 'success' : 'warning'"
      >
        <div class="change-card">
          <div class="change-head">
            <span class="change-code">{{ log.change_code }}</span>
            <el-tag size="small" :type="log.change_state === 1 ? 'success' : 'warning'">
              {{ log.change_state === 1 ? '已审' : '待审' }}
            </el-tag>
          </div>
          <div class="change-body">
            <span class="field-name">{{ log.field_name }}：</span>
            <span class="old-value">{{ log.old_value || '(空)' }}</span>
            <el-icon class="arrow"><Right /></el-icon>
            <span class="new-value">{{ log.new_value || '(空)' }}</span>
          </div>
          <div class="change-foot">
            <span class="change-by">变更人：{{ log.change_by }}</span>
            <span class="change-reason">原因：{{ log.change_reason }}</span>
          </div>
        </div>
      </el-timeline-item>
    </el-timeline>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { changeLogApi } from '@/api/integration'
import type { ChangeLog } from '@/types/bo'

const props = defineProps<{
  billType: string
  billId: string
}>()

const logs = ref<ChangeLog[]>([])

async function loadData() {
  if (!props.billType || !props.billId) return
  logs.value = await changeLogApi.list(props.billType, props.billId)
}

watch(() => [props.billType, props.billId], loadData)
onMounted(loadData)
</script>

<style scoped lang="scss">
.change-history {
  .history-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 16px;
  }
  .history-title {
    font-size: 13px;
    font-weight: 600;
  }
  .change-card {
    background: #fafbfc;
    border: 1px solid #ebeef5;
    border-radius: 4px;
    padding: 10px 12px;
  }
  .change-head {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 8px;
    .change-code {
      font-weight: 600;
      color: #1564ff;
      font-size: 13px;
    }
  }
  .change-body {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 6px;
    font-size: 13px;
    .field-name { color: #606266; }
    .old-value {
      text-decoration: line-through;
      color: #909399;
    }
    .arrow { color: #1564ff; }
    .new-value {
      color: #f5222d;
      font-weight: 600;
    }
  }
  .change-foot {
    display: flex;
    gap: 16px;
    font-size: 12px;
    color: #909399;
  }
}
</style>
