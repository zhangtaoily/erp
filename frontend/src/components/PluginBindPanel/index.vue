<template>
  <div class="plugin-bind-panel">
    <!-- 左：基类 + 事件树 -->
    <div class="panel-left panel-card">
      <div class="panel-header"><span class="panel-title">插件基类与事件</span></div>
      <div class="base-filter">
        <el-select v-model="filterBaseClass" placeholder="按基类筛选" clearable size="small" style="width:100%">
          <el-option v-for="b in PLUGIN_BASE_CLASS_OPTIONS" :key="b.value" :label="b.label" :value="b.value" />
        </el-select>
      </div>
      <el-tree
        :data="eventTree"
        :props="{ label: 'label', children: 'children' }"
        default-expand-all
        highlight-current
        @node-click="onEventClick"
      >
        <template #default="{ data }">
          <span class="event-node" :class="{ leaf: !data.children }">
            <span class="node-label">{{ data.label }}</span>
            <el-badge v-if="data.value && countByEvent(data.value)" :value="countByEvent(data.value)" class="event-badge" />
            <el-tag v-if="data.order" size="small" type="info" effect="plain" class="order-tag">{{ data.order }}</el-tag>
          </span>
        </template>
      </el-tree>
    </div>

    <!-- 中：插件列表 -->
    <div class="panel-center panel-card">
      <div class="panel-header">
        <span class="panel-title">插件列表<template v-if="currentEvent"> · {{ currentEventLabel }}</template></span>
        <el-button type="primary" size="small" @click="onAdd"><el-icon><Plus /></el-icon>新增插件</el-button>
      </div>
      <el-table :data="filteredPlugins" border size="small" row-key="id" height="100%">
        <el-table-column prop="exec_order" label="顺序" width="56" sortable />
        <el-table-column prop="plugin_code" label="编码" min-width="130" show-overflow-tooltip />
        <el-table-column prop="plugin_name" label="名称" min-width="150" show-overflow-tooltip />
        <el-table-column label="基类" width="96">
          <template #default="{ row }">
            <el-tag size="small" :type="baseClassTag(row.base_class)" effect="plain">
              {{ baseClassLabel(row.base_class) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="事件" min-width="120" show-overflow-tooltip>
          <template #default="{ row }">{{ eventLabel(row.base_class, row.event_name) }}</template>
        </el-table-column>
        <el-table-column label="类型" width="70">
          <template #default="{ row }">
            <el-tag size="small" :type="pluginTypeTag(row.plugin_type)">{{ pluginTypeLabel(row.plugin_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="64">
          <template #default="{ row }">
            <el-tag size="small" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="142" fixed="right">
          <template #default="{ row }">
            <el-button size="small" link type="primary" @click="onEdit(row as any)">编辑</el-button>
            <el-button size="small" link @click="onToggleStatus(row as any)">{{ row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button size="small" link type="danger" @click="onDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty><el-empty description="暂无插件，点击右上角新增" :image-size="60" /></template>
      </el-table>
    </div>

    <!-- 右：编辑器 -->
    <div class="panel-right panel-card">
      <div class="panel-header">
        <span class="panel-title">{{ editingPlugin ? `编辑：${editingPlugin.plugin_name || '新插件'}` : '插件开发指南' }}</span>
        <el-button v-if="editingPlugin" type="primary" size="small" @click="onSave">保存</el-button>
      </div>

      <template v-if="editingPlugin">
        <el-form :model="editingPlugin" label-width="76px" size="small" class="edit-form">
          <el-form-item label="插件编码" required>
            <el-input v-model="editingPlugin.plugin_code" placeholder="如 SO_AFTER_AUDIT" />
          </el-form-item>
          <el-form-item label="插件名称" required>
            <el-input v-model="editingPlugin.plugin_name" placeholder="如 销售订单审核后立账" />
          </el-form-item>

          <!-- 系统基类选择（参考金蝶三大基类）-->
          <el-form-item label="系统基类" required>
            <el-radio-group
              v-model="editingPlugin.base_class"
              :disabled="editingPlugin.plugin_type === 'class'"
              @change="onBaseClassChange"
            >
              <el-radio-button v-for="b in PLUGIN_BASE_CLASS_OPTIONS" :key="b.value" :value="b.value">
                {{ b.label }}
              </el-radio-button>
            </el-radio-group>
            <el-tag v-if="editingPlugin.plugin_type === 'class'" size="small" type="warning" effect="plain" class="auto-tag">
              反射自动识别
            </el-tag>
          </el-form-item>
          <el-alert
            :type="editingPlugin.plugin_type === 'class' ? 'warning' : 'info'"
            :closable="false" show-icon class="base-desc"
          >
            <template v-if="editingPlugin.plugin_type === 'class'">
              Java类插件的基类由系统反射 superclass 链自动识别，上传字节码后自动回填，无需（也不可）手填。
            </template>
            <template v-else>{{ baseClassDesc(editingPlugin.base_class) }}</template>
          </el-alert>

          <el-form-item label="绑定事件" required>
            <el-select v-model="editingPlugin.event_name" style="width:100%" @change="onEventChange">
              <el-option
                v-for="e in availableEvents"
                :key="e.value"
                :label="e.label"
                :value="e.value"
              >
                <span>{{ e.label }}</span>
                <span class="opt-desc">{{ e.desc || '' }}</span>
              </el-option>
            </el-select>
          </el-form-item>
          <el-form-item v-if="needFieldCode" label="触发字段">
            <el-input v-model="editingPlugin.field_code" placeholder="如 mat_id / qty" />
          </el-form-item>

          <el-form-item label="插件类型">
            <el-radio-group v-model="editingPlugin.plugin_type">
              <el-radio value="script">脚本</el-radio>
              <el-radio value="api">API</el-radio>
              <el-radio value="class">Java类</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="执行顺序">
            <el-input-number v-model="editingPlugin.exec_order" :min="0" :max="9999" :step="10" />
          </el-form-item>
        </el-form>

        <!-- 操作服务插件：流水线可视化 -->
        <div v-if="editingPlugin.base_class === 'OperationServicePlugin'" class="pipeline-section">
          <div class="section-label">
            <el-icon><Operation /></el-icon> 操作执行流水线（当前事件高亮）
          </div>
          <div class="pipeline-flow">
            <div
              v-for="(step, idx) in OPERATION_PIPELINE_EVENTS"
              :key="step.value"
              class="pipeline-step"
              :class="{
                active: editingPlugin.event_name === step.value,
                'in-tx': step.in_transaction
              }"
            >
              <div class="step-order">{{ step.order }}</div>
              <div class="step-name">{{ step.phase }}</div>
              <div class="step-event">{{ step.value }}</div>
              <el-icon v-if="step.in_transaction" class="tx-icon"><Lock /></el-icon>
              <el-icon v-if="idx < OPERATION_PIPELINE_EVENTS.length - 1" class="step-arrow"><ArrowRight /></el-icon>
            </div>
          </div>
          <el-alert type="warning" :closable="false" show-icon class="pipeline-tip">
            事务中事件（Begin/EndOperationTransaction）异常将回滚整个操作；事务前事件不可修改数据库。
          </el-alert>
        </div>

        <!-- 脚本编辑器 -->
        <div v-if="editingPlugin.plugin_type === 'script'" class="editor-wrap">
          <div class="editor-label">脚本内容（ANTLR4 表达式语法）</div>
          <ExpressionEditor
            v-model="editingPlugin.script_content"
            :bo-code="boCode"
            :height="220"
            @validate="onValidate"
          />
        </div>

        <!-- API 配置 -->
        <el-form v-else-if="editingPlugin.plugin_type === 'api'" :model="editingPlugin" label-width="76px" size="small" class="edit-form">
          <el-form-item label="API 地址" required>
            <el-input v-model="editingPlugin.api_url" placeholder="如 /api/sal-order/validate" />
          </el-form-item>
          <el-form-item label="请求方法">
            <el-radio-group v-model="editingPlugin.api_method">
              <el-radio value="GET">GET</el-radio>
              <el-radio value="POST">POST</el-radio>
              <el-radio value="PUT">PUT</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-alert type="info" :closable="false" show-icon>
            API 插件通过 HTTP 调用外部服务，系统将 PluginContext 序列化后传入，超时 10 秒按异常处理。
          </el-alert>
        </el-form>

        <!-- Java 类插件：自描述模型（反射自动识别基类与参数结构） -->
        <div v-else class="class-plugin-section">
          <el-alert type="warning" :closable="false" show-icon class="self-desc-tip">
            <template #title>Java类插件采用自描述模型</template>
            上传 .class/.jar 后系统反射自动识别基类（superclass 链）与参数结构（@FormParam / @BehaviorParam 注解），
            管理员仅需填写参数值，无需（也不可）手填基类、类名或参数结构。
          </el-alert>
          <el-form :model="editingPlugin" label-width="86px" size="small" class="edit-form">
            <el-form-item label="继承基类">
              <el-input :model-value="editingPlugin.class_base" disabled placeholder="上传字节码后由反射自动识别">
                <template #append>
                  <el-tooltip content="系统反射 superclass 链自动识别，插件类必须继承 AbstractBillPlugIn / AbstractListPlugIn / AbstractOperationServicePlugIn 之一" placement="top">
                    <el-icon><InfoFilled /></el-icon>
                  </el-tooltip>
                </template>
              </el-input>
            </el-form-item>
            <el-form-item label="实现类名">
              <el-input :model-value="editingPlugin.class_name" disabled placeholder="上传字节码后由反射自动识别">
                <template #append>
                  <el-tooltip content="系统反射自动识别，非用户填写" placement="top">
                    <el-icon><InfoFilled /></el-icon>
                  </el-tooltip>
                </template>
              </el-input>
            </el-form-item>
            <el-form-item label="上传字节码" required>
              <el-upload
                :auto-upload="false"
                accept=".class,.jar"
                :limit="1"
                :on-change="onClassFileChange"
                :on-remove="onClassFileRemove"
                :file-list="classFileList"
              >
                <el-button size="small" type="primary" plain :loading="reflecting">
                  <el-icon><Upload /></el-icon>{{ reflecting ? '反射扫描中...' : '选择 .class / .jar 文件' }}
                </el-button>
                <template #tip>
                  <div class="upload-tip">
                    上传后系统自动反射识别基类 + 扫描注解参数。文件名应与实现类名一致（如 SalOrderCreditValidator.class）。
                    <span class="sig-tip">GAP-D05-001 / PRD 06.2.6：上传前校验文件扩展名（.class/.jar）与签名，未通过校验的文件将被拒绝。</span>
                  </div>
                </template>
              </el-upload>
            </el-form-item>
          </el-form>

          <!-- 传入参数（自描述模型 + 参数零配置：全部由注解自动发现，系统运行时自动注入，管理员无需配置） -->
          <div class="params-section">
            <div class="params-header">
              <span class="params-title">传入参数（注解自描述，系统运行时自动注入，管理员无需配置）</span>
              <el-button
                size="small" type="primary" plain
                :disabled="!editingPlugin.class_file"
                @click="onRescanParams"
              >
                <el-icon><Refresh /></el-icon>重新扫描注解
              </el-button>
            </div>
            <el-alert type="success" :closable="false" show-icon class="params-tip">
              参数键 / 标签 / 类型 / 默认值由系统反射扫描 @FormParam / @BehaviorParam 注解自动生成（只读展示）。
              <strong>参数零配置</strong>：form 参数运行时读取 <code>bill_data[param_key]</code> 自动注入，behavior 参数运行时注入 <code>default_value</code>，管理员无需填写任何参数值。
            </el-alert>
            <el-table :data="editingPlugin.class_params || []" border size="small" empty-text="上传字节码后自动扫描注解生成" class="params-table">
              <el-table-column label="参数键" min-width="140">
                <template #default="{ row }"><span class="readonly-cell">{{ row.param_key }}</span></template>
              </el-table-column>
              <el-table-column label="标签" width="140">
                <template #default="{ row }"><span class="readonly-cell">{{ row.param_label }}</span></template>
              </el-table-column>
              <el-table-column label="类型" width="120">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.param_type === 'form' ? 'primary' : 'warning'" effect="plain">
                    {{ row.param_type === 'form' ? '@FormParam' : '@BehaviorParam' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="运行时值来源" min-width="200">
                <template #default="{ row }">
                  <span class="readonly-cell runtime-source">
                    {{ row.param_type === 'form'
                      ? `bill_data["${row.param_key}"]`
                      : (row.default_value || '—')
                    }}
                  </span>
                </template>
              </el-table-column>
            </el-table>
          </div>

          <!-- 校验器（操作服务插件 OnAddValidators 阶段，GAP-D05-006 / PRD 06.2.5：仅该事件可挂校验器）-->
          <div v-if="editingPlugin.base_class === 'OperationServicePlugin' && editingPlugin.event_name === 'OnAddValidators'" class="params-section">
            <div class="params-header">
              <span class="params-title">校验器（OnAddValidators 阶段挂载）</span>
              <el-button size="small" type="primary" plain @click="onAddValidator">
                <el-icon><Plus /></el-icon>添加校验器
              </el-button>
            </div>
            <el-table :data="editingPlugin.validators || []" border size="small" empty-text="暂无校验器" class="params-table">
              <el-table-column label="编码" width="120">
                <template #default="{ row }"><el-input v-model="row.validator_code" size="small" placeholder="如 CREDIT_CHECK" /></template>
              </el-table-column>
              <el-table-column label="名称" width="120">
                <template #default="{ row }"><el-input v-model="row.validator_name" size="small" /></template>
              </el-table-column>
              <el-table-column label="校验表达式" min-width="160">
                <template #default="{ row }"><el-input v-model="row.validate_expr" size="small" placeholder="如 amount <= credit" /></template>
              </el-table-column>
              <el-table-column label="失败提示" min-width="140">
                <template #default="{ row }"><el-input v-model="row.error_msg" size="small" /></template>
              </el-table-column>
              <el-table-column label="操作" width="52" align="center">
                <template #default="{ $index }">
                  <el-button size="small" link type="danger" @click="editingPlugin.validators?.splice($index, 1)">
                    <el-icon><Delete /></el-icon>
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>

          <!-- 校验器事件限制提示（GAP-D05-006：仅 OnAddValidators 事件可挂校验器）-->
          <el-alert
            v-if="editingPlugin.base_class === 'OperationServicePlugin' && editingPlugin.event_name !== 'OnAddValidators' && (editingPlugin.validators?.length || 0) > 0"
            type="warning" :closable="false" show-icon class="validator-warn-tip"
          >
            检测到当前事件为「{{ eventLabel(editingPlugin.base_class, editingPlugin.event_name) }}」但已配置 {{ editingPlugin.validators?.length }} 个校验器。
            校验器仅可在「增加校验器(OnAddValidators)」事件挂载，保存时将被阻断。请切换事件或清空校验器。
          </el-alert>

          <!-- Java 代码示例 -->
          <el-alert type="warning" :closable="false" show-icon class="code-example-tip">
            <template #title><span>Java 实现示例（继承基类 + 注解声明参数，系统反射自动识别）</span></template>
          </el-alert>
          <pre class="code-example">{{ codeExample }}</pre>
        </div>

        <!-- PluginContext 可用成员参考 -->
        <div class="ctx-ref">
          <div class="ctx-title">
            <el-icon><InfoFilled /></el-icon> PluginContext 可用成员（基类注入）
          </div>
          <div class="ctx-grid">
            <div v-for="m in contextMembers" :key="m.name" class="ctx-item">
              <code class="ctx-name">{{ m.name }}</code>
              <span class="ctx-desc">{{ m.desc }}</span>
            </div>
          </div>
        </div>
      </template>

      <template v-else>
        <div class="func-help">
          <div class="func-section">
            <div class="func-title">插件机制说明（参考金蝶 BOS）</div>
            <div class="func-text">
              系统提供三大插件基类，自定义插件只需继承对应基类并重写事件方法。
              运行时系统将 <code>PluginContext</code>（含 View/Model/Context/Option）注入插件，
              表单参数与行为参数通过基类统一传递，无需自行取数。
            </div>
          </div>
          <div class="func-section">
            <div class="func-title">三大基类</div>
            <div v-for="b in PLUGIN_BASE_CLASS_OPTIONS" :key="b.value" class="base-item">
              <el-tag size="small" :type="baseClassTag(b.value)">{{ b.label }}</el-tag>
              <code class="base-cn">{{ b.base_class_name }}</code>
              <div class="base-desc-text">{{ b.desc }}</div>
            </div>
          </div>
          <div class="func-section">
            <div class="func-title">执行规则</div>
            <div class="func-text">
              插件按 exec_order 串行执行；前置插件返回 blocked=true 或抛异常将阻断后续插件与主操作。
              事务边界为整个操作（含实体规则、插件与主流程），事务中异常回滚。
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Plus, Delete, InfoFilled, Upload, Operation, Lock, ArrowRight, Refresh
} from '@element-plus/icons-vue'
import { pluginApi } from '@/api/form'
import {
  PLUGIN_BASE_CLASS_OPTIONS, PLUGIN_BASE_CLASS_MAP,
  BILL_PLUGIN_EVENTS, LIST_PLUGIN_EVENTS, OPERATION_PIPELINE_EVENTS
} from '@/utils/enum'
import type { FormPlugin, PluginBaseClass } from '@/types/bo'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'

const props = withDefaults(defineProps<{
  boCode: string
  plugins?: FormPlugin[]
  readonly?: boolean
}>(), {
  plugins: () => [],
  readonly: false
})

const emit = defineEmits<{
  (e: 'change', plugins: FormPlugin[]): void
}>()

const filterBaseClass = ref('')
const currentEvent = ref('')
const plugins = ref<FormPlugin[]>([...props.plugins])
const editingPlugin = ref<FormPlugin | null>(null)
const classFileList = ref<any[]>([])
const reflecting = ref(false)

// 事件树：按基类分组
const eventTree = computed(() => {
  const groups = filterBaseClass.value
    ? PLUGIN_BASE_CLASS_OPTIONS.filter(b => b.value === filterBaseClass.value)
    : PLUGIN_BASE_CLASS_OPTIONS
  return groups.map(g => ({
    label: g.label,
    children: eventsByBaseClass(g.value).map(e => ({
      label: e.label,
      value: e.value,
      order: (e as any).order
    }))
  }))
})

function eventsByBaseClass(bc: string) {
  if (bc === 'BillPlugin') return BILL_PLUGIN_EVENTS
  if (bc === 'ListPlugin') return LIST_PLUGIN_EVENTS
  return OPERATION_PIPELINE_EVENTS
}

const availableEvents = computed(() => {
  if (!editingPlugin.value) return []
  return eventsByBaseClass(editingPlugin.value.base_class)
})

const currentEventLabel = computed(() => {
  if (!currentEvent.value) return ''
  const all = [...BILL_PLUGIN_EVENTS, ...LIST_PLUGIN_EVENTS, ...OPERATION_PIPELINE_EVENTS]
  return all.find(e => e.value === currentEvent.value)?.label || currentEvent.value
})

const needFieldCode = computed(() => {
  if (!editingPlugin.value) return false
  return editingPlugin.value.event_name === 'DataChanged' || editingPlugin.value.event_name === 'OnFieldValueChanged'
})

const filteredPlugins = computed(() => {
  let list = [...plugins.value].sort((a, b) => a.exec_order - b.exec_order)
  if (filterBaseClass.value) list = list.filter(p => p.base_class === filterBaseClass.value)
  if (currentEvent.value) list = list.filter(p => p.event_name === currentEvent.value)
  return list
})

const contextMembers = computed(() => {
  const common = [
    { name: 'ctx.bill_data', desc: '单据数据包（主/子/孙表）' },
    { name: 'ctx.bill_id / bill_code', desc: '单据内码与编号' },
    { name: 'ctx.operation', desc: '当前操作(save/submit/audit)' },
    { name: 'ctx.user_id / user_name', desc: '当前登录用户' },
    { name: 'ctx.org_id / org_name', desc: '当前业务组织' },
    { name: 'ctx.form_params', desc: '表单参数(字段值)' },
    { name: 'ctx.behavior_params', desc: '行为参数(控制逻辑)' }
  ]
  if (editingPlugin.value?.base_class === 'BillPlugin') {
    return [
      { name: 'ctx.View', desc: '表单视图(界面交互，BillPlugin独有)' },
      { name: 'ctx.Model', desc: '数据模型(GetValue/SetValue)' },
      ...common
    ]
  }
  return common
})

const codeExample = computed(() => {
  if (!editingPlugin.value) return ''
  const base = editingPlugin.value.class_base || 'com.eerp.plugin.base.AbstractBillPlugIn'
  const cls = editingPlugin.value.class_name || 'com.eerp.plugin.YourPlugin'
  const shortName = cls.split('.').pop() || 'YourPlugin'
  const baseShort = base.split('.').pop() || 'AbstractBillPlugIn'
  const pkg = cls.lastIndexOf('.') > 0 ? cls.substring(0, cls.lastIndexOf('.')) : 'com.eerp.plugin'
  const evt = editingPlugin.value.event_name
  const params = editingPlugin.value.class_params || []
  // 生成注解字段声明（@FormParam / @BehaviorParam）
  // form 参数：key = 单据字段编码，运行时系统读取 bill_data[key] 注入
  // behavior 参数：defaultValue = 运行时值，系统注入
  const fields = params.length
    ? params.map(p => {
        const anno = p.param_type === 'form' ? '@FormParam' : '@BehaviorParam'
        const labelPart = `label = "${p.param_label}"`
        const defaultPart = p.default_value ? `, defaultValue = "${p.default_value}"` : ''
        const fieldName = p.param_key.replace(/-/g, '_')
        const comment = p.param_type === 'form'
          ? `// 系统运行时读取 bill_data["${p.param_key}"] 注入`
          : `// 系统注入 defaultValue = "${p.default_value || ''}"`
        return `    ${comment}\n    ${anno}(key = "${p.param_key}", ${labelPart}${defaultPart})\n    private String ${fieldName};`
      }).join('\n\n')
    : `    // 无注解参数（插件未声明 @FormParam / @BehaviorParam 字段）`
  return `package ${pkg};

import ${base};
import com.eerp.plugin.annotation.FormParam;
import com.eerp.plugin.annotation.BehaviorParam;
import com.eerp.plugin.PluginContext;

/**
 * ${editingPlugin.value.plugin_name || '自定义插件'}
 * 继承系统基类 ${baseShort}，重写 ${evt} 事件
 * 参数由注解声明，系统反射自动发现，运行时自动注入（参数零配置）
 */
public class ${shortName} extends ${baseShort} {

${fields}

    @Override
    public void ${evt}(PluginContext ctx) {
        // 系统已按注解自动注入运行时值到上述字段，插件直接使用（无需 ctx.getFormParam）
        // 业务逻辑处理...
        return ctx.success();
    }
}`
})

function countByEvent(event: string) {
  return plugins.value.filter(p => p.event_name === event).length
}
function onEventClick(data: any) {
  currentEvent.value = data.value || ''
}

function onAdd() {
  editingPlugin.value = {
    id: 'new_' + Date.now(),
    bo_code: props.boCode,
    plugin_code: '',
    plugin_name: '',
    base_class: 'BillPlugin',
    event_name: 'OnLoad',
    plugin_type: 'script',
    script_content: '',
    api_url: '',
    api_method: 'POST',
    class_name: '',
    class_file: '',
    class_base: PLUGIN_BASE_CLASS_MAP['BillPlugin'],
    class_params: [],
    validators: [],
    exec_order: (Math.max(0, ...plugins.value.map(p => p.exec_order)) + 10),
    status: 1,
    field_code: ''
  }
  classFileList.value = []
}

function onBaseClassChange() {
  if (!editingPlugin.value) return
  const bc = editingPlugin.value.base_class
  editingPlugin.value.class_base = PLUGIN_BASE_CLASS_MAP[bc] || ''
  // 切换基类时，事件重置为该基类的第一个
  const evts = eventsByBaseClass(bc)
  if (evts.length && !evts.some(e => e.value === editingPlugin.value!.event_name)) {
    editingPlugin.value.event_name = evts[0].value
  }
}

function onEventChange() {
  // 事件变更无需特殊处理
}

function baseClassTag(bc: string) {
  return bc === 'BillPlugin' ? 'primary' : bc === 'ListPlugin' ? 'warning' : 'success'
}
function baseClassLabel(bc: string) {
  return PLUGIN_BASE_CLASS_OPTIONS.find(b => b.value === bc)?.label || bc
}
function baseClassDesc(bc: string) {
  return PLUGIN_BASE_CLASS_OPTIONS.find(b => b.value === bc)?.desc || ''
}
function eventLabel(bc: string, evt: string) {
  return eventsByBaseClass(bc).find(e => e.value === evt)?.label || evt
}
function pluginTypeTag(type: string) {
  return type === 'script' ? 'primary' : type === 'api' ? 'warning' : 'success'
}
function pluginTypeLabel(type: string) {
  return type === 'script' ? '脚本' : type === 'api' ? 'API' : 'Java类'
}

// 上传 .class/.jar → 调用反射扫描接口自动识别基类 + 注解参数（自描述模型）
// GAP-D05-001 / PRD 06.2.6：上传前进行签名校验（扩展名 + 文件名规则）
async function onClassFileChange(file: any) {
  if (!file || !file.name || !editingPlugin.value) return
  // ① 签名校验：扩展名必须为 .class 或 .jar
  const fileName = file.name
  if (!/\.(class|jar)$/i.test(fileName)) {
    ElMessage.error('签名校验失败：仅支持 .class / .jar 文件')
    classFileList.value = []
    return
  }
  // ② 签名校验：文件名应符合 Java 类名规范（首字母大写，无特殊字符）
  const baseName = fileName.replace(/\.(class|jar)$/i, '')
  if (!/^[A-Z][A-Za-z0-9_]*$/.test(baseName)) {
    ElMessage.error(`签名校验失败：文件名「${baseName}」不符合 Java 类名规范（首字母大写，仅字母数字下划线）`)
    classFileList.value = []
    return
  }
  ElMessage.info('签名校验通过，开始反射扫描...')
  editingPlugin.value.class_file = fileName
  classFileList.value = [file]
  await reflectClassMeta(fileName)
}
function onClassFileRemove() {
  if (editingPlugin.value) {
    editingPlugin.value.class_file = ''
    editingPlugin.value.class_name = ''
    editingPlugin.value.class_base = ''
    editingPlugin.value.class_params = []
  }
  classFileList.value = []
}
// 重新扫描注解（重新触发反射，刷新参数结构展示）
async function onRescanParams() {
  if (!editingPlugin.value?.class_file) return
  await reflectClassMeta(editingPlugin.value.class_file)
}
// 反射扫描：调用后端 getClassMeta，自动回填 base_class/class_base/class_name/class_params（参数零配置）
// RISK-D05-002 / PRD 06.2.4.1：传入 boCode 进行 @FormParam.key 字段存在性校验，warnings 仅提示不阻断
async function reflectClassMeta(fileName: string) {
  if (!editingPlugin.value) return
  reflecting.value = true
  try {
    const meta = await pluginApi.getClassMeta(fileName, props.boCode)
    // 自动回填基类与类信息
    editingPlugin.value.base_class = meta.base_class
    editingPlugin.value.class_base = meta.class_base
    editingPlugin.value.class_name = meta.class_name
    // 回填参数结构（全部只读，无 param_value，运行时系统自动注入）
    editingPlugin.value.class_params = meta.class_params
    // 联动事件集：若当前事件不属于识别到的基类，重置为该基类第一个事件
    const evts = eventsByBaseClass(meta.base_class)
    if (evts.length && !evts.some(e => e.value === editingPlugin.value!.event_name)) {
      editingPlugin.value.event_name = evts[0].value
    }
    ElMessage.success(`反射识别成功：${meta.base_class}，发现 ${meta.class_params.length} 个注解参数（参数零配置，运行时自动注入）`)
    // RISK-D05-002：展示 @FormParam.key 字段存在性校验告警（不阻断，仅提示管理员核对）
    if (meta.warnings && meta.warnings.length > 0) {
      meta.warnings.forEach(w => ElMessage.warning(w))
    }
  } catch (e: any) {
    ElMessage.error(e?.message || '反射扫描失败：插件类必须继承 AbstractBillPlugIn / AbstractListPlugIn / AbstractOperationServicePlugIn 之一')
    // 识别失败：清空基类相关字段，保留文件名待重新上传
    editingPlugin.value.class_name = ''
    editingPlugin.value.class_base = ''
    editingPlugin.value.class_params = []
  } finally {
    reflecting.value = false
  }
}
function onAddValidator() {
  if (!editingPlugin.value) return
  if (!editingPlugin.value.validators) editingPlugin.value.validators = []
  editingPlugin.value.validators.push({
    validator_code: '', validator_name: '', validate_expr: '', error_msg: '', is_enabled: true
  })
}

function onEdit(row: FormPlugin) {
  editingPlugin.value = { ...row }
  if (row.plugin_type === 'class' && row.class_file) {
    classFileList.value = [{ name: row.class_file, url: '' }]
  } else {
    classFileList.value = []
  }
}
// GAP-D05-007：启停状态切换调用后端 API 持久化
async function onToggleStatus(row: FormPlugin) {
  const newStatus = row.status === 0 ? 1 : 0
  try {
    if (!row.id.startsWith('new_')) {
      await pluginApi.toggleStatus(row.id, newStatus)
    }
    row.status = newStatus
    emit('change', plugins.value)
    ElMessage.success(newStatus === 1 ? '已启用' : '已停用')
  } catch {
    ElMessage.error('状态切换失败')
  }
}
async function onDelete(row: FormPlugin) {
  await ElMessageBox.confirm(`确定删除插件「${row.plugin_name}」吗？`, '提示', { type: 'warning' })
  try {
    if (!row.id.startsWith('new_')) await pluginApi.delete(row.id)
  } catch {}
  plugins.value = plugins.value.filter(p => p.id !== row.id)
  if (editingPlugin.value?.id === row.id) editingPlugin.value = null
  emit('change', plugins.value)
  ElMessage.success('删除成功')
}
function onValidate(result: { valid: boolean; error?: string }) {
  if (!result.valid) ElMessage.warning('脚本语法：' + result.error)
}
async function onSave() {
  const p = editingPlugin.value
  if (!p) return
  if (!p.plugin_code || !p.plugin_name) {
    ElMessage.warning('请填写插件编码和名称')
    return
  }
  // GAP-D05-006 / PRD 06.2.5：校验器仅可在 OnAddValidators 事件挂载
  if ((p.validators?.length || 0) > 0 && p.event_name !== 'OnAddValidators') {
    ElMessage.error(`校验器仅可在「增加校验器(OnAddValidators)」事件挂载，当前事件为「${eventLabel(p.base_class, p.event_name)}」，请切换事件或清空校验器`)
    return
  }
  // 切换到非 OnAddValidators 事件时，自动清空残留校验器（防脏数据）
  if (p.event_name !== 'OnAddValidators' && (p.validators?.length || 0) > 0) {
    p.validators = []
  }
  try {
    if (p.id.startsWith('new_')) {
      const created = await pluginApi.create(p)
      const idx = plugins.value.findIndex(x => x.id === p.id)
      if (idx > -1) plugins.value[idx] = { ...p, ...created }
      else plugins.value.push({ ...p, ...created })
    } else {
      await pluginApi.update(p.id, p)
      const idx = plugins.value.findIndex(x => x.id === p.id)
      if (idx > -1) plugins.value[idx] = { ...p }
    }
    emit('change', plugins.value)
    ElMessage.success('保存成功')
    editingPlugin.value = null
  } catch {
    ElMessage.error('保存失败')
  }
}

async function loadPlugins() {
  if (props.plugins?.length) {
    plugins.value = [...props.plugins]
  } else {
    try {
      const res = await pluginApi.list(props.boCode)
      plugins.value = res || []
    } catch { plugins.value = [] }
  }
}

watch(() => props.plugins, (v) => { if (v?.length) plugins.value = [...v] })
onMounted(loadPlugins)
defineExpose({ getPlugins: () => plugins.value })
</script>

<style scoped lang="scss">
.plugin-bind-panel {
  height: 100%;
  display: flex;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.panel-card {
  background: #fff;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.panel-left { width: 230px; padding: 10px; overflow: auto; }
.panel-center { flex: 1; padding: 10px; }
.panel-right { width: 500px; padding: 10px; overflow: auto; }
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
  .panel-title { font-size: 14px; font-weight: 600; }
}
.base-filter { margin-bottom: 8px; }
.event-node {
  display: flex;
  align-items: center;
  gap: 6px;
  flex: 1;
  padding-right: 6px;
  &.leaf { font-size: 13px; }
  .node-label { flex: 1; }
  .order-tag { transform: scale(0.85); }
}
.edit-form { margin-bottom: 8px; }
.base-desc { margin: -4px 0 10px; }
.opt-desc { float: right; color: #909399; font-size: 12px; }

/* 流水线 */
.pipeline-section {
  margin: 8px 0 12px;
  padding: 10px;
  background: #fafbfc;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  .section-label {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 13px;
    font-weight: 600;
    margin-bottom: 10px;
  }
}
.pipeline-flow {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 2px;
}
.pipeline-step {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 6px 8px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  background: #fff;
  min-width: 92px;
  font-size: 11px;
  &.in-tx { border-color: #f0c78a; background: #fffbeb; }
  &.active {
    border-color: #1564ff;
    background: #ecf5ff;
    box-shadow: 0 0 0 2px rgba(21, 100, 255, 0.2);
    .step-order { background: #1564ff; color: #fff; }
  }
  .step-order {
    width: 18px; height: 18px;
    border-radius: 50%;
    background: #c0c4cc;
    color: #fff;
    font-size: 11px;
    line-height: 18px;
    text-align: center;
    margin-bottom: 2px;
  }
  .step-name { font-weight: 600; color: #303133; }
  .step-event { color: #909399; font-family: 'Consolas', monospace; transform: scale(0.9); }
  .tx-icon { position: absolute; top: 2px; right: 2px; color: #e6a23c; font-size: 10px; }
  .step-arrow { position: absolute; right: -10px; top: 50%; transform: translateY(-50%); color: #c0c4cc; font-size: 12px; z-index: 1; }
}
.pipeline-tip { margin-top: 8px; }

.editor-wrap {
  margin-top: 8px;
  .editor-label {
    font-size: 12px;
    color: #606266;
    margin-bottom: 6px;
    font-weight: 600;
  }
}

/* Java class 插件 */
.class-plugin-section {
  .self-desc-tip { margin-bottom: 10px; }
  .upload-tip {
    font-size: 12px;
    color: #909399;
    margin-top: 4px;
    line-height: 1.5;
    .sig-tip {
      display: block;
      margin-top: 2px;
      color: #e6a23c;
    }
  }
  .readonly-cell {
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 12px;
    color: #606266;
    word-break: break-all;
  }
  .runtime-source {
    color: #722ed1;
  }
}
.auto-tag { margin-left: 8px; }
.params-section {
  margin-top: 12px;
  .params-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
    .params-title { font-size: 13px; font-weight: 600; }
  }
  .params-tip { margin-bottom: 8px; }
  .params-table { margin-bottom: 12px; }
}
.validator-warn-tip { margin-top: 10px; }
.code-example-tip { margin-top: 12px; }
.code-example {
  margin: 8px 0 0 0;
  padding: 10px 12px;
  background: #fafafa;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 11px;
  color: #303133;
  line-height: 1.55;
  overflow-x: auto;
  white-space: pre;
}

/* PluginContext 参考 */
.ctx-ref {
  margin-top: 12px;
  padding: 10px;
  background: #f5f7fa;
  border-radius: 4px;
  .ctx-title {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    font-weight: 600;
    margin-bottom: 8px;
    color: #606266;
  }
  .ctx-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 4px;
  }
  .ctx-item {
    display: flex;
    align-items: baseline;
    gap: 6px;
    font-size: 11px;
    .ctx-name {
      background: #fff;
      padding: 1px 5px;
      border-radius: 2px;
      color: #1564ff;
      font-family: 'Consolas', monospace;
      white-space: nowrap;
    }
    .ctx-desc { color: #909399; }
  }
}

/* 帮助页 */
.func-help {
  .func-section {
    margin-bottom: 16px;
    .func-title {
      font-weight: 600;
      margin-bottom: 8px;
      padding-bottom: 6px;
      border-bottom: 1px solid #ebeef5;
      font-size: 13px;
    }
    .func-text {
      font-size: 12px;
      color: #606266;
      line-height: 1.7;
      code {
        background: #f5f7fa;
        padding: 1px 4px;
        border-radius: 2px;
        color: #1564ff;
        font-family: 'Consolas', monospace;
      }
    }
    .base-item {
      padding: 8px 0;
      border-bottom: 1px dashed #f0f2f5;
      code {
        background: #f5f7fa;
        padding: 1px 4px;
        border-radius: 2px;
        color: #1564ff;
        font-family: 'Consolas', monospace;
        font-size: 11px;
        margin-left: 6px;
      }
      .base-desc-text { font-size: 12px; color: #909399; margin-top: 4px; line-height: 1.5; }
    }
  }
}
</style>
