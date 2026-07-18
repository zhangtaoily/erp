<template>
  <div class="form-plugin-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:240px" />
        <el-select
          v-model="selectedTemplate"
          placeholder="选择场景模板预览代码"
          clearable
          size="small"
          style="width:260px"
          :disabled="!boCode"
          @change="onTemplateChange"
        >
          <el-option
            v-for="t in sceneTemplates"
            :key="t.value"
            :label="t.label"
            :value="t.value"
          >
            <div class="tpl-option">
              <span>{{ t.label }}</span>
              <el-tag size="small" type="info" effect="plain">{{ eventLabel(t.event) }}</el-tag>
            </div>
          </el-option>
        </el-select>
      </div>
      <div class="header-right">
        <el-button size="small" @click="refreshPanel" :disabled="!boCode">
          <el-icon><Refresh /></el-icon>刷新
        </el-button>
      </div>
    </div>

    <!-- 信息横幅 -->
    <el-alert
      class="info-banner"
      type="info"
      :closable="false"
      show-icon
    >
      插件按 exec_order 串行执行，前置返回 false 或抛异常可阻断后续插件与主操作。事务边界为整个操作（含插件与主流程）。
    </el-alert>

    <!-- 主体 -->
    <div class="main-body panel-card">
      <el-empty v-if="!boCode" description="请先选择业务对象" :image-size="80" />
      <PluginBindPanel
        v-else
        ref="panelRef"
        :key="panelKey"
        :bo-code="boCode"
      />
    </div>

    <!-- 场景模板代码预览弹窗 -->
    <el-dialog
      v-model="previewVisible"
      :title="`场景模板：${currentTemplate?.label || ''}`"
      width="720px"
      append-to-body
    >
      <div class="preview-meta">
        <el-tag size="small" type="primary" effect="plain">事件：{{ eventLabel(currentTemplate?.event || '') }}</el-tag>
        <el-tag size="small" :type="currentTemplate?.pluginType === 'script' ? 'primary' : 'warning'" effect="plain">
          {{ currentTemplate?.pluginType === 'script' ? '脚本插件' : 'API 插件' }}
        </el-tag>
        <el-tag v-if="currentTemplate?.field" size="small" type="info" effect="plain">触发字段：{{ currentTemplate.field }}</el-tag>
      </div>
      <div class="preview-desc">{{ currentTemplate?.desc }}</div>
      <pre class="code-block"><code>{{ currentTemplate?.code }}</code></pre>
      <template #footer>
        <el-button @click="previewVisible = false">关闭</el-button>
        <el-button
          type="primary"
          :disabled="!boCode"
          @click="onApplyTemplate"
        >应用到当前业务对象</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import PluginBindPanel from '@/components/PluginBindPanel/index.vue'
import { pluginApi } from '@/api/form'
import { PLUGIN_EVENT_OPTIONS, BILL_PLUGIN_EVENTS, LIST_PLUGIN_EVENTS, OPERATION_PIPELINE_EVENTS } from '@/utils/enum'
import type { FormPlugin } from '@/types/bo'

const boCode = ref('')
const panelRef = ref<InstanceType<typeof PluginBindPanel> | null>(null)
const panelKey = ref(0)
const selectedTemplate = ref('')
const previewVisible = ref(false)

function eventLabel(event: string) {
  const all = [...PLUGIN_EVENT_OPTIONS, ...BILL_PLUGIN_EVENTS, ...LIST_PLUGIN_EVENTS, ...OPERATION_PIPELINE_EVENTS]
  return all.find(o => o.value === event)?.label || event
}

interface SceneTemplate {
  value: string
  label: string
  event: string
  pluginType: 'script' | 'api'
  field?: string
  desc: string
  code: string
  toPlugin: (boCode: string) => Partial<FormPlugin>
}

const sceneTemplates: SceneTemplate[] = [
  {
    value: 'tpl_credit_check',
    label: '客户信用额度校验',
    event: 'OnAddValidators',
    pluginType: 'script',
    desc: '审核前校验客户信用额度是否超限，超限则阻断审核。',
    code: `// OnBeforeAudit：客户信用额度校验
var custId = getFieldValue('cust_id');
var amount = getFieldValue('total_amount');
var used = queryData(
  "SELECT COALESCE(SUM(total_amount),0) AS used_amt " +
  "FROM sal_order WHERE cust_id = ? AND pact_state = 3",
  [custId]
)[0].used_amt;
var limit = LOOKUP('customer', custId).credit_limit;

if (used + amount > limit) {
  throwException('客户信用额度不足：已用 ' + used + ' + 本次 ' + amount + ' > 额度 ' + limit);
}
return true;`,
    toPlugin: (bc) => ({
      bo_code: bc,
      plugin_code: 'CREDIT_LIMIT_CHECK',
      plugin_name: '客户信用额度校验',
      base_class: 'OperationServicePlugin',
      event_name: 'OnAddValidators',
      plugin_type: 'script',
      exec_order: 10,
      status: 1
    })
  },
  {
    value: 'tpl_est_payable',
    label: '暂估应付生成',
    event: 'AfterAudit',
    pluginType: 'script',
    desc: '审核后自动生成暂估应付单据。',
    code: `// OnAfterAudit：暂估应付生成
var billId = getFieldValue('id');
var billCode = getFieldValue('code');
var supplierId = getFieldValue('supplier_id');
var amount = getFieldValue('total_amount');

// 调用暂估应付生成服务
queryData(
  "INSERT INTO est_payable (src_bill_type, src_bill_id, src_bill_code, " +
  " supplier_id, amount, create_time) " +
  " VALUES ('pur_order', ?, ?, ?, ?, NOW())",
  [billId, billCode, supplierId, amount]
);
return true;`,
    toPlugin: (bc) => ({
      bo_code: bc,
      plugin_code: 'EST_PAYABLE_GEN',
      plugin_name: '暂估应付生成',
      base_class: 'BillPlugin',
      event_name: 'AfterAudit',
      plugin_type: 'script',
      exec_order: 20,
      status: 1
    })
  },
  {
    value: 'tpl_avail_qty',
    label: '可用量校验',
    event: 'BeforeExecuteOperationTransaction',
    pluginType: 'script',
    desc: '保存前校验子表行物料可用量是否充足。',
    code: `// OnBeforeSave：可用量校验
var lines = getFieldValue('lines'); // 子表行
for (var i = 0; i < lines.length; i++) {
  var line = lines[i];
  var matId = line.mat_id;
  var qty = line.qty;
  var whId = line.wh_id;
  var avail = queryData(
    "SELECT get_avail_qty(?, ?) AS avail",
    [matId, whId]
  )[0].avail;
  if (qty > avail) {
    throwException('物料 ' + matId + ' 可用量不足：可用 ' + avail + '，本次 ' + qty);
  }
}
return true;`,
    toPlugin: (bc) => ({
      bo_code: bc,
      plugin_code: 'AVAIL_QTY_CHECK',
      plugin_name: '可用量校验',
      base_class: 'OperationServicePlugin',
      event_name: 'BeforeExecuteOperationTransaction',
      plugin_type: 'script',
      exec_order: 10,
      status: 1
    })
  },
  {
    value: 'tpl_mat_spec',
    label: '选物料带出规格',
    event: 'DataChanged',
    pluginType: 'script',
    field: 'mat_id',
    desc: '子表选择物料后，自动带出规格、单位、标准单价等字段。',
    code: `// OnFieldValueChanged：选物料带出规格
// 触发字段：mat_id
var matId = getFieldValue('mat_id');
if (!matId) return true;

var mat = LOOKUP('material', matId);
if (mat) {
  setFieldValue('spec', mat.spec);
  setFieldValue('unit_id', mat.unit_id);
  setFieldValue('price', mat.std_price);
  // 重新计算行金额
  var qty = getFieldValue('qty') || 0;
  setFieldValue('amount', ROUND(qty * mat.std_price, 2));
}
return true;`,
    toPlugin: (bc) => ({
      bo_code: bc,
      plugin_code: 'MAT_SPEC_FILL',
      plugin_name: '选物料带出规格',
      base_class: 'BillPlugin',
      event_name: 'DataChanged',
      plugin_type: 'script',
      field_code: 'mat_id',
      exec_order: 10,
      status: 1
    })
  },
  {
    value: 'tpl_wf_push',
    label: '提交后推送工作流',
    event: 'AfterExecuteOperationTransaction',
    pluginType: 'api',
    desc: '提交后通过 HTTP 调用外部工作流引擎发起审批流程。',
    code: `// OnAfterSubmit：提交后推送工作流（API 插件）
// 调用方式：POST /api/wf/start
// 请求体示例：
{
  "billType": "sal_order",
  "billId": "{{id}}",
  "billCode": "{{code}}",
  "submitBy": "{{getCurrentUser().userId}}",
  "amount": "{{total_amount}}",
  "processKey": "sal_order_audit"
}

// 工作流引擎返回流程实例ID后写入单据 wf_instance_id 字段。
// 超时时间默认 10 秒，超时按异常处理，将阻断提交事务。`,
    toPlugin: (bc) => ({
      bo_code: bc,
      plugin_code: 'WF_PUSH_AFTER_SUBMIT',
      plugin_name: '提交后推送工作流',
      base_class: 'OperationServicePlugin',
      event_name: 'AfterExecuteOperationTransaction',
      plugin_type: 'api',
      api_url: '/api/wf/start',
      api_method: 'POST',
      exec_order: 30,
      status: 1
    })
  }
]

const currentTemplate = computed(() =>
  sceneTemplates.find(t => t.value === selectedTemplate.value) || null
)

function onTemplateChange(val: string) {
  if (val) previewVisible.value = true
}

function refreshPanel() {
  // PluginBindPanel 仅在挂载时拉取数据，通过变更 key 重新挂载以重新加载
  panelKey.value++
  ElMessage.success('已刷新插件列表')
}

async function onApplyTemplate() {
  if (!boCode.value || !currentTemplate.value) return
  const tpl = currentTemplate.value
  const payload = tpl.toPlugin(boCode.value)
  try {
    await pluginApi.create(payload)
    ElMessage.success(`已应用模板「${tpl.label}」并创建插件`)
    previewVisible.value = false
    selectedTemplate.value = ''
    // 重新挂载插件面板以加载新建的插件
    panelKey.value++
  } catch {
    ElMessage.error('应用模板失败')
  }
}
</script>

<style scoped lang="scss">
.form-plugin-page {
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
.info-banner {
  margin: 0 12px;
}
.main-body {
  flex: 1;
  padding: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.main-body > :deep(.plugin-bind-panel) {
  height: 100%;
}
.tpl-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  width: 100%;
}
.preview-meta {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}
.preview-desc {
  font-size: 12px;
  color: #606266;
  margin-bottom: 10px;
  padding: 8px 12px;
  background: #f5f7fa;
  border-radius: 4px;
}
.code-block {
  background: #1e2a3a;
  color: #e6e6e6;
  padding: 14px 16px;
  border-radius: 4px;
  max-height: 380px;
  overflow: auto;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  line-height: 1.6;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
}
.code-block code {
  font-family: inherit;
}
</style>
