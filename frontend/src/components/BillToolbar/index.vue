<template>
  <div class="bill-toolbar">
    <template v-for="btn in visibleButtons" :key="btn.button_code">
      <el-button
        :type="getButtonType(btn)"
        :disabled="isDisabled(btn)"
        size="small"
        @click="onClick(btn)"
      >
        <el-icon v-if="btn.icon"><component :is="btn.icon" /></el-icon>
        <span>{{ getLabel(btn) }}</span>
      </el-button>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { standardButtons } from '@/config/standard-buttons'
import type { ButtonDef, ButtonAvailability } from '@/types/bo'

const props = withDefaults(defineProps<{
  pactState: number
  position?: 'form' | 'list'
  buttons?: ButtonDef[]
  isClosed?: boolean
  isCancel?: boolean
  selectedCount?: number  // 列表选中行数
}>(), {
  position: 'form',
  buttons: () => standardButtons,
  isClosed: false,
  isCancel: false,
  selectedCount: 0
})

const emit = defineEmits<{
  click: [buttonCode: string]
}>()

// 当前状态下的可用性
function getAvailability(btn: ButtonDef): ButtonAvailability {
  return btn.availability[props.pactState] || 'hidden'
}

// 可见按钮（过滤 hidden 和不符合 position 的）
const visibleButtons = computed(() => {
  return props.buttons.filter(btn => {
    if (btn.position !== 'both' && btn.position !== props.position) return false
    const avail = getAvailability(btn)
    if (avail === 'hidden') return false
    // 列表页部分按钮需选中行
    if (props.position === 'list') {
      if (['copy', 'push', 'revoke', 'delete', 'change', 'trace', 'close', 'cancel'].includes(btn.button_code)) {
        // add 不需要选中，其他需要
        if (btn.button_code !== 'add' && props.selectedCount === 0) return false
      }
    }
    return true
  })
})

function isDisabled(btn: ButtonDef): boolean {
  return getAvailability(btn) === 'disabled'
}

function getButtonType(btn: ButtonDef): 'primary' | 'default' | 'danger' | 'success' | 'warning' {
  if (btn.button_code === 'save' || btn.button_code === 'submit') return 'primary'
  if (btn.button_code === 'audit') return 'success'
  if (btn.button_code === 'delete' || btn.button_code === 'cancel') return 'danger'
  if (btn.button_code === 'reject') return 'danger'
  return 'default'
}

function getLabel(btn: ButtonDef): string {
  // 关闭/取消按钮根据状态显示反操作
  if (btn.button_code === 'close') return props.isClosed ? '反关闭' : '关闭'
  if (btn.button_code === 'cancel') return props.isCancel ? '反取消' : '取消'
  return btn.button_name
}

function onClick(btn: ButtonDef) {
  if (isDisabled(btn)) return
  if (btn.need_confirm) {
    // 需二次确认的按钮由父组件处理弹窗
    emit('click', btn.button_code)
  } else {
    emit('click', btn.button_code)
  }
}
</script>

<style scoped lang="scss">
.bill-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  padding: 8px 12px;
  background: #fff;
  border-bottom: 1px solid #ebeef5;
  .el-button {
    margin: 0;
  }
}
</style>
