<template>
  <div class="role-page">
    <!-- 左侧角色列表 -->
    <div class="role-left panel-card">
      <div class="panel-header">
        <span class="panel-title">角色列表</span>
        <el-button type="primary" size="small" @click="onAddRole">新增</el-button>
      </div>
      <el-tree
        :data="roleTree"
        node-key="id"
        :props="{ label: 'role_name', children: 'children' }"
        :expand-on-click-node="false"
        default-expand-all
        highlight-current
        @node-click="onRoleClick"
      >
        <template #default="{ data }">
          <span class="role-node">
            <el-icon><User /></el-icon>
            <span>{{ data.role_name }}</span>
            <el-tag v-if="data.parent_role_id" size="small" type="info" effect="plain">继承</el-tag>
            <el-tag v-if="data.status === 0" size="small" type="danger" effect="plain">停用</el-tag>
            <el-icon
              v-if="data.id !== currentRole?.id || !editingInfo"
              class="toggle-icon"
              :class="{ enabled: data.status === 1 }"
              :title="data.status === 1 ? '点击停用' : '点击启用'"
              @click.stop="onToggleRoleStatus(data as Role)"
            >
              <Switch v-if="data.status === 1" />
              <Unlock v-else />
            </el-icon>
          </span>
        </template>
      </el-tree>
    </div>

    <!-- 右侧详情 -->
    <div class="role-right panel-card">
      <el-empty v-if="!currentRole" description="请选择左侧角色" />
      <template v-else>
        <el-tabs v-model="activeTab">
          <!-- 角色信息 -->
          <el-tab-pane label="角色信息" name="info">
            <el-form :model="roleForm" label-width="90px" size="small" class="detail-form">
              <el-form-item label="角色编码">
                <el-input v-model="roleForm.role_code" :disabled="!editingInfo" />
              </el-form-item>
              <el-form-item label="角色名称">
                <el-input v-model="roleForm.role_name" :disabled="!editingInfo" />
              </el-form-item>
              <el-form-item label="上级角色">
                <el-select v-model="roleForm.parent_role_id" :disabled="!editingInfo" clearable style="width:100%">
                  <el-option v-for="r in roleList" :key="r.id" :label="r.role_name" :value="r.id" :disabled="r.id === currentRole.id" />
                </el-select>
              </el-form-item>
              <el-form-item label="状态">
                <el-radio-group v-model="roleForm.status" :disabled="!editingInfo">
                  <el-radio :value="1">启用</el-radio>
                  <el-radio :value="0">停用</el-radio>
                </el-radio-group>
              </el-form-item>
              <el-form-item label="备注">
                <el-input v-model="roleForm.remark" type="textarea" :rows="3" :disabled="!editingInfo" />
              </el-form-item>
              <el-form-item>
                <template v-if="!editingInfo">
                  <el-button type="primary" @click="editingInfo = true">编辑</el-button>
                </template>
                <template v-else>
                  <el-button type="primary" @click="onSaveRole">保存</el-button>
                  <el-button @click="onCancelRole">取消</el-button>
                </template>
              </el-form-item>
            </el-form>
          </el-tab-pane>

          <!-- 按钮权限矩阵 -->
          <el-tab-pane label="按钮权限" name="buttons">
            <div class="matrix-toolbar">
              <span class="perm-legend">
                <el-tag size="small" type="success">可用</el-tag>
                <el-tag size="small" type="warning">禁用</el-tag>
                <el-tag size="small" type="info">隐藏</el-tag>
              </span>
              <el-button type="primary" size="small" @click="onSaveButtons">保存权限</el-button>
            </div>
            <el-table :data="matrixData" size="small" border height="480">
              <el-table-column prop="bo_name" label="业务对象" width="130" fixed />
              <el-table-column
                v-for="btn in buttonList"
                :key="btn"
                :label="btnLabel(btn)"
                :prop="btn"
                align="center"
                min-width="70"
              >
                <template #default="{ row }">
                  <el-tag
                    :type="permTagType(row[btn]) || 'info'"
                    size="small"
                    class="perm-cell"
                    @click="cyclePerm(row as any, btn)"
                  >{{ permLabel(row[btn]) }}</el-tag>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>

          <!-- 用户组成员 -->
          <el-tab-pane label="用户组成员" name="members">
            <el-table :data="memberList" size="small" border>
              <el-table-column type="index" label="#" width="45" />
              <el-table-column prop="user_code" label="账号" width="120" />
              <el-table-column prop="user_name" label="姓名" width="100" />
              <el-table-column label="主组织" min-width="140">
                <template #default="{ row }">{{ row.org_name || '-' }}</template>
              </el-table-column>
              <el-table-column prop="position" label="岗位" width="120" />
              <el-table-column label="状态" width="80">
                <template #default="{ row }">
                  <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>
        </el-tabs>
      </template>
    </div>

    <!-- 新增角色弹窗 -->
    <el-dialog v-model="roleDialogVisible" title="新增角色" width="460px" append-to-body>
      <el-form :model="newRole" label-width="90px" size="small">
        <el-form-item label="角色编码" required>
          <el-input v-model="newRole.role_code" placeholder="如：warehouse_keeper" />
        </el-form-item>
        <el-form-item label="角色名称" required>
          <el-input v-model="newRole.role_name" placeholder="如：仓库管理员" />
        </el-form-item>
        <el-form-item label="上级角色">
          <el-select v-model="newRole.parent_role_id" clearable style="width:100%">
            <el-option v-for="r in roleList" :key="r.id" :label="r.role_name" :value="r.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="newRole.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="roleDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onCreateRole">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { User, Switch, Unlock } from '@element-plus/icons-vue'
import { roleApi, userApi } from '@/api/perm'
import { STANDARD_BUTTON_LABELS } from '@/utils/enum'
import type { Role, RoleButton, ButtonAvailability, SysUser } from '@/types/bo'

const roleList = ref<Role[]>([])
const currentRole = ref<Role | null>(null)
const activeTab = ref('info')
const editingInfo = ref(false)
const roleDialogVisible = ref(false)
const roleButtons = ref<RoleButton[]>([])
const memberList = ref<(SysUser & { org_name?: string })[]>([])

const roleForm = reactive<Partial<Role>>({})
const newRole = reactive<Partial<Role>>({ role_code: '', role_name: '', parent_role_id: undefined, remark: '', status: 1 })

const buttonList = ['add', 'copy', 'save', 'submit', 'audit', 'revoke', 'reject', 'delete', 'change', 'push', 'print']
const boList = [
  { code: 'sal_order', name: '销售订单' },
  { code: 'pur_order', name: '采购订单' },
  { code: 'mfg_order', name: '生产订单' },
  { code: 'customer', name: '客户' },
  { code: 'material', name: '物料' },
  { code: 'supplier', name: '供应商' }
]

interface MatrixRow {
  bo_code: string
  bo_name: string
  [btn: string]: string
}

const matrixData = ref<MatrixRow[]>([])

const roleTree = computed(() => {
  const map = new Map<string, Role & { children?: any[] }>()
  const roots: (Role & { children?: any[] })[] = []
  roleList.value.forEach(r => map.set(r.id, { ...r, children: [] }))
  roleList.value.forEach(r => {
    const node = map.get(r.id)!
    if (r.parent_role_id && map.has(r.parent_role_id)) map.get(r.parent_role_id)!.children!.push(node)
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

function btnLabel(code: string) {
  return STANDARD_BUTTON_LABELS[code] || code
}
function permLabel(perm: ButtonAvailability) {
  const m: Record<string, string> = { enabled: '可用', disabled: '禁用', hidden: '隐藏', readonly: '只读' }
  return m[perm] || perm
}
function permTagType(perm: ButtonAvailability): 'success' | 'warning' | 'info' | '' {
  const m: Record<string, 'success' | 'warning' | 'info' | ''> = {
    enabled: 'success', disabled: 'warning', hidden: 'info', readonly: ''
  }
  return m[perm] || 'info'
}
const PERM_CYCLE: ButtonAvailability[] = ['enabled', 'disabled', 'hidden', 'readonly']
function cyclePerm(row: MatrixRow, btn: string) {
  const cur = row[btn] as ButtonAvailability
  const idx = PERM_CYCLE.indexOf(cur)
  row[btn] = PERM_CYCLE[(idx + 1) % PERM_CYCLE.length]
}

async function loadRoles() {
  roleList.value = await roleApi.list()
}

function onRoleClick(role: Role) {
  currentRole.value = role
  activeTab.value = 'info'
  editingInfo.value = false
  Object.assign(roleForm, role)
  loadRoleButtons(role.id)
  loadMembers(role.id)
}

async function loadRoleButtons(roleId: string) {
  roleButtons.value = await roleApi.buttons(roleId)
  buildMatrix()
}

function buildMatrix() {
  matrixData.value = boList.map(bo => {
    const row: MatrixRow = { bo_code: bo.code, bo_name: bo.name }
    buttonList.forEach(btn => {
      const rb = roleButtons.value.find(b => b.bo_code === bo.code && b.button_code === btn)
      row[btn] = rb?.perm || 'hidden'
    })
    return row
  })
}

function collectButtons(): RoleButton[] {
  const result: RoleButton[] = []
  matrixData.value.forEach(row => {
    buttonList.forEach(btn => {
      result.push({
        role_id: currentRole.value!.id, bo_code: row.bo_code,
        button_code: btn, perm: row[btn] as ButtonAvailability
      })
    })
  })
  return result
}

async function onSaveButtons() {
  await roleApi.saveButtons(currentRole.value!.id, collectButtons())
  ElMessage.success('权限已保存')
  await loadRoleButtons(currentRole.value!.id)
}

async function loadMembers(roleId: string) {
  const res: any = await userApi.list({ pageSize: 100 })
  memberList.value = (res.list || []).filter((u: SysUser) => u.role_ids.includes(roleId))
}

async function onSaveRole() {
  if (!roleForm.role_code || !roleForm.role_name) {
    ElMessage.warning('请填写角色编码和名称')
    return
  }
  await roleApi.update(currentRole.value!.id, { ...roleForm })
  ElMessage.success('保存成功')
  editingInfo.value = false
  await loadRoles()
  const updated = roleList.value.find(r => r.id === currentRole.value!.id)
  if (updated) { currentRole.value = updated; Object.assign(roleForm, updated) }
}

function onCancelRole() {
  editingInfo.value = false
  if (currentRole.value) Object.assign(roleForm, currentRole.value)
}

function onAddRole() {
  Object.assign(newRole, { role_code: '', role_name: '', parent_role_id: undefined, remark: '', status: 1 })
  roleDialogVisible.value = true
}

async function onCreateRole() {
  if (!newRole.role_code || !newRole.role_name) {
    ElMessage.warning('请填写角色编码和名称')
    return
  }
  await roleApi.create({ ...newRole })
  ElMessage.success('新增成功')
  roleDialogVisible.value = false
  await loadRoles()
}

// GAP-D05-007 / PRD 04：角色快速启停（调用后端 API 持久化）
async function onToggleRoleStatus(role: Role) {
  const newStatus = role.status === 0 ? 1 : 0
  try {
    await ElMessageBox.confirm(
      `确定${newStatus === 1 ? '启用' : '停用'}角色「${role.role_name}」吗？${newStatus === 0 ? '停用后该角色用户将失去对应权限。' : ''}`,
      '提示',
      { type: 'warning', confirmButtonText: '确定', cancelButtonText: '取消' }
    )
  } catch { return }
  try {
    await roleApi.update(role.id, { status: newStatus })
    role.status = newStatus
    ElMessage.success(newStatus === 1 ? '已启用' : '已停用')
    await loadRoles()
    // 保持当前选中角色指向最新数据
    const updated = roleList.value.find(r => r.id === role.id)
    if (updated && currentRole.value?.id === updated.id) {
      currentRole.value = updated
      Object.assign(roleForm, updated)
    }
  } catch {
    ElMessage.error('状态切换失败')
  }
}

onMounted(loadRoles)
</script>

<style scoped lang="scss">
.role-page {
  height: 100%;
  display: flex;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.role-left {
  width: 280px;
  padding: 12px;
  overflow: auto;
}
.role-right {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title { font-size: 14px; font-weight: 600; }
.role-node {
  display: flex;
  align-items: center;
  gap: 6px;
  .el-icon { color: #1564ff; }
  .toggle-icon {
    margin-left: auto;
    cursor: pointer;
    color: #909399;
    font-size: 14px;
    padding: 2px;
    border-radius: 3px;
    transition: all 0.2s;
    &:hover { color: #1564ff; background: #ecf5ff; }
    &.enabled { color: #67c23a; }
    &.enabled:hover { color: #529b2e; background: #f0f9eb; }
  }
}
.detail-form { max-width: 520px; margin-top: 8px; }
.matrix-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.perm-legend {
  display: flex;
  gap: 6px;
  font-size: 12px;
  color: #606266;
  align-items: center;
}
.perm-cell {
  cursor: pointer;
  min-width: 44px;
  text-align: center;
}
</style>
