<template>
  <div class="expression-editor">
    <div class="editor-main">
      <div class="editor-wrapper" :style="{ height: typeof height === 'number' ? height + 'px' : height }">
        <vue-monaco-editor
          v-if="!useFallback"
          :value="modelValue || ''"
          language="bos-expr"
          theme="bos-expr-theme"
          :height="height"
          :options="editorOptions"
          @before-mount="onBeforeMount"
          @mount="onMount"
          @change="onChange"
          @validate="onValidate"
        />
        <el-input
          v-else
          :model-value="modelValue"
          type="textarea"
          :rows="Math.max(4, Math.floor(Number(height) / 24))"
          placeholder="请输入表达式，例如：SUM(F.qty * F.price) > 1000 AND F.cust_id != ''"
          @update:model-value="onTextareaInput"
          style="height: 100%"
        />
        <div v-if="loadFailed && !useFallback" class="editor-loading">
          <el-icon class="is-loading"><Loading /></el-icon>
          <span>Monaco 加载中...</span>
        </div>
      </div>
      <div v-if="useFallback" class="fallback-tip">
        <el-icon><WarningFilled /></el-icon>
        <span>Monaco 加载失败，已降级为文本输入</span>
        <el-button link type="primary" size="small" @click="retryMonaco">重试</el-button>
      </div>
    </div>

    <div class="helper-panel">
      <div class="helper-tabs">
        <div
          class="helper-tab"
          :class="{ active: helperTab === 'func' }"
          @click="helperTab = 'func'"
        >
          函数
        </div>
        <div
          class="helper-tab"
          :class="{ active: helperTab === 'field' }"
          @click="helperTab = 'field'"
        >
          字段
        </div>
        <div
          class="helper-tab"
          :class="{ active: helperTab === 'op' }"
          @click="helperTab = 'op'"
        >
          运算符
        </div>
      </div>
      <div class="helper-content">
        <div v-if="helperTab === 'func'" class="helper-list">
          <div
            v-for="fn in FUNCTIONS"
            :key="fn.name"
            class="helper-item"
            @click="insertText(fn.signature)"
          >
            <div class="item-head">
              <span class="item-name">{{ fn.name }}</span>
              <span class="item-sig">{{ fn.signature }}</span>
            </div>
            <div class="item-desc">{{ fn.desc }}</div>
          </div>
        </div>
        <div v-else-if="helperTab === 'field'" class="helper-list">
          <!-- 反写模式：双 BO 字段分组 -->
          <template v-if="writebackMode">
            <div class="field-group-title">源单字段（src.）{{ srcBoCode ? `· ${srcBoCode}` : '' }}</div>
            <div v-if="srcFields.length === 0" class="empty-tip">未加载源单字段，请选择下游单据</div>
            <div
              v-for="f in srcFields"
              :key="'src-' + f.field_code"
              class="helper-item"
              @click="insertText('src.' + f.field_code)"
            >
              <div class="item-head">
                <span class="item-name">src.{{ f.field_code }}</span>
                <el-tag size="small" effect="plain" type="info">{{ f.field_type }}</el-tag>
              </div>
              <div class="item-desc">{{ f.field_name }}</div>
            </div>
            <div class="field-group-title">目标单字段（target.）{{ targetBoCode ? `· ${targetBoCode}` : '' }}</div>
            <div v-if="targetFields.length === 0" class="empty-tip">未加载目标单字段，请选择上游单据</div>
            <div
              v-for="f in targetFields"
              :key="'target-' + f.field_code"
              class="helper-item"
              @click="insertText('target.' + f.field_code)"
            >
              <div class="item-head">
                <span class="item-name">target.{{ f.field_code }}</span>
                <el-tag size="small" effect="plain" type="info">{{ f.field_type }}</el-tag>
              </div>
              <div class="item-desc">{{ f.field_name }}</div>
            </div>
          </template>
          <!-- 普通模式：F. 字段 -->
          <template v-else>
            <div v-if="fields.length === 0" class="empty-tip">未加载到字段，请传入 boCode</div>
            <div
              v-for="f in fields"
              :key="f.field_code"
              class="helper-item"
              @click="insertText('F.' + f.field_code)"
            >
              <div class="item-head">
                <span class="item-name">F.{{ f.field_code }}</span>
                <el-tag size="small" effect="plain" type="info">{{ f.field_type }}</el-tag>
              </div>
              <div class="item-desc">{{ f.field_name }}</div>
            </div>
          </template>
        </div>
        <div v-else class="helper-list">
          <div
            v-for="op in OPERATORS"
            :key="op.symbol"
            class="helper-item op-item"
            @click="insertText(' ' + op.symbol + ' ')"
          >
            <span class="op-symbol">{{ op.symbol }}</span>
            <span class="op-desc">{{ op.desc }}</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="validateResult" class="validate-bar" :class="validateResult.valid ? 'valid' : 'invalid'">
      <el-icon><CircleCheck v-if="validateResult.valid" /><CircleClose v-else /></el-icon>
      <span>{{ validateResult.valid ? '语法校验通过' : validateResult.error }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, shallowRef, onMounted, watch } from 'vue'
import { VueMonacoEditor, loader } from '@guolao/vue-monaco-editor'
import * as monaco from 'monaco-editor'
import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'
import { entityApi } from '@/api/bo'
import type { FormField } from '@/types/bo'

// 使用本地 monaco-editor 包，避免从 CDN 加载失败导致"加载中"永久卡住
;(window as any).MonacoEnvironment = {
  getWorker: () => new editorWorker()
}
loader.config({ monaco })

const props = withDefaults(
  defineProps<{
    modelValue?: string
    height?: number | string
    boCode?: string
    /** 反写模式：启用 src./target. 双 BO 字段补全 */
    writebackMode?: boolean
    /** 反写模式源单 BO 编码（下游单据） */
    srcBoCode?: string
    /** 反写模式目标单 BO 编码（上游单据） */
    targetBoCode?: string
  }>(),
  { modelValue: '', height: 200, boCode: '', writebackMode: false, srcBoCode: '', targetBoCode: '' }
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'validate', result: { valid: boolean; error?: string }): void
}>()

const editorOptions = {
  minimap: { enabled: false },
  fontSize: 13,
  lineNumbers: 'on' as const,
  scrollBeyondLastLine: false,
  automaticLayout: true,
  tabSize: 2,
  wordWrap: 'on' as const,
  padding: { top: 6, bottom: 6 }
}

// 函数定义
const FUNCTIONS = [
  { name: 'SUM', signature: 'SUM(field)', desc: '求和' },
  { name: 'AVG', signature: 'AVG(field)', desc: '平均值' },
  { name: 'COUNT', signature: 'COUNT()', desc: '计数' },
  { name: 'MAX', signature: 'MAX(field)', desc: '最大值' },
  { name: 'MIN', signature: 'MIN(field)', desc: '最小值' },
  { name: 'LOOKUP', signature: 'LOOKUP(bo_code, filter, field)', desc: '基础资料反查' },
  { name: 'NOW', signature: 'NOW()', desc: '当前日期时间' },
  { name: 'TODAY', signature: 'TODAY()', desc: '当前日期' },
  { name: 'ROUND', signature: 'ROUND(num, digits)', desc: '四舍五入' },
  { name: 'ABS', signature: 'ABS(num)', desc: '绝对值' },
  { name: 'CONCAT', signature: 'CONCAT(str1, str2, ...)', desc: '字符串拼接' }
]

const OPERATORS = [
  { symbol: '+', desc: '加' },
  { symbol: '-', desc: '减' },
  { symbol: '*', desc: '乘' },
  { symbol: '/', desc: '除' },
  { symbol: '%', desc: '取模' },
  { symbol: '>', desc: '大于' },
  { symbol: '<', desc: '小于' },
  { symbol: '>=', desc: '大于等于' },
  { symbol: '<=', desc: '小于等于' },
  { symbol: '==', desc: '等于' },
  { symbol: '!=', desc: '不等于' },
  { symbol: 'AND', desc: '逻辑与' },
  { symbol: 'OR', desc: '逻辑或' },
  { symbol: 'NOT', desc: '逻辑非' }
]

const fields = ref<FormField[]>([])
const srcFields = ref<FormField[]>([])
const targetFields = ref<FormField[]>([])
const helperTab = ref<'func' | 'field' | 'op'>('func')
const editorRef = shallowRef<any>(null)
const monacoRef = shallowRef<any>(null)
const useFallback = ref(false)
const loadFailed = ref(false)
const validateResult = ref<{ valid: boolean; error?: string } | null>(null)

let mountedTimer: any = null
let languageRegistered = false

function registerLanguage(monaco: any) {
  if (languageRegistered) return
  languageRegistered = true

  // 注册语言
  if (!monaco.languages.getLanguages().some((l: any) => l.id === 'bos-expr')) {
    monaco.languages.register({ id: 'bos-expr' })
  }

  // Tokenizer
  monaco.languages.setMonarchTokensProvider('bos-expr', {
    defaultToken: '',
    tokenPostfix: '.expr',
    ignoreCase: false,
    keywords: ['AND', 'OR', 'NOT', 'TRUE', 'FALSE', 'NULL', 'ON', 'CHANGE', 'FOR', 'EACH', 'ERROR', 'REJECT', 'IN'],
    operators: [
      '+', '-', '*', '/', '%', '>', '<', '>=', '<=', '==', '!=', '=', '(', ')', ',', '.', '=>'
    ],
    tokenizer: {
      root: [
        [/\s+/, 'white'],
        [/\b(src|target|S|T|F)\.[a-zA-Z_]\w*/, 'variable.field'],
        [/[A-Z_][A-Z_0-9]*(?=\s*\()/, 'keyword.function'],
        [/\b(SUM|AVG|COUNT|MAX|MIN|LOOKUP|NOW|TODAY|ROUND|ABS|CONCAT)\b/, 'keyword.function'],
        [/\b(AND|OR|NOT|TRUE|FALSE|NULL|ON|CHANGE|FOR|EACH|ERROR|REJECT|IN)\b/, 'keyword'],
        [/".*?"/, 'string'],
        [/'[^']*'/, 'string'],
        [/\d+\.\d+/, 'number.float'],
        [/\d+/, 'number'],
        [/=>/, 'operator'],
        [/[<>=!]=?/, 'operator'],
        [/[+\-*/%]/, 'operator'],
        [/[(),.]/, 'delimiter'],
        [/[a-zA-Z_]\w*/, 'identifier']
      ]
    }
  })

  // 主题
  monaco.editor.defineTheme('bos-expr-theme', {
    base: 'vs',
    inherit: true,
    rules: [
      { token: 'variable.field', foreground: '1564ff' },
      { token: 'keyword.function', foreground: '722ed1', fontStyle: 'bold' },
      { token: 'keyword', foreground: 'c41d7f' },
      { token: 'number', foreground: 'fa8c16' },
      { token: 'number.float', foreground: 'fa8c16' },
      { token: 'string', foreground: '52c41a' },
      { token: 'operator', foreground: '595959' }
    ],
    colors: {}
  })

  // 补全
  monaco.languages.registerCompletionItemProvider('bos-expr', {
    triggerCharacters: ['F', '.', ' ', 's', 't', 'S', 'T'],
    provideCompletionItems: (model: any, position: any) => {
      const word = model.getWordUntilPosition(position)
      const range = {
        startLineNumber: position.lineNumber,
        endLineNumber: position.lineNumber,
        startColumn: word.startColumn,
        endColumn: word.endColumn
      }
      // 取光标前的文本以判定前缀
      const lineText = model.getLineContent(position.lineNumber) || ''
      const textBefore = lineText.slice(0, position.column - 1)
      const prefixMatch = textBefore.match(/(src|target|F|S|T)\.$/)
      const fnSuggestions = FUNCTIONS.map(fn => ({
        label: fn.name,
        kind: monaco.languages.CompletionItemKind.Function,
        insertText: `${fn.name}(${fn.signature.match(/\(([^)]*)\)/)?.[1] || ''})`,
        insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
        detail: fn.desc,
        documentation: fn.signature,
        range
      }))
      const opSuggestions = OPERATORS.map(op => ({
        label: op.symbol,
        kind: monaco.languages.CompletionItemKind.Operator,
        insertText: op.symbol,
        detail: op.desc,
        range
      }))
      // 默认 F. 字段（实体服务规则场景）
      const fFieldSuggestions = fields.value.map(f => ({
        label: `F.${f.field_code}`,
        kind: monaco.languages.CompletionItemKind.Field,
        insertText: `F.${f.field_code}`,
        detail: f.field_name,
        documentation: `${f.field_name} (${f.field_type})`,
        range
      }))
      // 反写场景：src./target. 双 BO 字段
      const srcFieldSuggestions = srcFields.value.map(f => ({
        label: `src.${f.field_code}`,
        kind: monaco.languages.CompletionItemKind.Field,
        insertText: `src.${f.field_code}`,
        detail: `[源] ${f.field_name}`,
        documentation: `[源单字段] ${f.field_name} (${f.field_type})`,
        range
      }))
      const targetFieldSuggestions = targetFields.value.map(f => ({
        label: `target.${f.field_code}`,
        kind: monaco.languages.CompletionItemKind.Field,
        insertText: `target.${f.field_code}`,
        detail: `[目标] ${f.field_name}`,
        documentation: `[目标单字段] ${f.field_name} (${f.field_type})`,
        range
      }))
      // 按前缀过滤
      if (prefixMatch) {
        const p = prefixMatch[1]
        if (p === 'src') return { suggestions: srcFieldSuggestions }
        if (p === 'target') return { suggestions: targetFieldSuggestions }
        if (p === 'F') return { suggestions: fFieldSuggestions }
        // S./T. 作为 src./target. 的简写也支持
        if (p === 'S') return { suggestions: srcFieldSuggestions }
        if (p === 'T') return { suggestions: targetFieldSuggestions }
      }
      // 反写模式下默认同时展示 src/target 字段（无前缀时）
      if (props.writebackMode) {
        return { suggestions: [...fnSuggestions, ...srcFieldSuggestions, ...targetFieldSuggestions, ...opSuggestions] }
      }
      return { suggestions: [...fnSuggestions, ...fFieldSuggestions, ...opSuggestions] }
    }
  })

  // 悬停
  monaco.languages.registerHoverProvider('bos-expr', {
    provideHover: (model: any, position: any) => {
      const word = model.getWordAtPosition(position)
      if (!word) return null
      const fn = FUNCTIONS.find(f => f.name === word.word)
      if (fn) {
        return {
          range: new monaco.Range(
            position.lineNumber,
            word.startColumn,
            position.lineNumber,
            word.endColumn
          ),
          contents: [{ value: `**${fn.signature}**\n\n${fn.desc}` }]
        }
      }
      return null
    }
  })
}

function onBeforeMount(monaco: any) {
  monacoRef.value = monaco
  registerLanguage(monaco)
}

function onMount(editor: any, monaco: any) {
  editorRef.value = editor
  monacoRef.value = monaco
  loadFailed.value = false
  if (mountedTimer) {
    clearTimeout(mountedTimer)
    mountedTimer = null
  }
  // 初始校验
  doValidate(props.modelValue)
}

function onChange(value: string | undefined) {
  const v = value || ''
  emit('update:modelValue', v)
  doValidate(v)
}

function onValidate(_markers: any[]) {
  // Monaco 自带语法标记（用于额外参考）
}

function onTextareaInput(v: string) {
  emit('update:modelValue', v)
  doValidate(v)
}

// 简化语法预校验：括号匹配 + ON...CHANGE / FOR EACH / ERROR 关键结构识别
function doValidate(expr: string) {
  if (!expr) {
    validateResult.value = null
    emit('validate', { valid: true })
    return
  }
  // 1. 字符串剥离后做括号匹配
  let stack = 0
  let inString: string | null = null
  for (let i = 0; i < expr.length; i++) {
    const ch = expr[i]
    if (inString) {
      if (ch === inString) inString = null
      continue
    }
    if (ch === '"' || ch === "'") {
      inString = ch
      continue
    }
    if (ch === '(') stack++
    else if (ch === ')') {
      stack--
      if (stack < 0) {
        const err = `位置 ${i + 1}：多余的右括号 ')'`
        validateResult.value = { valid: false, error: err }
        emit('validate', { valid: false, error: err })
        return
      }
    }
  }
  if (stack > 0) {
    const err = `缺少 ${stack} 个右括号 ')'`
    validateResult.value = { valid: false, error: err }
    emit('validate', { valid: false, error: err })
    return
  }
  // 2. ON...CHANGE 触发事件结构识别（linkage 规则常用）
  const upper = expr.toUpperCase()
  if (/\bON\b/.test(upper)) {
    if (!/\bCHANGE\b/.test(upper)) {
      const err = '缺少 ON...CHANGE 触发事件，请补全 CHANGE 关键字'
      validateResult.value = { valid: false, error: err }
      emit('validate', { valid: false, error: err })
      return
    }
    const onIdx = upper.indexOf('ON')
    const changeIdx = upper.indexOf('CHANGE', onIdx)
    if (changeIdx < 0 || changeIdx <= onIdx) {
      const err = 'ON...CHANGE 结构不完整'
      validateResult.value = { valid: false, error: err }
      emit('validate', { valid: false, error: err })
      return
    }
  }
  // 3. FOR EACH 子表遍历结构识别
  if (/\bFOR\b/.test(upper)) {
    if (!/\bEACH\b/.test(upper)) {
      const err = '缺少 FOR EACH 子句，请补全 EACH 关键字'
      validateResult.value = { valid: false, error: err }
      emit('validate', { valid: false, error: err })
      return
    }
  }
  // 4. ERROR 关键字必须出现在条件之后（不能单独作为开头）
  if (/\bERROR\b/.test(upper)) {
    const errIdx = upper.indexOf('ERROR')
    const before = expr.slice(0, errIdx).trim()
    if (!before) {
      const err = 'ERROR 必须在条件后，不能作为表达式开头'
      validateResult.value = { valid: false, error: err }
      emit('validate', { valid: false, error: err })
      return
    }
  }
  validateResult.value = { valid: true }
  emit('validate', { valid: true })
}

function insertText(text: string) {
  if (useFallback.value) {
    const v = (props.modelValue || '') + text
    emit('update:modelValue', v)
    doValidate(v)
    return
  }
  const editor = editorRef.value
  if (!editor) return
  const selection = editor.getSelection()
  editor.executeEdits('helper', [
    {
      range: selection,
      text,
      forceMoveMarkers: true
    }
  ])
  editor.focus()
}

async function loadFields() {
  if (!props.boCode) return
  try {
    const entities = await entityApi.list(props.boCode)
    const allFields: FormField[] = []
    ;(entities || []).forEach((e: any) => {
      if (e.fields?.length) allFields.push(...e.fields)
    })
    fields.value = allFields
  } catch (e) {
    fields.value = []
  }
}

async function loadSrcFields() {
  if (!props.srcBoCode) {
    srcFields.value = []
    return
  }
  try {
    const entities = await entityApi.list(props.srcBoCode)
    const allFields: FormField[] = []
    ;(entities || []).forEach((e: any) => {
      if (e.fields?.length) allFields.push(...e.fields)
    })
    srcFields.value = allFields
  } catch (e) {
    srcFields.value = []
  }
}

async function loadTargetFields() {
  if (!props.targetBoCode) {
    targetFields.value = []
    return
  }
  try {
    const entities = await entityApi.list(props.targetBoCode)
    const allFields: FormField[] = []
    ;(entities || []).forEach((e: any) => {
      if (e.fields?.length) allFields.push(...e.fields)
    })
    targetFields.value = allFields
  } catch (e) {
    targetFields.value = []
  }
}

function retryMonaco() {
  useFallback.value = false
  loadFailed.value = true
  mountedTimer = setTimeout(() => {
    if (!editorRef.value) {
      useFallback.value = true
      loadFailed.value = false
    }
  }, 8000)
}

watch(() => props.boCode, loadFields, { immediate: false })
watch(() => props.srcBoCode, loadSrcFields, { immediate: false })
watch(() => props.targetBoCode, loadTargetFields, { immediate: false })

onMounted(() => {
  loadFields()
  if (props.writebackMode) {
    loadSrcFields()
    loadTargetFields()
  }
  // Monaco 默认通过 @monaco-editor/loader 从 CDN 加载；
  // 若 8s 内未挂载成功（如离线环境），降级为 textarea
  loadFailed.value = true
  mountedTimer = setTimeout(() => {
    if (!editorRef.value) {
      useFallback.value = true
      loadFailed.value = false
    }
  }, 8000)
})
</script>

<style scoped lang="scss">
.expression-editor {
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  background: #fff;
  overflow: hidden;
}
.editor-main {
  display: flex;
  flex-direction: column;
}
.editor-wrapper {
  position: relative;
  border-bottom: 1px solid #f0f0f0;
}
.editor-loading {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.85);
  color: #909399;
  font-size: 13px;
}
.fallback-tip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #fff7e6;
  color: #fa8c16;
  font-size: 12px;
}
.helper-panel {
  display: flex;
  flex-direction: column;
  max-height: 200px;
}
.helper-tabs {
  display: flex;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
}
.helper-tab {
  padding: 6px 16px;
  cursor: pointer;
  font-size: 12px;
  color: #606266;
  border-right: 1px solid #f0f0f0;
  transition: all 0.15s;
}
.helper-tab:hover {
  color: #1564ff;
}
.helper-tab.active {
  color: #1564ff;
  background: #fff;
  font-weight: 600;
  border-bottom: 2px solid #1564ff;
}
.helper-content {
  flex: 1;
  overflow: auto;
  padding: 4px;
}
.helper-list {
  display: flex;
  flex-direction: column;
}
.helper-item {
  padding: 6px 8px;
  cursor: pointer;
  border-radius: 3px;
  transition: background 0.15s;
}
.helper-item:hover {
  background: #f0f7ff;
}
.item-head {
  display: flex;
  align-items: center;
  gap: 8px;
}
.item-name {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 12px;
  color: #1564ff;
  font-weight: 600;
}
.item-sig {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 11px;
  color: #909399;
}
.item-desc {
  font-size: 12px;
  color: #606266;
  margin-top: 2px;
}
.op-item {
  display: flex;
  align-items: center;
  gap: 12px;
}
.op-symbol {
  font-family: 'Consolas', 'Monaco', monospace;
  font-weight: 700;
  color: #722ed1;
  width: 40px;
}
.op-desc {
  color: #606266;
  font-size: 12px;
}
.empty-tip {
  padding: 16px;
  text-align: center;
  color: #c0c4cc;
  font-size: 12px;
}
.field-group-title {
  padding: 6px 8px 4px;
  font-size: 12px;
  font-weight: 600;
  color: #303133;
  background: #fafafa;
  border-top: 1px solid #f0f0f0;
  border-bottom: 1px solid #f0f0f0;
  position: sticky;
  top: 0;
  z-index: 1;
}
.field-group-title:first-child {
  border-top: none;
}
.validate-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  font-size: 12px;
  border-top: 1px solid #f0f0f0;
}
.validate-bar.valid {
  color: #52c41a;
  background: #f6ffed;
}
.validate-bar.invalid {
  color: #f5222d;
  background: #fff1f0;
}
</style>
