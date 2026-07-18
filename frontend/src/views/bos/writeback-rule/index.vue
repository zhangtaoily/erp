<template>
  <div class="writeback-rule-page">
    <!-- 顶部 header -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-title">反写规则配置</span>
        <el-tag size="small" type="info" effect="plain">下游审核/取消 → 上游反写</el-tag>
      </div>
      <div class="header-right">
        <el-button size="small" :icon="Refresh" @click="loadRules">刷新</el-button>
        <el-button size="small" type="primary" :icon="Plus" @click="onAdd">新增</el-button>
      </div>
    </div>

    <!-- 信息横幅 -->
    <el-alert
      class="info-banner"
      type="info"
      :closable="false"
      show-icon
    >
      反写规则支持下游单据审核/取消时反写上游单据字段。支持累加(add)/扣减(subtract)/覆盖(cover)三模式，block/warn/allow 超限控制。
    </el-alert>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左侧规则列表 -->
      <div class="rule-list-panel panel-card">
        <div class="panel-title">
          <span>反写规则</span>
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
                <el-switch
                  v-model="r.is_enabled"
                  size="small"
                  @click.stop
                />
              </div>
              <div class="rule-name" :title="r.rule_name">{{ r.rule_name }}</div>
              <div class="rule-flow">
                <el-tag size="small" type="info" effect="plain">{{ r.src_bill_type }}</el-tag>
                <el-icon class="flow-arrow"><Right /></el-icon>
                <el-tag size="small" type="info" effect="plain">{{ r.target_bill_type }}</el-tag>
              </div>
              <div class="rule-item-foot">
                <el-tag size="small" :type="modeTag(r.writeback_mode)" effect="light">
                  {{ modeLabel(r.writeback_mode) }}
                </el-tag>
                <el-tag size="small" :type="overTag(r.over_control)" effect="light">
                  {{ overLabel(r.over_control) }}
                </el-tag>
                <el-tag size="small" :type="r.trigger_op === 'audit' ? 'success' : 'warning'" effect="plain">
                  {{ r.trigger_op === 'audit' ? '审核' : '取消' }}
                </el-tag>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧详情 -->
      <div class="rule-detail-panel panel-card">
        <el-empty v-if="!current" description="请选择左侧规则或点击「新增」" :image-size="80" />
        <template v-else>
          <div class="panel-title">
            <span>规则详情</span>
            <el-tag size="small" type="info" effect="plain">
              {{ current.id && current.id.startsWith('new-') ? '未保存' : current.id }}
            </el-tag>
          </div>
          <div class="detail-body">
            <!-- 基本信息表单 -->
            <el-form :model="current" label-width="100px" size="small" class="basic-form">
              <el-row :gutter="12">
                <el-col :span="8">
                  <el-form-item label="规则编码">
                    <el-input v-model="current.rule_code" placeholder="如 OUT2SO" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="规则名称">
                    <el-input v-model="current.rule_name" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="启用">
                    <el-switch v-model="current.is_enabled" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="下游单据">
                    <BoPicker v-model="current.src_bill_type" @change="onSrcBillChange" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="上游单据">
                    <BoPicker v-model="current.target_bill_type" @change="onTargetBillChange" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="触发操作">
                    <el-radio-group v-model="current.trigger_op">
                      <el-radio value="audit">审核</el-radio>
                      <el-radio value="cancel">取消</el-radio>
                    </el-radio-group>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="反写模式">
                    <el-select v-model="current.writeback_mode" style="width:100%">
                      <el-option
                        v-for="o in WRITEBACK_MODE_OPTIONS"
                        :key="o.value"
                        :label="o.label"
                        :value="o.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="超限控制">
                    <el-select v-model="current.over_control" style="width:100%">
                      <el-option
                        v-for="o in OVER_CONTROL_OPTIONS"
                        :key="o.value"
                        :label="o.label"
                        :value="o.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="级联反写">
                    <el-switch v-model="current.cascade" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="源关联字段">
                    <el-input v-model="current.src_link_field" placeholder="下游单据行字段，如 src_order_goods_id" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="目标关联字段">
                    <el-input v-model="current.target_link_field" placeholder="上游单据行字段，如 id" />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>

            <!-- 反写字段映射 -->
            <div class="fields-section">
              <div class="section-header">
                <span class="section-title">反写字段映射（下游字段 → 上游字段）</span>
                <el-button size="small" type="primary" :icon="Plus" @click="onAddField">添加字段</el-button>
              </div>
              <el-table :data="current.fields" border size="small" row-key="id" class="fields-table">
                <el-table-column label="#" type="index" width="42" align="center" />
                <el-table-column label="下游字段 src_field" width="160">
                  <template #default="{ row }">
                    <el-input v-model="row.src_field" size="small" placeholder="如 qty" />
                  </template>
                </el-table-column>
                <el-table-column label="上游字段 target_field" width="160">
                  <template #default="{ row }">
                    <el-input v-model="row.target_field" size="small" placeholder="如 out_qty" />
                  </template>
                </el-table-column>
                <el-table-column label="反写表达式 writeback_expr" min-width="320">
                  <template #default="{ row }">
                    <ExpressionEditor
                      :model-value="row.writeback_expr"
                      height="60px"
                      writeback-mode
                      :src-bo-code="current.src_bill_type"
                      :target-bo-code="current.target_bill_type"
                      @update:model-value="(v: string) => onFieldChange(row as any, v)"
                    />
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="70" fixed="right">
                  <template #default="{ $index }">
                    <el-button link type="danger" size="small" @click="onRemoveField($index)">删除</el-button>
                  </template>
                </el-table-column>
              </el-table>
              <el-empty v-if="!current.fields.length" description="暂无字段映射，点击「添加字段」" :image-size="40" />
            </div>

            <!-- 表达式区 -->
            <div class="expr-section">
              <div class="section-header">
                <span class="section-title">超限校验表达式 over_expr</span>
                <span class="section-tip">支持 src./target. 前缀引用双 BO 字段，如 target.out_qty + src.qty &gt; target.order_qty</span>
              </div>
              <ExpressionEditor
                :model-value="current.over_expr"
                height="80px"
                writeback-mode
                :src-bo-code="current.src_bill_type"
                :target-bo-code="current.target_bill_type"
                @update:model-value="(v: string) => { if (current) current.over_expr = v }"
              />
            </div>
            <div class="expr-section">
              <div class="section-header">
                <span class="section-title">反写条件表达式 condition_expr</span>
              </div>
              <ExpressionEditor
                :model-value="current.condition_expr"
                height="80px"
                writeback-mode
                :src-bo-code="current.src_bill_type"
                :target-bo-code="current.target_bill_type"
                @update:model-value="(v: string) => { if (current) current.condition_expr = v }"
              />
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
import { Plus, Check, Delete, Refresh, Right } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'
import { writebackApi } from '@/api/rule'
import { WRITEBACK_MODE_OPTIONS, OVER_CONTROL_OPTIONS } from '@/utils/enum'
import type { WritebackRule, WritebackField, WritebackMode, OverControl } from '@/types/bo'

const rules = ref<WritebackRule[]>([])
const selectedId = ref('')
const loading = ref(false)

const current = computed(() => rules.value.find(r => r.id === selectedId.value) || null)

function modeLabel(m: WritebackMode) {
  return WRITEBACK_MODE_OPTIONS.find(o => o.value === m)?.label || m
}
function modeTag(m: WritebackMode): 'success' | 'warning' | 'primary' {
  if (m === 'add') return 'success'
  if (m === 'subtract') return 'warning'
  return 'primary'
}
function overLabel(o: OverControl) {
  return OVER_CONTROL_OPTIONS.find(x => x.value === o)?.label || o
}
function overTag(o: OverControl): 'danger' | 'warning' | 'success' {
  if (o === 'block') return 'danger'
  if (o === 'warn') return 'warning'
  return 'success'
}

async function loadRules() {
  loading.value = true
  try {
    const res = await writebackApi.list()
    rules.value = res || []
    selectedId.value = rules.value.length ? rules.value[0].id : ''
  } catch {
    rules.value = []
    selectedId.value = ''
  } finally {
    loading.value = false
  }
}

function onSelect(r: WritebackRule) {
  selectedId.value = r.id
}

function onAdd() {
  const newRule: WritebackRule = {
    id: 'new-' + Date.now(),
    rule_code: '',
    rule_name: '',
    src_bill_type: '',
    target_bill_type: '',
    trigger_op: 'audit',
    writeback_mode: 'add',
    over_control: 'block',
    cascade: false,
    src_link_field: '',
    target_link_field: '',
    fields: [],
    over_expr: '',
    condition_expr: '',
    is_enabled: true
  }
  rules.value.push(newRule)
  selectedId.value = newRule.id
}

function onSrcBillChange(_bo: any) {
  // 切换下游单据时，重置源关联字段（避免遗留旧字段名）
  if (current.value) current.value.src_link_field = ''
}

function onTargetBillChange(_bo: any) {
  // 切换上游单据时，重置目标关联字段
  if (current.value) current.value.target_link_field = ''
}

function onAddField() {
  if (!current.value) return
  const field: WritebackField = {
    id: 'new-field-' + Date.now(),
    rule_id: current.value.id,
    src_field: '',
    target_field: '',
    writeback_expr: ''
  }
  current.value.fields.push(field)
}

function onFieldChange(row: any, value: string) {
  row.writeback_expr = value
}

function onRemoveField(idx: number) {
  if (!current.value) return
  current.value.fields.splice(idx, 1)
}

async function onSave() {
  if (!current.value) return
  if (!current.value.rule_code || !current.value.rule_name) {
    ElMessage.warning('请填写规则编码和名称')
    return
  }
  try {
    const payload: Partial<WritebackRule> = { ...current.value }
    if (current.value.id.startsWith('new-')) {
      const created = await writebackApi.create(payload)
      Object.assign(current.value, created)
      ElMessage.success('新增成功')
    } else {
      await writebackApi.update(current.value.id, payload)
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
    await writebackApi.delete(id)
    const idx = rules.value.findIndex(r => r.id === id)
    if (idx > -1) rules.value.splice(idx, 1)
    selectedId.value = rules.value[0]?.id || ''
    ElMessage.success('删除成功')
  } catch {
    ElMessage.error('删除失败')
  }
}

onMounted(loadRules)
</script>

<style scoped lang="scss">
.writeback-rule-page {
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
.header-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
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
  width: 320px;
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
.rule-flow {
  display: flex;
  align-items: center;
  gap: 4px;
  margin: 4px 0;
}
.flow-arrow {
  color: #1564ff;
  font-size: 12px;
}
.rule-item-foot {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
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
.fields-section {
  margin-top: 8px;
  border-top: 1px dashed #ebeef5;
  padding-top: 10px;
  margin-bottom: 12px;
}
.expr-section {
  margin-top: 8px;
  margin-bottom: 10px;
}
.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  gap: 12px;
}
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  flex-shrink: 0;
}
.section-tip {
  font-size: 12px;
  color: #909399;
  font-weight: normal;
}
.fields-table :deep(.el-table__cell) {
  padding: 4px 0;
  vertical-align: top;
}
.detail-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-top: 1px solid #f0f0f0;
  background: #fafafa;
}
</style>
