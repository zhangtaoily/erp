<template>
  <div class="relation-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">当前业务对象：</span>
        <BoPicker v-model="boCode" style="width:280px" @change="onBoChange" />
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body panel-card">
      <el-tabs v-model="activeTab">
        <!-- 关系图 -->
        <el-tab-pane label="关系图" name="graph">
          <div v-if="!boCode" class="empty-tip">
            <el-empty description="请选择业务对象" :image-size="80" />
          </div>
          <div v-else class="graph-wrap">
            <div ref="graphRef" class="graph-container"></div>
            <div class="graph-legend">
              <span class="legend-item"><span class="dot center"></span>当前对象</span>
              <span class="legend-item"><span class="dot ref"></span>被引用对象</span>
              <span class="legend-item"><span class="dot push"></span>下推目标对象</span>
            </div>
          </div>
        </el-tab-pane>

        <!-- 引用关系 -->
        <el-tab-pane label="引用关系" name="refs">
          <el-table :data="refRelations" size="small" border stripe>
            <el-table-column prop="entity_name" label="实体" width="140" />
            <el-table-column prop="field_code" label="字段编码" width="140" />
            <el-table-column prop="field_name" label="字段名称" width="120" />
            <el-table-column label="引用对象" width="140">
              <template #default="{ row }">
                <el-tag size="small" type="success">{{ row.ref_bo_code }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="ref_bo_name" label="引用对象名称" min-width="120" />
            <el-table-column label="操作" width="100" align="center">
              <template #default="{ row }">
                <el-button link type="primary" size="small" @click="goToEntityModel(row.ref_bo_code)">查看</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 下推规则 -->
        <el-tab-pane label="下推规则" name="push">
          <div class="push-toolbar">
            <span class="panel-title">下推规则列表</span>
            <el-button type="primary" size="small" @click="goToPushRule">配置下推规则</el-button>
          </div>
          <el-table :data="pushRules" size="small" border stripe>
            <el-table-column prop="rule_code" label="规则编码" width="140" />
            <el-table-column prop="rule_name" label="规则名称" min-width="160" />
            <el-table-column label="源→目标" width="200">
              <template #default="{ row }">
                <span>{{ row.src_bo_code }}</span>
                <el-icon class="arrow"><Right /></el-icon>
                <span>{{ row.target_bo_code }}</span>
              </template>
            </el-table-column>
            <el-table-column label="允许合并" width="80" align="center">
              <template #default="{ row }">
                <el-tag :type="row.allow_merge ? 'success' : 'info'" size="small">{{ row.allow_merge ? '是' : '否' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="允许拆分" width="80" align="center">
              <template #default="{ row }">
                <el-tag :type="row.allow_split ? 'success' : 'info'" size="small">{{ row.allow_split ? '是' : '否' }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { Graph, Shape } from '@antv/x6'
import { Right } from '@element-plus/icons-vue'
import { boApi, entityApi } from '@/api/bo'
import { pushRuleApi } from '@/api/state'
import BoPicker from '@/components/BoPicker/index.vue'
import type { BusinessObject, FormEntity, FormField, PushRule } from '@/types/bo'

const router = useRouter()
const boCode = ref('')
const activeTab = ref('graph')
const graphRef = ref<HTMLElement>()
let graph: Graph | null = null

const allBoList = ref<BusinessObject[]>([])
const entities = ref<FormEntity[]>([])
const pushRules = ref<PushRule[]>([])
const refRelations = ref<any[]>([])

async function onBoChange(bo: BusinessObject | null) {
  if (!bo) return
  await loadData(bo.bo_code)
}

async function loadData(code: string) {
  // 加载实体
  entities.value = await entityApi.list(code) || []
  // 加载下推规则（当前BO为源）
  pushRules.value = await pushRuleApi.list({ src_bo_code: code }) || []
  // 构建引用关系
  buildRefRelations()
  // 渲染关系图
  await nextTick()
  renderGraph()
}

function buildRefRelations() {
  const refs: any[] = []
  const boMap = new Map(allBoList.value.map(b => [b.bo_code, b]))
  entities.value.forEach(entity => {
    entity.fields?.forEach(field => {
      if (field.ref_bo_code && field.ref_bo_code !== boCode.value) {
        const refBo = boMap.get(field.ref_bo_code)
        refs.push({
          entity_name: entity.entity_name,
          field_code: field.field_code,
          field_name: field.field_name,
          ref_bo_code: field.ref_bo_code,
          ref_bo_name: refBo?.bo_name || field.ref_bo_code
        })
      }
    })
  })
  refRelations.value = refs
}

function renderGraph() {
  if (!graphRef.value) return
  if (graph) {
    graph.dispose()
    graph = null
  }

  graph = new Graph({
    container: graphRef.value,
    background: { color: '#fafafa' },
    grid: { visible: true, size: 10, type: 'dot' },
    interacting: false,
    panning: true,
    mousewheel: true
  })

  const boMap = new Map(allBoList.value.map(b => [b.bo_code, b]))
  const currentBo = boMap.get(boCode.value)

  // 当前节点居中
  const centerX = 400
  const centerY = 200
  const nodeWidth = 140
  const nodeHeight = 50

  graph.addNode({
    shape: 'rect',
    x: centerX - nodeWidth / 2,
    y: centerY - nodeHeight / 2,
    width: nodeWidth,
    height: nodeHeight,
    attrs: {
      body: { fill: '#1564ff', stroke: '#1564ff', rx: 6, ry: 6 },
      label: { text: currentBo?.bo_name || boCode.value, fill: '#fff', fontSize: 13, fontWeight: 'bold' }
    },
    data: { boCode: boCode.value }
  })

  // 被引用对象（左侧）
  const refBoCodes = new Set<string>()
  refRelations.value.forEach(r => refBoCodes.add(r.ref_bo_code))

  const refBoList = [...refBoCodes].map(code => boMap.get(code)).filter(Boolean) as BusinessObject[]
  refBoList.forEach((bo, idx) => {
    const x = 80
    const y = 60 + idx * 80
    graph!.addNode({
      shape: 'rect',
      x, y,
      width: nodeWidth,
      height: nodeHeight,
      attrs: {
        body: { fill: '#f0f9eb', stroke: '#67c23a', rx: 6, ry: 6 },
        label: { text: bo.bo_name, fill: '#333', fontSize: 12 }
      },
      data: { boCode: bo.bo_code }
    })
    // 连线：引用对象 → 当前对象
    graph!.addEdge({
      source: { x: x + nodeWidth, y: y + nodeHeight / 2 },
      target: { x: centerX - nodeWidth / 2, y: centerY },
      attrs: {
        line: { stroke: '#67c23a', strokeWidth: 1.5, targetMarker: { name: 'block', width: 8, height: 6 } }
      },
      labels: [{ position: 0.5, attrs: { label: { text: '引用', fill: '#67c23a', fontSize: 10 } } }]
    })
  })

  // 下推目标对象（右侧）
  pushRules.value.forEach((rule, idx) => {
    const targetBo = boMap.get(rule.target_bo_code)
    const x = 680
    const y = 60 + idx * 80
    graph!.addNode({
      shape: 'rect',
      x, y,
      width: nodeWidth,
      height: nodeHeight,
      attrs: {
        body: { fill: '#fdf6ec', stroke: '#e6a23c', rx: 6, ry: 6 },
        label: { text: targetBo?.bo_name || rule.target_bo_code, fill: '#333', fontSize: 12 }
      },
      data: { boCode: rule.target_bo_code }
    })
    // 连线：当前对象 → 下推目标
    graph!.addEdge({
      source: { x: centerX + nodeWidth / 2, y: centerY },
      target: { x: x, y: y + nodeHeight / 2 },
      attrs: {
        line: { stroke: '#e6a23c', strokeWidth: 1.5, targetMarker: { name: 'block', width: 8, height: 6 } }
      },
      labels: [{ position: 0.5, attrs: { label: { text: '下推', fill: '#e6a23c', fontSize: 10 } } }]
    })
  })

  // 节点双击跳转
  graph.on('node:dblclick', ({ node }) => {
    const code = node.getData()?.boCode
    if (code && code !== boCode.value) {
      goToEntityModel(code)
    }
  })

  graph.zoomToFit({ padding: 20, maxScale: 1.5 })
}

function goToEntityModel(code: string) {
  router.push({ path: '/bos/entity-model', query: { boCode: code } })
}

function goToPushRule() {
  router.push('/bos/push-rule')
}

onMounted(async () => {
  // 加载所有业务对象（用于名称查找）
  const res: any = await boApi.list({ pageSize: 200 })
  allBoList.value = res?.list || res || []
})
</script>

<style scoped lang="scss">
.relation-page {
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
  padding: 10px 16px;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.header-label { font-size: 13px; font-weight: 600; white-space: nowrap; }
.main-body {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
}
.empty-tip {
  display: flex;
  justify-content: center;
  padding: 60px 0;
}
.graph-wrap {
  position: relative;
  height: 500px;
}
.graph-container {
  width: 100%;
  height: 100%;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
}
.graph-legend {
  position: absolute;
  bottom: 12px;
  left: 12px;
  display: flex;
  gap: 16px;
  background: rgba(255, 255, 255, 0.9);
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 4px;
}
.dot {
  width: 10px;
  height: 10px;
  border-radius: 2px;
  display: inline-block;
}
.dot.center { background: #1564ff; }
.dot.ref { background: #67c23a; }
.dot.push { background: #e6a23c; }
.push-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.panel-title { font-size: 14px; font-weight: 600; }
.arrow {
  margin: 0 4px;
  color: #1564ff;
}
</style>
