<template>
  <div class="state-machine-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width: 280px" @change="onBoChange" />
        <el-tag v-if="boCode" size="small" type="info" effect="plain">
          {{ states.length }} 状态 / {{ transitions.length }} 流转
        </el-tag>
      </div>
      <div class="header-right">
        <el-button size="small" @click="onPreviewStandard" :disabled="!boCode">
          <el-icon><View /></el-icon>预览标准状态机
        </el-button>
        <el-button type="warning" size="small" @click="onAddStateNode" :disabled="!boCode">
          <el-icon><Plus /></el-icon>新增状态节点
        </el-button>
        <el-button type="primary" size="small" @click="onAddTransition" :disabled="!boCode">
          <el-icon><Plus /></el-icon>新增流转
        </el-button>
        <el-button type="success" size="small" @click="onSaveAll" :disabled="!boCode">
          <el-icon><Check /></el-icon>保存
        </el-button>
      </div>
    </div>

    <!-- 主体：状态机 / 操作日志 Tab（GAP-D03-007）-->
    <el-tabs v-model="mainTab" class="main-tabs">
      <el-tab-pane label="状态机配置" name="state">
        <div class="main-body">
          <!-- 左：状态节点列表 -->
          <div class="state-list-panel panel-card">
            <div class="panel-header">
              <span class="panel-title">状态节点</span>
            </div>
            <el-empty v-if="!states.length" description="请选择业务对象" :image-size="50" />
            <ul v-else class="state-list">
              <li
                v-for="s in states"
                :key="s.id"
                class="state-item"
                :class="{ active: selectedType === 'node' && selectedNode?.state_code === s.state_code }"
                @click="onSelectNode(s)"
              >
                <span class="state-dot" :style="{ background: stateColor(s) }"></span>
                <span class="state-name">{{ s.state_name }}</span>
                <span class="state-code">{{ s.state_code }}</span>
                <el-tag v-if="s.is_initial" size="small" type="primary" effect="plain">初始</el-tag>
                <el-tag v-if="s.is_final" size="small" type="danger" effect="plain">终态</el-tag>
              </li>
            </ul>
            <div class="legend-box">
              <div class="legend-title">流转图例</div>
              <div class="legend-item">
                <span class="legend-line orange"></span>触发外部工作流
              </div>
              <div class="legend-item">
                <span class="legend-line gray"></span>普通流转
              </div>
            </div>
          </div>

          <!-- 中：状态机图 -->
          <div class="graph-panel panel-card">
            <div class="panel-header">
              <span class="panel-title">状态流转图</span>
              <span class="panel-tip">点击节点查看按钮矩阵，点击连线编辑流转属性；节点可拖拽，位置自动保存</span>
            </div>
            <div class="graph-wrapper">
              <StateMachineGraph
                v-if="states.length"
                :states="states"
                :transitions="transitions"
                :editable="true"
                @node-click="onSelectNode"
                @edge-click="onSelectEdge"
                @node-moved="onNodeMoved"
              />
              <el-empty v-else description="暂无状态数据" :image-size="80" />
            </div>
          </div>

          <!-- 右：属性面板 -->
          <div class="detail-panel panel-card">
            <!-- 节点模式：节点属性可编辑（GAP-D03-001）-->
            <template v-if="selectedType === 'node' && selectedNode">
              <div class="panel-header">
                <span class="panel-title">
                  {{ selectedNode.state_name }}
                  <el-tag size="small" :type="stateTagType(selectedNode.state_code)" effect="dark">
                    {{ selectedNode.state_code }}
                  </el-tag>
                </span>
                <div class="header-actions">
                  <el-button v-if="!selectedNode.id.startsWith('std_')" link type="danger" size="small" @click="onDeleteNode">
                    <el-icon><Delete /></el-icon>删除
                  </el-button>
                  <el-button link type="primary" size="small" @click="onClearSelect">关闭</el-button>
                </div>
              </div>
              <el-form label-width="80px" size="small" class="node-form">
                <el-form-item label="状态编码">
                  <el-input-number
                    v-model="selectedNode.state_code"
                    :min="0"
                    :max="99"
                    controls-position="right"
                    style="width: 100%"
                    @change="onNodeCodeChange"
                  />
                </el-form-item>
                <el-form-item label="状态名称">
                  <el-input v-model="selectedNode.state_name" placeholder="如 已审核" />
                </el-form-item>
                <el-form-item label="状态颜色">
                  <el-color-picker v-model="selectedNode.color" show-alpha />
                  <span class="color-hex">{{ selectedNode.color || '#409eff' }}</span>
                </el-form-item>
                <el-form-item label="初始状态">
                  <el-switch v-model="selectedNode.is_initial" @change="onInitialChange" />
                </el-form-item>
                <el-form-item label="终态">
                  <el-switch v-model="selectedNode.is_final" />
                </el-form-item>
              </el-form>
              <div class="matrix-section">
                <div class="section-label">按钮可用性矩阵（该状态下）</div>
                <ButtonMatrix
                  :buttons="buttons"
                  :role-buttons="roleButtons"
                  @change="onButtonsChange"
                />
              </div>
            </template>

            <!-- 边模式 -->
            <template v-else-if="selectedType === 'edge' && selectedEdge">
              <div class="panel-header">
                <span class="panel-title">流转属性</span>
                <div class="header-actions">
                  <el-button link type="danger" size="small" @click="onDeleteTransition">
                    <el-icon><Delete /></el-icon>删除
                  </el-button>
                  <el-button link type="primary" size="small" @click="onClearSelect">关闭</el-button>
                </div>
              </div>
              <el-form label-width="80px" size="small" class="edge-form">
                <el-form-item label="源状态">
                  <el-select :model-value="selectedEdge.from_state" disabled style="width: 100%">
                    <el-option v-for="s in states" :key="s.id" :label="s.state_name" :value="s.state_code" />
                  </el-select>
                </el-form-item>
                <el-form-item label="目标状态">
                  <el-select :model-value="selectedEdge.to_state" disabled style="width: 100%">
                    <el-option v-for="s in states" :key="s.id" :label="s.state_name" :value="s.state_code" />
                  </el-select>
                </el-form-item>
                <el-form-item label="操作名">
                  <el-input v-model="selectedEdge.action_name" placeholder="如 保存/提交/审核" />
                </el-form-item>
                <el-form-item label="前置校验">
                  <ExpressionEditor
                    v-model="selectedEdge.pre_check"
                    :bo-code="boCode"
                    :height="160"
                  />
                </el-form-item>
                <el-form-item label="后置动作">
                  <el-input
                    v-model="selectedEdge.post_action"
                    type="textarea"
                    :rows="2"
                    placeholder="如 立账/生成凭证/更新库存"
                  />
                </el-form-item>
                <el-form-item label="触发工作流">
                  <el-switch v-model="selectedEdge.need_wf" />
                  <span class="form-tip">开启后该流转将推送外部工作流系统</span>
                </el-form-item>
                <!-- 外部工作流对接 UI（GAP-D03-008 / PRD 02.1.3）-->
                <template v-if="selectedEdge.need_wf">
                  <el-divider content-position="left">
                    <span class="wf-divider">外部工作流对接配置</span>
                  </el-divider>
                  <el-form-item label="推送API">
                    <el-input
                      v-model="selectedEdge.wf_push_api"
                      placeholder="如 /api/wf/start"
                    />
                  </el-form-item>
                  <el-form-item label="回调URL">
                    <el-input
                      v-model="selectedEdge.wf_callback_url"
                      placeholder="如 /api/wf/callback"
                    />
                  </el-form-item>
                  <el-form-item label="回调展示">
                    <el-input
                      v-model="selectedEdge.wf_callback_display"
                      type="textarea"
                      :rows="2"
                      placeholder="如 回调回写 pact_state=3 审核通过 / 4 驳回，关联字段 wf_request_id"
                    />
                  </el-form-item>
                  <el-alert type="info" :closable="false" show-icon class="wf-tip">
                    提交时 ERP 调用推送API 发起审批，外部系统审批完成后回调 callback_url，ERP 据 wf_request_id 回写 pact_state（3 通过 / 4 驳回）。
                  </el-alert>
                </template>
              </el-form>
            </template>

            <!-- 空状态 -->
            <template v-else>
              <div class="panel-header">
                <span class="panel-title">属性面板</span>
              </div>
              <el-empty description="请点击左侧状态节点或图中连线" :image-size="80" />
            </template>
          </div>
        </div>
      </el-tab-pane>

      <!-- 操作日志 Tab（GAP-D03-007 / PRD 02.1.4）-->
      <el-tab-pane label="操作日志" name="oplog" :disabled="!boCode">
        <div class="oplog-panel panel-card">
          <div class="panel-header">
            <span class="panel-title">业务操作日志 biz_op_log</span>
            <span class="panel-tip">记录状态变更全记录（操作人、时间、前后状态、原因）</span>
          </div>
          <el-table :data="opLogs" border size="small" style="width: 100%">
            <el-table-column prop="op_time" label="操作时间" width="160" />
            <el-table-column prop="bill_code" label="单据编号" min-width="150" />
            <el-table-column prop="op_type" label="操作类型" width="100">
              <template #default="{ row }">
                <el-tag size="small" :type="opTypeTag(row.op_type)">{{ opTypeLabel(row.op_type) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="状态变更" width="120" align="center">
              <template #default="{ row }">
                <span v-if="row.from_state !== null && row.to_state !== null">
                  {{ row.from_state }} → {{ row.to_state }}
                </span>
                <span v-else>—</span>
              </template>
            </el-table-column>
            <el-table-column prop="op_remark" label="操作说明" min-width="220" show-overflow-tooltip />
            <el-table-column prop="op_by" label="操作人" width="100" />
            <el-table-column prop="ip" label="IP" width="130" />
            <template #empty>
              <el-empty description="暂无操作日志" :image-size="60" />
            </template>
          </el-table>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 新增流转弹窗 -->
    <el-dialog v-model="addDialogVisible" title="新增流转" width="460px" append-to-body destroy-on-close>
      <el-form :model="addForm" label-width="80px" size="small">
        <el-form-item label="源状态" required>
          <el-select v-model="addForm.from_state" placeholder="请选择" style="width: 100%">
            <el-option v-for="s in states" :key="s.id" :label="`${s.state_name}(${s.state_code})`" :value="s.state_code" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标状态" required>
          <el-select v-model="addForm.to_state" placeholder="请选择" style="width: 100%">
            <el-option v-for="s in states" :key="s.id" :label="`${s.state_name}(${s.state_code})`" :value="s.state_code" />
          </el-select>
        </el-form-item>
        <el-form-item label="操作名" required>
          <el-input v-model="addForm.action_name" placeholder="如 保存/提交/审核" />
        </el-form-item>
        <el-form-item label="触发工作流">
          <el-switch v-model="addForm.need_wf" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmAddTransition">确定</el-button>
      </template>
    </el-dialog>

    <!-- 新增状态节点弹窗（GAP-D03-002）-->
    <el-dialog v-model="addNodeDialogVisible" title="新增状态节点" width="460px" append-to-body destroy-on-close>
      <el-form :model="addNodeForm" label-width="80px" size="small">
        <el-form-item label="状态编码" required>
          <el-input-number v-model="addNodeForm.state_code" :min="5" :max="99" controls-position="right" style="width: 100%" />
          <div class="form-tip">自定义状态码建议 ≥5（0-4 为标准状态码）</div>
        </el-form-item>
        <el-form-item label="状态名称" required>
          <el-input v-model="addNodeForm.state_name" placeholder="如 已挂起 / 待确认" />
        </el-form-item>
        <el-form-item label="状态颜色">
          <el-color-picker v-model="addNodeForm.color" show-alpha />
          <span class="color-hex">{{ addNodeForm.color || '#409eff' }}</span>
        </el-form-item>
        <el-form-item label="初始状态">
          <el-switch v-model="addNodeForm.is_initial" />
        </el-form-item>
        <el-form-item label="终态">
          <el-switch v-model="addNodeForm.is_final" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addNodeDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmAddNode">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { View, Plus, Check, Delete } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import StateMachineGraph from '@/components/StateMachineGraph/index.vue'
import ButtonMatrix from '@/components/ButtonMatrix/index.vue'
import ExpressionEditor from '@/components/ExpressionEditor/index.vue'
import { stateApi, buttonApi } from '@/api/state'
import { roleApi } from '@/api/perm'
import { PACT_STATE_MAP } from '@/utils/enum'
import type { StateNode, StateTransition, ButtonDef, BusinessObject, RoleButton } from '@/types/bo'

const boCode = ref('')
const states = ref<StateNode[]>([])
const transitions = ref<StateTransition[]>([])
const buttons = ref<ButtonDef[]>([])
const roleButtons = ref<RoleButton[]>([])
const opLogs = ref<any[]>([])

const mainTab = ref<'state' | 'oplog'>('state')

const selectedType = ref<'node' | 'edge' | null>(null)
const selectedNode = ref<StateNode | null>(null)
const selectedEdge = ref<StateTransition | null>(null)

// 标记按钮矩阵是否被改动
const buttonsDirty = ref(false)

const addDialogVisible = ref(false)
const addForm = reactive<{ from_state: number | null; to_state: number | null; action_name: string; need_wf: boolean }>({
  from_state: null,
  to_state: null,
  action_name: '',
  need_wf: false
})

const addNodeDialogVisible = ref(false)
const addNodeForm = reactive<{ state_code: number; state_name: string; color: string; is_initial: boolean; is_final: boolean }>({
  state_code: 5,
  state_name: '',
  color: '#9c27b0',
  is_initial: false,
  is_final: false
})

// 按状态节点动态取色（GAP-D03-005 / RISK-D03-002）
const DEFAULT_STATE_COLORS: Record<number, string> = {
  0: '#909399', 1: '#1564ff', 2: '#e6a23c', 3: '#67c23a', 4: '#f56c6c'
}
function stateColor(s: StateNode): string {
  return s.color || DEFAULT_STATE_COLORS[s.state_code] || '#409eff'
}

function stateTagType(code: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  return (PACT_STATE_MAP[code]?.type as any) || 'info'
}

async function onBoChange(bo: BusinessObject | null) {
  const code = bo?.bo_code || ''
  boCode.value = code
  if (!code) {
    states.value = []
    transitions.value = []
    buttons.value = []
    roleButtons.value = []
    opLogs.value = []
    onClearSelect()
    return
  }
  await loadData()
}

async function loadData() {
  if (!boCode.value) return
  states.value = await stateApi.nodes(boCode.value)
  transitions.value = await stateApi.transitions(boCode.value)
  buttons.value = await buttonApi.list(boCode.value)
  // 角色按钮权限（GAP-D03-006 / RISK-D03-004）
  try {
    roleButtons.value = await roleApi.buttonsByBo(boCode.value)
  } catch {
    roleButtons.value = []
  }
  // 操作日志（GAP-D03-007）
  try {
    opLogs.value = await stateApi.opLogs(boCode.value)
  } catch {
    opLogs.value = []
  }
  onClearSelect()
}

function onSelectNode(s: StateNode) {
  selectedType.value = 'node'
  selectedNode.value = s
  selectedEdge.value = null
}

function onSelectEdge(t: StateTransition) {
  selectedType.value = 'edge'
  selectedEdge.value = { ...t }
  selectedNode.value = null
}

function onClearSelect() {
  selectedType.value = null
  selectedNode.value = null
  selectedEdge.value = null
}

function onButtonsChange(list: ButtonDef[]) {
  buttons.value = list
  buttonsDirty.value = true
}

// 节点拖拽位置持久化（GAP-D03-004 / RISK-D03-003）
async function onNodeMoved(stateCode: number, posX: number, posY: number) {
  const node = states.value.find(s => s.state_code === stateCode)
  if (!node) return
  node.pos_x = posX
  node.pos_y = posY
  try {
    await stateApi.saveNodePosition(node.id, posX, posY)
    ElMessage.success({ message: `节点「${node.state_name}」位置已保存`, duration: 1500 })
  } catch {
    /* mock 容错 */
  }
}

// 节点属性编辑（GAP-D03-001）
function onNodeCodeChange() {
  // state_code 变更后画布会按 props.states 重新渲染（watch deep）
}

// 仅一个初始状态：勾选当前节点为初始时，取消其他节点初始标记
function onInitialChange(val: string | number | boolean) {
  if (val && selectedNode.value) {
    states.value.forEach(s => {
      if (s.state_code !== selectedNode.value!.state_code) s.is_initial = false
    })
  }
}

// 新增状态节点（GAP-D03-002 / RISK-D03-001）
function onAddStateNode() {
  addNodeForm.state_code = Math.max(5, ...states.value.map(s => s.state_code), 4) + 1
  addNodeForm.state_name = ''
  addNodeForm.color = '#9c27b0'
  addNodeForm.is_initial = false
  addNodeForm.is_final = false
  addNodeDialogVisible.value = true
}

async function confirmAddNode() {
  if (addNodeForm.state_code === null || addNodeForm.state_code === undefined) {
    ElMessage.warning('请输入状态编码')
    return
  }
  if (!addNodeForm.state_name.trim()) {
    ElMessage.warning('请输入状态名称')
    return
  }
  // state_code 唯一性前端校验（防越界，RISK-D03-001）
  if (states.value.some(s => s.state_code === addNodeForm.state_code)) {
    ElMessage.warning(`状态码 ${addNodeForm.state_code} 已存在`)
    return
  }
  // 若标记为初始，取消其他节点初始标记
  if (addNodeForm.is_initial) {
    states.value.forEach(s => { s.is_initial = false })
  }
  const payload: Partial<StateNode> = {
    bo_code: boCode.value,
    state_code: addNodeForm.state_code,
    state_name: addNodeForm.state_name.trim(),
    color: addNodeForm.color,
    is_initial: addNodeForm.is_initial,
    is_final: addNodeForm.is_final,
    sort_index: states.value.length
  }
  try {
    const saved: any = await stateApi.saveNode(payload)
    if (saved && saved.id) {
      const newNode: StateNode = { id: saved.id, ...payload } as StateNode
      states.value.push(newNode)
      ElMessage.success('新增状态节点成功')
      addNodeDialogVisible.value = false
      onSelectNode(newNode)
    }
  } catch (e: any) {
    ElMessage.error(e?.message || '新增失败')
  }
}

// 删除自定义节点（GAP-D03-002）
async function onDeleteNode() {
  if (!selectedNode.value) return
  const node = selectedNode.value
  await ElMessageBox.confirm(`确定删除状态节点「${node.state_name}(${node.state_code})」吗？`, '提示', { type: 'warning' })
  try {
    if (!node.id.startsWith('new_')) await stateApi.deleteNode(node.id)
  } catch { /* mock 容错 */ }
  const idx = states.value.findIndex(s => s.id === node.id)
  if (idx > -1) states.value.splice(idx, 1)
  onClearSelect()
  ElMessage.success('删除成功')
}

function onAddTransition() {
  addForm.from_state = null
  addForm.to_state = null
  addForm.action_name = ''
  addForm.need_wf = false
  addDialogVisible.value = true
}

async function confirmAddTransition() {
  if (addForm.from_state === null || addForm.to_state === null) {
    ElMessage.warning('请选择源/目标状态')
    return
  }
  if (!addForm.action_name.trim()) {
    ElMessage.warning('请输入操作名')
    return
  }
  const payload: Partial<StateTransition> = {
    bo_code: boCode.value,
    from_state: addForm.from_state,
    to_state: addForm.to_state,
    action_name: addForm.action_name.trim(),
    need_wf: addForm.need_wf
  }
  const saved = await stateApi.saveTransition(payload)
  transitions.value.push({ id: saved.id || String(Date.now()), ...payload } as StateTransition)
  addDialogVisible.value = false
  ElMessage.success('新增流转成功')
}

function onDeleteTransition() {
  if (!selectedEdge.value) return
  const t = selectedEdge.value
  ElMessageBox.confirm(`确定删除流转「${t.action_name}」吗？`, '提示', { type: 'warning' })
    .then(async () => {
      if (t.id) {
        try {
          await stateApi.deleteTransition(t.id)
        } catch {
          /* mock 容错 */
        }
      }
      const idx = transitions.value.findIndex(x => x.id === t.id)
      if (idx > -1) transitions.value.splice(idx, 1)
      onClearSelect()
      ElMessage.success('删除成功')
    })
    .catch(() => {})
}

async function onSaveAll() {
  // 保存当前编辑中的流转（含工作流对接配置，GAP-D03-008）
  if (selectedEdge.value) {
    if (selectedEdge.value.id) {
      try {
        await stateApi.updateTransition(selectedEdge.value.id, selectedEdge.value)
      } catch { /* mock 容错 */ }
    } else {
      await stateApi.saveTransition(selectedEdge.value)
    }
  }
  // 保存节点属性变更（GAP-D03-001）
  if (selectedNode.value && selectedNode.value.id) {
    try {
      await stateApi.updateNode(selectedNode.value.id, {
        state_code: selectedNode.value.state_code,
        state_name: selectedNode.value.state_name,
        color: selectedNode.value.color,
        is_initial: selectedNode.value.is_initial,
        is_final: selectedNode.value.is_final
      })
    } catch { /* mock 容错 */ }
  }
  // 保存按钮矩阵变更
  if (buttonsDirty.value) {
    for (const btn of buttons.value) {
      try {
        await buttonApi.update(btn.id, { availability: btn.availability })
      } catch {
        /* mock 容错 */
      }
    }
    buttonsDirty.value = false
  }
  ElMessage.success('保存成功')
}

function onPreviewStandard() {
  ElMessageBox.alert(
    '标准 5 状态机：0暂存 → 1已创建 → 2已提交 → 3已审核；2→4 驳回；4→2 重新提交；3→1/2→1 撤销；3→3 关闭/取消/变更/下推。',
    '标准状态机预览',
    { confirmButtonText: '我知道了' }
  ).catch(() => {})
}

// 操作日志类型映射（GAP-D03-007）
function opTypeLabel(t: string): string {
  const m: Record<string, string> = {
    save: '保存', submit: '提交', audit: '审核', reject: '驳回', revoke: '撤销',
    delete: '删除', close: '关闭', cancel: '取消', change: '变更', push: '下推', print: '打印'
  }
  return m[t] || t
}
function opTypeTag(t: string): 'success' | 'warning' | 'info' | 'danger' | 'primary' {
  const m: Record<string, 'success' | 'warning' | 'info' | 'danger' | 'primary'> = {
    save: 'primary', submit: 'warning', audit: 'success', reject: 'danger', revoke: 'info',
    delete: 'danger', close: 'info', cancel: 'info', change: 'warning', push: 'primary', print: 'info'
  }
  return m[t] || 'info'
}
</script>

<style scoped lang="scss">
.state-machine-page {
  padding: 12px;
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  .header-left {
    display: flex;
    align-items: center;
    gap: 8px;
    .header-label {
      font-size: 13px;
      color: #606266;
    }
  }
  .header-right {
    display: flex;
    gap: 6px;
  }
}
.main-tabs {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  :deep(.el-tabs__content) {
    flex: 1;
    overflow: hidden;
  }
}
.main-body {
  height: 100%;
  display: flex;
  gap: 12px;
  min-height: 0;
}
.oplog-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: auto;
  padding: 0 0 12px 0;
}
.state-list-panel {
  width: 240px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}
.state-list {
  list-style: none;
  margin: 0;
  padding: 4px;
  flex: 1;
  overflow: auto;
}
.state-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 10px;
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.15s;
  .state-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    flex-shrink: 0;
  }
  .state-name {
    font-size: 13px;
  }
  .state-code {
    font-size: 11px;
    color: #c0c4cc;
    margin-left: auto;
  }
  &:hover {
    background: #f0f7ff;
  }
  &.active {
    background: #ecf5ff;
    .state-name {
      color: #1564ff;
      font-weight: 600;
    }
  }
}
.legend-box {
  border-top: 1px solid #f0f0f0;
  padding: 8px 10px;
  .legend-title {
    font-size: 12px;
    color: #909399;
    margin-bottom: 6px;
  }
  .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 12px;
    color: #606266;
    margin-bottom: 4px;
  }
  .legend-line {
    width: 24px;
    height: 2px;
    &.orange {
      background: #e6a23c;
    }
    &.gray {
      background: #8c8c8c;
    }
  }
}
.graph-panel {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.graph-wrapper {
  flex: 1;
  min-height: 420px;
  position: relative;
}
.detail-panel {
  width: 400px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
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
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .panel-tip {
    font-size: 12px;
    color: #909399;
    font-weight: normal;
  }
  .header-actions {
    display: flex;
    gap: 4px;
  }
}
.node-form,
.edge-form {
  padding: 12px;
  overflow: auto;
}
.matrix-section {
  padding: 0 12px 12px;
  .section-label {
    font-size: 12px;
    color: #909399;
    margin-bottom: 8px;
    padding-left: 8px;
    border-left: 3px solid #1564ff;
  }
}
.form-tip {
  margin-left: 8px;
  font-size: 12px;
  color: #909399;
}
.color-hex {
  margin-left: 8px;
  font-size: 12px;
  color: #909399;
  font-family: 'Consolas', monospace;
}
.wf-divider {
  font-size: 12px;
  color: #e6a23c;
  font-weight: 600;
}
.wf-tip {
  margin: 8px 12px 0;
}
:deep(.el-empty) {
  padding: 24px;
}
</style>
