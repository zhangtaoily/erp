<template>
  <div class="push-rule-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-title">下推转换规则</span>
        <el-tag size="small" type="info" effect="plain">共 {{ list.length }} 条</el-tag>
      </div>
      <div class="header-right">
        <el-button type="primary" size="small" @click="onAdd">
          <el-icon><Plus /></el-icon>新增规则
        </el-button>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左：规则列表 -->
      <div class="rule-list-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">规则列表</span>
        </div>
        <div class="list-wrap">
          <el-empty v-if="!list.length" description="暂无规则" :image-size="50" />
          <ul v-else class="rule-list">
            <li
              v-for="r in list"
              :key="r.id"
              class="rule-item"
              :class="{ active: selectedId === r.id }"
              @click="onSelectRule(r)"
            >
              <div class="rule-item-head">
                <span class="rule-code">{{ r.rule_code }}</span>
                <el-tag size="small" :type="r.is_enable === 1 ? 'success' : 'info'" effect="plain">
                  {{ r.is_enable === 1 ? '启用' : '停用' }}
                </el-tag>
              </div>
              <div class="rule-name">{{ r.rule_name }}</div>
              <div class="rule-flow">
                <span class="bo-code">{{ r.src_bo_code }}</span>
                <el-icon class="flow-arrow"><Right /></el-icon>
                <span class="bo-code">{{ r.tgt_bo_code }}</span>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <!-- 右：详情编辑 -->
      <div class="rule-detail-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">{{ isNew ? '新增规则' : '规则详情' }}</span>
          <span v-if="form.rule_code" class="panel-tip">{{ form.rule_code }}</span>
        </div>
        <div class="detail-body">
          <!-- 基本信息 -->
          <div class="section">
            <div class="section-title">基本信息</div>
            <el-form :model="form" label-width="110px" size="small" label-position="right">
              <el-row :gutter="12">
                <el-col :span="12">
                  <el-form-item label="规则编码">
                    <el-input v-model="form.rule_code" placeholder="如 SO2OUT" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="规则名称">
                    <el-input v-model="form.rule_name" placeholder="如 销售订单→销售出库" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="源业务对象">
                    <el-select
                      v-model="form.src_bo_code"
                      placeholder="请选择源业务对象"
                      filterable
                      style="width: 100%"
                      @change="onSrcBoChange"
                    >
                      <el-option
                        v-for="bo in boOptions"
                        :key="bo.bo_code"
                        :label="`${bo.bo_name} (${bo.bo_code})`"
                        :value="bo.bo_code"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="目标业务对象">
                    <el-select
                      v-model="form.tgt_bo_code"
                      placeholder="请选择目标业务对象"
                      filterable
                      style="width: 100%"
                      @change="onTgtBoChange"
                    >
                      <el-option
                        v-for="bo in boOptions"
                        :key="bo.bo_code"
                        :label="`${bo.bo_name} (${bo.bo_code})`"
                        :value="bo.bo_code"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="允许合并">
                    <el-switch v-model="form.allow_merge" :active-value="1" :inactive-value="0" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="允许拆分">
                    <el-switch v-model="form.allow_split" :active-value="1" :inactive-value="0" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="状态">
                    <el-switch
                      v-model="form.is_enable"
                      :active-value="1"
                      :inactive-value="0"
                      active-text="启用"
                      inactive-text="停用"
                      inline-prompt
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </div>

          <!-- 字段映射 -->
          <div class="section">
            <div class="section-title">
              <span>字段映射</span>
              <div class="section-actions">
                <el-tag size="small" type="info" effect="plain">
                  源 {{ srcFieldOptions.length }} 字段 / 目标 {{ tgtFieldOptions.length }} 字段
                </el-tag>
                <el-button type="primary" link size="small" :disabled="!canAutoMap" @click="onAutoMap">
                  <el-icon><MagicStick /></el-icon>自动带出字段
                </el-button>
                <el-button type="primary" link size="small" @click="onAddMapping">
                  <el-icon><Plus /></el-icon>添加映射
                </el-button>
              </div>
            </div>
            <el-table :data="mappings" border size="small" style="width: 100%">
              <el-table-column label="勾选" width="55" align="center">
                <template #default="{ row }">
                  <el-checkbox v-model="row.checked" />
                </template>
              </el-table-column>
              <el-table-column label="序号" width="60" align="center">
                <template #default="{ $index }">
                  <span>{{ $index + 1 }}</span>
                </template>
              </el-table-column>
              <el-table-column label="源字段" min-width="180">
                <template #default="{ row }">
                  <el-select
                    v-model="row.src_field"
                    placeholder="选择源字段"
                    filterable
                    size="small"
                    style="width: 100%"
                    @change="onSrcFieldChange(row)"
                  >
                    <el-option-group
                      v-for="grp in srcFieldGroups"
                      :key="grp.label"
                      :label="grp.label"
                    >
                      <el-option
                        v-for="f in grp.options"
                        :key="f.value"
                        :label="fieldLabel(f)"
                        :value="f.value"
                      />
                    </el-option-group>
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="目标字段" min-width="180">
                <template #default="{ row }">
                  <el-select
                    v-model="row.target_field"
                    placeholder="选择目标字段"
                    filterable
                    size="small"
                    style="width: 100%"
                  >
                    <el-option-group
                      v-for="grp in tgtFieldGroups"
                      :key="grp.label"
                      :label="grp.label"
                    >
                      <el-option
                        v-for="f in grp.options"
                        :key="f.value"
                        :label="fieldLabel(f)"
                        :value="f.value"
                      />
                    </el-option-group>
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="主表映射" width="90" align="center">
                <template #default="{ row }">
                  <el-switch v-model="row.is_main" />
                </template>
              </el-table-column>
              <el-table-column label="转换表达式" min-width="160">
                <template #default="{ row }">
                  <el-input v-model="row.transform_expr" size="small" placeholder="可选，如 F.qty * F.price" />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120" align="center" fixed="right">
                <template #default="{ $index }">
                  <el-button link size="small" :disabled="$index === 0" @click="onMoveUp($index)">
                    <el-icon><Top /></el-icon>
                  </el-button>
                  <el-button link size="small" :disabled="$index === mappings.length - 1" @click="onMoveDown($index)">
                    <el-icon><Bottom /></el-icon>
                  </el-button>
                  <el-button type="danger" link size="small" @click="onDeleteMapping($index)">
                    <el-icon><Delete /></el-icon>
                  </el-button>
                </template>
              </el-table-column>
              <template #empty>
                <el-empty description="暂无字段映射，请先选择源/目标业务对象后点击「自动带出字段」" :image-size="40" />
              </template>
            </el-table>
          </div>

          <!-- 表达式 -->
          <div class="section">
            <div class="section-title">表达式配置</div>
            <el-form :model="form" label-width="0" size="small" label-position="top">
              <el-form-item>
                <template #label>
                  <span class="expr-label">可下推量校验表达式（vp_check_expr）</span>
                </template>
                <ExpressionEditor
                  v-model="form.vp_check_expr"
                  :bo-code="form.src_bo_code"
                  height="100px"
                />
              </el-form-item>
              <el-form-item>
                <template #label>
                  <span class="expr-label">过滤条件表达式（filter_expr）</span>
                </template>
                <ExpressionEditor
                  v-model="form.filter_expr"
                  :bo-code="form.src_bo_code"
                  height="100px"
                />
              </el-form-item>
            </el-form>
          </div>

          <!-- 可下推量字段配置（GAP-D04-001 / PRD 02.3.3 / 02.3.5）-->
          <div class="section">
            <div class="section-title">
              <span>可下推量字段配置</span>
              <el-tag size="small" type="warning" effect="plain">
                运行时校验 F.{qty_field} - F.{pushed_field} &gt; 0
              </el-tag>
            </div>
            <el-form :model="form" label-width="120px" size="small">
              <el-row :gutter="12">
                <el-col :span="24">
                  <el-form-item label="数量字段层级">
                    <el-radio-group v-model="form.qty_field_scope" @change="onScopeChange">
                      <el-radio value="sub">子表明细下推（按子表行数量下推，默认）</el-radio>
                      <el-radio value="main">主表总量下推（按主表总量下推）</el-radio>
                    </el-radio-group>
                    <div class="field-tip">
                      子表明细下推：qty_field/pushed_field 取自子表，按勾选行逐行下推；
                      主表总量下推：qty_field/pushed_field 取自主表，按主表总量一次性下推。
                    </div>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="可下推数量字段">
                    <el-select
                      v-model="form.qty_field"
                      placeholder="选择源单数量字段"
                      filterable
                      clearable
                      style="width: 100%"
                    >
                      <el-option
                        v-for="f in qtyFieldOptions"
                        :key="f.value"
                        :label="fieldLabel(f)"
                        :value="f.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="已下推量回写字段">
                    <el-select
                      v-model="form.pushed_field"
                      placeholder="选择源单回写字段"
                      filterable
                      clearable
                      style="width: 100%"
                    >
                      <el-option
                        v-for="f in qtyFieldOptions"
                        :key="f.value"
                        :label="fieldLabel(f)"
                        :value="f.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <el-alert type="info" :closable="false" show-icon>
                下推时按 <code>F.{qty_field} - F.{pushed_field} &gt; 0</code> 校验可下推量；下推成功后回写 <code>F.{pushed_field} += 本次下推数量</code>，并维护单据关联表 <code>biz_bill_link</code>。
              </el-alert>
            </el-form>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部 -->
    <div class="page-footer panel-card">
      <div class="footer-right">
        <el-button type="danger" size="small" :disabled="isNew || !form.id" @click="onDelete">
          <el-icon><Delete /></el-icon>删除
        </el-button>
        <el-button type="primary" size="small" @click="onSave">
          <el-icon><Check /></el-icon>保存
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Check, Right, Top, Bottom, MagicStick } from '@element-plus/icons-vue'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'
import { pushRuleApi } from '@/api/state'
import { boApi, entityApi } from '@/api/bo'
import type { PushRule, PushFieldMapping, BusinessObject, FormEntity } from '@/types/bo'

const list = ref<PushRule[]>([])
const selectedId = ref('')
const isNew = ref(false)

// 业务对象下拉选项
const boOptions = ref<BusinessObject[]>([])
// 源/目标实体（含字段）
const srcEntities = ref<FormEntity[]>([])
const tgtEntities = ref<FormEntity[]>([])

// 字段选项（扁平化，带实体信息）
interface FieldOption {
  value: string
  label: string
  entity_code: string  // 所属实体编码
  entity_name: string  // 所属实体名称
  entity_type: string  // main / sub / grandchild
  is_main: boolean
}
const srcFieldOptions = ref<FieldOption[]>([])
const tgtFieldOptions = ref<FieldOption[]>([])

// 字段映射（本地编辑数组，保存时序列化为 field_mapping_json）
const mappings = ref<PushFieldMapping[]>([])

// 按实体分组用于 el-option-group（区分多个子表/孙表）
const srcFieldGroups = computed(() => groupByEntity(srcFieldOptions.value))
const tgtFieldGroups = computed(() => groupByEntity(tgtFieldOptions.value))

function groupByEntity(options: FieldOption[]) {
  const groupMap = new Map<string, { label: string; options: FieldOption[] }>()
  for (const o of options) {
    const key = o.entity_code || o.entity_type
    if (!groupMap.has(key)) {
      const typeLabel = o.is_main ? '主表' : o.entity_type === 'grandchild' ? '孙表' : '子表'
      const label = o.entity_name ? `${o.entity_name}（${typeLabel}）` : typeLabel
      groupMap.set(key, { label, options: [] })
    }
    groupMap.get(key)!.options.push(o)
  }
  return Array.from(groupMap.values())
}

// 字段带表信息的展示标签：实体名 / 字段名 (字段编码)
function fieldLabel(f: FieldOption) {
  const ent = f.entity_name ? `${f.entity_name} / ` : ''
  return `${ent}${f.label} (${f.value})`
}

// qty_field/pushed_field 选项：按 scope 过滤（main→主表字段，sub→子表字段）
const qtyFieldOptions = computed<FieldOption[]>(() => {
  const scope = form.qty_field_scope || 'sub'
  if (scope === 'main') {
    return srcFieldOptions.value.filter(o => o.is_main)
  }
  return srcFieldOptions.value.filter(o => !o.is_main && o.entity_type === 'sub')
})

const canAutoMap = computed(() => !!form.src_bo_code && !!form.tgt_bo_code && srcFieldOptions.value.length > 0)

function emptyForm(): PushRule {
  return {
    id: '',
    rule_code: '',
    rule_name: '',
    src_bo_code: '',
    tgt_bo_code: '',
    field_mapping_json: '',
    vp_check_expr: '',
    filter_expr: '',
    qty_field: '',
    pushed_field: '',
    qty_field_scope: 'sub',
    allow_merge: 1,
    allow_split: 1,
    is_enable: 1
  }
}

const form = reactive<PushRule>(emptyForm())

function flattenFields(entities: FormEntity[]): FieldOption[] {
  const result: FieldOption[] = []
  for (const e of entities || []) {
    for (const f of e.fields || []) {
      result.push({
        value: f.field_code,
        label: f.field_name || f.field_code,
        entity_code: e.entity_code || '',
        entity_name: e.entity_name || '',
        entity_type: e.entity_type || 'sub',
        is_main: e.entity_type === 'main'
      })
    }
  }
  return result
}

async function loadBoOptions() {
  try {
    const res: any = await boApi.list()
    boOptions.value = Array.isArray(res) ? res : res?.list || []
  } catch {
    boOptions.value = []
  }
}

async function onSrcBoChange(boCode: string) {
  srcEntities.value = []
  srcFieldOptions.value = []
  if (!boCode) return
  try {
    srcEntities.value = await entityApi.list(boCode) || []
    srcFieldOptions.value = flattenFields(srcEntities.value)
  } catch {
    srcFieldOptions.value = []
  }
  // 切换源 BO 时清空已带出的映射（避免字段失效）
  mappings.value = []
}

async function onTgtBoChange(boCode: string) {
  tgtEntities.value = []
  tgtFieldOptions.value = []
  if (!boCode) return
  try {
    tgtEntities.value = await entityApi.list(boCode) || []
    tgtFieldOptions.value = flattenFields(tgtEntities.value)
  } catch {
    tgtFieldOptions.value = []
  }
  mappings.value = []
}

/** 自动带出字段：源字段与目标字段同名匹配，命中则勾选；未命中也列出但不勾选 */
function onAutoMap() {
  if (!srcFieldOptions.value.length) {
    ElMessage.warning('源业务对象无可带出字段')
    return
  }
  const tgtMap = new Map(tgtFieldOptions.value.map(o => [o.value, o]))
  const result: PushFieldMapping[] = []
  for (const sf of srcFieldOptions.value) {
    const matched = tgtMap.get(sf.value)
    result.push({
      src_field: sf.value,
      target_field: matched ? matched.value : '',
      is_main: sf.is_main,
      transform_expr: '',
      checked: !!matched  // 同名命中才勾选
    })
  }
  mappings.value = result
  ElMessage.success(`已带出 ${result.length} 条映射，其中 ${result.filter(r => r.checked).length} 条同名命中`)
}

function onAddMapping() {
  mappings.value.push({
    src_field: '',
    target_field: '',
    is_main: false,
    transform_expr: '',
    checked: true
  })
}

function onSrcFieldChange(row: PushFieldMapping) {
  // 选择源字段后，自动按 entity_type 推断 is_main
  const sf = srcFieldOptions.value.find(o => o.value === row.src_field)
  if (sf) {
    row.is_main = sf.is_main
    // 若目标字段为空且同名目标字段存在，自动填充
    if (!row.target_field) {
      const matched = tgtFieldOptions.value.find(o => o.value === row.src_field)
      if (matched) {
        row.target_field = matched.value
        row.checked = true
      }
    }
  }
}

function onMoveUp(idx: number) {
  if (idx <= 0) return
  const arr = mappings.value
  ;[arr[idx - 1], arr[idx]] = [arr[idx], arr[idx - 1]]
}

function onMoveDown(idx: number) {
  const arr = mappings.value
  if (idx >= arr.length - 1) return
  ;[arr[idx + 1], arr[idx]] = [arr[idx], arr[idx + 1]]
}

function onDeleteMapping(idx: number) {
  mappings.value.splice(idx, 1)
}

function onScopeChange() {
  // 切换层级后，若已选的 qty_field/pushed_field 不在新选项范围内，则清空
  const validCodes = new Set(qtyFieldOptions.value.map(o => o.value))
  if (form.qty_field && !validCodes.has(form.qty_field)) form.qty_field = ''
  if (form.pushed_field && !validCodes.has(form.pushed_field)) form.pushed_field = ''
}

/** 解析 field_mapping_json 字符串到本地 mappings 数组 */
function parseMappings(json: string): PushFieldMapping[] {
  if (!json) return []
  try {
    const arr = JSON.parse(json)
    return (Array.isArray(arr) ? arr : []).map((m: any) => ({
      src_field: m.src_field || '',
      target_field: m.target_field || '',
      is_main: !!m.is_main,
      transform_expr: m.transform_expr || '',
      // 兼容历史数据：无 checked 字段默认为已勾选（即已配置的映射视为启用）
      checked: m.checked !== undefined ? !!m.checked : true
    }))
  } catch {
    return []
  }
}

/** 序列化 mappings（仅勾选的）为 field_mapping_json 字符串 */
function serializeMappings(): string {
  const arr = mappings.value
    .filter(m => m.checked && m.src_field && m.target_field)
    .map(m => ({
      src_field: m.src_field,
      target_field: m.target_field,
      is_main: m.is_main,
      transform_expr: m.transform_expr || null
    }))
  return JSON.stringify(arr)
}

async function loadList() {
  const res: any = await pushRuleApi.list()
  list.value = Array.isArray(res) ? res : res?.list || []
  if (list.value.length) {
    onSelectRule(list.value[0])
  } else {
    Object.assign(form, emptyForm())
    mappings.value = []
    selectedId.value = ''
    isNew.value = false
  }
}

async function onSelectRule(r: PushRule) {
  selectedId.value = r.id
  isNew.value = false
  const clone: PushRule = JSON.parse(JSON.stringify(r))
  Object.assign(form, clone)
  // 兼容历史数据：缺省 qty_field_scope 默认 sub
  if (!form.qty_field_scope) form.qty_field_scope = 'sub'
  // 解析 field_mapping_json → mappings
  mappings.value = parseMappings(form.field_mapping_json)
  // 加载源/目标字段选项（用于下拉）
  srcEntities.value = []
  tgtEntities.value = []
  srcFieldOptions.value = []
  tgtFieldOptions.value = []
  if (form.src_bo_code) {
    try {
      srcEntities.value = await entityApi.list(form.src_bo_code) || []
      srcFieldOptions.value = flattenFields(srcEntities.value)
    } catch { /* ignore */ }
  }
  if (form.tgt_bo_code) {
    try {
      tgtEntities.value = await entityApi.list(form.tgt_bo_code) || []
      tgtFieldOptions.value = flattenFields(tgtEntities.value)
    } catch { /* ignore */ }
  }
}

function onAdd() {
  const f = emptyForm()
  f.id = `pr_new_${Date.now()}`
  Object.assign(form, f)
  mappings.value = []
  srcEntities.value = []
  tgtEntities.value = []
  srcFieldOptions.value = []
  tgtFieldOptions.value = []
  selectedId.value = form.id
  isNew.value = true
}

async function onSave() {
  if (!form.rule_code.trim()) {
    ElMessage.warning('请输入规则编码')
    return
  }
  if (!form.rule_name.trim()) {
    ElMessage.warning('请输入规则名称')
    return
  }
  if (!form.src_bo_code || !form.tgt_bo_code) {
    ElMessage.warning('请选择源/目标业务对象')
    return
  }
  const payload: Partial<PushRule> = {
    rule_code: form.rule_code,
    rule_name: form.rule_name,
    src_bo_code: form.src_bo_code,
    tgt_bo_code: form.tgt_bo_code,
    field_mapping_json: serializeMappings(),
    vp_check_expr: form.vp_check_expr,
    filter_expr: form.filter_expr,
    qty_field: form.qty_field,
    pushed_field: form.pushed_field,
    qty_field_scope: form.qty_field_scope,
    allow_merge: form.allow_merge,
    allow_split: form.allow_split,
    is_enable: form.is_enable
  }
  try {
    // id 为空或临时 id（pr_new_ 前缀）视为新增，避免 update 到空 URL
    const isTempId = !form.id || String(form.id).startsWith('pr_new_')
    if (isNew.value || isTempId) {
      const saved: any = await pushRuleApi.create(payload)
      const id = saved?.id || form.id
      Object.assign(form, { id }, payload)
      isNew.value = false
      ElMessage.success('新增成功')
    } else {
      await pushRuleApi.update(String(form.id), payload)
      ElMessage.success('保存成功')
    }
    await loadList()
    const found = list.value.find(r => r.id === form.id)
    if (found) onSelectRule(found)
  } catch {
    ElMessage.error('保存失败')
  }
}

function onDelete() {
  if (isNew.value || !form.id) return
  ElMessageBox.confirm(`确定删除规则「${form.rule_name || form.rule_code}」吗？`, '提示', {
    type: 'warning'
  })
    .then(async () => {
      try {
        await pushRuleApi.delete(form.id)
      } catch {
        /* mock 容错 */
      }
      ElMessage.success('删除成功')
      await loadList()
      if (list.value.length) onSelectRule(list.value[0])
      else Object.assign(form, emptyForm())
    })
    .catch(() => {})
}

onMounted(async () => {
  await loadBoOptions()
  await loadList()
})
</script>

<style scoped lang="scss">
.push-rule-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  .header-left {
    display: flex;
    align-items: center;
    gap: 10px;
    .header-title {
      font-size: 15px;
      font-weight: 600;
      color: #303133;
    }
  }
  .header-right {
    display: flex;
    gap: 6px;
  }
}
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  min-height: 0;
}
.rule-list-panel {
  width: 300px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.list-wrap {
  flex: 1;
  overflow: auto;
  padding: 4px;
}
.rule-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.rule-item {
  padding: 10px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
  &:hover {
    border-color: #1564ff;
    background: #f0f7ff;
  }
  &.active {
    border-color: #1564ff;
    background: #ecf5ff;
    box-shadow: 0 0 0 1px #1564ff inset;
    .rule-code {
      color: #1564ff;
    }
  }
  .rule-item-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 4px;
    .rule-code {
      font-size: 13px;
      font-weight: 600;
      color: #303133;
      font-family: 'Consolas', 'Monaco', monospace;
    }
  }
  .rule-name {
    font-size: 12px;
    color: #606266;
    margin-bottom: 6px;
  }
  .rule-flow {
    display: flex;
    align-items: center;
    gap: 6px;
    .bo-code {
      font-size: 12px;
      color: #1564ff;
      font-family: 'Consolas', 'Monaco', monospace;
      background: #f0f7ff;
      padding: 1px 6px;
      border-radius: 3px;
    }
    .flow-arrow {
      color: #c0c4cc;
      font-size: 12px;
    }
  }
}
.rule-detail-panel {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.panel-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  .panel-title {
    font-size: 13px;
    font-weight: 600;
    color: #303133;
  }
  .panel-tip {
    font-size: 12px;
    color: #1564ff;
    font-family: 'Consolas', 'Monaco', monospace;
  }
}
.detail-body {
  flex: 1;
  overflow: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  padding-left: 8px;
  border-left: 3px solid #1564ff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  .section-actions {
    display: flex;
    align-items: center;
    gap: 10px;
  }
}
.expr-label {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}
.field-tip {
  font-size: 11px;
  color: #909399;
  line-height: 1.4;
  margin-top: 2px;
}
.page-footer {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 12px;
  .footer-right {
    display: flex;
    gap: 8px;
  }
}
:deep(.el-empty) {
  padding: 16px;
}
</style>
