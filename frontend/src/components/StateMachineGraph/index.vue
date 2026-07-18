<template>
  <div class="state-machine-graph">
    <div ref="containerRef" class="graph-container"></div>
    <div v-if="!ready" class="graph-loading">状态机图加载中...</div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { Graph, Shape } from '@antv/x6'
import type { StateNode, StateTransition } from '@/types/bo'

const props = withDefaults(defineProps<{
  states: StateNode[]
  transitions: StateTransition[]
  editable?: boolean
}>(), {
  editable: true
})

const emit = defineEmits<{
  'node-click': [state: StateNode]
  'edge-click': [transition: StateTransition]
  // 节点拖拽位置变更（GAP-D03-004 / RISK-D03-003）：父组件持久化 pos_x/pos_y
  'node-moved': [stateCode: number, pos_x: number, pos_y: number]
}>()

const containerRef = ref<HTMLElement>()
const ready = ref(false)
let graph: Graph | null = null

// 默认状态色（state_code 无 color 时回退使用，GAP-D03-005 / RISK-D03-002）
const DEFAULT_STATE_COLORS: Record<number, string> = {
  0: '#909399', // 暂存-灰
  1: '#1564ff', // 已创建-蓝
  2: '#e6a23c', // 已提交-橙
  3: '#67c23a', // 已审核-绿
  4: '#f56c6c'  // 已驳回-红
}

// 按 state_value 动态读取 node.color（GAP-D03-005 / RISK-D03-001/002）
function stateColor(state: StateNode): string {
  if (state.color) return state.color
  return DEFAULT_STATE_COLORS[state.state_code] || '#409eff'
}

function initGraph() {
  if (!containerRef.value) return

  graph = new Graph({
    container: containerRef.value,
    background: { color: '#fafafa' },
    grid: { visible: true, size: 10, type: 'dot' },
    interacting: props.editable,
    connecting: {
      router: 'orth',
      anchor: 'center',
      connectionPoint: 'anchor',
      allowBlank: false,
      allowLoop: false,
      snap: { radius: 20 },
      createEdge() {
        return new Shape.Edge({
          attrs: {
            line: { stroke: '#1564ff', strokeWidth: 1.5, targetMarker: { name: 'block', width: 8, height: 6 } }
          },
          labels: []
        })
      }
    }
  })

  renderGraph()
  ready.value = true

  graph.on('node:click', ({ node }) => {
    const stateCode = node.getData()?.stateCode
    const state = props.states.find(s => s.state_code === stateCode)
    if (state) emit('node-click', state)
  })

  graph.on('edge:click', ({ edge }) => {
    const id = edge.getData()?.id
    const t = props.transitions.find(tr => tr.id === id)
    if (t) emit('edge-click', t)
  })

  // 节点拖拽位置变更（GAP-D03-004 / RISK-D03-003）
  graph.on('node:moved', ({ node }) => {
    const stateCode = node.getData()?.stateCode
    if (stateCode === undefined) return
    const pos = node.getPosition()
    emit('node-moved', stateCode, Math.round(pos.x), Math.round(pos.y))
  })
}

function renderGraph() {
  if (!graph) return
  graph.clearCells()

  // 布局节点：优先使用持久化的 pos_x/pos_y，否则横向排列
  const nodeWidth = 110
  const nodeHeight = 50
  const gap = 80
  const startX = 40
  const startY = 60

  const nodeMap = new Map<number, any>()

  props.states.forEach((state, idx) => {
    // 持久化位置优先（GAP-D03-004）
    const hasPersistedPos = state.pos_x !== undefined && state.pos_y !== undefined
    const x = hasPersistedPos ? state.pos_x! : startX + idx * (nodeWidth + gap)
    const y = hasPersistedPos ? state.pos_y! : startY
    const color = stateColor(state) // 按 state_value 动态映射（GAP-D03-005）

    const node = graph!.addNode({
      shape: 'rect',
      x,
      y,
      width: nodeWidth,
      height: nodeHeight,
      attrs: {
        body: { fill: color, stroke: color, rx: 8, ry: 8 },
        label: { text: state.state_name, fill: '#fff', fontSize: 13, fontWeight: 'bold' }
      },
      data: { stateCode: state.state_code }
    })
    nodeMap.set(state.state_code, node)

    // is_initial / is_final 标记渲染（PRD 2.1.3 节点设计）
    if (state.is_initial || state.is_final) {
      const tagText = state.is_initial ? '初始' : '终态'
      graph!.addNode({
        shape: 'rect',
        x: x + nodeWidth - 30,
        y: y - 14,
        width: 28,
        height: 16,
        attrs: {
          body: { fill: '#fff', stroke: color, rx: 8, ry: 8, strokeWidth: 1 },
          label: { text: tagText, fill: color, fontSize: 9, fontWeight: 'bold' }
        },
        data: { stateCode: state.state_code, isTag: true }
      })
    }
  })

  // 绘制流转连线
  props.transitions.forEach(tr => {
    if (tr.to_state === -1) return // 删除操作不画线
    const source = nodeMap.get(tr.from_state)
    const target = nodeMap.get(tr.to_state)
    if (!source || !target) return

    const isSelf = tr.from_state === tr.to_state
    const edge = graph!.addEdge({
      source,
      target,
      attrs: {
        line: {
          stroke: tr.need_wf ? '#e6a23c' : '#8c8c8c',
          strokeWidth: 1.5,
          targetMarker: { name: 'block', width: 8, height: 6 }
        }
      },
      labels: [{
        position: isSelf ? 'right' : 0.5,
        attrs: {
          label: {
            text: tr.action_name,
            fill: '#595959',
            fontSize: 11,
            fillBg: '#fff'
          },
          rect: { fill: '#fff', stroke: '#d9d9d9', rx: 3, ry: 3 }
        }
      }],
      data: { id: tr.id }
    })

    // 自环特殊处理
    if (isSelf) {
      edge.setVertices([
        { x: source.getPosition().x + 130, y: source.getPosition().y + 25 },
        { x: source.getPosition().x + 130, y: source.getPosition().y + 70 },
        { x: source.getPosition().x + 55, y: source.getPosition().y + 70 }
      ])
    }
  })
}

watch(() => [props.states, props.transitions], () => {
  if (graph) renderGraph()
}, { deep: true })

onMounted(() => {
  initGraph()
  // 自适应
  setTimeout(() => graph?.resize?.(), 100)
})

onUnmounted(() => {
  graph?.dispose()
  graph = null
})

defineExpose({
  resize: () => (graph as any)?.resizeGraph?.(),
  exportData: () => graph?.toJSON()
})
</script>

<style scoped lang="scss">
.state-machine-graph {
  position: relative;
  width: 100%;
  height: 100%;
}
.graph-container {
  width: 100%;
  height: 100%;
  min-height: 300px;
}
.graph-loading {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: #909399;
}
</style>
