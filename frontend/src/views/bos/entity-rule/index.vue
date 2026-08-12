<template>
  <div class="entity-rule-page">
    <!-- 顶部 header -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:260px" @change="onBoChange" />
      </div>
      <div class="header-right">
        <el-button size="small" type="primary" :icon="Plus" :disabled="!boCode" @click="onAdd">新增规则</el-button>
        <el-button size="small" :icon="Check" :disabled="!rules.length" @click="onSaveAll">保存全部</el-button>
      </div>
    </div>

    <!-- 信息横幅 -->
    <el-alert
      class="info-banner"
      type="info"
      :closable="false"
      show-icon
    >
      实体服务规则按 priority 升序执行，先于插件执行。支持 validate/calc/linkage/available 四类，使用 ANTLR4 表达式引擎。
    </el-alert>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左侧规则列表 -->
      <div class="rule-list-panel panel-card">
        <div class="panel-title">
          <span>规则列表</span>
          <el-tag v-if="rules.length" size="small" type="info" effect="plain">{{ rules.length }}</el-tag>
        </div>
        <div v-loading="loading" class="rule-list-scroll">
          <el-empty v-if="!rules.length && !loading" description="暂无规则" :image-size="60" />
          <div v-else class="rule-list">
            <div
              v-for="r in rules"
              :key="r.id"
              class="rule-item"
              :class="{ active: r.id === selectedId }"
              @click="onSelect(r)"
            >
              <div class="rule-item-head">
                <span class="rule-code" :title="r.rule_code">{{ r.rule_code }}</span>
                <el-tag size="small" :type="ruleTypeTag(r.rule_type)" effect="light">
                  {{ ruleTypeLabel(r.rule_type) }}
                </el-tag>
              </div>
              <div class="rule-name" :title="r.rule_name">{{ r.rule_name }}</div>
              <div class="rule-item-foot">
                <span class="rule-priority">优先级 {{ r.priority }}</span>
                <el-switch
                  v-model="r.is_enabled"
                  size="small"
                  @click.stop
                  @change="onToggleEnabled(r)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧详情 -->
      <div class="rule-detail-panel panel-card">
        <el-empty v-if="!current" description="请选择左侧规则或点击「新增规则」" :image-size="80" />
        <template v-else>
          <div class="panel-title">
            <span>规则详情</span>
            <el-tag size="small" type="info" effect="plain">
              {{ current.id && current.id.startsWith('new-') ? '未保存' : current.id }}
            </el-tag>
          </div>
          <div class="detail-body">
            <!-- 基本信息表单 -->
            <el-form :model="current" label-width="90px" size="small" class="basic-form">
              <el-row :gutter="12">
                <el-col :span="8">
                  <el-form-item label="规则编码">
                    <el-input v-model="current.rule_code" placeholder="如 SO_AMT_CALC" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="规则名称">
                    <el-input v-model="current.rule_name" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="实体编码">
                    <el-input v-model="current.entity_code" placeholder="如 sal_order_goods" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="规则类型">
                    <el-select v-model="current.rule_type" style="width:100%">
                      <el-option
                        v-for="o in RULE_TYPE_OPTIONS"
                        :key="o.value"
                        :label="o.label"
                        :value="o.value"
                      >
                        <div class="type-option">
                          <span class="type-dot" :class="'dot-' + o.value"></span>
                          <span>{{ o.label }}</span>
                        </div>
                      </el-option>
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="触发事件">
                    <el-select v-model="current.trigger_event" style="width:100%">
                      <el-option
                        v-for="o in TRIGGER_EVENT_OPTIONS"
                        :key="o.value"
                        :label="o.label"
                        :value="o.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col v-if="current.trigger_event === 'OnFieldValueChange'" :span="8">
                  <el-form-item label="触发字段">
                    <el-input v-model="current.trigger_field" placeholder="如 qty / price" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="优先级">
                    <el-input-number
                      v-model="current.priority"
                      :min="0"
                      :max="9999"
                      controls-position="right"
                      style="width:100%"
                    />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="启用">
                    <el-switch v-model="current.is_enabled" />
                  </el-form-item>
                </el-col>
                <el-col :span="24">
                  <el-form-item label="备注">
                    <el-input v-model="current.remark" type="textarea" :rows="2" />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>

            <!-- 规则项 items 区 -->
            <div class="items-section">
              <div class="section-header">
                <span class="section-title">规则项（条件 → 动作）</span>
                <el-button size="small" type="primary" :icon="Plus" @click="onAddItem">添加项</el-button>
              </div>
              <el-table :data="current.items" border size="small" row-key="id" class="items-table">
                <el-table-column label="#" type="index" width="42" align="center" />
                <el-table-column label="条件表达式 condition_expr" min-width="300">
                  <template #default="{ row }">
                    <div class="expr-cell">
                      <ExpressionEditor
                        :model-value="row.condition_expr"
                        height="80px"
                        :bo-code="boCode"
                        @update:model-value="(v: string) => onItemChange(row as any, 'condition_expr', v)"
                      />
                      <div class="expr-tools">
                        <el-button link type="primary" size="small" @click="onValidateExpr(row.condition_expr)">
                          <el-icon><Check /></el-icon>校验
                        </el-button>
                      </div>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column label="动作表达式 action_expr" min-width="300">
                  <template #default="{ row }">
                    <div class="expr-cell">
                      <ExpressionEditor
                        :model-value="row.action_expr"
                        height="80px"
                        :bo-code="boCode"
                        @update:model-value="(v: string) => onItemChange(row as any, 'action_expr', v)"
                      />
                      <div class="expr-tools">
                        <el-button link type="primary" size="small" @click="onValidateExpr(row.action_expr)">
                          <el-icon><Check /></el-icon>校验
                        </el-button>
                      </div>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column v-if="current.rule_type === 'validate'" label="错误提示" width="180">
                  <template #default="{ row }">
                    <el-input v-model="row.error_msg" size="small" placeholder="校验失败提示" />
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="70" fixed="right">
                  <template #default="{ $index }">
                    <el-button link type="danger" size="small" @click="onRemoveItem($index)">删除</el-button>
                  </template>
                </el-table-column>
              </el-table>
              <el-empty v-if="!current.items.length" description="暂无规则项，点击「添加项」" :image-size="40" />
            </div>
          </div>

          <!-- 底部操作 -->
          <div class="detail-footer">
            <el-button size="small" type="primary" :icon="Check" @click="onSave">保存</el-button>
            <el-button size="small" type="danger" :icon="Delete" @click="onDelete">删除</el-button>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Check, Delete } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'
import { entityRuleApi } from '@/api/rule'
import { RULE_TYPE_OPTIONS, TRIGGER_EVENT_OPTIONS } from '@/utils/enum'
import type { EntityRule, EntityRuleItem, RuleType } from '@/types/bo'

const boCode = ref('sal_order')
const rules = ref<EntityRule[]>([])
const selectedId = ref('')
const loading = ref(false)

const current = computed(() => rules.value.find(r => r.id === selectedId.value) || null)

function ruleTypeLabel(t: RuleType) {
  return RULE_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}
function ruleTypeTag(t: RuleType): 'danger' | 'primary' | 'warning' | 'success' {
  if (t === 'validate') return 'danger'
  if (t === 'calc') return 'primary'
  if (t === 'linkage') return 'warning'
  return 'success'
}

async function loadRules() {
  if (!boCode.value) {
    rules.value = []
    selectedId.value = ''
    return
  }
  loading.value = true
  try {
    const res = await entityRuleApi.list(boCode.value)
    rules.value = (res || []).slice().sort((a, b) => a.priority - b.priority)
    selectedId.value = rules.value.length ? rules.value[0].id : ''
  } catch {
    rules.value = []
    selectedId.value = ''
  } finally {
    loading.value = false
  }
}

function onBoChange() {
  selectedId.value = ''
  loadRules()
}

function onSelect(r: EntityRule) {
  selectedId.value = r.id
}

function onAdd() {
  const newRule: EntityRule = {
    id: 'new-' + Date.now(),
    rule_code: '',
    rule_name: '',
    bo_code: boCode.value,
    entity_code: '',
    rule_type: 'validate',
    trigger_event: 'OnBeforeSave',
    trigger_field: '',
    priority: rules.value.length ? Math.max(...rules.value.map(r => r.priority)) + 10 : 10,
    is_enabled: true,
    remark: '',
    items: []
  }
  rules.value.push(newRule)
  selectedId.value = newRule.id
}

function onAddItem() {
  if (!current.value) return
  const seq = current.value.items.length + 1
  const item: EntityRuleItem = {
    id: 'new-item-' + Date.now() + '-' + seq,
    rule_id: current.value.id,
    item_seq: seq,
    condition_expr: '',
    action_expr: '',
    error_msg: ''
  }
  current.value.items.push(item)
}

function onItemChange(row: any, field: 'condition_expr' | 'action_expr', value: string) {
  row[field] = value
}

function onRemoveItem(idx: number) {
  if (!current.value) return
  current.value.items.splice(idx, 1)
  current.value.items.forEach((it, i) => (it.item_seq = i + 1))
}

function onToggleEnabled(_r: EntityRule) {
  // 即时切换，保存时统一提交
}

async function onValidateExpr(expr: string) {
  if (!expr) {
    ElMessage.warning('请先输入表达式')
    return
  }
  try {
    const res = await entityRuleApi.validate(expr)
    if (res.valid) {
      ElMessage.success('语法校验通过')
    } else {
      ElMessage.error(res.error || '校验失败')
    }
  } catch {
    ElMessage.error('校验请求失败')
  }
}

async function onSave() {
  if (!current.value) return
  if (!current.value.rule_code || !current.value.rule_name) {
    ElMessage.warning('请填写规则编码和名称')
    return
  }
  // 强制调用 entityRuleApi.validate 预编译校验每个规则项表达式（PRD §8.1.11）
  // 校验失败阻断保存，避免语法错误的规则入库
  for (const item of current.value.items) {
    if (item.condition_expr && item.condition_expr.trim()) {
      try {
        const res = await entityRuleApi.validate(item.condition_expr)
        if (!res.valid) {
          ElMessage.error(
            `规则项 #${item.item_seq} 条件表达式校验失败：${res.error || '语法错误'}`
          )
          return
        }
      } catch {
        ElMessage.error(`规则项 #${item.item_seq} 条件表达式校验请求失败`)
        return
      }
    }
    if (item.action_expr && item.action_expr.trim()) {
      try {
        const res = await entityRuleApi.validate(item.action_expr)
        if (!res.valid) {
          ElMessage.error(
            `规则项 #${item.item_seq} 动作表达式校验失败：${res.error || '语法错误'}`
          )
          return
        }
      } catch {
        ElMessage.error(`规则项 #${item.item_seq} 动作表达式校验请求失败`)
        return
      }
    }
  }
  try {
    const payload: Partial<EntityRule> = {
      ...current.value,
      bo_code: boCode.value,
      items: current.value.items.map(item => {
        const cleaned: any = { ...item }
        if (typeof cleaned.id === 'string' && cleaned.id.startsWith('new-')) {
          delete cleaned.id
        }
        if (typeof cleaned.rule_id === 'string' && cleaned.rule_id.startsWith('new-')) {
          delete cleaned.rule_id
        }
        return cleaned
      })
    }
    if (current.value.id.startsWith('new-')) {
      delete (payload as any).id
      const created = await entityRuleApi.create(payload)
      Object.assign(current.value, created)
      ElMessage.success('新增成功')
    } else {
      await entityRuleApi.update(current.value.id, payload)
      ElMessage.success('保存成功')
    }
  } catch {
    ElMessage.error('保存失败')
  }
}

async function onDelete() {
  if (!current.value) return
  try {
    await ElMessageBox.confirm(
      `确认删除规则「${current.value.rule_name || current.value.rule_code}」？`,
      '提示',
      { type: 'warning' }
    )
  } catch {
    return
  }
  const id = current.value.id
  if (id.startsWith('new-')) {
    const idx = rules.value.findIndex(r => r.id === id)
    if (idx > -1) rules.value.splice(idx, 1)
    selectedId.value = rules.value[0]?.id || ''
    ElMessage.success('已移除')
    return
  }
  try {
    await entityRuleApi.delete(id)
    const idx = rules.value.findIndex(r => r.id === id)
    if (idx > -1) rules.value.splice(idx, 1)
    selectedId.value = rules.value[0]?.id || ''
    ElMessage.success('删除成功')
  } catch {
    ElMessage.error('删除失败')
  }
}

async function onSaveAll() {
  if (!rules.value.length) return
  let okCount = 0
  let failCount = 0
  for (const r of rules.value) {
    if (!r.rule_code || !r.rule_name) {
      failCount++
      continue
    }
    try {
      const payload: Partial<EntityRule> = {
        ...r,
        bo_code: boCode.value,
        items: r.items.map(item => {
          const cleaned: any = { ...item }
          if (typeof cleaned.id === 'string' && cleaned.id.startsWith('new-')) {
            delete cleaned.id
          }
          if (typeof cleaned.rule_id === 'string' && cleaned.rule_id.startsWith('new-')) {
            delete cleaned.rule_id
          }
          return cleaned
        })
      }
      if (r.id.startsWith('new-')) {
        delete (payload as any).id
        const created = await entityRuleApi.create(payload)
        Object.assign(r, created)
        okCount++
      } else {
        await entityRuleApi.update(r.id, payload)
        okCount++
      }
    } catch {
      failCount++
    }
  }
  if (failCount) {
    ElMessage.warning(`已保存 ${okCount} 条，${failCount} 条失败`)
  } else {
    ElMessage.success(`已保存 ${okCount} 条规则`)
  }
}

onMounted(loadRules)
</script>

<style scoped lang="scss">
.entity-rule-page {
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
  flex-wrap: wrap;
}
.header-label {
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.info-banner {
  margin: 0;
}
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  overflow: hidden;
}
.rule-list-panel {
  width: 340px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.panel-title {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid #f0f0f0;
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}
.rule-list-scroll {
  flex: 1;
  overflow: auto;
  padding: 6px;
}
.rule-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.rule-item {
  padding: 8px 10px;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
  background: #fff;
}
.rule-item:hover {
  border-color: #1564ff;
  background: #f0f7ff;
}
.rule-item.active {
  border-color: #1564ff;
  background: #e9f1ff;
  box-shadow: 0 0 0 1px #1564ff inset;
}
.rule-item-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
}
.rule-code {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  font-weight: 600;
  color: #1564ff;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.rule-name {
  font-size: 13px;
  color: #303133;
  margin: 4px 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.rule-item-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.rule-priority {
  font-size: 12px;
  color: #909399;
}
.rule-detail-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.detail-body {
  flex: 1;
  overflow: auto;
  padding: 12px;
}
.basic-form {
  margin-bottom: 8px;
}
.items-section {
  margin-top: 8px;
  border-top: 1px dashed #ebeef5;
  padding-top: 10px;
}
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
}
.expr-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 4px;
}
.expr-tools {
  display: flex;
  justify-content: flex-end;
}
.items-table :deep(.el-table__cell) {
  padding: 4px 0;
  vertical-align: top;
}
.type-option {
  display: flex;
  align-items: center;
  gap: 6px;
}
.type-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}
.dot-validate { background: #f5222d; }
.dot-calc { background: #1564ff; }
.dot-linkage { background: #faad14; }
.dot-available { background: #52c41a; }
.detail-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-top: 1px solid #f0f0f0;
  background: #fafafa;
}
</style>
