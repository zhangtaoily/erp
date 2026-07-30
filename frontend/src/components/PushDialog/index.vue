<template>
  <el-dialog
    v-model="visible"
    title="下推"
    width="860px"
    destroy-on-close
    @open="onOpen"
    @closed="onClosed"
  >
    <!-- 步骤1：选择下推规则（目标业务对象） -->
    <div v-if="step === 'selectRule'">
      <el-empty v-if="!loading && !rules.length" description="当前业务对象未配置可用的下推规则" :image-size="60">
        <template #description>
          <p>当前业务对象未配置可用的下推规则</p>
          <p style="font-size:12px;color:#909399">请在「下推规则配置」页面为该业务对象配置下推规则</p>
        </template>
      </el-empty>
      <el-table
        v-else
        v-loading="loading"
        :data="rules"
        border
        size="small"
        highlight-current-row
        @row-click="onSelectRule"
      >
        <el-table-column label="规则名称" prop="rule_name" min-width="160" />
        <el-table-column label="目标业务对象" prop="tgt_bo_code" width="160" />
        <el-table-column label="数量层级" width="110" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="row.qty_field_scope === 'main' ? 'warning' : 'info'" effect="plain">
              {{ row.qty_field_scope === 'main' ? '主表总量' : '子表明细' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="可下推数量字段" prop="qty_field" width="140" />
        <el-table-column label="操作" width="80" align="center" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click.stop="onSelectRule(row)">选择</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 步骤2：选择下推行（sub scope 才需要，main scope 直接下推） -->
    <div v-else-if="step === 'selectLines'">
      <div class="rule-info-bar">
        <span class="info-item"><b>规则：</b>{{ selectedRule?.rule_name }}</span>
        <span class="info-item"><b>目标：</b>{{ selectedRule?.tgt_bo_code }}</span>
        <span class="info-item">
          <b>层级：</b>
          <el-tag size="small" :type="isMainScope ? 'warning' : 'info'" effect="plain">
            {{ isMainScope ? '主表总量下推' : '子表明细下推' }}
          </el-tag>
        </span>
        <el-button link type="primary" size="small" @click="backToRuleSelect">返回选择规则</el-button>
      </div>

      <div v-loading="billLoading">
        <div class="convert-tip">
          <el-icon><InfoFilled /></el-icon>
          <span>勾选要下推的明细行，下推后将在新页面打开目标单据，可在目标单据中调整数量和字段后保存。</span>
        </div>

        <div class="sub-toolbar">
          <el-button size="small" @click="selectAllLines">全选</el-button>
          <el-button size="small" @click="clearSelection">清空</el-button>
          <span class="selection-tip">已选 {{ selectedLineIds.length }} 行</span>
        </div>
        <el-table
          ref="lineTableRef"
          :data="sourceLines"
          border
          size="small"
          max-height="360"
          row-key="id"
          @selection-change="onSelectionChange"
        >
          <el-table-column type="selection" width="40" />
          <el-table-column label="序号" width="55" type="index" />
          <el-table-column
            v-for="col in lineDisplayColumns"
            :key="col.prop"
            :label="col.label"
            :prop="col.prop"
            :min-width="col.width || 100"
            show-overflow-tooltip
          />
          <template #empty>
            <el-empty description="无子表行" :image-size="40" />
          </template>
        </el-table>
      </div>
    </div>

    <!-- 底部 -->
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button
        v-if="step === 'selectLines'"
        type="primary"
        :disabled="!canPush"
        @click="onConfirm"
      >
        下推
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'
import { useRouter } from 'vue-router'
import { billApi } from '@/api/bill'
import { pushRuleApi } from '@/api/state'
import type { PushRule } from '@/types/bo'

const props = defineProps<{
  modelValue: boolean
  srcBoCode: string
  srcBillId: string | number
}>()

const emit = defineEmits<{
  'update:modelValue': [val: boolean]
}>()

const router = useRouter()

const visible = computed({
  get: () => props.modelValue,
  set: (v: boolean) => emit('update:modelValue', v)
})

// 步骤
const step = ref<'selectRule' | 'selectLines'>('selectRule')
const loading = ref(false)
const billLoading = ref(false)

// 规则
const rules = ref<PushRule[]>([])
const selectedRule = ref<PushRule | null>(null)

// 源单数据
const sourceLines = ref<any[]>([])
const selectedLines = ref<any[]>([])
const lineTableRef = ref<any>(null)

// 计算属性
const isMainScope = computed(() => selectedRule.value?.qty_field_scope === 'main')

// 子表明细的展示列（取前几个非系统字段）
const lineDisplayColumns = computed(() => {
  if (!sourceLines.value.length) return []
  const row = sourceLines.value[0]
  const skipKeys = new Set(['id', 'parent_id', 'sort_index', 'is_system', 'create_by', 'create_time', 'update_by', 'update_time'])
  const cols: { prop: string; label: string; width?: number }[] = []
  for (const key of Object.keys(row)) {
    if (skipKeys.has(key)) continue
    if (selectedRule.value?.qty_field === key || selectedRule.value?.pushed_field === key) continue
    cols.push({ prop: key, label: key, width: 100 })
    if (cols.length >= 5) break
  }
  return cols
})

const selectedLineIds = computed(() => selectedLines.value.map((r: any) => String(r.id)))

const canPush = computed(() => {
  if (isMainScope.value) return true // main scope 直接下推
  return selectedLines.value.length > 0
})

// 方法
async function onOpen() {
  step.value = 'selectRule'
  selectedRule.value = null
  sourceLines.value = []
  selectedLines.value = []
  await loadRules()
}

function onClosed() {
  step.value = 'selectRule'
  selectedRule.value = null
  sourceLines.value = []
  selectedLines.value = []
}

async function loadRules() {
  loading.value = true
  try {
    const res: any = await pushRuleApi.list({ srcBoCode: props.srcBoCode })
    const all = Array.isArray(res) ? res : res?.list || []
    rules.value = all.filter((r: PushRule) => r.is_enable === 1)
    if (rules.value.length === 1) {
      onSelectRule(rules.value[0])
    }
  } catch {
    rules.value = []
  } finally {
    loading.value = false
  }
}

async function onSelectRule(rule: PushRule) {
  selectedRule.value = rule
  if (isMainScope.value) {
    // main scope：无需选行，直接下推
    doPush([])
    return
  }
  step.value = 'selectLines'
  await loadSourceLines()
}

function backToRuleSelect() {
  step.value = 'selectRule'
  selectedRule.value = null
  sourceLines.value = []
  selectedLines.value = []
}

async function loadSourceLines() {
  if (!props.srcBillId) return
  billLoading.value = true
  try {
    const raw = await billApi.detail(props.srcBoCode, String(props.srcBillId))
    const subs = raw?.subs || {}
    const allLines: any[] = []
    for (const entityCode of Object.keys(subs)) {
      const rows = subs[entityCode]
      if (Array.isArray(rows)) {
        for (const row of rows) {
          allLines.push({ ...row, _entity_code: entityCode })
        }
      }
    }
    sourceLines.value = allLines
    // 默认全选
    selectedLines.value = [...allLines]
  } catch {
    ElMessage.error('加载源单据失败')
  } finally {
    billLoading.value = false
  }
}

function onSelectionChange(sel: any[]) {
  selectedLines.value = sel
}

function selectAllLines() {
  if (lineTableRef.value) {
    lineTableRef.value.toggleAllSelection?.()
  } else {
    selectedLines.value = [...sourceLines.value]
  }
}

function clearSelection() {
  if (lineTableRef.value) {
    lineTableRef.value.clearSelection?.()
  } else {
    selectedLines.value = []
  }
}

function onConfirm() {
  if (!isMainScope.value && selectedLineIds.value.length === 0) {
    ElMessage.warning('请选择要下推的明细行')
    return
  }
  doPush(selectedLineIds.value)
}

/** 下推转换：打开目标单据新建页，加载转换后的内存数据 */
function doPush(lineIds: string[]) {
  if (!selectedRule.value) return
  const rule = selectedRule.value
  const tgtBoCode = rule.tgt_bo_code

  // 构建目标单据新建页 URL，带下推参数
  const query: Record<string, string> = {
    pushFrom: props.srcBoCode,
    pushFromId: String(props.srcBillId),
    pushRule: rule.rule_code
  }
  if (lineIds.length > 0) {
    query.pushLineIds = lineIds.join(',')
  }

  // 在新标签页打开目标单据新建页
  const route = router.resolve({ path: `/bill/${tgtBoCode}/new`, query })
  window.open(route.href, '_blank')

  visible.value = false
  ElMessage.success(`正在打开目标单据 [${tgtBoCode}]，请在目标单据中确认数据后保存`)
}
</script>

<style scoped lang="scss">
.rule-info-bar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 12px;
  background: #f5f7fa;
  border-radius: 4px;
  margin-bottom: 12px;
  font-size: 13px;
  .info-item {
    color: #606266;
    b {
      color: #303133;
    }
  }
}
.convert-tip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: #ecf5ff;
  border-radius: 4px;
  margin-bottom: 12px;
  font-size: 12px;
  color: #409eff;
  .el-icon {
    font-size: 14px;
  }
}
.sub-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  .selection-tip {
    font-size: 12px;
    color: #909399;
  }
}
</style>
