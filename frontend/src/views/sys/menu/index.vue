<template>
  <div class="menu-page">
    <!-- 工具栏 -->
    <div class="panel-card toolbar">
      <span class="panel-title">菜单管理</span>
      <div>
        <el-button type="primary" size="small" @click="onAdd(null)">新增顶级菜单</el-button>
        <el-button size="small" @click="loadList">刷新</el-button>
      </div>
    </div>

    <!-- 菜单树表格 -->
    <div class="panel-card table-panel">
      <div class="table-body">
        <el-table
          :data="tableData"
          v-loading="loading"
          size="small"
          border
          row-key="id"
          default-expand-all
          :tree-props="{ children: 'children' }"
        >
          <el-table-column prop="menu_name" label="菜单名称" min-width="200" />
          <el-table-column prop="menu_code" label="编码" width="180" />
          <el-table-column label="类型" width="80" align="center">
            <template #default="{ row }">
              <el-tag :type="typeTag(row.menu_type)" size="small">{{ typeLabel(row.menu_type) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="path" label="路由路径" width="200" />
          <el-table-column prop="icon" label="图标" width="110" />
          <el-table-column prop="sort_index" label="排序" width="70" align="center" />
          <el-table-column label="可见" width="70" align="center">
            <template #default="{ row }">
              <el-tag :type="row.visible === 1 ? 'success' : 'info'" size="small">
                {{ row.visible === 1 ? '显示' : '隐藏' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="70" align="center">
            <template #default="{ row }">
              <el-switch :model-value="row.status === 1" @change="onToggleStatus(row as any)" />
            </template>
          </el-table-column>
          <el-table-column label="操作" width="180" fixed="right" align="center">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="onAdd(row as any)">新增子菜单</el-button>
              <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
              <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" append-to-body>
      <el-form :model="form" label-width="100px" size="small">
        <el-form-item label="父菜单">
          <el-tree-select
            v-model="form.parent_id"
            :data="parentOptions"
            :props="{ label: 'menu_name', children: 'children', value: 'id' }"
            check-strictly
            clearable
            placeholder="顶级菜单（不选）"
            style="width:100%"
          />
        </el-form-item>
        <el-form-item label="菜单编码" required>
          <el-input v-model="form.menu_code" placeholder="如 SYS_USER（唯一）" :disabled="dialogMode === 'edit'" />
        </el-form-item>
        <el-form-item label="菜单名称" required>
          <el-input v-model="form.menu_name" placeholder="如 用户管理" />
        </el-form-item>
        <el-form-item label="菜单类型" required>
          <el-radio-group v-model="form.menu_type">
            <el-radio value="directory">目录</el-radio>
            <el-radio value="menu">菜单</el-radio>
            <el-radio value="button">按钮</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.menu_type === 'menu'" label="路由路径">
          <el-input v-model="form.path" placeholder="如 /sys/user（前端路由 path）" />
        </el-form-item>
        <el-form-item label="图标">
          <el-input v-model="form.icon" placeholder="Element Plus 图标名，如 DataBoard" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort_index" :min="1" :max="999" controls-position="right" />
        </el-form-item>
        <el-form-item label="是否显示">
          <el-switch v-model="form.visible" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="启用状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { menuApi, type SysMenu } from '@/api/perm'

const loading = ref(false)
const tableData = ref<SysMenu[]>([])
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const form = reactive<Partial<SysMenu>>({
  id: undefined,
  menu_code: '',
  menu_name: '',
  parent_id: 0,
  menu_type: 'menu',
  path: '',
  icon: '',
  sort_index: 99,
  visible: 1,
  status: 1,
  remark: ''
})

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增菜单' : '编辑菜单')

// 父菜单选项（含顶级"根"），用全量树
const parentOptions = computed(() => {
  const roots: any[] = [{ id: 0, menu_name: '顶级菜单', children: tableData.value }]
  return roots
})

function typeLabel(t: string) {
  if (t === 'directory') return '目录'
  if (t === 'menu') return '菜单'
  if (t === 'button') return '按钮'
  return t
}
function typeTag(t: string): 'primary' | 'success' | 'warning' | 'info' {
  if (t === 'directory') return 'primary'
  if (t === 'menu') return 'success'
  if (t === 'button') return 'warning'
  return 'info'
}

async function loadList() {
  loading.value = true
  try {
    tableData.value = await menuApi.adminTree()
  } finally {
    loading.value = false
  }
}

function resetForm() {
  Object.assign(form, {
    id: undefined, menu_code: '', menu_name: '', parent_id: 0,
    menu_type: 'menu', path: '', icon: '', sort_index: 99,
    visible: 1, status: 1, remark: ''
  })
}

function onAdd(parent: SysMenu | null) {
  resetForm()
  dialogMode.value = 'add'
  if (parent) {
    form.parent_id = parent.id
    // 子菜单类型默认跟父级互补：父是 directory → 子是 menu；父是 menu → 子是 button
    form.menu_type = parent.menu_type === 'directory' ? 'menu' : 'button'
  } else {
    form.parent_id = 0
    form.menu_type = 'directory'
  }
  dialogVisible.value = true
}

function onEdit(row: SysMenu) {
  resetForm()
  dialogMode.value = 'edit'
  Object.assign(form, row)
  dialogVisible.value = true
}

async function onSave() {
  if (!form.menu_code || !form.menu_name) {
    ElMessage.warning('请填写菜单编码和名称')
    return
  }
  if (form.menu_type === 'menu' && !form.path) {
    ElMessage.warning('菜单类型必须填写路由路径')
    return
  }
  if (form.parent_id == null) form.parent_id = 0
  try {
    if (dialogMode.value === 'add') {
      await menuApi.create({ ...form })
      ElMessage.success('新增成功')
    } else {
      if (form.id) {
        await menuApi.update(String(form.id), { ...form })
        ElMessage.success('保存成功')
      }
    }
    dialogVisible.value = false
    await loadList()
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  }
}

async function onDelete(row: SysMenu) {
  await ElMessageBox.confirm(`确定删除菜单「${row.menu_name}」吗？`, '提示', { type: 'warning' })
  try {
    await menuApi.delete(String(row.id))
    ElMessage.success('删除成功')
    await loadList()
  } catch (e: any) {
    ElMessage.error(e.message || '删除失败')
  }
}

async function onToggleStatus(row: SysMenu) {
  const newStatus = row.status === 1 ? 0 : 1
  await menuApi.update(String(row.id), { status: newStatus })
  ElMessage.success(newStatus === 1 ? '已启用' : '已停用')
  await loadList()
}

onMounted(loadList)
</script>

<style scoped lang="scss">
.menu-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
}
.panel-title { font-size: 14px; font-weight: 600; }
.table-panel {
  flex: 1;
  padding: 12px 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-body {
  flex: 1;
  overflow: auto;
}
</style>
