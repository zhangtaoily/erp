<template>
  <div class="generic-bill-detail-page">
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
        <span v-if="layoutName" class="layout-tip">布局：{{ layoutName }} v{{ layoutVersion }}</span>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左：表单 -->
      <div class="form-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">{{ billTitle }}</span>
          <span v-if="mode === 'view'" class="panel-tip">只读模式（已提交/审核单据不可编辑）</span>
        </div>
        <div class="form-wrapper">
          <MasterDetailEditor
            v-if="sortedEntities.length"
            v-model="formData"
            :entities="sortedEntities"
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
              :bill-type="boCode"
              :bill-id="formData.id"
            />
            <el-empty v-else description="保存后可上传附件" :image-size="50" />
          </el-tab-pane>

          <el-tab-pane label="联查" name="trace" :disabled="!formData.id">
            <BillTraceTree
              v-if="formData.id"
              :bill-type="boCode"
              :bill-id="String(formData.id)"
            />
            <el-empty v-else description="保存后可联查" :image-size="50" />
          </el-tab-pane>
        </el-tabs>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onActivated } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import BillToolbar from '@/components/BillToolbar/index.vue'
import MasterDetailEditor from '@/components/MasterDetailEditor/index.vue'
import AttachmentUpload from '@/components/AttachmentUpload/index.vue'
import BillTraceTree from '@/components/BillTraceTree/index.vue'
import { billApi } from '@/api/bill'
import { entityApi, formLayoutApi, type FormLayout } from '@/api/bo'
import { PACT_STATE_MAP } from '@/utils/enum'
import type { FormEntity } from '@/types/bo'

const route = useRoute()
const router = useRouter()

// 路由参数：/bill/:boCode/:id
const boCode = computed(() => String(route.params.boCode || ''))
const billId = computed(() => String(route.params.id || 'new'))
const isNew = computed(() => billId.value === 'new' || !billId.value)

const entities = ref<FormEntity[]>([])
const formData = reactive<Record<string, any>>({})
const activeSideTab = ref('info')
const layoutName = ref('')
const layoutVersion = ref(0)

const mode = computed<'view' | 'edit' | 'add'>(() => {
  if (isNew.value) return 'add'
  const ps = Number(formData.pact_state)
  // 0=暂存, 1=已创建 → 可编辑；2=已提交, 3=已审核, 4=已驳回 → 只读
  if (ps === 0 || ps === 1) return 'edit'
  return 'view'
})

const modeLabel = computed(() => {
  return { view: '查看', edit: '编辑', add: '新增' }[mode.value]
})

const billTitle = computed(() => {
  const main = entities.value.find(e => e.entity_type === 'main')
  return main?.entity_name || boCode.value
})

// 按布局元数据排序实体（layoutJson.tabs.sort 驱动实体显示顺序）
const sortedEntities = computed<FormEntity[]>(() => {
  return entities.value
})

function stateLabel(code: number): string {
  return PACT_STATE_MAP[code]?.label || String(code)
}

function stateTagType(code: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  return (PACT_STATE_MAP[code]?.type as any) || 'info'
}

// 后端 {main, subs} 结构扁平化为 MasterDetailEditor 期望的结构
// 后端返回: { main: {...主表字段}, subs: { entity_code: [...子表行] } }
// 孙表行已嵌套在父行中（key=孙表 entity_code）
// MasterDetailEditor 期望: { ...主表字段, entity_code: [...子表行] }
function flattenBillData(raw: any): Record<string, any> {
  const data: Record<string, any> = { ...(raw?.main || {}) }
  const subs = raw?.subs || {}
  // 子表数据扁平化
  entities.value.filter(e => e.entity_type === 'sub').forEach(sub => {
    data[sub.entity_code] = subs[sub.entity_code] || []
  })
  // 孙表数据分配到对应的子表行中（MasterDetailEditor 期望嵌套结构 parentRow[gc_entity_code]）
  // 后端返回扁平列表 subs[gc_entity_code]，需按 link_field 分组挂到子表行上
  entities.value.filter(e => e.entity_type === 'grandchild').forEach(gc => {
    const gcRows: any[] = subs[gc.entity_code] || []
    const gcLink = gc.link_field
    const parentCode = gc.parent_entity_code
    const subRows: any[] = data[parentCode] || []
    subRows.forEach((subRow: any) => {
      subRow[gc.entity_code] = gcRows.filter((gcRow: any) =>
        String(subRow.id) === String(gcRow[gcLink])
      )
    })
  })
  return data
}

// 保存前：MasterDetailEditor 扁平结构转回后端 {main, subs} 结构
// 关键：将 boolean→int（后端 int 列不接受 boolean）、空串/0 link_field→null（后端仅在 null 时回填关联字段）
function buildSaveData(): { main: Record<string, any>; subs: Record<string, any[]> } {
  const main: Record<string, any> = {}
  const subs: Record<string, any[]> = {}
  const subEntities = entities.value.filter(e => e.entity_type === 'sub')
  const grandchildEntities = entities.value.filter(e => e.entity_type === 'grandchild')
  // 所有非主表实体的 entity_code（子表+孙表），用于排除主表字段
  const allSubCodes = new Set([
    ...subEntities.map(e => e.entity_code),
    ...grandchildEntities.map(e => e.entity_code)
  ])
  const linkFieldSet = new Set<string>()
  subEntities.forEach(e => { if (e.link_field) linkFieldSet.add(e.link_field) })
  grandchildEntities.forEach(e => { if (e.link_field) linkFieldSet.add(e.link_field) })
  // 主表字段
  Object.keys(formData).forEach(k => {
    if (!allSubCodes.has(k)) main[k] = normalizeVal(formData[k], k === 'id' || linkFieldSet.has(k))
  })
  // 子表行（含嵌套的孙表行，后端 saveNestedGrandChildren 从子表行中读取孙表数据并回填 link_field）
  subEntities.forEach(sub => {
    const linkField = sub.link_field
    subs[sub.entity_code] = (formData[sub.entity_code] || []).map((row: Record<string, any>) => {
      const cleaned: Record<string, any> = {}
      Object.keys(row).forEach(k => {
        // 嵌套的孙表行数组需递归 normalize（id 和 link_field 空值→null）
        const gcEntity = grandchildEntities.find(g => g.entity_code === k)
        if (gcEntity) {
          const gcLink = gcEntity.link_field
          cleaned[k] = (row[k] || []).map((gcRow: any) => {
            const gcCleaned: Record<string, any> = {}
            Object.keys(gcRow).forEach(gck => {
              if (gck === gcEntity.entity_code) return // 排除更深嵌套键
              gcCleaned[gck] = normalizeVal(gcRow[gck], gck === 'id' || gck === gcLink)
            })
            return gcCleaned
          })
        } else {
          cleaned[k] = normalizeVal(row[k], k === 'id' || k === linkField)
        }
      })
      return cleaned
    })
  })
  return { main, subs }
}

// 标量值规整：boolean→0/1；空串/0（仅当 isLinkOrId=true）→null
function normalizeVal(v: any, isLinkOrId: boolean): any {
  if (typeof v === 'boolean') return v ? 1 : 0
  if (isLinkOrId && (v === '' || v === 0 || v === '0' || v === null || v === undefined)) return null
  return v
}

// 新增时按实体定义初始化默认值
function initNewForm() {
  const main = entities.value.find(e => e.entity_type === 'main')
  if (main) {
    main.fields.forEach(f => {
      if (f.is_system && f.field_code === 'pact_state') {
        formData[f.field_code] = 0
      } else if (f.is_system && (f.field_code === 'is_closed' || f.field_code === 'is_cancel')) {
        formData[f.field_code] = 0
      } else if (f.default_value === 'TODAY') {
        formData[f.field_code] = new Date().toISOString().slice(0, 10)
      } else if (f.default_value !== undefined && f.default_value !== '') {
        formData[f.field_code] = f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty'
          ? Number(f.default_value)
          : f.default_value
      } else if (f.ctrl_type === 'checkbox') {
        formData[f.field_code] = 0
      } else if (f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty') {
        formData[f.field_code] = 0
      } else {
        formData[f.field_code] = ''
      }
    })
  }
  entities.value.filter(e => e.entity_type === 'sub').forEach(sub => {
    formData[sub.entity_code] = []
  })
}

// 按布局元数据排序实体
function applyLayout(layout: FormLayout | null) {
  if (!layout || !layout.layout_json) return
  let parsed: { tabs?: Array<{ entity_code: string; sort: number }> } = {}
  try { parsed = JSON.parse(layout.layout_json) } catch { return }
  if (!parsed.tabs?.length) return
  layoutName.value = layout.layout_name || '默认布局'
  layoutVersion.value = layout.version || 0
  const orderMap = new Map(parsed.tabs.map(t => [t.entity_code, t.sort]))
  entities.value.sort((a, b) => (orderMap.get(a.entity_code) ?? 99) - (orderMap.get(b.entity_code) ?? 99))
}

async function loadMeta() {
  entities.value = await entityApi.list(boCode.value)
  // 加载布局元数据并按 tabs.sort 排序实体
  try {
    const layout = await formLayoutApi.getDefault(boCode.value)
    applyLayout(layout)
  } catch {
    // 布局加载失败不阻断，使用默认排序
  }
}

async function loadDetail() {
  // 复制：从 copyFrom 参数加载源单据数据，清空 id/code 等字段作为新单据
  const copyFrom = route.query.copyFrom
  if (isNew.value && copyFrom) {
    const raw = await billApi.detail(boCode.value, String(copyFrom))
    const flattened = flattenBillData(raw || {})
    Object.keys(formData).forEach(k => delete formData[k])
    Object.assign(formData, flattened)
    // 清空主表 id 和编码，作为新单据
    formData.id = ''
    formData.code = ''
    // 清空审计/流程字段
    formData.auditor = ''
    formData.audit_by = ''
    formData.audit_time = ''
    formData.create_by = ''
    formData.create_time = ''
    // 重置单据状态为暂存
    formData.pact_state = 0
    formData.is_closed = 0
    formData.is_cancel = 0
    // 清空子表行的 id 和 link_field（作为新行），同时清空嵌套的孙表行
    entities.value.filter(e => e.entity_type === 'sub').forEach(sub => {
      const linkField = sub.link_field
      ;(formData[sub.entity_code] || []).forEach((row: any) => {
        row.id = ''
        row._tempId = Date.now() + Math.random()
        if (linkField) row[linkField] = ''
        // 清空嵌套的孙表行 id 和 link_field
        entities.value.filter(e => e.entity_type === 'grandchild' && e.parent_entity_code === sub.entity_code).forEach(gc => {
          const gcLink = gc.link_field
          ;(row[gc.entity_code] || []).forEach((gcRow: any) => {
            gcRow.id = ''
            gcRow._tempId = Date.now() + Math.random()
            if (gcLink) gcRow[gcLink] = ''
          })
        })
      })
    })
    return
  }
  if (isNew.value) {
    initNewForm()
    return
  }
  const raw = await billApi.detail(boCode.value, billId.value)
  const flattened = flattenBillData(raw || {})
  Object.keys(formData).forEach(k => delete formData[k])
  Object.assign(formData, flattened)
}

async function reloadDetail() {
  if (!formData.id) return
  const raw = await billApi.detail(boCode.value, String(formData.id))
  const flattened = flattenBillData(raw || {})
  Object.keys(formData).forEach(k => delete formData[k])
  Object.assign(formData, flattened)
}

// keep-alive 缓存组件，首次挂载时 onMounted + onActivated 都会触发；
// 用 firstMount 标记避免首次重复加载；后续从缓存恢复时 onActivated 重新拉取最新元数据
let firstMount = true

onMounted(async () => {
  if (!boCode.value) return
  await loadMeta()
  await loadDetail()
  if (route.query.tab === 'trace') {
    activeSideTab.value = 'trace'
  }
  firstMount = false
})

// 从 keep-alive 缓存恢复时（如从表单设计器返回），重新拉取最新元数据，
// 确保表单设计器保存的 is_readonly/is_hidden 等属性立即生效
onActivated(async () => {
  if (firstMount) return // 首次挂载 onMounted 已加载，跳过
  if (!boCode.value) return
  await loadMeta()
  await loadDetail()
  if (route.query.tab === 'trace') {
    activeSideTab.value = 'trace'
  }
})

// ============ 工具栏操作 ============
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
      ElMessage.info('下推功能请从列表页或专用入口操作')
      break
    case 'copy':
      if (!formData.id) {
        ElMessage.warning('请先保存单据再复制')
        return
      }
      router.push(`/bill/${boCode.value}/new?copyFrom=${formData.id}`)
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
    const saveData = buildSaveData()
    const res = await billApi.save(boCode.value, saveData)
    if (res?.id) {
      formData.id = res.id
    }
    if (!isDraft) {
      if (formData.pact_state === 0 || formData.pact_state === undefined) {
        formData.pact_state = 1
      }
    }
    ElMessage.success(isDraft ? '暂存成功' : '保存成功')
    if (isNew.value && formData.id) {
      router.replace(`/bill/${boCode.value}/${formData.id}`)
    } else {
      await reloadDetail()
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
    await billApi.operate(boCode.value, String(formData.id), action, extra)
    applyStateChange(action)
    ElMessage.success(`${actionLabel(action)}成功`)
    await reloadDetail()
  } catch {
    ElMessage.error(`${actionLabel(action)}失败`)
  }
}

async function handleToggle(action: 'close' | 'unclose' | 'cancel' | 'uncancel') {
  if (!formData.id) {
    ElMessage.warning('请先保存单据')
    return
  }
  let extra: any
  // cancel 流转配置 require_reason=1，需填写取消原因；close/unclose/uncancel 不需要
  if (action === 'cancel') {
    const reason = await ElMessageBox.prompt('请输入取消原因', '取消', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputType: 'textarea'
    }).then(r => r.value).catch(() => null)
    if (reason === null) return
    extra = { reason }
  }
  try {
    await billApi.operate(boCode.value, String(formData.id), action, extra)
    if (action === 'close') formData.is_closed = 1
    if (action === 'unclose') formData.is_closed = 0
    if (action === 'cancel') formData.is_cancel = 1
    if (action === 'uncancel') formData.is_cancel = 0
    ElMessage.success(`${actionLabel(action)}成功`)
    await reloadDetail()
  } catch {
    ElMessage.error(`${actionLabel(action)}失败`)
  }
}

async function handleDelete() {
  if (!formData.id) {
    ElMessage.warning('新单据无需删除')
    return
  }
  try {
    await ElMessageBox.confirm('确定删除该单据？删除后不可恢复', '删除', { type: 'warning' })
  } catch {
    return
  }
  try {
    await billApi.delete(boCode.value, String(formData.id))
    ElMessage.success('删除成功')
    router.push(`/bill/${boCode.value}`)
  } catch {
    ElMessage.error('删除失败')
  }
}

function applyStateChange(action: string) {
  const map: Record<string, number> = {
    submit: 2, audit: 3, reject: 4, revoke: 1
  }
  if (map[action] !== undefined) {
    formData.pact_state = map[action]
  }
}

function actionLabel(action: string): string {
  const map: Record<string, string> = {
    submit: '提交', audit: '审核', reject: '驳回', revoke: '撤销',
    close: '关闭', unclose: '反关闭', cancel: '取消', uncancel: '反取消',
    delete: '删除'
  }
  return map[action] || action
}
</script>

<style scoped lang="scss">
.generic-bill-detail-page {
  display: flex;
  flex-direction: column;
  height: 100%;
  gap: 12px;
}
.page-header {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  .header-meta {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
    .mode-tip {
      color: #909399;
      font-size: 12px;
    }
    .layout-tip {
      color: #1564ff;
      font-size: 12px;
    }
  }
}
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  min-height: 0;
  .form-panel {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
    .panel-header {
      display: flex;
      align-items: center;
      gap: 8px;
      padding-bottom: 8px;
      border-bottom: 1px solid #ebeef5;
      margin-bottom: 8px;
      .panel-title {
        font-weight: 600;
        font-size: 14px;
      }
      .panel-tip {
        color: #909399;
        font-size: 12px;
      }
    }
    .form-wrapper {
      flex: 1;
      overflow: auto;
    }
  }
  .side-panel {
    width: 320px;
    display: flex;
    flex-direction: column;
    .side-tabs {
      flex: 1;
      overflow: auto;
    }
  }
}
.info-form {
  padding: 4px;
}
.reject-reason {
  color: #f56c6c;
}
</style>
