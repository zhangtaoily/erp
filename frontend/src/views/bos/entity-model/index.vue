<template>
  <div class="entity-model-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:280px" @change="onBoChange" />
        <el-tag v-if="currentBo" size="small" :type="boTypeTag(currentBo.bo_type)" effect="plain">
          {{ boTypeLabel(currentBo.bo_type) }}
        </el-tag>
        <span v-if="currentBo" class="bo-remark">{{ currentBo.remark || '' }}</span>
      </div>
      <div class="header-right">
        <el-button type="primary" size="small" @click="onSaveAll" :disabled="!boCode">保存全部</el-button>
      </div>
    </div>

    <!-- 主体：左实体树 + 右字段配置 -->
    <div class="main-body">
      <!-- 左侧实体树 -->
      <div class="entity-tree-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">实体层级</span>
          <div class="header-actions">
            <el-button type="primary" size="small" link @click="onAddEntity(null)" :disabled="!boCode || readonly">
              <el-icon><Plus /></el-icon>新增实体
            </el-button>
          </div>
        </div>
        <el-empty v-if="!entityTree.length" description="请选择业务对象" :image-size="60" />
        <el-tree
          v-else
          ref="treeRef"
          :data="entityTree"
          node-key="id"
          :props="{ label: 'entity_name', children: 'children' }"
          :expand-on-click-node="false"
          default-expand-all
          highlight-current
          @node-click="onEntityClick"
        >
          <template #default="{ data }">
            <span class="entity-node">
              <el-tag :type="entityTypeTag(data.entity_type)" size="small" effect="plain">
                {{ entityTypeLabel(data.entity_type) }}
              </el-tag>
              <span class="entity-name">{{ data.entity_name }}</span>
              <span class="entity-code">{{ data.entity_code }}</span>
              <el-button link type="primary" size="small" @click.stop="onAddEntity(data)" :disabled="readonly">
                <el-icon><Plus /></el-icon>
              </el-button>
              <el-button link type="danger" size="small" @click.stop="onDeleteEntity(data)" :disabled="readonly">
                <el-icon><Delete /></el-icon>
              </el-button>
            </span>
          </template>
        </el-tree>
      </div>

      <!-- 右侧字段配置 -->
      <div class="field-panel panel-card">
        <el-empty v-if="!currentEntity" description="请选择左侧实体" :image-size="80" />
        <template v-else>
          <div class="panel-header">
            <span class="panel-title">
              {{ currentEntity.entity_name }}
              <span class="entity-code-tag">{{ currentEntity.entity_code }}</span>
            </span>
            <div class="header-actions">
              <span v-if="currentEntity.entity_type !== 'main'" class="rel-info">
                父实体：{{ currentEntity.parent_entity_code }} · 关联字段：{{ currentEntity.link_field }}
              </span>
            </div>
          </div>
          <FieldConfigTable
            :fields="currentFields"
            :entity-code="currentEntity.entity_code"
            :readonly="readonly"
            :max-height="tableMaxHeight"
            @save="onSaveFields"
            @change="onFieldsChange"
          />
        </template>
      </div>
    </div>

    <!-- 实体新增/编辑弹窗 -->
    <el-dialog v-model="entityDialogVisible" :title="entityDialogTitle" width="500px" append-to-body>
      <el-form :model="entityForm" label-width="100px" size="small">
        <el-form-item label="实体编码" required>
          <el-input v-model="entityForm.entity_code" placeholder="如：sal_order_goods（表名）" />
        </el-form-item>
        <el-form-item label="实体名称" required>
          <el-input v-model="entityForm.entity_name" placeholder="如：订单明细" />
        </el-form-item>
        <el-form-item label="实体类型" required>
          <el-radio-group v-model="entityForm.entity_type" @change="onEntityTypeChange">
            <el-option v-for="o in ENTITY_TYPE_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="entityForm.entity_type !== 'main'" label="父实体" required>
          <el-select v-model="entityForm.parent_entity_code" placeholder="选择父实体" style="width:100%">
            <el-option
              v-for="e in parentEntityOptions"
              :key="e.entity_code"
              :label="`${e.entity_name} (${e.entity_code})`"
              :value="e.entity_code"
            />
          </el-select>
        </el-form-item>
        <el-form-item v-if="entityForm.entity_type !== 'main'" label="关联字段" required>
          <el-input v-model="entityForm.link_field" placeholder="如：order_id（外键字段名）" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="entityForm.sort_index" :min="1" :max="99" controls-position="right" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="entityDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSaveEntity">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'
import { boApi, entityApi, fieldApi } from '@/api/bo'
import BoPicker from '@/components/BoPicker/index.vue'
import FieldConfigTable from '@/components/FieldConfigTable/index.vue'
import { ENTITY_TYPE_OPTIONS, BO_TYPE_OPTIONS } from '@/utils/enum'
import type { BusinessObject, FormEntity, FormField, EntityType, BoType } from '@/types/bo'

const route = useRoute()
const treeRef = ref()

const boCode = ref('')
const currentBo = ref<BusinessObject | null>(null)
const entities = ref<FormEntity[]>([])
const currentEntity = ref<FormEntity | null>(null)
const currentFields = ref<FormField[]>([])
const readonly = ref(false)
const tableMaxHeight = 520

const entityDialogVisible = ref(false)
const entityDialogTitle = ref('新增实体')
const entityDialogMode = ref<'add' | 'edit'>('add')
const entityForm = reactive<Partial<FormEntity>>({
  entity_code: '', entity_name: '', entity_type: 'main', entity_level: 0,
  parent_entity_code: '', link_field: '', sort_index: 1
})

const boTypeLabel = (t: BoType) => BO_TYPE_OPTIONS.find(o => o.value === t)?.label || t
const boTypeTag = (t: BoType): 'primary' | 'success' | 'warning' => {
  if (t === 'bill') return 'primary'
  if (t === 'master') return 'success'
  return 'warning'
}
const entityTypeLabel = (t: EntityType) => ENTITY_TYPE_OPTIONS.find(o => o.value === t)?.label || t
const entityTypeTag = (t: EntityType): 'primary' | 'success' | 'warning' => {
  if (t === 'main') return 'primary'
  if (t === 'sub') return 'success'
  return 'warning'
}

// 构建实体树（主表 → 子表 → 孙表）
const entityTree = computed(() => {
  const mains = entities.value.filter(e => e.entity_type === 'main').sort((a, b) => a.sort_index - b.sort_index)
  const buildChildren = (parentCode: string): FormEntity[] => {
    const subs = entities.value.filter(e => e.parent_entity_code === parentCode && e.entity_type === 'sub')
    return subs.sort((a, b) => a.sort_index - b.sort_index).map(s => ({
      ...s,
      children: buildGrandchildren(s.entity_code)
    }))
  }
  const buildGrandchildren = (parentCode: string): FormEntity[] => {
    return entities.value
      .filter(e => e.parent_entity_code === parentCode && e.entity_type === 'grandchild')
      .sort((a, b) => a.sort_index - b.sort_index)
  }
  return mains.map(m => ({ ...m, children: buildChildren(m.entity_code) }))
})

const parentEntityOptions = computed(() => {
  if (entityForm.entity_type === 'sub') {
    return entities.value.filter(e => e.entity_type === 'main')
  } else if (entityForm.entity_type === 'grandchild') {
    return entities.value.filter(e => e.entity_type === 'sub')
  }
  return []
})

async function onBoChange(bo: BusinessObject | null) {
  if (!bo) {
    currentBo.value = null
    entities.value = []
    currentEntity.value = null
    currentFields.value = []
    return
  }
  currentBo.value = bo
  await loadEntities(bo.bo_code)
}

async function loadEntities(code: string) {
  const res = await entityApi.list(code)
  entities.value = res || []
  // 默认选中主表
  const main = entities.value.find(e => e.entity_type === 'main')
  if (main) {
    onEntityClick(main)
  }
}

function onEntityClick(data: FormEntity) {
  currentEntity.value = data
  loadFields(data.entity_code)
}

async function loadFields(entityCode: string) {
  if (!boCode.value) {
    currentFields.value = []
    return
  }
  const res = await fieldApi.list(boCode.value, entityCode)
  currentFields.value = res || []
}

function onAddEntity(parent: FormEntity | null) {
  entityDialogMode.value = 'add'
  entityDialogTitle.value = '新增实体'
  Object.assign(entityForm, {
    id: undefined, entity_code: '', entity_name: '',
    entity_type: parent ? (parent.entity_type === 'main' ? 'sub' : 'grandchild') : 'main',
    entity_level: parent ? (parent.entity_type === 'main' ? 1 : 2) : 0,
    parent_entity_code: parent?.entity_code || '',
    link_field: '', sort_index: entities.value.length + 1,
    bo_code: boCode.value
  })
  entityDialogVisible.value = true
}

function onEntityTypeChange() {
  if (entityForm.entity_type === 'main') {
    entityForm.parent_entity_code = ''
    entityForm.link_field = ''
    entityForm.entity_level = 0
  } else if (entityForm.entity_type === 'sub') {
    entityForm.entity_level = 1
  } else if (entityForm.entity_type === 'grandchild') {
    entityForm.entity_level = 2
  }
}

async function onSaveEntity() {
  if (!entityForm.entity_code || !entityForm.entity_name) {
    ElMessage.warning('请填写实体编码和名称')
    return
  }
  if (entityForm.entity_type !== 'main' && !entityForm.parent_entity_code) {
    ElMessage.warning('子表/孙表必须选择父实体')
    return
  }
  const data = { ...entityForm, bo_code: boCode.value }
  if (entityDialogMode.value === 'add') {
    const created = await entityApi.create(data)
    entities.value.push(created)
    ElMessage.success('新增成功')
  } else {
    if (entityForm.id) {
      await entityApi.update(entityForm.id, data)
      const idx = entities.value.findIndex(e => e.id === entityForm.id)
      if (idx > -1) Object.assign(entities.value[idx], data)
      ElMessage.success('保存成功')
    }
  }
  entityDialogVisible.value = false
}

async function onDeleteEntity(data: FormEntity) {
  await ElMessageBox.confirm(`确定删除实体「${data.entity_name}」及其所有字段吗？`, '提示', { type: 'warning' })
  // 检查是否有子实体
  const hasChildren = entities.value.some(e => e.parent_entity_code === data.entity_code)
  if (hasChildren) {
    ElMessage.warning('该实体下有子实体，请先删除子实体')
    return
  }
  if (data.id) await entityApi.delete(data.id)
  const idx = entities.value.findIndex(e => e.id === data.id)
  if (idx > -1) entities.value.splice(idx, 1)
  if (currentEntity.value?.id === data.id) {
    currentEntity.value = null
    currentFields.value = []
  }
  ElMessage.success('删除成功')
}

function onFieldsChange(fields: FormField[]) {
  if (currentEntity.value) {
    currentEntity.value.fields = fields
  }
}

async function onSaveFields(fields: FormField[]) {
  if (currentEntity.value) {
    await fieldApi.batchSave(boCode.value, currentEntity.value.entity_code, fields)
    currentEntity.value.fields = fields
  }
}

async function onSaveAll() {
  ElMessage.info('保存全部变更...')
  for (const entity of entities.value) {
    if (entity.fields?.length) {
      await fieldApi.batchSave(boCode.value, entity.entity_code, entity.fields)
    }
  }
  ElMessage.success('全部保存成功')
}

// 初始化：从路由参数加载
onMounted(async () => {
  const queryBoCode = route.query.boCode as string
  if (route.query.readonly === '1') readonly.value = true
  if (queryBoCode) {
    boCode.value = queryBoCode
    const bo = await boApi.detail(queryBoCode)
    if (bo) {
      currentBo.value = bo
      await loadEntities(queryBoCode)
    }
  }
})
</script>

<style scoped lang="scss">
.entity-model-page {
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
}
.header-label { font-size: 13px; font-weight: 600; white-space: nowrap; }
.bo-remark { color: #909399; font-size: 12px; }
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  overflow: hidden;
}
.entity-tree-panel {
  width: 320px;
  flex-shrink: 0;
  padding: 12px;
  overflow: auto;
}
.field-panel {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title {
  font-size: 14px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
}
.entity-code-tag {
  font-size: 12px;
  color: #909399;
  font-weight: normal;
}
.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.rel-info {
  font-size: 12px;
  color: #909399;
}
.entity-node {
  display: flex;
  align-items: center;
  gap: 4px;
  flex: 1;
  padding-right: 8px;
  .entity-name { margin-left: 4px; font-size: 13px; }
  .entity-code { color: #909399; font-size: 11px; margin-left: auto; }
}
:deep(.el-tree-node__content) {
  height: 32px;
}
:deep(.el-radio-group) {
  display: flex;
  gap: 8px;
}
</style>
