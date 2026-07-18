<template>
  <div class="fp-page page-container">
    <!-- 顶部选择 -->
    <div class="panel-card filter-bar">
      <el-form :inline="true" size="small">
        <el-form-item label="业务对象">
          <el-select v-model="boCode" @change="loadMatrix">
            <el-option v-for="b in boList" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="批量设置">
          <el-select v-model="batchPerm" style="width:100px">
            <el-option v-for="p in FIELD_PERM_OPTIONS" :key="p.value" :label="p.label" :value="p.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onBatchSet">应用到所选字段</el-button>
          <el-button type="success" @click="onSave">保存权限</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 字段矩阵 -->
    <div class="panel-card matrix-panel">
      <el-table :data="matrixData" size="small" border v-loading="loading" @selection-change="onSelectionChange" height="100%">
        <el-table-column type="selection" width="40" fixed />
        <el-table-column prop="field_name" label="字段名称" width="140" fixed />
        <el-table-column prop="field_code" label="字段编码" width="150" fixed />
        <el-table-column
          v-for="r in roleList"
          :key="r.id"
          :label="r.role_name"
          align="center"
          min-width="90"
        >
          <template #default="{ row }">
            <el-tag
              :type="permTagType(row[r.id])"
              size="small"
              class="perm-cell"
              effect="dark"
              @click="cyclePerm(row, r.id)"
            >{{ permLabel(row[r.id]) }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
      <div class="legend-bar">
        <span>图例：</span>
        <el-tag size="small" type="success" effect="dark">可见</el-tag>
        <el-tag size="small" type="info" effect="dark">隐藏</el-tag>
        <el-tag size="small" type="warning" effect="dark">脱敏</el-tag>
        <span class="legend-tip">点击单元格切换权限状态</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { roleApi, fieldPermApi } from '@/api/perm'
import { entityApi } from '@/api/bo'
import { FIELD_PERM_OPTIONS } from '@/utils/enum'
import type { Role, FieldPermission, FieldPerm, FormField } from '@/types/bo'

const loading = ref(false)
const boCode = ref('sal_order')
const roleList = ref<Role[]>([])
const matrixData = ref<Record<string, any>[]>([])
const selectedRows = ref<Record<string, any>[]>([])
const batchPerm = ref<FieldPerm>('visible')
// 动态加载的字段清单（GAP-D11-007 / RISK-D11-003：调用 entityApi.fields(boCode) 替代硬编码 fieldDefs）
const dynamicFields = ref<{ field_code: string; field_name: string; entity_name?: string }[]>([])

const boList = [
  { code: 'sal_order', name: '销售订单' },
  { code: 'pur_order', name: '采购订单' },
  { code: 'mfg_order', name: '生产订单' },
  { code: 'customer', name: '客户' },
  { code: 'material', name: '物料' }
]

function permLabel(perm: FieldPerm) {
  const m: Record<string, string> = { visible: '可见', hidden: '隐藏', mask: '脱敏' }
  return m[perm] || '可见'
}
function permTagType(perm: FieldPerm): 'success' | 'info' | 'warning' {
  const m: Record<string, 'success' | 'info' | 'warning'> = {
    visible: 'success', hidden: 'info', mask: 'warning'
  }
  return m[perm] || 'success'
}

const PERM_CYCLE: FieldPerm[] = ['visible', 'hidden', 'mask']
function cyclePerm(row: Record<string, any>, roleId: string) {
  const cur = row[roleId] as FieldPerm
  const idx = PERM_CYCLE.indexOf(cur)
  row[roleId] = PERM_CYCLE[(idx + 1) % PERM_CYCLE.length]
}

function onSelectionChange(rows: Record<string, any>[]) {
  selectedRows.value = rows
}

function onBatchSet() {
  if (!selectedRows.value.length) {
    ElMessage.warning('请先勾选字段')
    return
  }
  selectedRows.value.forEach(row => {
    roleList.value.forEach(r => { row[r.id] = batchPerm.value })
  })
  ElMessage.success(`已将 ${selectedRows.value.length} 个字段设置为「${permLabel(batchPerm.value)}」`)
}

// 动态加载业务对象字段（GAP-D11-007 / RISK-D11-003：从 meta_form_field 加载）
async function loadFields() {
  try {
    const fields: FormField[] = await entityApi.fields(boCode.value)
    dynamicFields.value = (fields || []).map(f => ({
      field_code: f.field_code,
      field_name: f.field_name,
      entity_name: f.entity_code
    }))
    // 若元数据为空，兜底使用最小化字段集
    if (!dynamicFields.value.length) {
      dynamicFields.value = [
        { field_code: 'code', field_name: '单据编号' },
        { field_code: 'total_amount', field_name: '总金额' },
        { field_code: 'audit_by', field_name: '审核人' }
      ]
    }
  } catch {
    dynamicFields.value = [
      { field_code: 'code', field_name: '单据编号' },
      { field_code: 'total_amount', field_name: '总金额' }
    ]
  }
}

async function loadMatrix() {
  if (!roleList.value.length) return
  loading.value = true
  try {
    await loadFields()
    const fields = dynamicFields.value
    // 为每个角色拉取字段权限
    const allPerms: FieldPermission[][] = await Promise.all(
      roleList.value.map(r => fieldPermApi.list(r.id, boCode.value))
    )
    matrixData.value = fields.map(f => {
      const row: Record<string, any> = {
        field_code: f.field_code, field_name: f.field_name,
        entity_name: f.entity_name || ''
      }
      roleList.value.forEach((r, idx) => {
        const fp = allPerms[idx].find(p => p.field_code === f.field_code)
        row[r.id] = fp?.perm || 'visible'
      })
      return row
    })
  } finally {
    loading.value = false
  }
}

async function onSave() {
  // 对每个角色保存
  for (const r of roleList.value) {
    const perms: FieldPermission[] = matrixData.value.map(row => ({
      role_id: r.id, bo_code: boCode.value,
      field_code: row.field_code, perm: row[r.id] as FieldPerm
    }))
    await fieldPermApi.save(r.id, boCode.value, perms)
  }
  ElMessage.success('字段权限已保存')
}

onMounted(async () => {
  roleList.value = await roleApi.list()
  await loadMatrix()
})
</script>

<style scoped lang="scss">
.fp-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
  height: 100%;
}
.filter-bar { padding: 12px 12px 0; }
.matrix-panel {
  flex: 1;
  padding: 12px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.matrix-panel :deep(.el-table) {
  flex: 1;
}
.perm-cell {
  cursor: pointer;
  min-width: 44px;
  text-align: center;
}
.legend-bar {
  margin-top: 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #606266;
}
.legend-tip {
  margin-left: 12px;
  color: #909399;
}
</style>
