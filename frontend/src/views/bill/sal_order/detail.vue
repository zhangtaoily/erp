<template>
  <div class="sal-order-detail-page">
    <!-- 顶部工具栏 -->
    <div class="page-header panel-card">
      <BillToolbar
        :pact-state="formData.pact_state ?? 0"
        position="form"
        :is-closed="!!formData.is_closed"
        :is-cancel="!!formData.is_cancel"
        @click="onToolbarClick"
      />
      <div class="header-meta">
        <el-tag v-if="formData.bill_no" size="small" type="info" effect="plain">{{ formData.bill_no }}</el-tag>
        <el-tag v-if="formData.pact_state !== undefined" size="small" :type="stateTagType(formData.pact_state)" effect="dark">
          {{ stateLabel(formData.pact_state) }}
        </el-tag>
        <el-tag v-if="formData.is_closed" size="small" type="warning" effect="plain">已关闭</el-tag>
        <el-tag v-if="formData.is_cancel" size="small" type="danger" effect="plain">已取消</el-tag>
        <span class="mode-tip">当前模式：{{ modeLabel }}</span>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左：表单 -->
      <div class="form-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">销售订单</span>
          <span v-if="mode === 'view'" class="panel-tip">只读模式（已提交/审核单据不可编辑）</span>
        </div>
        <div class="form-wrapper">
          <MasterDetailEditor
            v-if="entities.length"
            v-model="formData"
            :entities="entities"
            :mode="mode"
            layout="stacked"
          />
          <el-empty v-else description="元数据加载中..." :image-size="60" />
        </div>
      </div>

      <!-- 右：信息页签 -->
      <div class="side-panel panel-card">
        <el-tabs v-model="activeSideTab" class="side-tabs">
          <el-tab-pane label="单据信息" name="info">
            <el-form label-width="80px" size="small" class="info-form">
              <el-form-item label="单据编号">
                <span>{{ formData.bill_no || '（未生成）' }}</span>
              </el-form-item>
              <el-form-item label="单据状态">
                <el-tag v-if="formData.pact_state !== undefined" size="small" :type="stateTagType(formData.pact_state)" effect="dark">
                  {{ stateLabel(formData.pact_state) }}
                </el-tag>
              </el-form-item>
              <el-form-item label="创建人">{{ formData.create_by || '—' }}</el-form-item>
              <el-form-item label="创建时间">{{ formData.create_time || '—' }}</el-form-item>
              <el-form-item label="审核人">{{ formData.audit_by || '—' }}</el-form-item>
              <el-form-item label="审核时间">{{ formData.audit_time || '—' }}</el-form-item>
              <el-form-item v-if="formData.reject_reason" label="驳回原因">
                <span class="reject-reason">{{ formData.reject_reason }}</span>
              </el-form-item>
              <el-form-item v-if="formData.cancel_reason" label="取消原因">
                <span class="reject-reason">{{ formData.cancel_reason }}</span>
              </el-form-item>
            </el-form>
          </el-tab-pane>

          <el-tab-pane label="附件" name="attachment" :disabled="!formData.id">
            <AttachmentUpload
              v-if="formData.id"
              bill-type="sal_order"
              :bill-id="formData.id"
            />
            <el-empty v-else description="保存后可上传附件" :image-size="50" />
          </el-tab-pane>

          <el-tab-pane label="联查" name="trace" :disabled="!formData.id">
            <BillTraceTree
              v-if="formData.id"
              bill-type="sal_order"
              :bill-id="formData.id"
              direction="down"
              @click="onTraceClick"
            />
            <el-empty v-else description="保存后可联查" :image-size="50" />
          </el-tab-pane>

          <el-tab-pane label="变更历史" name="history" :disabled="!formData.id">
            <ChangeHistoryTimeline
              v-if="formData.id"
              bill-type="sal_order"
              :bill-id="formData.id"
            />
            <el-empty v-else description="保存后可查看变更历史" :image-size="50" />
          </el-tab-pane>
        </el-tabs>
      </div>
    </div>

    <!-- 下推弹窗（行勾选 + 数量输入 + biz_bill_link 回写展示，GAP-D04-002/005 / PRD 02.3.3/02.3.5）-->
    <el-dialog v-model="pushDialogVisible" title="下推生成下游单据" width="780px" append-to-body destroy-on-close>
      <el-form :model="pushForm" label-width="100px" size="small">
        <el-form-item label="目标单类型" required>
          <el-select v-model="pushForm.target_bo" placeholder="请选择" style="width: 100%">
            <el-option label="生产订单" value="mfg_order" />
            <el-option label="销售出库单" value="sal_out_stock" />
          </el-select>
        </el-form-item>
        <el-form-item label="下推规则">
          <el-tag v-if="pushForm.rule" size="small" type="primary" effect="plain">
            {{ pushForm.rule.rule_name }}（{{ pushForm.rule.rule_code }}）
          </el-tag>
          <span v-else class="muted">未匹配到下推规则，按默认映射</span>
        </el-form-item>
        <el-form-item label="明细勾选" required>
          <el-table :data="pushForm.lines" border size="small" style="width:100%" @selection-change="onPushSelectionChange">
            <el-table-column type="selection" width="42" :selectable="(row: any) => (row.qty - (row.out_qty || 0)) > 0" />
            <el-table-column label="物料" prop="mat_name" min-width="160" show-overflow-tooltip />
            <el-table-column label="规格" prop="spec" width="100" />
            <el-table-column label="订单数量" prop="qty" width="90" align="right" />
            <el-table-column label="已下推量" prop="out_qty" width="90" align="right" />
            <el-table-column label="可下推量" width="90" align="right">
              <template #default="{ row }">
                <span :class="{ 'num-warn': (row.qty - (row.out_qty || 0)) <= 0 }">
                  {{ (row.qty - (row.out_qty || 0)).toFixed(2) }}
                </span>
              </template>
            </el-table-column>
            <el-table-column label="本次下推量" width="140">
              <template #default="{ row }">
                <el-input-number
                  v-model="row.push_qty"
                  :min="0"
                  :max="row.qty - (row.out_qty || 0)"
                  :precision="2"
                  size="small"
                  controls-position="right"
                  style="width: 120px"
                  :disabled="!pushForm.selectedIds.includes(row.id)"
                />
              </template>
            </el-table-column>
          </el-table>
          <div class="push-tip">
            勾选要下推的明细行，输入本次下推量；可下推量 = 订单数量 - 已下推量，超出将阻断（vp_check_expr）。
          </div>
        </el-form-item>
        <el-form-item label="回写动作">
          <el-tag size="small" type="success" effect="plain">下推成功后：</el-tag>
          <span class="muted">回写源单 out_qty += 本次下推量；写入 biz_bill_link 关联表（src=sal_order 行 → target=目标单行）</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pushDialogVisible = false">取消</el-button>
        <el-button type="primary" :disabled="!pushForm.selectedIds.length" @click="confirmPush">
          确定下推（{{ pushForm.selectedIds.length }} 行）
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import BillToolbar from '@/components/BillToolbar/index.vue'
import MasterDetailEditor from '@/components/MasterDetailEditor/index.vue'
import AttachmentUpload from '@/components/AttachmentUpload/index.vue'
import BillTraceTree from '@/components/BillTraceTree/index.vue'
import ChangeHistoryTimeline from '@/components/ChangeHistoryTimeline/index.vue'
import { billApi } from '@/api/bill'
import { entityApi } from '@/api/bo'
import { pushRuleApi } from '@/api/state'
import { PACT_STATE_MAP } from '@/utils/enum'
import type { FormEntity } from '@/types/bo'

const route = useRoute()
const router = useRouter()
const BO_CODE = 'sal_order'

const billId = computed(() => String(route.params.id || 'new'))
const isNew = computed(() => billId.value === 'new')

const entities = ref<FormEntity[]>([])
const formData = reactive<Record<string, any>>({})
const activeSideTab = ref('info')

const mode = computed<'view' | 'edit' | 'add'>(() => {
  if (isNew.value) return 'add'
  const ps = formData.pact_state
  if (ps === 0) return 'edit'
  return 'view'
})

const modeLabel = computed(() => {
  return { view: '查看', edit: '编辑', add: '新增' }[mode.value]
})

function stateLabel(code: number): string {
  return PACT_STATE_MAP[code]?.label || String(code)
}

function stateTagType(code: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  return (PACT_STATE_MAP[code]?.type as any) || 'info'
}

// 将 mock 详情数据（goods/assign 键）映射为 entity_code 键（sal_order_goods/sal_order_goods_assign）
function transformDetail(raw: any): Record<string, any> {
  const data: Record<string, any> = { ...raw }
  if (Array.isArray(raw.goods)) {
    data.sal_order_goods = raw.goods.map((g: any) => {
      const { assign, ...rest } = g
      return { ...rest, sal_order_goods_assign: assign || [] }
    })
    delete data.goods
  } else {
    data.sal_order_goods = []
  }
  return data
}

// 新增时按实体定义初始化默认值
function initNewForm() {
  const main = entities.value.find(e => e.entity_type === 'main')
  if (main) {
    main.fields.forEach(f => {
      if (f.is_system && f.field_code === 'pact_state') {
        formData[f.field_code] = 0
      } else if (f.is_system && (f.field_code === 'is_closed' || f.field_code === 'is_cancel')) {
        formData[f.field_code] = false
      } else if (f.default_value === 'TODAY') {
        formData[f.field_code] = new Date().toISOString().slice(0, 10)
      } else if (f.default_value !== undefined && f.default_value !== '') {
        formData[f.field_code] = f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty'
          ? Number(f.default_value)
          : f.default_value
      } else if (f.ctrl_type === 'checkbox') {
        formData[f.field_code] = false
      } else if (f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty') {
        formData[f.field_code] = 0
      } else {
        formData[f.field_code] = ''
      }
    })
  }
  // 子表初始化空数组
  entities.value.filter(e => e.entity_type === 'sub').forEach(sub => {
    formData[sub.entity_code] = []
  })
}

async function loadMeta() {
  entities.value = await entityApi.list(BO_CODE)
}

async function loadDetail() {
  if (isNew.value) {
    initNewForm()
    return
  }
  const raw = await billApi.detail(BO_CODE, billId.value)
  const transformed = transformDetail(raw || {})
  Object.keys(formData).forEach(k => delete formData[k])
  Object.assign(formData, transformed)
  if (!formData.sal_order_goods) formData.sal_order_goods = []
}

async function reloadDetail() {
  if (!formData.id) return
  const raw = await billApi.detail(BO_CODE, String(formData.id))
  const transformed = transformDetail(raw || {})
  Object.keys(formData).forEach(k => delete formData[k])
  Object.assign(formData, transformed)
}

onMounted(async () => {
  await loadMeta()
  await loadDetail()
})

// 工具栏操作分发
async function onToolbarClick(buttonCode: string) {
  switch (buttonCode) {
    case 'save':
    case 'draft':
      await handleSave(buttonCode === 'draft')
      break
    case 'submit':
    case 'audit':
    case 'reject':
    case 'revoke':
      await handleOperate(buttonCode)
      break
    case 'close':
      await handleToggle(formData.is_closed ? 'unclose' : 'close')
      break
    case 'cancel':
      await handleToggle(formData.is_cancel ? 'uncancel' : 'cancel')
      break
    case 'delete':
      await handleDelete()
      break
    case 'push':
      openPushDialog()
      break
    case 'copy':
      router.push('/bill/sal_order/new')
      break
    case 'print':
      ElMessage.info('调用打印模板（请先在打印模板设计器配置）')
      break
    case 'trace':
      activeSideTab.value = 'trace'
      break
    case 'change':
      if (formData.pact_state !== 3) {
        ElMessage.warning('仅已审核单据可变更')
        return
      }
      ElMessage.info('变更功能：生成变更单，变更审核后回写')
      break
    default:
      ElMessage.info(`操作：${buttonCode}`)
  }
}

async function handleSave(isDraft: boolean) {
  try {
    const res = await billApi.save(BO_CODE, { ...formData })
    if (res?.id) {
      formData.id = res.id
    }
    if (!isDraft) {
      // 保存后通常进入已创建（pact_state=1），此处保持 mock 简单：保存即 0→1
      if (formData.pact_state === 0 || formData.pact_state === undefined) {
        formData.pact_state = 1
      }
    }
    ElMessage.success(isDraft ? '暂存成功' : '保存成功')
    if (isNew.value && formData.id) {
      router.replace(`/bill/sal_order/${formData.id}`)
    }
  } catch {
    ElMessage.error('保存失败')
  }
}

async function handleOperate(action: string) {
  if (!formData.id) {
    ElMessage.warning('请先保存单据')
    return
  }
  const needReason = action === 'reject'
  let extra: any
  if (needReason) {
    const reason = await ElMessageBox.prompt('请输入驳回原因', '驳回', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputType: 'textarea'
    }).then(r => r.value).catch(() => null)
    if (reason === null) return
    extra = { reason }
  }
  if (action === 'audit' || action === 'revoke') {
    const confirmText = action === 'audit' ? '确定审核该单据？' : '确定撤销该单据？'
    try {
      await ElMessageBox.confirm(confirmText, '提示', { type: 'warning' })
    } catch {
      return
    }
  }
  try {
    await billApi.operate(BO_CODE, String(formData.id), action, extra)
    // 本地状态联动（mock 不真实改后端，前端同步显示）
    applyStateChange(action)
    ElMessage.success(`${actionLabel(action)}成功`)
  } catch {
    ElMessage.error(`${actionLabel(action)}失败`)
  }
}

async function handleToggle(action: 'close' | 'unclose' | 'cancel' | 'uncancel') {
  if (!formData.id) {
    ElMessage.warning('请先保存单据')
    return
  }
  try {
    await billApi.operate(BO_CODE, String(formData.id), action)
    if (action === 'close') formData.is_closed = true
    if (action === 'unclose') formData.is_closed = false
    if (action === 'cancel') formData.is_cancel = true
    if (action === 'uncancel') formData.is_cancel = false
    ElMessage.success(`${actionLabel(action)}成功`)
  } catch {
    ElMessage.error(`${actionLabel(action)}失败`)
  }
}

function applyStateChange(action: string) {
  const map: Record<string, number> = {
    submit: 2,
    audit: 3,
    reject: 4,
    revoke: 1
  }
  if (map[action] !== undefined) {
    formData.pact_state = map[action]
  }
  if (action === 'audit') {
    formData.audit_by = formData.audit_by || '当前用户'
    formData.audit_time = formData.audit_time || new Date().toISOString().replace('T', ' ').slice(0, 19)
  }
  if (action === 'revoke') {
    formData.audit_by = ''
    formData.audit_time = ''
  }
}

async function handleDelete() {
  if (!formData.id) return
  try {
    await ElMessageBox.confirm('确定删除该单据吗？删除后不可恢复。', '提示', { type: 'warning' })
  } catch {
    return
  }
  try {
    await billApi.delete(BO_CODE, String(formData.id))
    ElMessage.success('删除成功')
    router.push('/bill/sal_order')
  } catch {
    ElMessage.error('删除失败')
  }
}

function actionLabel(action: string): string {
  const map: Record<string, string> = {
    submit: '提交', audit: '审核', reject: '驳回', revoke: '撤销',
    close: '关闭', unclose: '反关闭', cancel: '取消', uncancel: '反取消'
  }
  return map[action] || action
}

// 下推（行勾选 + 数量输入 + biz_bill_link 回写，GAP-D04-002/005 / PRD 02.3.5）
interface PushLine {
  id: string
  mat_id: string
  mat_name: string
  spec: string
  qty: number
  out_qty: number
  push_qty: number
}
interface PushForm {
  target_bo: string
  rule: any | null
  lines: PushLine[]
  selectedIds: string[]
}
const pushDialogVisible = ref(false)
const pushForm = reactive<PushForm>({
  target_bo: 'mfg_order',
  rule: null,
  lines: [],
  selectedIds: []
})

async function openPushDialog() {
  if (!formData.id) {
    ElMessage.warning('请先保存单据')
    return
  }
  if (formData.pact_state !== 3) {
    ElMessage.warning('仅已审核单据可下推')
    return
  }
  pushForm.target_bo = 'mfg_order'
  pushForm.selectedIds = []
  // 加载下推规则（mock 仅 1 条 SO2OUT，原型简化：取列表第一条匹配目标 BO）
  try {
    const rules: any = await pushRuleApi.list()
    const list = Array.isArray(rules) ? rules : (rules?.list || [])
    pushForm.rule = list[0] || null
  } catch {
    pushForm.rule = null
  }
  // 构造行数据：从 sal_order_goods 子表读取
  const goods: any[] = formData.sal_order_goods || []
  pushForm.lines = goods.map((g: any) => ({
    id: String(g.id || ''),
    mat_id: g.mat_id || '',
    mat_name: g.mat_name || '',
    spec: g.spec || '',
    qty: Number(g.qty || 0),
    out_qty: Number(g.out_qty || 0),
    push_qty: Math.max(0, Number(g.qty || 0) - Number(g.out_qty || 0))
  }))
  pushDialogVisible.value = true
}

function onPushSelectionChange(rows: PushLine[]) {
  pushForm.selectedIds = rows.map(r => r.id)
}

async function confirmPush() {
  if (!pushForm.target_bo) {
    ElMessage.warning('请选择目标单类型')
    return
  }
  const selectedLines = pushForm.lines.filter(l => pushForm.selectedIds.includes(l.id))
  if (!selectedLines.length) {
    ElMessage.warning('请勾选要下推的明细行')
    return
  }
  // 校验可下推量（vp_check_expr: F.qty - F.out_qty > 0）
  const invalid = selectedLines.find(l => l.push_qty <= 0 || l.push_qty > (l.qty - l.out_qty))
  if (invalid) {
    ElMessage.error(`物料「${invalid.mat_name}」下推量超出可下推量（${(invalid.qty - invalid.out_qty).toFixed(2)}）`)
    return
  }
  const totalPushQty = selectedLines.reduce((s, l) => s + l.push_qty, 0)
  try {
    await billApi.operate(BO_CODE, String(formData.id), 'push', {
      target_bo: pushForm.target_bo,
      rule_code: pushForm.rule?.rule_code,
      lines: selectedLines.map(l => ({ src_line_id: l.id, qty: l.push_qty }))
    })
    // 本地回写源单 out_qty（mock 不真实改后端，前端同步显示）
    selectedLines.forEach(l => {
      const g = (formData.sal_order_goods || []).find((x: any) => String(x.id) === l.id)
      if (g) g.out_qty = Number(g.out_qty || 0) + l.push_qty
    })
    ElMessage.success(`已下推生成${pushForm.target_bo === 'mfg_order' ? '生产订单' : '销售出库单'}（${selectedLines.length} 行，共 ${totalPushQty}）；已回写 out_qty 与 biz_bill_link`)
    pushDialogVisible.value = false
    activeSideTab.value = 'trace'
  } catch {
    ElMessage.error('下推失败')
  }
}

function onTraceClick(node: any) {
  if (node?.bill_type === 'sal_order') {
    router.push(`/bill/sal_order/${node.bill_id}`)
  } else {
    ElMessage.info(`下游单据：${node.bill_code}（${node.bill_type}，由对应模块查看）`)
  }
}
</script>

<style scoped lang="scss">
.sal-order-detail-page {
  padding: 12px;
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.page-header {
  padding: 0;
  overflow: hidden;
  :deep(.bill-toolbar) {
    border-bottom: 1px solid #ebeef5;
  }
  .header-meta {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 12px;
    background: #fafafa;
    flex-wrap: wrap;
    .mode-tip {
      margin-left: auto;
      font-size: 12px;
      color: #909399;
    }
  }
}
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  min-height: 0;
}
.form-panel {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  .panel-title {
    font-size: 13px;
    font-weight: 600;
  }
  .panel-tip {
    font-size: 12px;
    color: #909399;
  }
}
.form-wrapper {
  flex: 1;
  overflow: auto;
  padding: 4px;
}
.side-panel {
  width: 340px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}
.side-tabs {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 0 8px;
  :deep(.el-tabs__content) {
    flex: 1;
    overflow: auto;
  }
}
.info-form {
  padding: 12px 8px;
  .reject-reason {
    color: #f56c6c;
    font-size: 12px;
  }
}
:deep(.el-empty) {
  padding: 24px;
}
.muted {
  color: #909399;
  font-size: 12px;
  margin-left: 6px;
}
.num-warn {
  color: #f56c6c;
}
.push-tip {
  margin-top: 6px;
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
}
</style>
