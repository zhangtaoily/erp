<template>
  <div class="scheme-manager">
    <div class="scheme-tabs">
      <el-radio-group v-model="activeTab" size="small">
        <el-radio-button value="mine">我的方案 ({{ mine.length }})</el-radio-button>
        <el-radio-button value="public">公共方案 ({{ pub.length }})</el-radio-button>
      </el-radio-group>
      <el-button type="primary" size="small" @click="onCreate"><el-icon><Plus /></el-icon>新建方案</el-button>
    </div>

    <div class="scheme-list">
      <div v-for="s in displayList" :key="s.id" class="scheme-card" :class="{ active: currentScheme?.id === s.id }">
        <div class="card-header">
          <div class="card-title">
            <el-icon v-if="s.is_favorite" class="fav-icon" @click="onToggleFav(s)"><StarFilled /></el-icon>
            <el-icon v-else class="fav-icon-empty" @click="onToggleFav(s)"><Star /></el-icon>
            <span class="title-text">{{ s.scheme_name }}</span>
            <el-tag v-if="s.is_default" size="small" type="success" effect="plain">默认</el-tag>
            <el-tag v-if="s.is_public" size="small" type="warning" effect="plain">公共</el-tag>
          </div>
          <el-dropdown trigger="click" @command="(cmd: string) => onCommand(cmd, s)">
            <el-icon class="more-icon"><MoreFilled /></el-icon>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="apply">应用</el-dropdown-item>
                <el-dropdown-item command="edit">编辑</el-dropdown-item>
                <el-dropdown-item command="copy">复制</el-dropdown-item>
                <el-dropdown-item command="default">设为默认</el-dropdown-item>
                <el-dropdown-item command="favorite">{{ s.is_favorite ? '取消收藏' : '收藏' }}</el-dropdown-item>
                <el-dropdown-item v-if="!s.is_public && !readonly" command="publish">发布为公共</el-dropdown-item>
                <el-dropdown-item divided command="delete" style="color:#f5222d">删除</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
        <div class="card-body">
          <div class="meta-row">
            <span class="meta-label">条件：</span>
            <span class="meta-value">{{ s.conditions.length }} 项</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">字段：</span>
            <span class="meta-value">{{ s.columns.length }} 列</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">排序：</span>
            <span class="meta-value">{{ s.order_by || '默认' }}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">分页：</span>
            <span class="meta-value">{{ s.page_size }} 条/页</span>
          </div>
        </div>
        <div class="card-conditions" v-if="s.conditions.length">
          <el-tag v-for="(c, i) in s.conditions.slice(0, 3)" :key="i" size="small" type="info" effect="plain">
            {{ fieldName(c.field_code) }} {{ opLabel(c.operator) }} {{ displayValue(c.value) }}
          </el-tag>
          <el-tag v-if="s.conditions.length > 3" size="small" type="info" effect="plain">+{{ s.conditions.length - 3 }}</el-tag>
        </div>
        <div class="card-footer">
          <el-button size="small" type="primary" @click="onApply(s)">应用</el-button>
          <el-button v-if="!readonly" size="small" @click="emit('edit', s)">编辑</el-button>
        </div>
      </div>
      <el-empty v-if="!displayList.length" description="暂无查询方案" :image-size="80" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { schemeApi } from '@/api/list'
import { QUERY_OPERATORS } from '@/utils/enum'
import type { QueryScheme } from '@/types/bo'

const props = withDefaults(defineProps<{
  boCode: string
  currentScheme?: QueryScheme | null
  readonly?: boolean
}>(), {
  currentScheme: null,
  readonly: false
})

const emit = defineEmits<{
  (e: 'apply', scheme: QueryScheme): void
  (e: 'edit', scheme: QueryScheme): void
  (e: 'delete', scheme: QueryScheme): void
  (e: 'create'): void
}>()

const schemes = ref<QueryScheme[]>([])
const activeTab = ref<'mine' | 'public'>('mine')

const mine = computed(() => schemes.value.filter(s => !s.is_public).sort((a, b) => Number(b.is_favorite) - Number(a.is_favorite)))
const pub = computed(() => schemes.value.filter(s => s.is_public))
const displayList = computed(() => activeTab.value === 'mine' ? mine.value : pub.value)

const opMap = new Map(QUERY_OPERATORS.map(o => [o.value, o.label]))
function opLabel(op: string) { return opMap.get(op) || op }
function fieldName(code: string) {
  return code // 父组件可通过 currentScheme 关联展示，这里简化为 code
}
function displayValue(v: any) {
  if (v == null) return ''
  if (Array.isArray(v)) return v.join('~')
  return String(v)
}

async function loadSchemes() {
  try {
    const res = await schemeApi.list(props.boCode)
    schemes.value = res || []
  } catch { schemes.value = [] }
}

function onApply(s: QueryScheme) { emit('apply', s) }
function onCreate() { emit('create') }

async function onToggleFav(s: QueryScheme) {
  s.is_favorite = !s.is_favorite
  try { await schemeApi.favorite(s.id, s.is_favorite) } catch {}
}

async function onCommand(cmd: string, s: QueryScheme) {
  switch (cmd) {
    case 'apply': onApply(s); break
    case 'edit': emit('edit', s); break
    case 'copy':
      emit('create')
      break
    case 'default':
      schemes.value.forEach(x => x.is_default = false)
      s.is_default = true
      try { await schemeApi.setDefault(s.id) } catch {}
      ElMessage.success('已设为默认')
      break
    case 'favorite': onToggleFav(s); break
    case 'publish':
      s.is_public = true
      try { await schemeApi.update(s.id, { is_public: true }) } catch {}
      ElMessage.success('已发布为公共方案')
      break
    case 'delete':
      await ElMessageBox.confirm(`确定删除方案「${s.scheme_name}」吗？`, '提示', { type: 'warning' })
      try { await schemeApi.delete(s.id) } catch {}
      schemes.value = schemes.value.filter(x => x.id !== s.id)
      emit('delete', s)
      ElMessage.success('删除成功')
      break
  }
}

onMounted(loadSchemes)
defineExpose({ refresh: loadSchemes })
</script>

<style scoped lang="scss">
.scheme-manager { height: 100%; display: flex; flex-direction: column; }
.scheme-tabs {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.scheme-list {
  flex: 1;
  overflow: auto;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
  align-content: start;
}
.scheme-card {
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 12px;
  background: #fff;
  transition: all 0.2s;
  &:hover { box-shadow: 0 2px 8px rgba(21, 100, 255, 0.12); border-color: #1564ff; }
  &.active { border-color: #1564ff; box-shadow: 0 0 0 2px rgba(21, 100, 255, 0.2); }
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.card-title {
  display: flex;
  align-items: center;
  gap: 4px;
  flex: 1;
  .title-text { font-weight: 600; font-size: 14px; margin-right: 4px; }
  .fav-icon { color: #faad14; cursor: pointer; }
  .fav-icon-empty { color: #c0c4cc; cursor: pointer; }
}
.more-icon { cursor: pointer; color: #909399; padding: 2px; }
.more-icon:hover { color: #1564ff; }
.card-body {
  margin-bottom: 8px;
  .meta-row { font-size: 12px; color: #606266; line-height: 22px; }
  .meta-label { color: #909399; }
  .meta-value { color: #303133; }
}
.card-conditions {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 8px;
  padding-top: 8px;
  border-top: 1px dashed #ebeef5;
}
.card-footer {
  display: flex;
  gap: 6px;
  padding-top: 8px;
  border-top: 1px solid #ebeef5;
}
</style>
