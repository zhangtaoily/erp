<template>
  <div class="print-designer-page">
    <!-- 顶部工具栏 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:200px" @change="onBoChange" />
        <el-divider direction="vertical" />
        <el-select v-model="currentTemplateId" placeholder="选择模板" style="width:200px" size="small" :disabled="!boCode" @change="onTemplateChange">
          <el-option v-for="t in templates" :key="t.id" :label="t.template_name + (t.is_default ? '（默认）' : '')" :value="t.id" />
        </el-select>
      </div>
      <div class="header-right">
        <el-button-group size="small">
          <el-button @click="insertRow" :disabled="!boCode"><el-icon><Plus /></el-icon>插入行</el-button>
          <el-button @click="insertCol" :disabled="!boCode">插入列</el-button>
          <el-button @click="mergeCells" :disabled="!canMerge"><el-icon><Grid /></el-icon>合并</el-button>
          <el-button @click="unmergeCells" :disabled="!canUnmerge">拆分</el-button>
        </el-button-group>
        <!-- 纸张设置（GAP-D10-001/009 / RISK-D10-004）-->
        <el-button size="small" @click="paperDialogVisible = true" :disabled="!boCode"><el-icon><Document /></el-icon>纸张设置</el-button>
        <!-- 套打配置（GAP-D10-002）-->
        <el-button size="small" @click="batchDialogVisible = true" :disabled="!boCode"><el-icon><Files /></el-icon>套打配置</el-button>
        <el-button size="small" @click="onNewTemplate" :disabled="!boCode"><el-icon><Plus /></el-icon>新建模板</el-button>
        <el-button size="small" type="danger" @click="onDeleteTemplate" :disabled="!currentTemplateId">删除</el-button>
        <el-button size="small" type="success" @click="onSave" :disabled="!boCode || !currentTemplateId"><el-icon><Check /></el-icon>保存</el-button>
        <el-button size="small" type="primary" @click="onPreview" :disabled="!boCode"><el-icon><View /></el-icon>预览</el-button>
      </div>
    </div>

    <!-- 主体三栏 -->
    <div class="main-body">
      <!-- 左：数据字段 + 元素 -->
      <div class="field-tree-panel panel-card">
        <div class="panel-header"><span class="panel-title">数据字段</span><span class="panel-tip">拖到单元格</span></div>
        <el-empty v-if="!fieldTree.length" description="请选择业务对象" :image-size="40" />
        <el-tree v-else :data="fieldTree" :props="{ label: 'label', children: 'children' }" default-expand-all node-key="nodeKey">
          <template #default="{ data }">
            <span class="tree-node" :class="{ draggable: data.draggable }" :draggable="data.draggable" @dragstart="onFieldDragStart($event, data)">
              <el-icon v-if="data.children?.length" class="node-icon"><Folder /></el-icon>
              <el-icon v-else class="node-icon"><Document /></el-icon>
              <span class="node-label">{{ data.label }}</span>
              <span v-if="data.fieldCode" class="node-code">{{ data.fieldCode }}</span>
            </span>
          </template>
        </el-tree>
        <div class="element-lib">
          <div class="lib-title">公式 / 元素</div>
          <div class="lib-items">
            <span v-for="el in FORMULA_ELEMENTS" :key="el.value" class="lib-item" draggable="true" @dragstart="onFormulaDragStart($event, el)">
              <el-icon><component :is="el.icon" /></el-icon>{{ el.label }}
            </span>
          </div>
          <div class="lib-title" style="margin-top:8px">函数</div>
          <div class="func-list">
            <code v-for="fn in FUNCTIONS" :key="fn" class="func-item" @click="insertFunction(fn)">{{ fn }}</code>
          </div>
        </div>
      </div>

      <!-- 中：类Excel单元格画布 -->
      <div class="canvas-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">单元格画布（{{ currentTemplate?.template_name || '未选择' }}）</span>
          <span class="panel-tip">点击选格 / 拖拽选区 / 双击编辑 / 合并/拆分</span>
        </div>
        <div class="band-legend">
          <span class="legend-item"><i class="dot title"></i>标题区</span>
          <span class="legend-item"><i class="dot header"></i>表头区</span>
          <span class="legend-item"><i class="dot detail"></i>明细区(扩展)</span>
          <span class="legend-item"><i class="dot summary"></i>汇总区</span>
        </div>
        <div class="canvas-scroll">
          <table class="cell-grid" @mousedown="onGridMouseDown">
            <thead>
              <tr>
                <th class="corner-h"></th>
                <th v-for="c in colCount" :key="c" class="col-h" @click="selectCol(c - 1)">{{ colLabel(c - 1) }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in rowCount" :key="r">
                <td class="row-h" :class="bandClass(r - 1)" @click="selectRow(r - 1)">
                  <span class="row-num">{{ r }}</span>
                  <el-select v-model="rowBands[r - 1]" size="small" class="band-select" @change="markDirty">
                    <el-option label="标题" value="title" />
                    <el-option label="表头" value="header" />
                    <el-option label="明细" value="detail" />
                    <el-option label="汇总" value="summary" />
                  </el-select>
                </td>
                <td
                  v-for="c in colCount"
                  :key="c"
                  :ref="el => setCellRef(el as any, r - 1, c - 1)"
                  class="cell"
                  :class="cellClass(r - 1, c - 1)"
                  :rowspan="getMerge(r - 1, c - 1)?.rowspan || 1"
                  :colspan="getMerge(r - 1, c - 1)?.colspan || 1"
                  :style="cellStyle(r - 1, c - 1)"
                  @mousedown.stop="onCellMouseDown($event, r - 1, c - 1)"
                  @mouseenter="onCellMouseEnter(r - 1, c - 1)"
                  @dblclick="onCellDblClick(r - 1, c - 1)"
                  @dragover.prevent="onCellDragOver(r - 1, c - 1)"
                  @drop="onCellDrop($event, r - 1, c - 1)"
                >
                  <template v-if="!isCovered(r - 1, c - 1)">
                    <span v-if="getCell(r - 1, c - 1).cell_type === 'field'" class="cell-field">
                      <el-icon><Connection /></el-icon>{{ getCell(r - 1, c - 1).field_code }}
                      <span v-if="getCell(r - 1, c - 1).expand !== 'none'" class="expand-mark">{{ expandMark(getCell(r - 1, c - 1).expand) }}</span>
                    </span>
                    <span v-else-if="getCell(r - 1, c - 1).cell_type === 'formula'" class="cell-formula">{{ getCell(r - 1, c - 1).content }}</span>
                    <span v-else-if="getCell(r - 1, c - 1).content" class="cell-static">{{ getCell(r - 1, c - 1).content }}</span>
                    <input
                      v-else-if="editingCell && editingCell.r === r - 1 && editingCell.c === c - 1"
                      v-model="editingText"
                      class="cell-input"
                      @blur="commitEdit"
                      @keydown.enter.prevent="commitEdit"
                      ref="editInputRef"
                    />
                  </template>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- 右：单元格属性 -->
      <div class="prop-panel panel-card">
        <div class="panel-header"><span class="panel-title">单元格属性</span></div>
        <el-empty v-if="!selectedCell" description="请选中单元格" :image-size="50" />
        <el-form v-else :model="selectedCellData" label-width="72px" size="small" class="prop-form">
          <el-form-item label="位置">
            <el-tag size="small" type="info">{{ cellPosLabel }}</el-tag>
            <el-tag v-if="selectedMerge" size="small" type="warning" style="margin-left:4px">合并 {{ selectedMerge.rowspan }}×{{ selectedMerge.colspan }}</el-tag>
          </el-form-item>
          <el-form-item label="类型">
            <el-radio-group v-model="selectedCellData.cell_type" @change="markDirty">
              <el-radio-button value="static">静态</el-radio-button>
              <el-radio-button value="field">字段</el-radio-button>
              <el-radio-button value="formula">公式</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'static'" label="文本">
            <el-input v-model="selectedCellData.content" placeholder="如 销售订单" @input="markDirty" />
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'field'" label="实体">
            <el-select v-model="selectedCellData.entity_code" style="width:100%" @change="onEntityChange">
              <el-option v-for="e in entities" :key="e.entity_code" :label="e.entity_name" :value="e.entity_code" />
            </el-select>
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'field'" label="字段">
            <el-select v-model="selectedCellData.field_code" filterable style="width:100%" @change="markDirty">
              <el-option v-for="f in fieldsForEntity(selectedCellData.entity_code)" :key="f.field_code" :label="f.field_name + ' (' + f.field_code + ')'" :value="f.field_code" />
            </el-select>
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'field'" label="扩展方向">
            <el-radio-group v-model="selectedCellData.expand" @change="markDirty">
              <el-radio value="none">不扩展</el-radio>
              <el-radio value="vertical">纵向</el-radio>
              <el-radio value="horizontal">横向</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'field'" label="数据设置">
            <el-select v-model="selectedCellData.data_setting" style="width:100%" @change="markDirty">
              <el-option v-for="o in CELL_DATA_SETTING_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
          </el-form-item>
          <el-form-item v-if="selectedCellData.cell_type === 'formula'" label="公式">
            <el-input v-model="selectedCellData.content" placeholder="如 =sum(D3) / =count()" @input="markDirty" />
          </el-form-item>
          <el-form-item label="格式化">
            <el-input v-model="selectedCellData.format" placeholder="如 YYYY-MM-DD / #,##0.00" @input="markDirty" />
          </el-form-item>
          <el-divider content-position="left">样式</el-divider>
          <el-form-item label="字号">
            <el-input-number v-model="selectedCellData.font_size" :min="8" :max="36" controls-position="right" style="width:100%" @change="markDirty" />
          </el-form-item>
          <el-form-item label="加粗">
            <el-switch v-model="selectedCellData.font_bold" @change="markDirty" />
          </el-form-item>
          <el-form-item label="对齐">
            <el-radio-group v-model="selectedCellData.align" @change="markDirty">
              <el-radio-button value="left">左</el-radio-button>
              <el-radio-button value="center">中</el-radio-button>
              <el-radio-button value="right">右</el-radio-button>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="边框">
            <el-switch v-model="selectedCellData.border" @change="markDirty" />
          </el-form-item>
          <el-form-item label="背景">
            <el-color-picker v-model="selectedCellData.bg_color" @change="markDirty" />
          </el-form-item>
        </el-form>
      </div>
    </div>

    <!-- 预览弹窗（支持多单据翻页 + 主子孙三层嵌套 GAP-D10-003/004）-->
    <el-dialog v-model="previewVisible" title="打印预览（模拟扩展）" width="900px" append-to-body destroy-on-close>
      <div class="print-preview">
        <!-- 多单据翻页（GAP-D10-003）-->
        <div class="preview-pager">
          <el-button size="small" :disabled="previewBillIdx <= 0" @click="onPreviewPrev">上一单</el-button>
          <span class="pager-info">第 {{ previewBillIdx + 1 }} / {{ previewBillList.length }} 单（{{ currentPreviewBillCode }}）</span>
          <el-button size="small" :disabled="previewBillIdx >= previewBillList.length - 1" @click="onPreviewNext">下一单</el-button>
          <span class="pager-paper">纸张：{{ paperSettings.paper_type }} {{ paperSettings.orientation === 'portrait' ? '纵向' : '横向' }}</span>
        </div>
        <!-- 套打份数提示（GAP-D10-002）-->
        <div v-if="batchConfig.batch_enabled" class="preview-batch">
          <el-tag size="small" type="warning">套打模式：共 {{ previewBillList.length }} 单 × {{ batchConfig.copies }} 份 = {{ previewBillList.length * batchConfig.copies }} 页</el-tag>
          <el-tag size="small" type="info">打印人：{{ batchConfig.print_by || '管理员' }}</el-tag>
        </div>
        <table class="preview-table" :style="previewTableStyle">
          <tbody>
            <tr v-for="(row, ri) in previewRows" :key="ri">
              <td
                v-for="(cell, ci) in row"
                :key="ci"
                :style="previewCellStyle(cell)"
                :colspan="cell.colspan"
              >{{ cell.text }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </el-dialog>

    <!-- 纸张设置弹窗（GAP-D10-001/009 / RISK-D10-004）-->
    <el-dialog v-model="paperDialogVisible" title="纸张设置" width="500px" append-to-body>
      <el-form :model="paperSettings" label-width="100px" size="small">
        <el-form-item label="纸张类型">
          <el-radio-group v-model="paperSettings.paper_type" @change="onPaperTypeChange">
            <el-radio-button value="A4">A4</el-radio-button>
            <el-radio-button value="A5">A5</el-radio-button>
            <el-radio-button value="letter">Letter</el-radio-button>
            <el-radio-button value="custom">自定义</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="paperSettings.paper_type === 'custom'" label="纸张宽度">
          <el-input-number v-model="paperSettings.paper_width" :min="50" :max="1000" :step="1" controls-position="right" /> mm
        </el-form-item>
        <el-form-item v-if="paperSettings.paper_type === 'custom'" label="纸张高度">
          <el-input-number v-model="paperSettings.paper_height" :min="50" :max="1500" :step="1" controls-position="right" /> mm
        </el-form-item>
        <el-form-item label="方向">
          <el-radio-group v-model="paperSettings.orientation">
            <el-radio-button value="portrait">纵向</el-radio-button>
            <el-radio-button value="landscape">横向</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-divider content-position="left">页边距（mm）</el-divider>
        <el-form-item label="上边距">
          <el-input-number v-model="paperSettings.margin_json.top" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="下边距">
          <el-input-number v-model="paperSettings.margin_json.bottom" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="左边距">
          <el-input-number v-model="paperSettings.margin_json.left" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="右边距">
          <el-input-number v-model="paperSettings.margin_json.right" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="页眉">
          <el-input-number v-model="paperSettings.margin_json.header" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="页脚">
          <el-input-number v-model="paperSettings.margin_json.footer" :min="0" :max="100" :step="1" controls-position="right" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="paperDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSavePaperSettings">应用</el-button>
      </template>
    </el-dialog>

    <!-- 套打配置弹窗（GAP-D10-002）-->
    <el-dialog v-model="batchDialogVisible" title="套打配置（批量多单据打印）" width="540px" append-to-body>
      <el-form :model="batchConfig" label-width="120px" size="small">
        <el-form-item label="启用套打">
          <el-switch v-model="batchConfig.batch_enabled" :active-value="1" :inactive-value="0" />
          <span class="form-tip">启用后预览将加载多单据，可翻页</span>
        </el-form-item>
        <el-form-item label="每单打印份数">
          <el-input-number v-model="batchConfig.copies" :min="1" :max="10" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="打印方式">
          <el-radio-group v-model="batchConfig.collate">
            <el-radio :value="1">逐份（1,2,3,1,2,3）</el-radio>
            <el-radio :value="0">逐单（1,1,2,2,3,3）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="打印机">
          <el-input v-model="batchConfig.printer" placeholder="如 HP LaserJet 1020" />
        </el-form-item>
        <el-form-item label="打印人">
          <el-input v-model="batchConfig.print_by" placeholder="打印人姓名（自动记录）" />
        </el-form-item>
        <el-form-item label="单据 ID 列表">
          <el-input v-model="batchBillIdsInput" type="textarea" :rows="3" placeholder="逗号分隔的单据 ID，如 1,2,3（留空则加载全部 3 单样例）" />
        </el-form-item>
      </el-form>
      <div class="batch-print-history" v-if="printHistory.length">
        <div class="history-title">打印记录：</div>
        <el-table :data="printHistory" size="small" border max-height="200">
          <el-table-column prop="print_time" label="打印时间" width="160" />
          <el-table-column prop="print_by" label="打印人" width="80" />
          <el-table-column prop="bill_count" label="单据数" width="70" />
          <el-table-column prop="copies" label="份数" width="60" />
          <el-table-column prop="printer" label="打印机" min-width="120" />
        </el-table>
      </div>
      <template #footer>
        <el-button @click="batchDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onConfirmBatch">确认</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Check, View, Grid, Folder, Document, Connection, Files } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import { printApi } from '@/api/state'
import { entityApi } from '@/api/bo'
import { billApi } from '@/api/bill'
import { CELL_DATA_SETTING_OPTIONS } from '@/utils/enum'
import type { FormEntity, FormField, BusinessObject, PrintPaperSettings, PrintBatchConfig } from '@/types/bo'

// ============ 类型 ============
interface PrintCell {
  content: string
  cell_type: 'static' | 'field' | 'formula' | 'image'
  entity_code?: string
  field_code?: string
  expand: 'none' | 'vertical' | 'horizontal'
  data_setting: 'list' | 'group' | 'sum' | 'avg' | 'max' | 'min' | 'count'
  font_size: number
  font_bold: boolean
  align: 'left' | 'center' | 'right'
  border: boolean
  format?: string
  bg_color?: string
}
interface MergeInfo { rowspan: number; colspan: number }
interface PrintTemplate {
  id: string
  template_name: string
  paper_size?: string
  // 纸张设置（GAP-D10-001/009 / RISK-D10-004）
  paper_type?: 'A4' | 'A5' | 'letter' | 'custom'
  paper_width?: number
  paper_height?: number
  orientation?: 'portrait' | 'landscape'
  margin_json?: PrintPaperSettings['margin_json']
  // 套打配置（GAP-D10-002）
  batch_config?: PrintBatchConfig
  is_default?: boolean
  row_count?: number
  col_count?: number
  cells?: Record<string, PrintCell>
  merges?: Record<string, MergeInfo>
  row_bands?: string[]
}

interface FieldNode { nodeKey: string; label: string; fieldCode?: string; entityCode?: string; draggable?: boolean; children?: FieldNode[] }

const FORMULA_ELEMENTS = [
  { value: 'sum', label: '求和', icon: 'Grid' },
  { value: 'count', label: '计数', icon: 'Grid' },
  { value: 'image', label: '图片', icon: 'Document' }
]
const FUNCTIONS = ['=sum()', '=count()', '=avg()', '=max()', '=min()', '=round(,2)']

// ============ 状态 ============
const boCode = ref('')
const templates = ref<PrintTemplate[]>([])
const currentTemplateId = ref('')
const currentTemplate = computed(() => templates.value.find(t => t.id === currentTemplateId.value))
const entities = ref<FormEntity[]>([])

const rowCount = ref(12)
const colCount = ref(8)
const cells = ref<Record<string, PrintCell>>({})
const merges = ref<Record<string, MergeInfo>>({})
const rowBands = ref<string[]>([])

const selectStart = ref<{ r: number; c: number } | null>(null)
const selectEnd = ref<{ r: number; c: number } | null>(null)
const editingCell = ref<{ r: number; c: number } | null>(null)
const editingText = ref('')
const editInputRef = ref<any>(null)
const cellRefs = ref<Record<string, any>>({})
const previewVisible = ref(false)
const previewData = ref<any>(null)

const fieldTree = ref<FieldNode[]>([])
let dragData: { kind: 'field' | 'formula'; fieldCode?: string; entityCode?: string; formula?: string } | null = null

// ============ D10 纸张设置 + 套打配置 + 多单据翻页 状态（GAP-D10-001/002/003）============
// 纸张设置（默认 A4 纵向，标准页边距）
const paperSettings = ref<PrintPaperSettings>({
  paper_type: 'A4',
  paper_width: 210,
  paper_height: 297,
  orientation: 'portrait',
  margin_json: { top: 20, bottom: 20, left: 18, right: 18, header: 10, footer: 10 }
})
const paperDialogVisible = ref(false)

// 套打配置
const batchConfig = ref<PrintBatchConfig>({
  batch_enabled: 0,
  copies: 1,
  collate: 1,
  print_by: '',
  printer: ''
})
const batchDialogVisible = ref(false)
const batchBillIdsInput = ref('')
const printHistory = ref<Array<{ print_time: string; print_by: string; bill_count: number; copies: number; printer: string }>>([])

// 多单据预览翻页（GAP-D10-003）
const previewBillList = ref<any[]>([])
const previewBillIdx = ref(0)
const currentPreviewBillCode = computed(() => previewBillList.value[previewBillIdx.value]?.code || previewBillList.value[previewBillIdx.value]?.bill_no || '')

// 预览表格样式（按纸张设置动态计算宽度，GAP-D10-001）
const PAPER_SIZE_MAP: Record<string, { w: number; h: number }> = {
  A4: { w: 210, h: 297 },
  A5: { w: 148, h: 210 },
  letter: { w: 216, h: 279 }
}
const previewTableStyle = computed(() => {
  const ps = paperSettings.value
  let pageW = 0
  if (ps.paper_type === 'custom') pageW = ps.paper_width || 210
  else pageW = PAPER_SIZE_MAP[ps.paper_type]?.w || 210
  const isLandscape = ps.orientation === 'landscape'
  const effectiveW = isLandscape ? (ps.paper_type === 'custom' ? (ps.paper_height || 297) : (PAPER_SIZE_MAP[ps.paper_type]?.h || 297)) : pageW
  const margin = ps.margin_json
  const contentW = effectiveW - (margin?.left || 0) - (margin?.right || 0)
  return {
    width: Math.max(contentW * 3.78, 600) + 'px',  // mm → px (96dpi ≈ 3.78)
    margin: '0 auto'
  }
})

// ============ 工具函数 ============
function cellKey(r: number, c: number) { return `${r}_${c}` }

function defaultCell(): PrintCell {
  return {
    content: '', cell_type: 'static', expand: 'none', data_setting: 'list',
    font_size: 11, font_bold: false, align: 'left', border: false
  }
}

function getCell(r: number, c: number): PrintCell {
  const k = cellKey(r, c)
  if (!cells.value[k]) cells.value[k] = defaultCell()
  return cells.value[k]
}

function setCellRef(el: any, r: number, c: number) {
  if (el) cellRefs.value[cellKey(r, c)] = el
}

function isCovered(r: number, c: number): boolean {
  for (const [k, m] of Object.entries(merges.value)) {
    const [sr, sc] = k.split('_').map(Number)
    if (r >= sr && r < sr + m.rowspan && c >= sc && c < sc + m.colspan && !(r === sr && c === sc)) return true
  }
  return false
}

function getMerge(r: number, c: number): MergeInfo | undefined {
  return merges.value[cellKey(r, c)]
}

function isMergedCell(r: number, c: number): boolean {
  return !!merges.value[cellKey(r, c)]
}

function colLabel(c: number) { return String.fromCharCode(65 + c) }

function bandClass(r: number) {
  return `band-${rowBands.value[r] || 'title'}`
}

function cellClass(r: number, c: number) {
  const cls: string[] = []
  if (isSelected(r, c)) cls.push('selected')
  if (isCovered(r, c)) cls.push('covered')
  if (isMergedCell(r, c)) cls.push('merged')
  return cls
}

function cellStyle(r: number, c: number) {
  const cell = getCell(r, c)
  const s: any = {
    fontSize: cell.font_size + 'px',
    textAlign: cell.align,
    fontWeight: cell.font_bold ? 'bold' : 'normal'
  }
  if (cell.border) { s.border = '1px solid #303133' }
  if (cell.bg_color) { s.background = cell.bg_color }
  return s
}

function expandMark(expand: string) {
  return expand === 'vertical' ? '↓' : expand === 'horizontal' ? '→' : ''
}

// ============ 选择 ============
function isSelected(r: number, c: number): boolean {
  if (!selectStart.value || !selectEnd.value) {
    return selectStart.value?.r === r && selectStart.value?.c === c
  }
  const r1 = Math.min(selectStart.value.r, selectEnd.value.r)
  const r2 = Math.max(selectStart.value.r, selectEnd.value.r)
  const c1 = Math.min(selectStart.value.c, selectEnd.value.c)
  const c2 = Math.max(selectStart.value.c, selectEnd.value.c)
  return r >= r1 && r <= r2 && c >= c1 && c <= c2
}

function onCellMouseDown(e: MouseEvent, r: number, c: number) {
  if (editingCell.value) return
  if (e.shiftKey && selectStart.value) {
    selectEnd.value = { r, c }
  } else {
    selectStart.value = { r, c }
    selectEnd.value = { r, c }
  }
}

function onCellMouseEnter(r: number, c: number) {
  if (eMouseDown && selectStart.value) {
    selectEnd.value = { r, c }
  }
}

let eMouseDown = false
function onGridMouseDown() { eMouseDown = true; window.addEventListener('mouseup', () => { eMouseDown = false }, { once: true }) }

function selectRow(r: number) { selectStart.value = { r, c: 0 }; selectEnd.value = { r, c: colCount.value - 1 } }
function selectCol(c: number) { selectStart.value = { r: 0, c }; selectEnd.value = { r: rowCount.value - 1, c } }

const selectedCell = computed(() => {
  if (!selectStart.value) return null
  return selectStart.value
})
const selectedCellData = computed({
  get: () => getCell(selectedCell.value!.r, selectedCell.value!.c),
  set: (v: PrintCell) => { if (selectedCell.value) cells.value[cellKey(selectedCell.value.r, selectedCell.value.c)] = v }
})
const cellPosLabel = computed(() => {
  if (!selectedCell.value) return ''
  return `${colLabel(selectedCell.value.c)}${selectedCell.value.r + 1}`
})
const selectedMerge = computed(() => {
  if (!selectedCell.value) return null
  return merges.value[cellKey(selectedCell.value.r, selectedCell.value.c)] || null
})

// ============ 合并/拆分 ============
const canMerge = computed(() => {
  if (!selectStart.value || !selectEnd.value) return false
  const r1 = Math.min(selectStart.value.r, selectEnd.value.r)
  const r2 = Math.max(selectStart.value.r, selectEnd.value.r)
  const c1 = Math.min(selectStart.value.c, selectEnd.value.c)
  const c2 = Math.max(selectStart.value.c, selectEnd.value.c)
  return r2 > r1 || c2 > c1
})
const canUnmerge = computed(() => {
  if (!selectedCell.value) return false
  return isMergedCell(selectedCell.value.r, selectedCell.value.c)
})

function mergeCells() {
  if (!canMerge.value || !selectStart.value || !selectEnd.value) return
  const r1 = Math.min(selectStart.value.r, selectEnd.value.r)
  const r2 = Math.max(selectStart.value.r, selectEnd.value.r)
  const c1 = Math.min(selectStart.value.c, selectEnd.value.c)
  const c2 = Math.max(selectStart.value.c, selectEnd.value.c)
  merges.value[cellKey(r1, c1)] = { rowspan: r2 - r1 + 1, colspan: c2 - c1 + 1 }
  markDirty()
}

function unmergeCells() {
  if (!selectedCell.value) return
  delete merges.value[cellKey(selectedCell.value.r, selectedCell.value.c)]
  markDirty()
}

// ============ 编辑 ============
function onCellDblClick(r: number, c: number) {
  editingCell.value = { r, c }
  editingText.value = getCell(r, c).content
  nextTick(() => { editInputRef.value?.[0]?.focus?.() })
}
function commitEdit() {
  if (!editingCell.value) return
  const cell = getCell(editingCell.value.r, editingCell.value.c)
  cell.content = editingText.value
  if (editingText.value.startsWith('=')) cell.cell_type = 'formula'
  editingCell.value = null
  markDirty()
}

function insertFunction(fn: string) {
  if (!selectedCell.value) { ElMessage.warning('请先选中单元格'); return }
  const cell = getCell(selectedCell.value.r, selectedCell.value.c)
  cell.content = fn
  cell.cell_type = 'formula'
  markDirty()
}

// ============ 行列操作 ============
function insertRow() {
  if (!selectedCell.value) { ElMessage.warning('请先选中一行'); return }
  const r = selectedCell.value.r + 1
  rowCount.value++
  // 后移 cells 和 merges
  const newCells: Record<string, PrintCell> = {}
  const newMerges: Record<string, MergeInfo> = {}
  for (const [k, v] of Object.entries(cells.value)) {
    const [cr, cc] = k.split('_').map(Number)
    newCells[cr >= r ? `${cr + 1}_${cc}` : k] = v
  }
  for (const [k, v] of Object.entries(merges.value)) {
    const [cr, cc] = k.split('_').map(Number)
    newMerges[cr >= r ? `${cr + 1}_${cc}` : k] = v
  }
  cells.value = newCells
  merges.value = newMerges
  rowBands.value.splice(r, 0, 'detail')
  markDirty()
}

function insertCol() {
  if (!selectedCell.value) { ElMessage.warning('请先选中一列'); return }
  const c = selectedCell.value.c + 1
  colCount.value++
  const newCells: Record<string, PrintCell> = {}
  const newMerges: Record<string, MergeInfo> = {}
  for (const [k, v] of Object.entries(cells.value)) {
    const [cr, cc] = k.split('_').map(Number)
    newCells[cc >= c ? `${cr}_${cc + 1}` : k] = v
  }
  for (const [k, v] of Object.entries(merges.value)) {
    const [cr, cc] = k.split('_').map(Number)
    newMerges[cc >= c ? `${cr}_${cc + 1}` : k] = v
  }
  cells.value = newCells
  merges.value = newMerges
  markDirty()
}

// ============ 拖拽绑定 ============
function onFieldDragStart(_e: DragEvent, data: FieldNode) {
  if (!data.draggable) return
  dragData = { kind: 'field', fieldCode: data.fieldCode, entityCode: data.entityCode }
}
function onFormulaDragStart(_e: DragEvent, el: any) {
  const map: Record<string, string> = { sum: '=sum()', count: '=count()', image: '' }
  dragData = { kind: 'formula', formula: map[el.value] || '=sum()' }
}
function onCellDragOver(_r: number, _c: number) { /* allow drop */ }
function onCellDrop(_e: DragEvent, r: number, c: number) {
  if (!dragData) return
  const cell = getCell(r, c)
  if (dragData.kind === 'field') {
    cell.cell_type = 'field'
    cell.field_code = dragData.fieldCode
    cell.entity_code = dragData.entityCode
    cell.expand = 'vertical'
    cell.data_setting = 'list'
    cell.content = ''
  } else if (dragData.kind === 'formula') {
    cell.cell_type = 'formula'
    cell.content = dragData.formula || '=sum()'
  }
  selectStart.value = { r, c }
  selectEnd.value = { r, c }
  dragData = null
  markDirty()
}

// ============ 字段树 ============
async function loadFieldTree() {
  if (!boCode.value) return
  entities.value = await entityApi.list(boCode.value)
  fieldTree.value = (entities.value || []).map((e: FormEntity) => ({
    nodeKey: `e_${e.entity_code}`,
    label: e.entity_name,
    children: (e.fields || []).map((f) => ({
      nodeKey: `${e.entity_code}.${f.field_code}`,
      label: f.field_name,
      fieldCode: f.field_code,
      entityCode: e.entity_code,
      draggable: true
    }))
  }))
}

function fieldsForEntity(ec?: string): FormField[] {
  if (!ec) return entities.value.flatMap(e => e.fields || [])
  return entities.value.find(e => e.entity_code === ec)?.fields || []
}
function onEntityChange() { selectedCellData.value.field_code = '' }

// ============ BO 切换 ============
async function onBoChange(bo: BusinessObject | null) {
  boCode.value = bo?.bo_code || ''
  currentTemplateId.value = ''
  if (!boCode.value) { templates.value = []; fieldTree.value = []; return }
  await loadTemplates()
  await loadFieldTree()
}

async function loadTemplates() {
  if (!boCode.value) return
  templates.value = await printApi.list(boCode.value)
  if (templates.value.length) {
    currentTemplateId.value = templates.value[0].id
    onTemplateChange(currentTemplateId.value)
  } else {
    resetCanvas()
  }
}

function resetCanvas() {
  rowCount.value = 12
  colCount.value = 8
  cells.value = {}
  merges.value = {}
  rowBands.value = Array(12).fill('title')
  rowBands.value[2] = 'header'
  rowBands.value[3] = 'detail'
}

function onTemplateChange(id: string) {
  const t = templates.value.find(x => x.id === id)
  if (!t) { resetCanvas(); return }
  rowCount.value = t.row_count || 12
  colCount.value = t.col_count || 8
  cells.value = { ...(t.cells || {}) }
  merges.value = { ...(t.merges || {}) }
  rowBands.value = [...(t.row_bands || Array(rowCount.value).fill('title'))]
  if (rowBands.value.length < rowCount.value) {
    rowBands.value = rowBands.value.concat(Array(rowCount.value - rowBands.value.length).fill('detail'))
  }
  // 加载纸张设置（GAP-D10-001/009 / RISK-D10-004）
  if (t.paper_type || t.paper_width || t.orientation || t.margin_json) {
    paperSettings.value = {
      paper_type: t.paper_type || 'A4',
      paper_width: t.paper_width || (t.paper_type === 'custom' ? 210 : PAPER_SIZE_MAP[t.paper_type || 'A4']?.w),
      paper_height: t.paper_height || (t.paper_type === 'custom' ? 297 : PAPER_SIZE_MAP[t.paper_type || 'A4']?.h),
      orientation: t.orientation || 'portrait',
      margin_json: t.margin_json || { top: 20, bottom: 20, left: 18, right: 18, header: 10, footer: 10 }
    }
  }
  // 加载套打配置（GAP-D10-002）
  if (t.batch_config) {
    batchConfig.value = { ...t.batch_config }
  }
  selectStart.value = null
  selectEnd.value = null
}

// ============ 纸张设置 + 套打配置 函数（GAP-D10-001/002）============
function onPaperTypeChange(val: string | number | boolean | undefined) {
  // 切换纸张类型时自动填充标准尺寸
  const v = String(val)
  if (v !== 'custom') {
    const sz = PAPER_SIZE_MAP[v]
    if (sz) {
      paperSettings.value.paper_width = sz.w
      paperSettings.value.paper_height = sz.h
    }
  }
  markDirty()
}

function onSavePaperSettings() {
  if (paperSettings.value.paper_type === 'custom' && (!paperSettings.value.paper_width || !paperSettings.value.paper_height)) {
    ElMessage.warning('自定义纸张需填写宽度和高度')
    return
  }
  paperDialogVisible.value = false
  markDirty()
  ElMessage.success('纸张设置已应用，请保存模板以持久化')
}

function onConfirmBatch() {
  if (batchConfig.value.batch_enabled === 1 && batchConfig.value.copies < 1) {
    ElMessage.warning('打印份数必须 ≥1')
    return
  }
  batchDialogVisible.value = false
  markDirty()
  ElMessage.success('套打配置已保存，请保存模板以持久化')
}

function onPreviewPrev() {
  if (previewBillIdx.value > 0) {
    previewBillIdx.value--
    renderPreview()
  }
}

function onPreviewNext() {
  if (previewBillIdx.value < previewBillList.value.length - 1) {
    previewBillIdx.value++
    renderPreview()
  }
}

let dirty = false
function markDirty() { dirty = true }

// ============ 模板操作 ============
async function onNewTemplate() {
  const name = await ElMessageBox.prompt('请输入模板名称', '新建模板', {
    confirmButtonText: '确定', cancelButtonText: '取消', inputPattern: /.+/, inputErrorMessage: '名称不能为空'
  }).then((r) => r.value).catch(() => null)
  if (!name) return
  const saved = await printApi.save({ bo_code: boCode.value, template_name: name, paper_size: 'A4', is_default: templates.value.length === 0, layout: [] })
  const t: PrintTemplate = { id: saved.id || String(Date.now()), template_name: name, paper_size: 'A4', is_default: templates.value.length === 0 }
  templates.value.push(t)
  currentTemplateId.value = t.id
  resetCanvas()
  ElMessage.success('新建成功')
}

async function onDeleteTemplate() {
  if (!currentTemplateId.value) return
  await ElMessageBox.confirm(`确定删除模板「${currentTemplate.value?.template_name}」吗？`, '提示', { type: 'warning' })
  try { await printApi.delete(currentTemplateId.value) } catch {}
  const idx = templates.value.findIndex(t => t.id === currentTemplateId.value)
  if (idx > -1) templates.value.splice(idx, 1)
  currentTemplateId.value = templates.value[0]?.id || ''
  if (currentTemplateId.value) onTemplateChange(currentTemplateId.value)
  else resetCanvas()
  ElMessage.success('删除成功')
}

async function onSave() {
  if (!currentTemplate.value) return
  await printApi.save({
    id: currentTemplateId.value, bo_code: boCode.value,
    template_name: currentTemplate.value.template_name,
    paper_size: currentTemplate.value.paper_size || paperSettings.value.paper_type,
    // 纸张设置（GAP-D10-001/009 / RISK-D10-004）
    paper_type: paperSettings.value.paper_type,
    paper_width: paperSettings.value.paper_width,
    paper_height: paperSettings.value.paper_height,
    orientation: paperSettings.value.orientation,
    margin_json: paperSettings.value.margin_json,
    // 套打配置（GAP-D10-002）
    batch_config: { ...batchConfig.value },
    is_default: currentTemplate.value.is_default,
    layout: [],
    // 扩展字段（原型持久化）
    ...({ row_count: rowCount.value, col_count: colCount.value, cells: cells.value, merges: merges.value, row_bands: rowBands.value } as any)
  } as any)
  currentTemplate.value.cells = { ...cells.value }
  currentTemplate.value.merges = { ...merges.value }
  currentTemplate.value.row_bands = [...rowBands.value]
  currentTemplate.value.paper_type = paperSettings.value.paper_type
  currentTemplate.value.orientation = paperSettings.value.orientation
  currentTemplate.value.batch_config = { ...batchConfig.value }
  dirty = false
  ElMessage.success('保存成功')
}

// ============ 预览（模拟扩展）============
interface PreviewCell { text: string; colspan?: number; align?: string; font_size?: number; font_bold?: boolean }
const previewRows = ref<PreviewCell[][]>([])

// 样例单据（含主表/子表/孙表三层嵌套，GAP-D10-004）
function buildSampleBill(id: string): any {
  const samples: Record<string, any> = {
    '1': {
      code: 'SO20260701001', cust_name: '上海纺织集团', order_date: '2026-07-01', total_amount: 11000, salesman: '张三',
      sal_order_goods: [
        { mat_name: '涤纶纱', qty: 100, price: 50, amount: 5000, sal_order_goods_assign: [{ assign_qty: 60, workshop: '纺纱车间' }, { assign_qty: 40, workshop: '织布车间' }] },
        { mat_name: '棉纱', qty: 200, price: 30, amount: 6000, sal_order_goods_assign: [{ assign_qty: 200, workshop: '纺纱车间' }] }
      ]
    },
    '2': {
      code: 'SO20260701002', cust_name: '江苏毛纺厂', order_date: '2026-07-01', total_amount: 121600, salesman: '王五',
      sal_order_goods: [
        { mat_name: '羊毛纱线', qty: 3200, price: 38, amount: 121600, sal_order_goods_assign: [{ assign_qty: 2000, workshop: '纺纱车间' }, { assign_qty: 1200, workshop: '染整车间' }] }
      ]
    },
    '3': {
      code: 'SO20260630007', cust_name: '江苏毛纺厂', order_date: '2026-06-30', total_amount: 43200, salesman: '王五',
      sal_order_goods: [
        { mat_name: '羊毛纱线', qty: 1200, price: 36, amount: 43200, sal_order_goods_assign: [{ assign_qty: 1200, workshop: '纺纱车间' }] }
      ]
    }
  }
  return samples[id] || samples['1']
}

async function onPreview() {
  // 多单据加载（GAP-D10-003 套打翻页）
  const boCodeVal = boCode.value || 'sal_order'
  const billIds = batchBillIdsInput.value
    ? batchBillIdsInput.value.split(',').map(s => s.trim()).filter(Boolean)
    : ['1', '2', '3']
  previewBillList.value = []
  for (const id of billIds) {
    try {
      const detail = await billApi.detail(boCodeVal, id)
      // 若返回数据缺少孙表，套用样例
      if (!detail || !detail.sal_order_goods) {
        previewBillList.value.push(buildSampleBill(id))
      } else {
        previewBillList.value.push(detail)
      }
    } catch {
      previewBillList.value.push(buildSampleBill(id))
    }
  }
  previewBillIdx.value = 0
  // 套打模式：记录打印历史（GAP-D10-002）
  if (batchConfig.value.batch_enabled === 1) {
    printHistory.value.unshift({
      print_time: new Date().toLocaleString('zh-CN'),
      print_by: batchConfig.value.print_by || '管理员',
      bill_count: previewBillList.value.length,
      copies: batchConfig.value.copies,
      printer: batchConfig.value.printer || '默认打印机'
    })
  }
  renderPreview()
  previewVisible.value = true
}

// 渲染当前单据（含主子孙三层数据嵌套扩展 GAP-D10-003/004）
function renderPreview() {
  const data = previewBillList.value[previewBillIdx.value]
  if (!data) { previewRows.value = []; return }
  previewData.value = data
  const outRows: PreviewCell[][] = []
  const detailRowIdx = rowBands.value.findIndex(b => b === 'detail')
  const subData = (data.sal_order_goods || data.lines || []) as any[]
  // 孙表实体编码集合（用于判定字段归属）
  const grandchildCodes = new Set(entities.value.filter(e => e.entity_type === 'grandchild').map(e => e.entity_code))

  for (let r = 0; r < rowCount.value; r++) {
    const band = rowBands.value[r] || 'title'
    if (band === 'detail' && detailRowIdx === r) {
      // 子表数据纵向扩展 + 孙表嵌套扩展（GAP-D10-004）
      const expandCount = subData.length || 1
      for (let i = 0; i < expandCount; i++) {
        const row: PreviewCell[] = []
        const grandchildData = subData[i]?.sal_order_goods_assign || subData[i]?.assigns || []
        for (let c = 0; c < colCount.value; c++) {
          if (isCovered(r, c)) continue
          const m = getMerge(r, c)
          const cell = getCell(r, c)
          // 孙表字段：合并展示（孙表数据以「值1 / 值2」形式呈现，GAP-D10-004）
          if (cell.entity_code && grandchildCodes.has(cell.entity_code)) {
            const gcText = grandchildData.map((g: any) => g[cell.field_code!] ?? '').filter((v: any) => v !== '').join(' / ')
            row.push({ text: gcText, colspan: m?.colspan, align: cell.align, font_size: cell.font_size, font_bold: cell.font_bold })
          } else {
            row.push({ text: resolveCellText(cell, data, subData[i], outRows), colspan: m?.colspan, align: cell.align, font_size: cell.font_size, font_bold: cell.font_bold })
          }
        }
        outRows.push(row)
      }
    } else {
      const row: PreviewCell[] = []
      for (let c = 0; c < colCount.value; c++) {
        if (isCovered(r, c)) continue
        const m = getMerge(r, c)
        const cell = getCell(r, c)
        row.push({ text: resolveCellText(cell, data, null, outRows), colspan: m?.colspan, align: cell.align, font_size: cell.font_size, font_bold: cell.font_bold })
      }
      outRows.push(row)
    }
  }
  // 公式引擎二次解析：基于已展开的 outRows 计算 SUM/AVG/MAX/MIN/COUNT（RISK-D10-002）
  for (let r = 0; r < outRows.length; r++) {
    for (let c = 0; c < outRows[r].length; c++) {
      const cell = outRows[r][c]
      if (cell.text && cell.text.startsWith('=')) {
        cell.text = applyFormula(cell.text, outRows)
      }
    }
  }
  previewRows.value = outRows
}

function resolveCellText(cell: PrintCell, main: any, sub: any, _outRows: PreviewCell[][]): string {
  if (cell.cell_type === 'static') return cell.content
  if (cell.cell_type === 'field') {
    const val = sub && sub[cell.field_code!] != null ? sub[cell.field_code!] : main[cell.field_code!]
    return val != null ? String(val) : ''
  }
  if (cell.cell_type === 'formula') return cell.content  // 公式留待二次解析
  return ''
}

// 公式引擎（简化版，支持 =SUM(D3:D10) / =AVG / =MAX / =MIN / =COUNT / =SUM(D3)）（RISK-D10-002）
function applyFormula(formula: string, rows: PreviewCell[][]): string {
  const m = formula.trim().toUpperCase().match(/^=(SUM|AVG|MAX|MIN|COUNT)\((.*)\)$/)
  if (!m) return formula
  const fn = m[1]
  const args = m[2].trim()
  // 解析单元格引用，支持 D3 或 D3:D10
  const refMatch = args.match(/([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?/)
  if (!refMatch) return formula
  const colStart = colLetterToIdx(refMatch[1])
  const rowStart = Number(refMatch[2]) - 1
  const colEnd = refMatch[4] ? colLetterToIdx(refMatch[3]) : colStart
  const rowEnd = refMatch[4] ? Number(refMatch[4]) - 1 : rowStart
  // 收集范围内的数值
  const values: number[] = []
  for (let r = rowStart; r <= rowEnd; r++) {
    if (r < 0 || r >= rows.length) continue
    const row = rows[r]
    for (let c = colStart; c <= colEnd; c++) {
      // 注：预览行中 colspan 会影响列对齐，原型简化按数组下标取列
      const cell = row[c]
      if (cell && cell.text != null && cell.text !== '' && !cell.text.startsWith('=')) {
        const n = Number(cell.text)
        if (!isNaN(n)) values.push(n)
      }
    }
  }
  let result = 0
  switch (fn) {
    case 'SUM': result = values.reduce((a, b) => a + b, 0); break
    case 'AVG': result = values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0; break
    case 'MAX': result = values.length ? Math.max(...values) : 0; break
    case 'MIN': result = values.length ? Math.min(...values) : 0; break
    case 'COUNT': result = values.length; break
  }
  return String(Math.round(result * 100) / 100)
}

function colLetterToIdx(letters: string): number {
  let idx = 0
  for (let i = 0; i < letters.length; i++) {
    idx = idx * 26 + (letters.charCodeAt(i) - 'A'.charCodeAt(0) + 1)
  }
  return idx - 1
}

function previewCellStyle(cell: PreviewCell) {
  const s: any = { border: '1px solid #d0d0d0', padding: '4px 8px' }
  if (cell.align) s.textAlign = cell.align
  if (cell.font_size) s.fontSize = cell.font_size + 'px'
  if (cell.font_bold) s.fontWeight = 'bold'
  return s
}
</script>

<style scoped lang="scss">
.print-designer-page { padding: 10px; height: 100%; display: flex; flex-direction: column; gap: 10px; overflow: hidden; }
.page-header { display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; flex-wrap: wrap; gap: 8px;
  .header-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; .header-label { font-size: 13px; color: #606266; } }
  .header-right { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
}
.main-body { flex: 1; display: flex; gap: 10px; min-height: 0; }
.field-tree-panel { width: 220px; flex-shrink: 0; display: flex; flex-direction: column; }
:deep(.el-tree) { flex: 1; overflow: auto; padding: 6px; }
.tree-node { display: flex; align-items: center; gap: 4px; flex: 1; .node-icon { color: #1564ff; font-size: 14px; } .node-label { font-size: 13px; } .node-code { font-size: 11px; color: #c0c4cc; margin-left: auto; font-family: 'Consolas', monospace; } &.draggable { cursor: grab; &:hover { color: #1564ff; } } }
.element-lib { border-top: 1px solid #f0f0f0; padding: 8px;
  .lib-title { font-size: 12px; color: #909399; margin-bottom: 6px; }
  .lib-items { display: flex; flex-wrap: wrap; gap: 4px; }
  .lib-item { display: inline-flex; align-items: center; gap: 3px; padding: 3px 7px; border: 1px dashed #d9d9d9; border-radius: 3px; font-size: 12px; cursor: grab; color: #606266; &:hover { border-color: #1564ff; color: #1564ff; } }
  .func-list { display: flex; flex-direction: column; gap: 3px; }
  .func-item { font-size: 11px; color: #1564ff; cursor: pointer; font-family: 'Consolas', monospace; padding: 2px 4px; &:hover { background: #ecf5ff; } }
}
.canvas-panel { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.panel-header { display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; border-bottom: 1px solid #f0f0f0; background: #fafafa;
  .panel-title { font-size: 13px; font-weight: 600; }
  .panel-tip { font-size: 11px; color: #909399; font-weight: normal; }
}
.band-legend { display: flex; gap: 12px; padding: 4px 12px; font-size: 11px; color: #909399; border-bottom: 1px solid #f5f5f5;
  .legend-item { display: flex; align-items: center; gap: 3px; }
  .dot { width: 8px; height: 8px; border-radius: 2px; display: inline-block; }
  .dot.title { background: #e8f4ff; } .dot.header { background: #f0f9eb; } .dot.detail { background: #fef0f0; } .dot.summary { background: #fdf6ec; }
}
.canvas-scroll { flex: 1; overflow: auto; padding: 8px; background: #f5f5f5; }
.cell-grid { border-collapse: collapse; table-layout: fixed; background: #fff;
  th.corner-h { width: 60px; min-width: 60px; background: #f5f7fa; }
  th.col-h { min-width: 80px; height: 22px; background: #f5f7fa; border: 1px solid #e4e7ed; font-size: 11px; font-weight: normal; color: #909399; cursor: pointer; }
  td.row-h { background: #f5f7fa; border: 1px solid #e4e7ed; text-align: center; vertical-align: middle; padding: 0; position: relative; cursor: pointer;
    .row-num { font-size: 11px; color: #909399; display: block; line-height: 18px; }
    .band-select { width: 100%; :deep(.el-select__wrapper) { min-height: 18px; padding: 0 4px; } :deep(.el-select__placeholder) { font-size: 10px; } }
    &.band-title { background: #e8f4ff; } &.band-header { background: #f0f9eb; } &.band-detail { background: #fef0f0; } &.band-summary { background: #fdf6ec; }
  }
  td.cell { border: 1px solid #e4e7ed; height: 26px; padding: 2px 6px; vertical-align: middle; cursor: cell; position: relative; overflow: hidden;
    &.selected { outline: 2px solid #1564ff; outline-offset: -2px; z-index: 2; background: #ecf5ff; }
    &.covered { visibility: hidden; }
    .cell-field { color: #1564ff; font-family: 'Consolas', monospace; font-size: 12px; display: flex; align-items: center; gap: 2px; }
    .expand-mark { color: #e6a23c; font-weight: bold; margin-left: 2px; }
    .cell-formula { color: #722ed1; font-family: 'Consolas', monospace; font-size: 12px; }
    .cell-static { color: #303133; font-size: 12px; }
    .cell-input { width: 100%; height: 100%; border: none; outline: none; font-size: 12px; padding: 0; background: #fff; }
  }
}
.prop-panel { width: 280px; flex-shrink: 0; display: flex; flex-direction: column; }
.prop-form { padding: 10px; overflow: auto; }
.print-preview { background: #fff; padding: 16px; overflow: auto; }
.preview-pager { display: flex; align-items: center; gap: 8px; padding: 8px 0 12px; border-bottom: 1px dashed #ebeef5; margin-bottom: 12px;
  .pager-info { font-size: 13px; color: #303133; font-weight: 600; }
  .pager-paper { margin-left: auto; font-size: 12px; color: #909399; }
}
.preview-batch { display: flex; gap: 8px; margin-bottom: 12px; }
.preview-table { border-collapse: collapse; width: 100%; min-width: 600px;
  td { border: 1px solid #d0d0d0; padding: 4px 8px; font-size: 12px; }
}
.form-tip { font-size: 12px; color: #909399; margin-left: 8px; }
.batch-print-history { margin-top: 12px; border-top: 1px dashed #ebeef5; padding-top: 8px;
  .history-title { font-size: 12px; color: #606266; margin-bottom: 6px; }
}
:deep(.el-empty) { padding: 20px; }
</style>
