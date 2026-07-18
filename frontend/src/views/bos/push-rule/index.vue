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
                <el-tag size="small" :type="r.status === 1 ? 'success' : 'info'" effect="plain">
                  {{ r.status === 1 ? '启用' : '停用' }}
                </el-tag>
              </div>
              <div class="rule-name">{{ r.rule_name }}</div>
              <div class="rule-flow">
                <span class="bo-code">{{ r.src_bo_code }}</span>
                <el-icon class="flow-arrow"><Right /></el-icon>
                <span class="bo-code">{{ r.target_bo_code }}</span>
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
                    <el-input v-model="form.src_bo_code" placeholder="如 sal_order" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="目标业务对象">
                    <el-input v-model="form.target_bo_code" placeholder="如 sal_out_stock" />
                  </el-form-item>
                </el-col>
                <!-- GAP-D04-001 / PRD 02.3.3：可下推数量字段 + 已下推量回写字段 -->
                <el-col :span="12">
                  <el-form-item label="可下推数量字段">
                    <el-input v-model="form.qty_field" placeholder="如 qty（源单数量字段）" />
                    <div class="field-tip">源单可下推数量字段，与 vp_check_expr 配合校验可下推量</div>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="已下推量回写域">
                    <el-input v-model="form.pushed_field" placeholder="如 out_qty（源单回写字段）" />
                    <div class="field-tip">下推成功后回写源单该字段（累加），用于下次可下推量校验</div>
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="允许合并">
                    <el-switch v-model="form.allow_merge" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="允许拆分">
                    <el-switch v-model="form.allow_split" />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="状态">
                    <el-switch
                      v-model="form.status"
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
              <el-button type="primary" link size="small" @click="onAddMapping">
                <el-icon><Plus /></el-icon>添加映射
              </el-button>
            </div>
            <el-table :data="form.field_mappings" border size="small" style="width: 100%">
              <el-table-column label="源字段" min-width="150">
                <template #default="{ row }">
                  <el-input v-model="row.src_field" size="small" placeholder="如 code" />
                </template>
              </el-table-column>
              <el-table-column label="目标字段" min-width="150">
                <template #default="{ row }">
                  <el-input v-model="row.target_field" size="small" placeholder="如 src_order_code" />
                </template>
              </el-table-column>
              <el-table-column label="主表映射" width="100" align="center">
                <template #default="{ row }">
                  <el-switch v-model="row.is_main" />
                </template>
              </el-table-column>
              <el-table-column label="转换表达式" min-width="180">
                <template #default="{ row }">
                  <el-input v-model="row.transform_expr" size="small" placeholder="可选，如 F.qty * F.price" />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="70" align="center" fixed="right">
                <template #default="{ $index }">
                  <el-button type="danger" link size="small" @click="onDeleteMapping($index)">
                    <el-icon><Delete /></el-icon>
                  </el-button>
                </template>
              </el-table-column>
              <template #empty>
                <el-empty description="暂无字段映射，点击“添加映射”" :image-size="40" />
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
              <el-tag size="small" type="warning" effect="plain">运行时校验 F.{qty_field} - F.{pushed_field} &gt; 0</el-tag>
            </div>
            <el-form :model="form" label-width="120px" size="small">
              <el-row :gutter="12">
                <el-col :span="12">
                  <el-form-item label="可下推数量字段">
                    <el-input v-model="form.qty_field" placeholder="如 qty" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="已下推量回写字段">
                    <el-input v-model="form.pushed_field" placeholder="如 out_qty" />
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
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Check, Right } from '@element-plus/icons-vue'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'
import { pushRuleApi } from '@/api/state'
import type { PushRule } from '@/types/bo'

const list = ref<PushRule[]>([])
const selectedId = ref('')
const isNew = ref(false)

function emptyForm(): PushRule {
  return {
    id: '',
    rule_code: '',
    rule_name: '',
    src_bo_code: '',
    target_bo_code: '',
    field_mappings: [],
    vp_check_expr: '',
    filter_expr: '',
    qty_field: '',
    pushed_field: '',
    allow_merge: true,
    allow_split: true,
    status: 1
  }
}

const form = reactive<PushRule>(emptyForm())

async function loadList() {
  const res: any = await pushRuleApi.list()
  list.value = Array.isArray(res) ? res : res?.list || []
  if (list.value.length) {
    onSelectRule(list.value[0])
  } else {
    Object.assign(form, emptyForm())
    selectedId.value = ''
    isNew.value = false
  }
}

function onSelectRule(r: PushRule) {
  selectedId.value = r.id
  isNew.value = false
  Object.assign(form, JSON.parse(JSON.stringify(r)))
}

function onAdd() {
  const f = emptyForm()
  f.id = `pr_new_${Date.now()}`
  Object.assign(form, f)
  selectedId.value = form.id
  isNew.value = true
}

function onAddMapping() {
  form.field_mappings.push({
    src_field: '',
    target_field: '',
    is_main: false,
    transform_expr: ''
  })
}

function onDeleteMapping(idx: number) {
  form.field_mappings.splice(idx, 1)
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
  const payload: Partial<PushRule> = {
    rule_code: form.rule_code,
    rule_name: form.rule_name,
    src_bo_code: form.src_bo_code,
    target_bo_code: form.target_bo_code,
    field_mappings: JSON.parse(JSON.stringify(form.field_mappings)),
    vp_check_expr: form.vp_check_expr,
    filter_expr: form.filter_expr,
    qty_field: form.qty_field,
    pushed_field: form.pushed_field,
    allow_merge: form.allow_merge,
    allow_split: form.allow_split,
    status: form.status
  }
  try {
    if (isNew.value) {
      const saved: any = await pushRuleApi.create(payload)
      const id = saved?.id || form.id
      Object.assign(form, { id }, payload)
      isNew.value = false
      ElMessage.success('新增成功')
    } else {
      await pushRuleApi.update(form.id, payload)
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

onMounted(loadList)
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
