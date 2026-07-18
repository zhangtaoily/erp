<template>
  <div class="user-page">
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
          <el-input v-model="query.keyword" clearable placeholder="账号/姓名/手机号" style="width:180px" @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
          <el-button type="primary" plain @click="onAdd">新增用户</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 用户列表 -->
    <div class="panel-card table-panel">
      <div class="table-body">
        <el-table :data="tableData" size="small" border stripe v-loading="loading">
          <el-table-column type="index" label="#" width="45" />
          <el-table-column prop="user_code" label="账号" width="110" />
          <el-table-column prop="user_name" label="姓名" width="90" />
          <el-table-column label="主组织" width="130">
            <template #default="{ row }">{{ orgName(row.org_id) }}</template>
          </el-table-column>
          <el-table-column label="多组织" width="80" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="info" effect="plain">{{ userOrgCount(row) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="部门" width="90">
            <template #default="{ row }">{{ deptName(row.dept_id) }}</template>
          </el-table-column>
          <el-table-column prop="position" label="岗位" width="100" />
          <el-table-column label="角色" min-width="160">
            <template #default="{ row }">
              <el-tag v-for="rid in row.role_ids" :key="rid" size="small" class="mr-4">{{ roleName(rid) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="phone" label="手机号" width="120" />
          <el-table-column label="状态" width="70">
            <template #default="{ row }">
              <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="170" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="onConfigOrgs(row as any)">多组织</el-button>
              <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
              <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" append-to-body>
      <el-form :model="dialogForm" label-width="90px" size="small">
        <el-form-item label="账号" required>
          <el-input v-model="dialogForm.user_code" :disabled="dialogMode === 'edit'" placeholder="登录账号" />
        </el-form-item>
        <el-form-item label="姓名" required>
          <el-input v-model="dialogForm.user_name" placeholder="真实姓名" />
        </el-form-item>
        <el-form-item label="主组织" required>
          <el-tree-select
            v-model="dialogForm.org_id"
            :data="orgTreeData"
            :props="({ label: 'org_name', children: 'children', value: 'id' }) as any"
            check-strictly
            placeholder="选择主组织"
            style="width:100%"
          />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="dialogForm.dept_id" clearable placeholder="选择部门" style="width:100%">
            <el-option v-for="d in deptList" :key="d.id" :label="d.dept_name + '（' + orgName(d.org_id) + '）'" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="岗位">
          <el-input v-model="dialogForm.position" placeholder="岗位名称" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="dialogForm.role_ids" multiple placeholder="选择角色（可多选）" style="width:100%">
            <el-option v-for="r in roleList" :key="r.id" :label="r.role_name" :value="r.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="dialogForm.phone" placeholder="手机号" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="dialogForm.email" placeholder="邮箱" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="dialogForm.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onDialogSave">确定</el-button>
      </template>
    </el-dialog>

    <!-- 多组织归属配置弹窗（GAP-D11-001 / RISK-D11-002）-->
    <el-dialog v-model="orgDialogVisible" :title="'多组织归属配置 - ' + (orgEditUser?.user_name || '')" width="640px" append-to-body>
      <el-alert type="info" :closable="false" show-icon style="margin-bottom:12px">
        一个用户可归属多个组织，标记一个主组织（is_main=1）；跨组织业务时按归属组织查询数据。
      </el-alert>
      <el-table :data="userOrgs" size="small" border v-loading="orgEditLoading">
        <el-table-column label="主组织" width="80" align="center">
          <template #default="{ row, $index }">
            <el-radio :model-value="row.is_main" :value="1" @change="onSetMainOrg($index)">&nbsp;</el-radio>
          </template>
        </el-table-column>
        <el-table-column label="归属组织" min-width="180">
          <template #default="{ row }">
            <el-tree-select
              v-model="row.org_id"
              :data="orgTreeData"
              :props="({ label: 'org_name', children: 'children', value: 'id' }) as any"
              check-strictly
              placeholder="选择组织"
              style="width:100%"
              size="small"
            />
          </template>
        </el-table-column>
        <el-table-column label="生效日期" width="150">
          <template #default="{ row }">
            <el-date-picker v-model="row.eff_date" type="date" value-format="YYYY-MM-DD" size="small" style="width:100%" />
          </template>
        </el-table-column>
        <el-table-column label="失效日期" width="150">
          <template #default="{ row }">
            <el-date-picker v-model="row.exp_date" type="date" value-format="YYYY-MM-DD" size="small" style="width:100%" placeholder="永久" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="70" align="center">
          <template #default="{ $index }">
            <el-button link type="danger" size="small" @click="onRemoveUserOrg($index)">移除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="margin-top:10px">
        <el-button type="primary" plain size="small" @click="onAddUserOrg">+ 添加归属组织</el-button>
      </div>
      <template #footer>
        <el-button @click="orgDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSaveUserOrgs">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { userApi, orgApi, roleApi, deptApi, userOrgApi } from '@/api/perm'
import type { SysUser, Org, Role, SysDept, SysUserOrg } from '@/types/bo'

const loading = ref(false)
const tableData = ref<SysUser[]>([])
const total = ref(0)
const orgList = ref<Org[]>([])
const roleList = ref<Role[]>([])
const deptList = ref<SysDept[]>([])   // 部门列表改为从 API 加载（GAP-D11-004）
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const query = reactive({
  org_id: '' as string, status: '' as string | number, keyword: '',
  pageNum: 1, pageSize: 10
})
const dialogForm = reactive<Partial<SysUser>>({
  user_code: '', user_name: '', org_id: '', dept_id: '', position: '',
  role_ids: [], phone: '', email: '', status: 1
})

// 多组织归属配置（GAP-D11-001 / RISK-D11-002）
const orgDialogVisible = ref(false)
const orgEditUser = ref<SysUser | null>(null)
const userOrgs = ref<SysUserOrg[]>([])
const orgEditLoading = ref(false)

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增用户' : '编辑用户')

interface TreeNode extends Org { children?: TreeNode[] }
// GAP-D11-010：组织树过滤 status===1 停用组织，避免停用组织被选为主组织/兼任组织
const orgTreeData = computed<TreeNode[]>(() => buildTree(orgList.value.filter(o => o.status === 1)))

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

function orgName(id: string) {
  return orgList.value.find(o => o.id === id)?.org_name || '-'
}
function deptName(id?: string) {
  return deptList.value.find(d => d.id === id)?.dept_name || '-'
}
function roleName(id: string) {
  return roleList.value.find(r => r.id === id)?.role_name || id
}

// 主组织/兼任组织标签（GAP-D11-001 / RISK-D11-002）
function userOrgCount(row: any): string {
  // 仅原型展示：根据 mock userOrgList 推断（实际由后端返回 user_org_count 字段更佳）
  return row.org_id ? '1+' : '-'
}

async function loadData() {
  loading.value = true
  try {
    const res: any = await userApi.list(query)
    tableData.value = res.list || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

async function loadDepts() {
  // 部门列表改为从 API 加载（GAP-D11-004）
  deptList.value = await deptApi.list()
}

function onSearch() {
  query.pageNum = 1
  loadData()
}
function onReset() {
  query.org_id = ''
  query.status = ''
  query.keyword = ''
  query.pageNum = 1
  loadData()
}

function onAdd() {
  dialogMode.value = 'add'
  Object.assign(dialogForm, {
    user_code: '', user_name: '', org_id: '', dept_id: '', position: '',
    role_ids: [], phone: '', email: '', status: 1
  })
  dialogVisible.value = true
}

function onEdit(row: SysUser) {
  dialogMode.value = 'edit'
  Object.assign(dialogForm, { ...row, role_ids: [...row.role_ids] })
  dialogVisible.value = true
}

async function onDialogSave() {
  if (!dialogForm.user_code || !dialogForm.user_name || !dialogForm.org_id) {
    ElMessage.warning('请填写账号、姓名和主组织')
    return
  }
  if (dialogMode.value === 'add') {
    await userApi.create({ ...dialogForm })
    ElMessage.success('新增成功')
  } else {
    await userApi.update((dialogForm as SysUser).id, { ...dialogForm })
    ElMessage.success('保存成功')
  }
  dialogVisible.value = false
  loadData()
}

async function onDelete(row: SysUser) {
  await ElMessageBox.confirm(`确定删除用户「${row.user_name}」吗？`, '提示', { type: 'warning' })
  await userApi.delete(row.id)
  ElMessage.success('删除成功')
  loadData()
}

// 多组织归属配置（GAP-D11-001 / RISK-D11-002）
async function onConfigOrgs(row: SysUser) {
  orgEditUser.value = row
  orgDialogVisible.value = true
  orgEditLoading.value = true
  try {
    userOrgs.value = await userOrgApi.list(row.id)
    // 若用户无任何组织归属记录，按主组织自动补一条
    if (!userOrgs.value.length) {
      userOrgs.value = [{ id: 'tmp_' + Date.now(), user_id: row.id, org_id: row.org_id, is_main: 1, eff_date: '2026-01-01' }]
    }
  } finally {
    orgEditLoading.value = false
  }
}

function onAddUserOrg() {
  userOrgs.value.push({ id: 'tmp_' + Date.now(), user_id: orgEditUser.value?.id || '', org_id: '', is_main: 0, eff_date: '2026-01-01' })
}

function onRemoveUserOrg(idx: number) {
  userOrgs.value.splice(idx, 1)
}

function onSetMainOrg(idx: number) {
  // 一个用户仅一个主组织，切换主组织时清除其他 is_main
  userOrgs.value.forEach((o, i) => { o.is_main = i === idx ? 1 : 0 })
}

async function onSaveUserOrgs() {
  if (!orgEditUser.value) return
  // 校验：必须且仅有一个主组织
  const mainCount = userOrgs.value.filter(o => o.is_main === 1).length
  if (mainCount !== 1) {
    ElMessage.warning('必须且仅有一个主组织')
    return
  }
  // 校验：组织不能重复
  const orgIds = userOrgs.value.map(o => o.org_id)
  if (new Set(orgIds).size !== orgIds.length) {
    ElMessage.warning('组织不能重复')
    return
  }
  // 同步回主组织字段
  const mainOrg = userOrgs.value.find(o => o.is_main === 1)
  if (mainOrg && mainOrg.org_id !== orgEditUser.value.org_id) {
    orgEditUser.value.org_id = mainOrg.org_id
    await userApi.update(orgEditUser.value.id, { org_id: mainOrg.org_id })
  }
  await userOrgApi.save(orgEditUser.value.id, userOrgs.value)
  ElMessage.success('多组织归属已保存')
  orgDialogVisible.value = false
  loadData()
}

onMounted(async () => {
  orgList.value = await orgApi.tree()
  roleList.value = await roleApi.list()
  await loadDepts()
  loadData()
})
</script>

<style scoped lang="scss">
.user-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.search-bar {
  padding: 12px 12px 0;
}
.table-panel {
  padding: 12px;
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-body {
  flex: 1;
  overflow: auto;
}
.pagination-bar {
  margin-top: 12px;
  display: flex;
  justify-content: flex-end;
}
.mr-4 { margin-right: 4px; }
</style>
