<template>
  <div class="dept-page page-container">
    <!-- 搜索栏 -->
    <div class="panel-card search-bar">
      <el-form :inline="true" size="small">
        <el-form-item label="组织">
          <el-tree-select
            v-model="query.org_id"
            :data="orgTreeData"
            :props="({ label: 'org_name', children: 'children', value: 'id' }) as any"
            check-strictly
            clearable
            placeholder="全部组织"
            style="width:200px"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" clearable placeholder="编码/名称" style="width:180px" @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
          <el-button type="primary" plain @click="onAdd">新增部门</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 部门列表 -->
    <div class="panel-card table-panel">
      <el-table :data="filteredDeptList" size="small" border stripe v-loading="loading" row-key="id" default-expand-all>
        <el-table-column prop="dept_code" label="部门编码" width="140" />
        <el-table-column prop="dept_name" label="部门名称" min-width="160" />
        <el-table-column label="所属组织" width="160">
          <template #default="{ row }">{{ orgName(row.org_id) }}</template>
        </el-table-column>
        <el-table-column label="上级部门" width="140">
          <template #default="{ row }">{{ parentName(row.parent_id) }}</template>
        </el-table-column>
        <el-table-column prop="sort_index" label="排序" width="80" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
            <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="520px" append-to-body>
      <el-form :model="dialogForm" label-width="90px" size="small">
        <el-form-item label="部门编码" required>
          <el-input v-model="dialogForm.dept_code" :disabled="dialogMode === 'edit'" placeholder="如 SALES" />
        </el-form-item>
        <el-form-item label="部门名称" required>
          <el-input v-model="dialogForm.dept_name" placeholder="如 销售部" />
        </el-form-item>
        <el-form-item label="所属组织" required>
          <el-tree-select
            v-model="dialogForm.org_id"
            :data="orgTreeData"
            :props="({ label: 'org_name', children: 'children', value: 'id' }) as any"
            check-strictly
            placeholder="选择组织"
            style="width:100%"
          />
        </el-form-item>
        <el-form-item label="上级部门">
          <el-select v-model="dialogForm.parent_id" clearable placeholder="顶级部门" style="width:100%">
            <el-option v-for="d in parentCandidates" :key="d.id" :label="d.dept_name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="dialogForm.sort_index" :min="0" :max="999" controls-position="right" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="dialogForm.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="dialogForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onDialogSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { deptApi, orgApi } from '@/api/perm'
import type { SysDept, Org } from '@/types/bo'

const loading = ref(false)
const deptList = ref<SysDept[]>([])
const orgList = ref<Org[]>([])
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const query = reactive({
  org_id: '' as string, status: '' as string | number, keyword: ''
})
const dialogForm = reactive<Partial<SysDept>>({
  dept_code: '', dept_name: '', org_id: '', parent_id: undefined,
  sort_index: 99, status: 1, remark: ''
})

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增部门' : '编辑部门')

interface TreeNode extends Org { children?: TreeNode[] }
const orgTreeData = computed<TreeNode[]>(() => buildTree(orgList.value))

function buildTree(list: Org[]): TreeNode[] {
  const map = new Map<string, TreeNode>()
  const roots: TreeNode[] = []
  list.forEach(o => map.set(o.id, { ...o, children: [] }))
  list.forEach(o => {
    const node = map.get(o.id)!
    if (o.parent_id && map.has(o.parent_id)) map.get(o.parent_id)!.children!.push(node)
    else roots.push(node)
  })
  const clean = (nodes: TreeNode[]) => {
    nodes.forEach(n => {
      if (n.children && n.children.length === 0) delete n.children
      else if (n.children) clean(n.children)
    })
  }
  clean(roots)
  return roots
}

// 树形数据（按 parent_id 构建层级）
const deptTreeData = computed(() => {
  const map = new Map<string, SysDept & { children?: any[] }>()
  const roots: (SysDept & { children?: any[] })[] = []
  deptList.value.forEach(d => map.set(d.id, { ...d, children: [] }))
  deptList.value.forEach(d => {
    const node = map.get(d.id)!
    if (d.parent_id && map.has(d.parent_id)) map.get(d.parent_id)!.children!.push(node)
    else roots.push(node)
  })
  const clean = (nodes: any[]) => {
    nodes.forEach(n => {
      if (n.children && n.children.length === 0) delete n.children
      else if (n.children) clean(n.children)
    })
  }
  clean(roots)
  return roots
})

// 过滤显示（保留树形结构）
const filteredDeptList = computed(() => {
  let list = deptTreeData.value
  // 关键字过滤：扁平化后过滤，再重建树
  if (query.keyword) {
    const kw = query.keyword
    const flat = deptList.value.filter(d => d.dept_code.includes(kw) || d.dept_name.includes(kw))
    return flat
  }
  if (query.org_id) {
    // 按组织过滤（扁平化展示）
    return deptList.value.filter(d => d.org_id === query.org_id)
  }
  if (query.status !== '' && query.status !== undefined) {
    return deptList.value.filter(d => d.status === Number(query.status))
  }
  return list
})

function orgName(id: string) {
  return orgList.value.find(o => o.id === id)?.org_name || '-'
}
function parentName(id?: string) {
  if (!id) return '-'
  return deptList.value.find(d => d.id === id)?.dept_name || '-'
}

// 上级部门候选（排除自己和子孙）
const parentCandidates = computed(() => {
  if (dialogMode.value !== 'edit' || !dialogForm.id) return deptList.value
  // 排除自身
  return deptList.value.filter(d => d.id !== dialogForm.id)
})

async function loadData() {
  loading.value = true
  try {
    deptList.value = await deptApi.list()
  } finally {
    loading.value = false
  }
}

function onSearch() { loadData() }
function onReset() {
  query.org_id = ''
  query.status = ''
  query.keyword = ''
  loadData()
}

function onAdd() {
  dialogMode.value = 'add'
  Object.assign(dialogForm, {
    id: undefined, dept_code: '', dept_name: '', org_id: query.org_id || '',
    parent_id: undefined, sort_index: 99, status: 1, remark: ''
  })
  dialogVisible.value = true
}

function onEdit(row: SysDept) {
  dialogMode.value = 'edit'
  Object.assign(dialogForm, { ...row })
  dialogVisible.value = true
}

async function onDialogSave() {
  if (!dialogForm.dept_code || !dialogForm.dept_name || !dialogForm.org_id) {
    ElMessage.warning('请填写部门编码、名称和所属组织')
    return
  }
  if (dialogMode.value === 'add') {
    await deptApi.create({ ...dialogForm })
    ElMessage.success('新增成功')
  } else {
    await deptApi.update((dialogForm as SysDept).id!, { ...dialogForm })
    ElMessage.success('保存成功')
  }
  dialogVisible.value = false
  loadData()
}

async function onDelete(row: SysDept) {
  // 校验：是否有子部门
  const hasChild = deptList.value.some(d => d.parent_id === row.id)
  if (hasChild) {
    ElMessage.warning('该部门存在子部门，请先删除子部门')
    return
  }
  await ElMessageBox.confirm(`确定删除部门「${row.dept_name}」吗？`, '提示', { type: 'warning' })
  await deptApi.delete(row.id)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(async () => {
  orgList.value = await orgApi.tree()
  loadData()
})
</script>

<style scoped lang="scss">
.dept-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.search-bar { padding: 12px 12px 0; }
.table-panel { padding: 12px; flex: 1; }
</style>
