<template>
  <div class="query-scheme-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:240px" />
      </div>
    </div>

    <!-- 信息横幅 -->
    <el-alert
      class="info-banner"
      type="info"
      :closable="false"
      show-icon
    >
      方案含查询条件+列设置+排序+分页大小；可设默认/收藏；管理员可发布公共方案。
    </el-alert>

    <!-- 主体 -->
    <div class="main-body panel-card">
      <el-empty v-if="!boCode" description="请先选择业务对象" :image-size="80" />

      <template v-else>
        <!-- 场景示例卡片 -->
        <div class="scene-section">
          <div class="section-title">
            <el-icon><MagicStick /></el-icon>
            <span>场景示例（点击快速创建方案）</span>
          </div>
          <div class="scene-cards">
            <div
              v-for="s in sceneSamples"
              :key="s.key"
              class="scene-card"
              @click="onPickScene(s)"
            >
              <div class="scene-card-title">
                <el-icon :color="'#1564ff'"><component :is="s.icon" /></el-icon>
                <span>{{ s.name }}</span>
              </div>
              <div class="scene-card-desc">{{ s.desc }}</div>
              <div class="scene-card-tags">
                <el-tag
                  v-for="(c, i) in s.conditions"
                  :key="i"
                  size="small"
                  type="info"
                  effect="plain"
                >{{ c.field_code }} {{ opLabel(c.operator) }} {{ displayValue(c.value) }}</el-tag>
              </div>
              <div class="scene-card-cta">
                <el-button type="primary" link size="small">基于此创建 →</el-button>
              </div>
            </div>
          </div>
        </div>

        <!-- 查询方案管理器 -->
        <div class="manager-section">
          <QuerySchemeManager
            ref="managerRef"
            :bo-code="boCode"
            @apply="onApply"
            @edit="onEdit"
            @delete="onDelete"
            @create="onCreate"
          />
        </div>
      </template>
    </div>

    <!-- 新建/编辑方案弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogMode === 'create' ? '新建查询方案' : '编辑查询方案'"
      width="760px"
      append-to-body
      :close-on-click-modal="false"
    >
      <el-form :model="dialogForm" label-width="90px" size="small">
        <el-form-item label="方案名称" required>
          <el-input v-model="dialogForm.scheme_name" placeholder="如：本月待发货订单" />
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="排序">
              <el-input v-model="dialogForm.order_by" placeholder="如：order_date desc" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="每页条数">
              <el-input-number
                v-model="dialogForm.page_size"
                :min="10"
                :max="500"
                :step="10"
                controls-position="right"
                style="width:100%"
              />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="公共方案">
              <el-switch v-model="dialogForm.is_public" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="设为默认">
              <el-switch v-model="dialogForm.is_default" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="展示列">
          <el-input
            v-model="columnsText"
            type="textarea"
            :rows="2"
            placeholder="字段编码，逗号分隔，如：code,order_date,cust_name,total_amount"
          />
        </el-form-item>

        <el-form-item label="查询条件">
          <div class="cond-editor">
            <div
              v-for="(c, i) in dialogForm.conditions"
              :key="i"
              class="cond-row"
            >
              <el-input v-model="c.field_code" placeholder="字段编码" style="width:160px" />
              <el-select v-model="c.operator" placeholder="运算符" style="width:120px">
                <el-option
                  v-for="op in QUERY_OPERATORS"
                  :key="op.value"
                  :label="op.label"
                  :value="op.value"
                />
              </el-select>
              <el-input v-model="c.value" placeholder="值（多值用逗号分隔）" style="flex:1" />
              <el-select v-model="c.logic" style="width:80px">
                <el-option label="AND" value="AND" />
                <el-option label="OR" value="OR" />
              </el-select>
              <el-button
                link type="danger" size="small"
                @click="dialogForm.conditions.splice(i, 1)"
              ><el-icon><Delete /></el-icon></el-button>
            </div>
            <el-button
              size="small" type="primary" link
              @click="dialogForm.conditions.push({ field_code: '', operator: 'eq', value: '', logic: 'AND' })"
            >
              <el-icon><Plus /></el-icon>添加条件
            </el-button>
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onDialogSave">保存方案</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { MagicStick, Plus, Delete, Box, Document, TrendCharts } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import QuerySchemeManager from '@/components/QuerySchemeManager/index.vue'
import { schemeApi } from '@/api/list'
import { QUERY_OPERATORS } from '@/utils/enum'
import type { QueryScheme, QueryCondition } from '@/types/bo'

const boCode = ref('')
const managerRef = ref<InstanceType<typeof QuerySchemeManager> | null>(null)

// ============ 场景示例 ============
interface SceneSample {
  key: string
  name: string
  desc: string
  icon: any
  conditions: QueryCondition[]
  columns: string[]
  order_by: string
  page_size: number
}

const sceneSamples: SceneSample[] = [
  {
    key: 'wool_yarn_this_month',
    name: '本月待发货羊毛纱订单',
    desc: '本月已审核、含羊毛纱品类且尚未发货的销售订单。',
    icon: Box,
    conditions: [
      { field_code: 'order_date', operator: 'between', value: '2026-07-01,2026-07-31', logic: 'AND' },
      { field_code: 'material_name', operator: 'like', value: '羊毛纱', logic: 'AND' },
      { field_code: 'pact_state', operator: 'eq', value: '3', logic: 'AND' }
    ],
    columns: ['code', 'order_date', 'cust_name', 'material_name', 'total_qty', 'delivery_date', 'pact_state'],
    order_by: 'delivery_date asc',
    page_size: 50
  },
  {
    key: 'my_unaudited_contract',
    name: '我的未审核合同',
    desc: '当前用户创建、已提交待审核的合同单据。',
    icon: Document,
    conditions: [
      { field_code: 'create_by', operator: 'eq', value: '${currentUser}', logic: 'AND' },
      { field_code: 'pact_state', operator: 'eq', value: '2', logic: 'AND' }
    ],
    columns: ['code', 'contract_date', 'cust_name', 'total_amount', 'submit_by', 'submit_time', 'pact_state'],
    order_by: 'submit_time desc',
    page_size: 30
  },
  {
    key: 'large_order_follow_up',
    name: '大额订单跟进',
    desc: '金额超过 10 万、处于创建/提交/审核中的订单，便于重点跟进。',
    icon: TrendCharts,
    conditions: [
      { field_code: 'total_amount', operator: 'gt', value: '100000', logic: 'AND' },
      { field_code: 'pact_state', operator: 'in', value: '1,2,3', logic: 'AND' }
    ],
    columns: ['code', 'order_date', 'cust_name', 'salesman_name', 'total_amount', 'pact_state', 'delivery_date'],
    order_by: 'total_amount desc',
    page_size: 20
  }
]

const opMap = new Map(QUERY_OPERATORS.map(o => [o.value, o.label]))
function opLabel(op: string) { return opMap.get(op) || op }
function displayValue(v: any) {
  if (v == null) return ''
  if (Array.isArray(v)) return v.join('~')
  return String(v)
}

// ============ 弹窗 ============
const dialogVisible = ref(false)
const dialogMode = ref<'create' | 'edit'>('create')
const editingId = ref<string | null>(null)
const columnsText = ref('')

const dialogForm = reactive<{
  scheme_name: string
  is_public: boolean
  is_default: boolean
  order_by: string
  page_size: number
  conditions: QueryCondition[]
}>({
  scheme_name: '',
  is_public: false,
  is_default: false,
  order_by: '',
  page_size: 30,
  conditions: []
})

function resetForm() {
  dialogForm.scheme_name = ''
  dialogForm.is_public = false
  dialogForm.is_default = false
  dialogForm.order_by = ''
  dialogForm.page_size = 30
  dialogForm.conditions = []
  columnsText.value = ''
  editingId.value = null
}

function fillForm(scheme: Partial<QueryScheme>) {
  dialogForm.scheme_name = scheme.scheme_name || ''
  dialogForm.is_public = scheme.is_public || false
  dialogForm.is_default = scheme.is_default || false
  dialogForm.order_by = scheme.order_by || ''
  dialogForm.page_size = scheme.page_size || 30
  dialogForm.conditions = (scheme.conditions || []).map(c => ({ ...c }))
  columnsText.value = (scheme.columns || []).join(',')
  editingId.value = scheme.id || null
}

function onPickScene(s: SceneSample) {
  if (!boCode.value) {
    ElMessage.warning('请先选择业务对象')
    return
  }
  dialogMode.value = 'create'
  resetForm()
  dialogForm.scheme_name = s.name
  dialogForm.order_by = s.order_by
  dialogForm.page_size = s.page_size
  dialogForm.conditions = s.conditions.map(c => ({ ...c }))
  columnsText.value = s.columns.join(',')
  dialogVisible.value = true
}

function onCreate() {
  if (!boCode.value) return
  dialogMode.value = 'create'
  resetForm()
  dialogVisible.value = true
}

function onEdit(scheme: QueryScheme) {
  dialogMode.value = 'edit'
  fillForm(scheme)
  dialogVisible.value = true
}

function onApply(scheme: QueryScheme) {
  ElMessage.success(`已应用方案「${scheme.scheme_name}」，共 ${scheme.conditions.length} 个条件、${scheme.columns.length} 列`)
}

function onDelete(scheme: QueryScheme) {
  ElMessage.success(`方案「${scheme.scheme_name}」已删除`)
  managerRef.value?.refresh?.()
}

function parseColumns(text: string): string[] {
  return text.split(/[,，\n]/).map(s => s.trim()).filter(Boolean)
}

function parseValue(v: any): any {
  if (v == null) return ''
  const s = String(v).trim()
  if (s === '') return ''
  // 逗号分隔的多值转数组
  if (s.includes(',')) return s.split(',').map(x => x.trim()).filter(Boolean)
  return s
}

async function onDialogSave() {
  if (!boCode.value) {
    ElMessage.warning('请先选择业务对象')
    return
  }
  if (!dialogForm.scheme_name.trim()) {
    ElMessage.warning('请填写方案名称')
    return
  }
  if (!dialogForm.conditions.length) {
    ElMessage.warning('请至少添加一个查询条件')
    return
  }
  const payload: Partial<QueryScheme> = {
    scheme_name: dialogForm.scheme_name.trim(),
    bo_code: boCode.value,
    is_public: dialogForm.is_public,
    is_default: dialogForm.is_default,
    is_favorite: false,
    order_by: dialogForm.order_by,
    page_size: dialogForm.page_size,
    columns: parseColumns(columnsText.value),
    conditions: dialogForm.conditions
      .filter(c => c.field_code.trim())
      .map(c => ({ ...c, value: parseValue(c.value) })),
    user_id: ''
  }
  try {
    if (dialogMode.value === 'create' || !editingId.value) {
      await schemeApi.create(payload)
      ElMessage.success('方案已创建')
    } else {
      await schemeApi.update(editingId.value, payload)
      ElMessage.success('方案已更新')
    }
    dialogVisible.value = false
    managerRef.value?.refresh?.()
  } catch {
    ElMessage.error('保存方案失败')
  }
}
</script>

<style scoped lang="scss">
.query-scheme-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.header-label {
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
}
.info-banner {
  margin: 0 12px;
}
.main-body {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
  .el-icon { color: #1564ff; }
}
.scene-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}
.scene-card {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 12px;
  background: #fff;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  gap: 8px;
  &:hover {
    border-color: #1564ff;
    box-shadow: 0 2px 8px rgba(21, 100, 255, 0.12);
  }
}
.scene-card-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
  color: #1564ff;
}
.scene-card-desc {
  font-size: 12px;
  color: #606266;
  line-height: 1.5;
}
.scene-card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
.scene-card-cta {
  text-align: right;
  border-top: 1px dashed #ebeef5;
  padding-top: 6px;
}
.manager-section {
  flex: 1;
  min-height: 320px;
  display: flex;
  flex-direction: column;
}
.manager-section > :deep(.scheme-manager) {
  height: 100%;
}
.cond-editor {
  width: 100%;
}
.cond-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}
</style>
