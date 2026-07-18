<template>
  <div class="dp-page">
    <!-- 左侧角色列表 -->
    <div class="dp-left panel-card">
      <div class="panel-header"><span class="panel-title">角色列表</span></div>
      <el-radio-group v-model="selectedRoleId" class="role-radio-list" @change="loadRules">
        <el-radio v-for="r in roleList" :key="r.id" :value="r.id" class="role-radio-item">
          <el-icon><User /></el-icon>
          <span>{{ r.role_name }}</span>
          <el-tag v-if="r.parent_role_id" size="small" type="info" effect="plain">继承</el-tag>
        </el-radio>
      </el-radio-group>
    </div>

    <!-- 右侧规则 -->
    <div class="dp-right panel-card">
      <div class="panel-header">
        <span class="panel-title">数据权限规则{{ currentRole ? ' - ' + currentRole.role_name : '' }}</span>
        <el-button type="primary" size="small" :disabled="!selectedRoleId" @click="onAdd">新增规则</el-button>
      </div>
      <el-table :data="ruleList" size="small" border v-loading="loading" empty-text="暂无数据权限规则">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column label="业务对象" width="140">
          <template #default="{ row }">
            <el-select v-model="row.bo_code" size="small" @change="onSaveRow(row as any)">
              <el-option v-for="b in boList" :key="b.code" :label="b.name" :value="b.code" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="数据维度" width="160">
          <template #default="{ row }">
            <el-select v-model="row.dimension" size="small" @change="onDimensionChange(row as any)">
              <el-option v-for="d in dimensions" :key="d.value" :label="d.label" :value="d.value" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="过滤字段" width="170">
          <template #default="{ row }">
            <el-select
              v-model="row.field_code"
              size="small"
              filterable
              allow-create
              default-first-option
              clearable
              placeholder="字段编码"
              @change="onSaveRow(row as any)"
            >
              <el-option v-for="f in fieldOptions(row.dimension)" :key="f" :label="f" :value="f" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="数据范围" min-width="320">
          <template #default="{ row }">
            <el-radio-group v-model="row.scope" size="small" @change="onSaveRow(row as any)">
              <el-radio-button v-for="s in DATA_SCOPE_OPTIONS" :key="s.value" :value="s.value">{{ s.label }}</el-radio-button>
            </el-radio-group>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="dp-tip">
        <el-icon><InfoFilled /></el-icon>
        <span>说明：数据范围控制单据查询时可见的行级数据。本人=仅自己创建；本部门=同部门数据；本部门及下级=含子部门；本组织=同组织数据；全部=无限制。</span>
      </div>
    </div>

    <!-- 新增弹窗 -->
    <el-dialog v-model="dialogVisible" title="新增数据权限规则" width="440px" append-to-body>
      <el-form :model="dialogForm" label-width="90px" size="small">
        <el-form-item label="业务对象" required>
          <el-select v-model="dialogForm.bo_code" style="width:100%">
            <el-option v-for="b in boList" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据维度" required>
          <el-select v-model="dialogForm.dimension" style="width:100%" @change="onDialogDimensionChange">
            <el-option v-for="d in dimensions" :key="d.value" :label="d.label" :value="d.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="过滤字段">
          <el-select
            v-model="dialogForm.field_code"
            style="width:100%"
            filterable
            allow-create
            default-first-option
            clearable
            placeholder="按维度自动推荐，可手动输入"
          >
            <el-option v-for="f in fieldOptions(dialogForm.dimension)" :key="f" :label="f" :value="f" />
          </el-select>
          <div class="field-code-tip">控制行级过滤的数据库列（与 SQL data_permission_rule.field_code 对齐，RISK-D11-005）</div>
        </el-form-item>
        <el-form-item label="数据范围" required>
          <el-radio-group v-model="dialogForm.scope">
            <el-radio v-for="s in DATA_SCOPE_OPTIONS" :key="s.value" :value="s.value">{{ s.label }}</el-radio>
          </el-radio-group>
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
import { roleApi, dataPermApi } from '@/api/perm'
import { DATA_SCOPE_OPTIONS } from '@/utils/enum'
import type { Role, DataPermissionRule } from '@/types/bo'

const loading = ref(false)
const roleList = ref<Role[]>([])
const ruleList = ref<DataPermissionRule[]>([])
const selectedRoleId = ref('')
const dialogVisible = ref(false)

const boList = [
  { code: 'sal_order', name: '销售订单' },
  { code: 'pur_order', name: '采购订单' },
  { code: 'mfg_order', name: '生产订单' },
  { code: 'customer', name: '客户' },
  { code: 'supplier', name: '供应商' },
  { code: 'material', name: '物料' }
]
const dimensions = [
  { value: 'org', label: '组织' },
  { value: 'dept', label: '部门' },
  { value: 'salesman', label: '业务员' },
  { value: 'customer', label: '客户' },
  { value: 'supplier', label: '供应商' },
  { value: 'warehouse', label: '仓库' },
  { value: 'workshop', label: '车间' }
]

const dialogForm = reactive<Partial<DataPermissionRule>>({
  bo_code: 'sal_order', dimension: 'org', scope: 'self', field_code: ''
})

const currentRole = computed(() => roleList.value.find(r => r.id === selectedRoleId.value))

// 数据维度 → 推荐过滤字段编码（与 SQL data_permission_rule.field_code 对齐，RISK-D11-005）
const DIMENSION_FIELD_MAP: Record<string, string[]> = {
  org: ['org_id'],
  dept: ['dept_id'],
  salesman: ['saler_id', 'salesman_id'],
  customer: ['customer_id'],
  supplier: ['supplier_id'],
  warehouse: ['warehouse_id'],
  workshop: ['workshop_id']
}
function fieldOptions(dimension?: string): string[] {
  if (!dimension) return []
  return DIMENSION_FIELD_MAP[dimension] || []
}

// 维度切换时自动回填推荐 field_code（仅当当前为空或不在推荐列表时）
function applyDefaultFieldCode(row: Partial<DataPermissionRule>) {
  const opts = fieldOptions(row.dimension)
  if (opts.length && (!row.field_code || !opts.includes(row.field_code))) {
    row.field_code = opts[0]
  }
}
function onDimensionChange(row: DataPermissionRule) {
  applyDefaultFieldCode(row)
  onSaveRow(row)
}
function onDialogDimensionChange() {
  applyDefaultFieldCode(dialogForm)
}

async function loadRoles() {
  roleList.value = await roleApi.list()
  if (roleList.value.length && !selectedRoleId.value) {
    selectedRoleId.value = roleList.value[0].id
    loadRules()
  }
}

async function loadRules() {
  if (!selectedRoleId.value) return
  loading.value = true
  try {
    ruleList.value = await dataPermApi.list(selectedRoleId.value)
  } finally {
    loading.value = false
  }
}

function onAdd() {
  Object.assign(dialogForm, { bo_code: 'sal_order', dimension: 'org', scope: 'self', field_code: 'org_id' })
  dialogVisible.value = true
}

async function onDialogSave() {
  if (!dialogForm.bo_code || !dialogForm.dimension || !dialogForm.scope) {
    ElMessage.warning('请填写完整')
    return
  }
  ruleList.value.push({
    id: 'tmp_' + Date.now(), role_id: selectedRoleId.value,
    bo_code: dialogForm.bo_code!, dimension: dialogForm.dimension as any,
    scope: dialogForm.scope as any,
    field_code: dialogForm.field_code || undefined
  })
  dialogVisible.value = false
  await persistRules()
  ElMessage.success('新增成功')
  await loadRules()
}

async function onSaveRow(_row: DataPermissionRule) {
  await persistRules()
  ElMessage.success('已更新')
}

async function onDelete(row: DataPermissionRule) {
  await ElMessageBox.confirm('确定删除该规则？', '提示', { type: 'warning' })
  ruleList.value = ruleList.value.filter(r => r.id !== row.id)
  await persistRules()
  ElMessage.success('删除成功')
  await loadRules()
}

async function persistRules() {
  await dataPermApi.save(selectedRoleId.value, ruleList.value.map(r => ({
    id: r.id, bo_code: r.bo_code, dimension: r.dimension, scope: r.scope,
    field_code: r.field_code    // RISK-D11-005：过滤字段持久化
  })))
}

onMounted(loadRoles)
</script>

<style scoped lang="scss">
.dp-page {
  height: 100%;
  display: flex;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.dp-left {
  width: 240px;
  padding: 12px;
  overflow: auto;
}
.dp-right {
  flex: 1;
  padding: 12px;
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
.role-radio-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}
.role-radio-item {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 8px;
  border-radius: 4px;
  margin-right: 0;
  &:hover { background: #f5f7fa; }
  .el-icon { color: #1564ff; }
}
.dp-tip {
  margin-top: 12px;
  padding: 8px 12px;
  background: #ecf5ff;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  display: flex;
  gap: 6px;
  align-items: flex-start;
  .el-icon { color: #1564ff; margin-top: 2px; }
}
.field-code-tip {
  font-size: 12px;
  color: #909399;
  line-height: 1.4;
  margin-top: 4px;
}
</style>
