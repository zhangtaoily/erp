<template>
  <div class="tree-selector">
    <div class="tree-panel">
      <div class="tree-header">
        <span class="tree-title">{{ title }}</span>
        <div class="tree-actions">
          <el-button size="small" type="primary" link @click="onAddRoot" :disabled="readonly">
            <el-icon><Plus /></el-icon>新增
          </el-button>
          <el-button size="small" type="primary" link @click="onEdit" :disabled="!currentNode || readonly">
            <el-icon><Edit /></el-icon>编辑
          </el-button>
          <el-button size="small" type="danger" link @click="onDelete" :disabled="!currentNode || readonly">
            <el-icon><Delete /></el-icon>删除
          </el-button>
        </div>
      </div>

      <div v-if="showTypeFilter" class="type-filter">
        <el-select
          v-model="typeFilter"
          placeholder="按类型过滤"
          clearable
          size="small"
          style="width: 100%"
        >
          <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
        </el-select>
      </div>

      <el-tree
        ref="treeRef"
        :data="treeData"
        node-key="id"
        :props="treeProps"
        :draggable="draggable && !readonly"
        :expand-on-click-node="false"
        highlight-current
        default-expand-all
        :filter-node-method="filterNode"
        @node-click="onNodeClick"
        @node-drop="onNodeDrop"
      >
        <template #default="{ node, data }">
          <span class="tree-node">
            <el-tag
              v-if="data.type"
              :type="typeTagType(data.type)"
              size="small"
              effect="plain"
              class="node-type-tag"
            >
              {{ typeLabel(data.type) }}
            </el-tag>
            <span class="node-label" :title="node.label">{{ node.label }}</span>
          </span>
        </template>
      </el-tree>
    </div>

    <div class="detail-panel">
      <div class="detail-header">节点详情</div>
      <el-form
        v-if="currentNode"
        :model="currentNode"
        label-width="80px"
        size="small"
        class="detail-form"
      >
        <el-form-item label="节点ID">
          <el-input v-model="currentNode.id" disabled />
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="currentNode.label" :disabled="readonly" @change="onDetailChange" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select
            v-model="currentNode.type"
            :disabled="readonly"
            @change="onDetailChange"
            style="width: 100%"
          >
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="currentNode.children !== undefined" label="子节点数">
          <el-input :model-value="(currentNode.children || []).length" disabled />
        </el-form-item>
      </el-form>
      <el-empty v-else description="请选择左侧节点" :image-size="60" />
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="400px"
      append-to-body
      destroy-on-close
    >
      <el-form :model="dialogForm" label-width="80px" size="small">
        <el-form-item label="名称" required>
          <el-input v-model="dialogForm.label" placeholder="请输入节点名称" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="dialogForm.type" style="width: 100%" placeholder="请选择类型">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmDialog">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

export interface TreeNode {
  id: string
  label: string
  type?: string
  children?: TreeNode[]
  [key: string]: any
}

const props = withDefaults(
  defineProps<{
    treeData: TreeNode[]
    title?: string
    showTypeFilter?: boolean
    draggable?: boolean
    readonly?: boolean
    typeOptions?: { value: string; label: string }[]
  }>(),
  {
    title: '树形选择',
    showTypeFilter: false,
    draggable: true,
    readonly: false,
    typeOptions: () => [
      { value: 'group', label: '分组' },
      { value: 'item', label: '项' }
    ]
  }
)

const emit = defineEmits<{
  (e: 'nodeClick', node: TreeNode): void
  (e: 'add', parent: TreeNode | null, newNode: TreeNode): void
  (e: 'edit', node: TreeNode): void
  (e: 'delete', node: TreeNode): void
  (e: 'drop', dragNode: TreeNode, dropNode: TreeNode, position: string): void
}>()

const treeRef = ref()
const currentNode = ref<TreeNode | null>(null)
const typeFilter = ref('')
const treeProps = { label: 'label', children: 'children' }

const dialogVisible = ref(false)
const dialogTitle = ref('新增节点')
const dialogMode = ref<'add' | 'edit'>('add')
const dialogForm = reactive<{ label: string; type: string }>({ label: '', type: '' })

const typeOptions = computed(() => props.typeOptions)

function typeLabel(t?: string) {
  if (!t) return ''
  return typeOptions.value.find(o => o.value === t)?.label || t
}

function typeTagType(t?: string): 'primary' | 'success' | 'warning' | 'info' | 'danger' {
  const map: Record<string, 'primary' | 'success' | 'warning' | 'info' | 'danger'> = {
    group: 'primary',
    item: 'success',
    default: 'info'
  }
  return map[t || 'default'] || 'info'
}

function onNodeClick(data: TreeNode) {
  currentNode.value = data
  emit('nodeClick', data)
}

function filterNode(value: string, data: any) {
  if (!value) return true
  return (data as TreeNode).type === value
}

watch(typeFilter, (val) => {
  treeRef.value?.filter(val)
})

function findParent(tree: TreeNode[], id: string, parent: TreeNode | null = null): TreeNode | null {
  for (const n of tree) {
    if (n.id === id) return parent
    if (n.children?.length) {
      const found = findParent(n.children, id, n)
      if (found) return found
    }
  }
  return null
}

function findNode(tree: TreeNode[], id: string): TreeNode | null {
  for (const n of tree) {
    if (n.id === id) return n
    if (n.children?.length) {
      const found = findNode(n.children, id)
      if (found) return found
    }
  }
  return null
}

function onAddRoot() {
  dialogMode.value = 'add'
  dialogTitle.value = '新增根节点'
  dialogForm.label = ''
  dialogForm.type = typeOptions.value[0]?.value || ''
  dialogVisible.value = true
}

function onEdit() {
  if (!currentNode.value) return
  dialogMode.value = 'edit'
  dialogTitle.value = '编辑节点'
  dialogForm.label = currentNode.value.label
  dialogForm.type = currentNode.value.type || ''
  dialogVisible.value = true
}

function onDelete() {
  if (!currentNode.value) return
  const node = currentNode.value
  ElMessageBox.confirm(`确定删除节点「${node.label}」及其子节点吗？`, '提示', {
    type: 'warning'
  })
    .then(() => {
      const parent = findParent(props.treeData, node.id)
      if (parent && parent.children) {
        const idx = parent.children.findIndex(n => n.id === node.id)
        if (idx > -1) parent.children.splice(idx, 1)
      } else {
        const idx = props.treeData.findIndex(n => n.id === node.id)
        if (idx > -1) props.treeData.splice(idx, 1)
      }
      currentNode.value = null
      emit('delete', node)
      ElMessage.success('删除成功')
    })
    .catch(() => {})
}

function confirmDialog() {
  if (!dialogForm.label.trim()) {
    ElMessage.warning('请输入节点名称')
    return
  }
  if (dialogMode.value === 'add') {
    const newNode: TreeNode = {
      id: `n_${Date.now()}`,
      label: dialogForm.label,
      type: dialogForm.type,
      children: []
    }
    if (currentNode.value) {
      if (!currentNode.value.children) currentNode.value.children = []
      currentNode.value.children.push(newNode)
    } else {
      props.treeData.push(newNode)
    }
    emit('add', currentNode.value, newNode)
    ElMessage.success('新增成功')
  } else {
    if (currentNode.value) {
      currentNode.value.label = dialogForm.label
      currentNode.value.type = dialogForm.type
      emit('edit', currentNode.value)
      ElMessage.success('编辑成功')
    }
  }
  dialogVisible.value = false
}

function onDetailChange() {
  if (currentNode.value) {
    emit('edit', currentNode.value)
    // 触发树刷新
    const id = currentNode.value.id
    nextTick(() => {
      treeRef.value?.setCurrentKey(id)
    })
  }
}

function onNodeDrop(
  draggingNode: any,
  dropNode: any,
  dropType: 'before' | 'after' | 'inner'
) {
  const dragData = draggingNode.data as TreeNode
  const dropData = dropNode.data as TreeNode
  emit('drop', dragData, dropData, dropType)
}
</script>

<style scoped lang="scss">
.tree-selector {
  display: flex;
  gap: 12px;
  height: 100%;
  min-height: 360px;
  background: #fff;
}
.tree-panel {
  flex: 1;
  min-width: 0;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.tree-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
}
.tree-title {
  font-weight: 600;
  font-size: 13px;
}
.tree-actions {
  display: flex;
  gap: 4px;
}
.type-filter {
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
}
:deep(.el-tree) {
  flex: 1;
  overflow: auto;
  padding: 8px;
}
.tree-node {
  display: flex;
  align-items: center;
  gap: 6px;
  flex: 1;
  overflow: hidden;
}
.node-type-tag {
  flex-shrink: 0;
}
.node-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.detail-panel {
  width: 280px;
  flex-shrink: 0;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
}
.detail-header {
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  font-weight: 600;
  font-size: 13px;
}
.detail-form {
  padding: 12px;
  flex: 1;
  overflow: auto;
}
:deep(.el-tree-node__content) {
  height: 30px;
}
</style>
