<template>
  <div class="transfer-picker">
    <div v-if="title" class="transfer-title">{{ title }}</div>
    <el-transfer
      v-model="rightKeys"
      :data="transferData"
      :titles="['待选', '已选']"
      :button-texts="['移除', '添加']"
      :filterable="filterable"
      :filter-placeholder="filterPlaceholder"
      :props="{ key: 'id', label: 'label' }"
      :left-default-checked="leftDefaultChecked"
      :right-default-checked="rightDefaultChecked"
      @change="onChange"
      @left-check-change="onLeftCheck"
      @right-check-change="onRightCheck"
    >
      <template #default="{ option }">
        <slot name="option" :option="option">
          <span class="transfer-option">
            <span class="opt-label">{{ option.label }}</span>
            <span v-if="option.desc" class="opt-desc">{{ option.desc }}</span>
          </span>
        </slot>
      </template>
      <template #left-footer>
        <span class="footer-tip">共 {{ leftData.length }} 条</span>
      </template>
      <template #right-footer>
        <span class="footer-tip">已选 {{ rightKeys.length }} 条</span>
      </template>
    </el-transfer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'

export interface TransferItem {
  id: string | number
  label: string
  desc?: string
  [key: string]: any
}

const props = withDefaults(
  defineProps<{
    leftData: TransferItem[]
    rightData?: TransferItem[]
    title?: string
    filterable?: boolean
    filterPlaceholder?: string
  }>(),
  {
    rightData: () => [],
    title: '',
    filterable: true,
    filterPlaceholder: '请输入关键字搜索'
  }
)

const emit = defineEmits<{
  (e: 'change', rightData: TransferItem[]): void
  (e: 'left-check-change', checked: TransferItem[]): void
  (e: 'right-check-change', checked: TransferItem[]): void
}>()

// el-transfer 的 data 需要包含所有可选项（左右合并）
const transferData = computed(() => {
  // 合并：左侧全部 + 右侧中不在左侧的项
  const merged: TransferItem[] = [...props.leftData]
  props.rightData.forEach(r => {
    if (!merged.find(m => m.id === r.id)) merged.push(r)
  })
  return merged
})

const rightKeys = ref<(string | number)[]>([])

// 同步已选 keys
function syncRightKeys() {
  rightKeys.value = props.rightData.map(d => d.id)
}

watch(() => props.rightData, syncRightKeys, { immediate: true, deep: true })

const leftDefaultChecked = ref<(string | number)[]>([])
const rightDefaultChecked = ref<(string | number)[]>([])

function onChange(keys: (string | number)[]) {
  const rightData = props.leftData
    .concat(props.rightData)
    .filter(item => keys.includes(item.id))
  emit('change', rightData)
}

function onLeftCheck(checkedKeys: (string | number)[]) {
  const checked = props.leftData.filter(item => checkedKeys.includes(item.id))
  emit('left-check-change', checked)
}

function onRightCheck(checkedKeys: (string | number)[]) {
  const checked = props.rightData.filter(item => checkedKeys.includes(item.id))
  emit('right-check-change', checked)
}
</script>

<style scoped lang="scss">
.transfer-picker {
  background: #fff;
}
.transfer-title {
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 8px;
  color: #303133;
}
.transfer-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding-right: 8px;
}
.opt-label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.opt-desc {
  color: #909399;
  font-size: 12px;
  margin-left: 8px;
  flex-shrink: 0;
}
.footer-tip {
  color: #909399;
  font-size: 12px;
  padding: 0 12px;
  line-height: 32px;
}
:deep(.el-transfer-panel) {
  width: 240px;
}
:deep(.el-transfer-panel__body) {
  height: 280px;
}
:deep(.el-transfer-panel__list) {
  height: 100%;
}
</style>
