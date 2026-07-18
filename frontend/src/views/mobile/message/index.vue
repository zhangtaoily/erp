<template>
  <div class="m-message">
    <!-- 类型筛选 -->
    <div class="msg-filter">
      <el-radio-group v-model="filterType" size="small" @change="loadMessages">
        <el-radio-button value="">全部</el-radio-button>
        <el-radio-button value="approve">审批</el-radio-button>
        <el-radio-button value="warn">预警</el-radio-button>
        <el-radio-button value="system">系统</el-radio-button>
      </el-radio-group>
    </div>

    <!-- 未读统计 -->
    <div class="unread-stat">
      <el-icon><Bell /></el-icon>
      <span>未读消息 <b>{{ unreadCount }}</b> 条</span>
    </div>

    <!-- 消息列表 -->
    <div v-if="messages.length" class="msg-list">
      <el-card
        v-for="msg in messages"
        :key="msg.id"
        class="msg-card"
        :class="{ unread: !msg.is_read }"
        shadow="hover"
        @click="onRead(msg)"
      >
        <div class="msg-head">
          <span class="dot" :class="'level-' + msg.level"></span>
          <span class="msg-type" :class="'type-' + msg.type">{{ typeLabel(msg.type) }}</span>
          <span v-if="!msg.is_read" class="unread-tag">未读</span>
          <span class="msg-time">{{ msg.create_time }}</span>
        </div>
        <div class="msg-title">{{ msg.title }}</div>
        <div class="msg-content">{{ msg.content }}</div>
      </el-card>
    </div>
    <el-empty v-else description="暂无消息" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { request } from '@/api/request'

interface MessageItem {
  id: string
  type: string
  title: string
  content: string
  create_time: string
  is_read: boolean
  level: string
}

const messages = ref<MessageItem[]>([])
const filterType = ref('')

const unreadCount = computed(() => messages.value.filter(m => !m.is_read).length)

function typeLabel(t: string) {
  const m: Record<string, string> = { approve: '审批', warn: '预警', system: '系统' }
  return m[t] || t
}

async function loadMessages() {
  messages.value = await request.get('/message/list', { params: { type: filterType.value } }) as any
}

async function onRead(msg: MessageItem) {
  if (!msg.is_read) {
    await request.post(`/message/${msg.id}/read`)
    msg.is_read = true
  }
}

onMounted(loadMessages)
</script>

<style scoped lang="scss">
.m-message { padding: 12px; }
.msg-filter { margin-bottom: 10px; overflow-x: auto; }
.unread-stat {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: #fff7e6;
  border-radius: 6px;
  margin-bottom: 12px;
  font-size: 13px;
  color: #faad14;
  .el-icon { font-size: 16px; }
  b { font-size: 16px; margin: 0 2px; }
}
.msg-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.msg-card {
  cursor: pointer;
  transition: all 0.2s;
  :deep(.el-card__body) { padding: 12px; }
  &.unread {
    border-left: 3px solid #1564ff;
  }
}
.msg-head {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 6px;
  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
    &.level-info { background: #1564ff; }
    &.level-warning { background: #faad14; }
    &.level-danger { background: #f5222d; }
  }
  .msg-type {
    font-size: 11px;
    padding: 1px 6px;
    border-radius: 3px;
    color: #fff;
    &.type-approve { background: #1564ff; }
    &.type-warn { background: #faad14; }
    &.type-system { background: #909399; }
  }
  .unread-tag {
    font-size: 10px;
    color: #f5222d;
    border: 1px solid #f5222d;
    border-radius: 3px;
    padding: 0 4px;
  }
  .msg-time {
    margin-left: auto;
    font-size: 11px;
    color: #c0c4cc;
  }
}
.msg-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 4px;
}
.msg-content {
  font-size: 13px;
  color: #606266;
  line-height: 1.5;
}
</style>
