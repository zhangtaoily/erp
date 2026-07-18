<template>
  <div class="form-designer-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width:240px" @change="onBoChange" />
        <el-radio-group v-model="mode" size="small">
          <el-radio-button value="design">设计</el-radio-button>
          <el-radio-button value="view">预览-只读</el-radio-button>
          <el-radio-button value="edit">预览-编辑</el-radio-button>
          <el-radio-button value="add">预览-新增</el-radio-button>
        </el-radio-group>
      </div>
      <div class="header-right">
        <el-button size="small" @click="onLoadLayout" :disabled="!boCode || mode !== 'design'">加载布局</el-button>
        <el-button type="success" size="small" @click="onSaveLayout" :disabled="!boCode || mode !== 'design'">保存布局</el-button>
        <el-button type="primary" size="small" @click="onSave" :disabled="!boCode || mode !== 'design'">保存</el-button>
      </div>
    </div>

    <!-- 设计模式 -->
    <div v-if="mode === 'design'" class="designer-body">
      <!-- 左：控件库 -->
      <div class="control-library panel-card">
        <div class="panel-header"><span class="panel-title">控件库</span></div>
        <div class="control-list">
          <div class="control-group-label">字段控件</div>
          <div
            v-for="ct in CONTROL_TYPE_OPTIONS"
            :key="ct.value"
            class="control-item"
            draggable="true"
            @dragstart="onDragStart($event, ct, 'field')"
            @click="onAddField(ct)"
          >
            <el-icon class="control-icon"><component :is="controlIcon(ct.value)" /></el-icon>
            <span>{{ ct.label }}</span>
          </div>

          <div class="control-group-label" style="margin-top:12px">容器控件</div>
          <div
            v-for="ct in CONTAINER_CONTROL_OPTIONS"
            :key="ct.value"
            class="control-item container-control"
            draggable="true"
            @dragstart="onDragStart($event, ct, 'container')"
            @click="onAddContainer(ct)"
          >
            <el-icon class="control-icon"><component :is="containerIcon(ct.value)" /></el-icon>
            <div class="container-text">
              <span class="container-label">{{ ct.label }}</span>
              <span class="container-desc">{{ ct.desc }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 中：画布 -->
      <div class="canvas-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">表单画布</span>
        </div>
        <div v-if="!boCode" class="empty-tip"><el-empty description="请选择业务对象" :image-size="60" /></div>
        <div v-else class="canvas-content">
          <!-- ====== ① 主表：字段分组 Tab ====== -->
          <div v-if="mainEntity" class="layer-section main-layer" :class="{ active: activeEntityCode === mainEntity.entity_code }" @click="activeEntityCode = mainEntity.entity_code">
            <div class="layer-bar">
              <span class="layer-bar-name">{{ mainEntity.entity_name }}（{{ mainEntity.entity_code }}）</span>
              <el-tag type="primary" size="small">主表</el-tag>
            </div>
            <el-tabs v-model="activeMainGroup" type="card">
              <el-tab-pane
                v-for="group in mainFieldGroups"
                :key="group"
                :label="group"
                :name="group"
              >
                <div class="group-fields">
                  <div
                    v-for="field in mainFieldsByGroup(group)"
                    :key="field.id"
                    class="field-card"
                    :class="{ selected: selectedFieldId === field.id, system: field.is_system }"
                    @click.stop="onSelectField(field); activeEntityCode = mainEntity.entity_code"
                  >
                    <span class="field-name">{{ field.field_name }}</span>
                    <span class="field-code">{{ field.field_code }}</span>
                    <el-tag size="small" effect="plain" type="info">{{ controlLabel(field.ctrl_type) }}</el-tag>
                    <el-icon v-if="field.is_required" class="required-icon"><Star /></el-icon>
                    <el-icon v-if="field.is_system" class="system-icon"><Lock /></el-icon>
                    <el-button
                      v-if="!field.is_system"
                      link type="danger" size="small"
                      @click.stop="onDeleteField(mainEntity, field)"
                    ><el-icon><Delete /></el-icon></el-button>
                  </div>
                </div>
              </el-tab-pane>
            </el-tabs>
            <div class="drop-zone" @dragover.prevent="onDragOver" @drop="(e) => onDrop(e, mainEntity)">
              <el-icon><Plus /></el-icon><span>拖拽字段控件到此处添加字段</span>
            </div>
          </div>

          <!-- ====== ② 子表：多个子表分 Tab ====== -->
          <div v-if="subEntities.length" class="layer-section sub-layer" :class="{ active: activeEntityCode === activeSubCode }" @click="activeEntityCode = activeSubCode">
            <div class="layer-bar">
              <span class="layer-bar-name">子表</span>
              <el-tag type="success" size="small">{{ subEntities.length }} 个子表</el-tag>
            </div>
            <el-tabs v-model="activeSubCode" type="card" @tab-click="activeEntityCode = activeSubCode">
              <el-tab-pane
                v-for="sub in subEntities"
                :key="sub.entity_code"
                :label="sub.entity_name"
                :name="sub.entity_code"
              >
                <template #label>
                  <span>{{ sub.entity_name }} ({{ sub.fields?.length || 0 }})</span>
                </template>
                <!-- 表格预览 -->
                <el-table :data="[{ _sample: true }]" border size="small" class="design-table">
                  <el-table-column type="index" label="#" width="45" />
                  <el-table-column
                    v-for="f in sub.fields?.filter(x => !x.is_hidden) || []"
                    :key="f.field_code"
                    :label="f.field_name"
                    min-width="120"
                  >
                    <template #header>
                      <span
                        class="design-col-header"
                        :class="{ selected: selectedFieldId === f.id, system: f.is_system }"
                        @click.stop="onSelectField(f)"
                      >
                        <span class="col-name">{{ f.field_name }}</span>
                        <span class="col-code">{{ f.field_code }}</span>
                        <el-icon v-if="f.is_system" class="system-icon"><Lock /></el-icon>
                        <el-icon v-if="f.is_required" class="required-icon"><Star /></el-icon>
                        <el-button
                          v-if="!f.is_system"
                          link type="danger" size="small"
                          @click.stop="onDeleteField(sub, f)"
                        ><el-icon><Delete /></el-icon></el-button>
                      </span>
                    </template>
                    <template #default>
                      <span class="sample-cell">{{ f.ctrl_type === 'number' || f.ctrl_type === 'qty' || f.ctrl_type === 'amount' ? '0' : '—' }}</span>
                    </template>
                  </el-table-column>
                </el-table>
              </el-tab-pane>
            </el-tabs>
            <div class="drop-zone" @dragover.prevent="onDragOver" @drop="(e) => onDropEntity(e, activeSubEntity!)">
              <el-icon><Plus /></el-icon><span>拖拽字段控件到此处添加字段</span>
            </div>
            <!-- 子表删除按钮 -->
            <div class="layer-actions">
              <el-button size="small" type="danger" plain @click="onDeleteEntity(activeSubEntity!)" :disabled="!activeSubEntity">删除当前子表</el-button>
            </div>
          </div>

          <!-- ====== ③ 孙表：多个孙表分 Tab ====== -->
          <div v-if="grandchildEntities.length" class="layer-section gc-layer" :class="{ active: activeEntityCode === activeGcCode }" @click="activeEntityCode = activeGcCode">
            <div class="layer-bar">
              <span class="layer-bar-name">孙表</span>
              <el-tag type="warning" size="small">{{ grandchildEntities.length }} 个孙表</el-tag>
            </div>
            <el-tabs v-model="activeGcCode" type="card" @tab-click="activeEntityCode = activeGcCode">
              <el-tab-pane
                v-for="gc in grandchildEntities"
                :key="gc.entity_code"
                :name="gc.entity_code"
              >
                <template #label>
                  <span>{{ gc.entity_name }} ({{ gc.fields?.length || 0 }})</span>
                </template>
                <div class="entity-bar">
                  <span class="entity-bar-rel">父表：{{ designEntities.find(e => e.entity_code === gc.parent_entity_code)?.entity_name || gc.parent_entity_code }}</span>
                </div>
                <!-- 表格预览 -->
                <el-table :data="[{ _sample: true }]" border size="small" class="design-table">
                  <el-table-column type="index" label="#" width="45" />
                  <el-table-column
                    v-for="f in gc.fields?.filter(x => !x.is_hidden) || []"
                    :key="f.field_code"
                    :label="f.field_name"
                    min-width="120"
                  >
                    <template #header>
                      <span
                        class="design-col-header"
                        :class="{ selected: selectedFieldId === f.id, system: f.is_system }"
                        @click.stop="onSelectField(f)"
                      >
                        <span class="col-name">{{ f.field_name }}</span>
                        <span class="col-code">{{ f.field_code }}</span>
                        <el-icon v-if="f.is_system" class="system-icon"><Lock /></el-icon>
                        <el-icon v-if="f.is_required" class="required-icon"><Star /></el-icon>
                        <el-button
                          v-if="!f.is_system"
                          link type="danger" size="small"
                          @click.stop="onDeleteField(gc, f)"
                        ><el-icon><Delete /></el-icon></el-button>
                      </span>
                    </template>
                    <template #default>
                      <span class="sample-cell">{{ f.ctrl_type === 'number' || f.ctrl_type === 'qty' || f.ctrl_type === 'amount' ? '0' : '—' }}</span>
                    </template>
                  </el-table-column>
                </el-table>
              </el-tab-pane>
            </el-tabs>
            <div class="drop-zone" @dragover.prevent="onDragOver" @drop="(e) => onDropEntity(e, activeGrandchildEntity!)">
              <el-icon><Plus /></el-icon><span>拖拽字段控件到此处添加字段</span>
            </div>
            <div class="layer-actions">
              <el-button size="small" type="danger" plain @click="onDeleteEntity(activeGrandchildEntity!)" :disabled="!activeGrandchildEntity">删除当前孙表</el-button>
            </div>
          </div>
        </div>
      </div>

      <!-- 右：属性面板 -->
      <div class="property-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">
            {{ selectedField ? '字段属性' : currentEntity ? '实体属性' : '属性' }}
          </span>
          <el-button
            v-if="currentEntity && currentEntity.entity_type !== 'main' && !selectedField"
            type="danger" size="small" plain
            @click="onDeleteEntity(currentEntity)"
          >删除该实体</el-button>
        </div>

        <!-- 字段属性 -->
        <el-form v-if="selectedField" :model="selectedField" label-width="80px" size="small">
          <el-form-item label="字段编码">
            <el-input v-model="selectedField.field_code" :disabled="selectedField.is_system" />
          </el-form-item>
          <el-form-item label="字段名称">
            <el-input v-model="selectedField.field_name" />
          </el-form-item>
          <el-form-item label="控件类型">
            <el-select v-model="selectedField.ctrl_type" style="width:100%">
              <el-option v-for="o in CONTROL_TYPE_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
          </el-form-item>
          <el-form-item label="数据类型">
            <el-select v-model="selectedField.field_type" style="width:100%">
              <el-option v-for="o in FIELD_TYPE_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
          </el-form-item>
          <el-form-item label="长度">
            <el-input-number v-model="selectedField.data_length" :min="0" :disabled="!supportsLength(selectedField.field_type)" controls-position="right" style="width:100%" />
          </el-form-item>
          <el-form-item label="精度">
            <el-input-number v-model="selectedField.data_precision" :min="0" :max="10" controls-position="right" style="width:100%" />
          </el-form-item>
          <el-form-item label="必填">
            <el-switch v-model="selectedField.is_required" :disabled="selectedField.is_system" />
          </el-form-item>
          <el-form-item label="隐藏">
            <el-switch v-model="selectedField.is_hidden" />
          </el-form-item>
          <el-form-item label="默认值">
            <el-input v-model="selectedField.default_value" placeholder="如：TODAY" />
          </el-form-item>
          <el-form-item label="分组">
            <el-input v-model="selectedField.group_name" placeholder="如：基本信息" />
          </el-form-item>
          <el-form-item label="引用对象" v-if="selectedField.ctrl_type === 'ref'">
            <el-input v-model="selectedField.ref_bo_code" placeholder="如：customer" />
          </el-form-item>
          <el-form-item label="枚举编码" v-if="selectedField.ctrl_type === 'select'">
            <el-input v-model="selectedField.enum_code" placeholder="如：UNIT" />
          </el-form-item>
          <el-form-item label="占位提示">
            <el-input v-model="selectedField.placeholder" />
          </el-form-item>
        </el-form>

        <!-- 实体属性（未选中字段时） -->
        <el-form v-else-if="currentEntity" :model="currentEntity" label-width="80px" size="small">
          <el-form-item label="实体编码">
            <el-input v-model="currentEntity.entity_code" :disabled="currentEntity.entity_type === 'main'" />
          </el-form-item>
          <el-form-item label="实体名称">
            <el-input v-model="currentEntity.entity_name" />
          </el-form-item>
          <el-form-item label="实体类型">
            <el-tag :type="entityTagType(currentEntity.entity_type)" size="small">
              {{ entityTypeLabel(currentEntity.entity_type) }}
            </el-tag>
          </el-form-item>
          <el-form-item v-if="currentEntity.entity_type !== 'main'" label="父实体">
            <el-select
              v-model="currentEntity.parent_entity_code"
              style="width:100%"
              :disabled="currentEntity.entity_type === 'sub'"
              placeholder="请选择父实体"
            >
              <el-option
                v-for="e in parentEntityOptions(currentEntity.entity_type)"
                :key="e.entity_code"
                :label="e.entity_name"
                :value="e.entity_code"
              />
            </el-select>
          </el-form-item>
          <el-form-item v-if="currentEntity.entity_type !== 'main'" label="关联外键">
            <el-input v-model="currentEntity.link_field" placeholder="如 parent_id" />
          </el-form-item>
          <el-alert type="info" :closable="false" show-icon class="mt-8">
            <template v-if="currentEntity.entity_type === 'main'">主表承载单据头信息，以分组表单形式展示。</template>
            <template v-else-if="currentEntity.entity_type === 'sub'">子表以页签表格形式展示，如订单明细。每行可展开孙表。</template>
            <template v-else>孙表挂在子表行下展开，如指定用料。需指定父实体（子表）。</template>
          </el-alert>
          <el-divider content-position="left">字段列表</el-divider>
          <div class="entity-field-summary">
            <div v-for="f in currentEntity.fields" :key="f.id" class="summary-row" @click="onSelectField(f)">
              <span class="summary-name">{{ f.field_name }}</span>
              <span class="summary-code">{{ f.field_code }}</span>
              <el-tag size="small" effect="plain">{{ controlLabel(f.ctrl_type) }}</el-tag>
            </div>
            <div v-if="!currentEntity.fields?.length" class="summary-empty">暂无字段，请从左侧拖入控件</div>
          </div>
        </el-form>
        <el-empty v-else description="请选择实体" :image-size="60" />
      </div>
    </div>

    <!-- 预览模式（参照 bill/sal_order/1 布局：顶部工具栏 + 左表单 + 右侧信息页签）-->
    <div v-else class="preview-mode-page">
      <el-empty v-if="!boCode" description="请选择业务对象" :image-size="80" />

      <template v-else>
        <!-- 顶部工具栏（模拟正式单据页面）-->
        <div class="preview-header panel-card">
          <div class="preview-toolbar">
            <el-button-group size="small">
              <el-button :type="mode === 'view' ? 'primary' : ''" @click="mode = 'view'" :icon="View">查看</el-button>
              <el-button :type="mode === 'edit' ? 'primary' : ''" @click="mode = 'edit'" :icon="EditPen">编辑</el-button>
              <el-button :type="mode === 'add' ? 'primary' : ''" @click="mode = 'add'" :icon="Plus">新增</el-button>
            </el-button-group>
            <div class="preview-status">
              <el-tag v-if="previewData.bill_no" size="small" type="info" effect="plain">{{ previewData.bill_no }}</el-tag>
              <el-tag v-if="previewData.pact_state !== undefined" size="small" :type="previewStateTagType(previewData.pact_state)" effect="dark">
                {{ previewStateLabel(previewData.pact_state) }}
              </el-tag>
              <el-tag v-if="previewData.is_closed" size="small" type="warning" effect="plain">已关闭</el-tag>
              <el-tag v-if="previewData.is_cancel" size="small" type="danger" effect="plain">已取消</el-tag>
              <span class="mode-tip">预览模式：{{ previewModeLabel }}</span>
            </div>
          </div>
        </div>

        <!-- 主体：左表单 + 右侧信息页签 -->
        <div class="preview-main">
          <!-- 左：表单面板（扁平布局：主表 → 子表表格 → 孙表表格，全部可见，无 Tab 切换） -->
          <div class="preview-form panel-card">
            <div class="form-wrapper">
              <!-- ① 主表表单 -->
              <div v-if="mainEntity" class="flat-section main-flat">
                <div class="section-title">{{ mainEntity.entity_name }}</div>
                <el-form :model="previewData" label-width="100px" :disabled="mode === 'view'" class="flat-main-form">
                  <el-row :gutter="16">
                    <el-col
                      v-for="f in mainEntity.fields?.filter(x => !x.is_hidden) || []"
                      :key="f.field_code"
                      :span="8"
                    >
                      <el-form-item :label="f.field_name" :required="f.is_required">
                        <FieldControl
                          :field="f"
                          :model-value="previewData[f.field_code]"
                          :disabled="f.is_system && mode === 'edit'"
                          @update:model-value="(v: any) => (previewData[f.field_code] = v)"
                        />
                      </el-form-item>
                    </el-col>
                  </el-row>
                </el-form>
              </div>

              <!-- ② 子表独立表格（每个子表一个表格，全部展示） -->
              <div v-for="sub in subEntities" :key="sub.entity_code" class="flat-section sub-flat">
                <div class="section-title">{{ sub.entity_name }}</div>
                <el-table
                  :data="previewData[sub.entity_code] || []"
                  border
                  size="small"
                  class="flat-table"
                >
                  <el-table-column type="index" label="#" width="45" />
                  <el-table-column
                    v-for="f in sub.fields?.filter(x => !x.is_hidden) || []"
                    :key="f.field_code"
                    :prop="f.field_code"
                    :label="f.field_name"
                    min-width="120"
                  >
                    <template #default="{ row }">
                      <FieldControl
                        :field="f"
                        :model-value="row[f.field_code]"
                        :disabled="mode === 'view' || f.is_system"
                        size="small"
                        @update:model-value="(v: any) => (row[f.field_code] = v)"
                      />
                    </template>
                  </el-table-column>
                </el-table>
              </div>

              <!-- ③ 孙表独立表格（每个孙表一个表格，全部展示在页面最底部） -->
              <div v-for="gc in grandchildEntities" :key="gc.entity_code" class="flat-section gc-flat">
                <div class="section-title">
                  {{ gc.entity_name }}
                  <span class="section-sub">（挂在 {{ gc.parent_entity_code }} 下，已展开所有行数据）</span>
                </div>
                <el-table
                  :data="getFlatGrandchildData(gc)"
                  border
                  size="small"
                  class="flat-table"
                >
                  <el-table-column type="index" label="#" width="45" />
                  <el-table-column
                    v-for="f in gc.fields?.filter(x => !x.is_hidden) || []"
                    :key="f.field_code"
                    :prop="f.field_code"
                    :label="f.field_name"
                    min-width="120"
                  >
                    <template #default="{ row }">
                      <FieldControl
                        :field="f"
                        :model-value="row[f.field_code]"
                        :disabled="mode === 'view' || f.is_system"
                        size="small"
                        @update:model-value="(v: any) => (row[f.field_code] = v)"
                      />
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </div>
          </div>
          <div class="preview-side panel-card">
            <el-tabs class="side-tabs">
              <el-tab-pane label="单据信息" name="info">
                <el-form label-width="80px" size="small" class="info-form">
                  <el-form-item label="业务对象">{{ boCode }}</el-form-item>
                  <el-form-item label="主表实体">{{ mainEntity?.entity_name || '—' }}</el-form-item>
                  <el-form-item label="子表数">{{ designEntities.filter(e => e.entity_type === 'sub').length }}</el-form-item>
                  <el-form-item label="孙表数">{{ designEntities.filter(e => e.entity_type === 'grandchild').length }}</el-form-item>
                  <el-form-item label="字段总数">{{ totalFieldCount }}</el-form-item>
                  <el-form-item label="布局版本">{{ currentLayout?.version || 1 }}</el-form-item>
                </el-form>
              </el-tab-pane>
              <el-tab-pane label="附件" name="attachment">
                <el-empty description="预览模式不可上传附件" :image-size="50" />
              </el-tab-pane>
              <el-tab-pane label="联查" name="trace">
                <el-empty description="预览模式不可联查" :image-size="50" />
              </el-tab-pane>
              <el-tab-pane label="变更历史" name="history">
                <el-empty description="预览模式无变更历史" :image-size="50" />
              </el-tab-pane>
            </el-tabs>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Star, Lock, Document, EditPen, Calendar, Picture, Files, Tickets, Money, Histogram, Box, Grid, Operation, View } from '@element-plus/icons-vue'
import { entityApi, fieldApi, formLayoutApi, type FormLayout } from '@/api/bo'
import { formApi } from '@/api/form'
import BoPicker from '@/components/BoPicker/index.vue'
import FieldControl from '@/components/MasterDetailEditor/FieldControl.vue'
import { CONTROL_TYPE_OPTIONS, CONTAINER_CONTROL_OPTIONS, FIELD_TYPE_OPTIONS, FIELD_TYPE_CONTROL_MAP } from '@/utils/enum'
import type { FormEntity, FormField, FieldType, ControlType, EntityType } from '@/types/bo'

const route = useRoute()
const boCode = ref('')
const mode = ref<'design' | 'view' | 'edit' | 'add'>('design')
const designEntities = ref<FormEntity[]>([])
const activeEntityCode = ref('')
const selectedFieldId = ref('')
const dragControl = ref<{ value: string; label: string; kind: 'field' | 'container' } | null>(null)

// 分层 Tab 状态（设计模式用）
const activeMainGroup = ref('基本信息')
const activeSubCode = ref('')
const activeGcCode = ref('')

// 三层实体分组（设计与预览共用）
const mainEntity = computed(() => designEntities.value.find(e => e.entity_type === 'main') || null)
const subEntities = computed(() => designEntities.value.filter(e => e.entity_type === 'sub'))
const grandchildEntities = computed(() => designEntities.value.filter(e => e.entity_type === 'grandchild'))

// 主表字段分组 Tab
const mainFieldGroups = computed(() => {
  if (!mainEntity.value?.fields?.length) return ['基本信息']
  const groups = [...new Set(mainEntity.value.fields.map(f => f.group_name || '').filter(Boolean))]
  return groups.length ? groups : ['基本信息']
})

function mainFieldsByGroup(group: string) {
  return (mainEntity.value?.fields || []).filter(f => (f.group_name || '基本信息') === group)
}

// 当前激活的子表/孙表实体
const activeSubEntity = computed(() => 
  subEntities.value.find(s => s.entity_code === activeSubCode.value) || subEntities.value[0] || null
)
const activeGrandchildEntity = computed(() =>
  grandchildEntities.value.find(g => g.entity_code === activeGcCode.value) || grandchildEntities.value[0] || null
)

// 子表/孙表拖拽添加字段
function onDropEntity(e: DragEvent, entity: FormEntity) {
  if (!entity) return
  activeEntityCode.value = entity.entity_code
  if (!dragControl.value) return
  if (dragControl.value.kind === 'container') {
    onAddContainer(dragControl.value)
  } else {
    onAddFieldToEntity(dragControl.value, entity)
  }
  dragControl.value = null
}

const selectedField = computed(() => {
  const entity = designEntities.value.find(e => e.entity_code === activeEntityCode.value)
  return entity?.fields?.find(f => f.id === selectedFieldId.value) || null
})

const currentEntity = computed(() =>
  designEntities.value.find(e => e.entity_code === activeEntityCode.value) || null
)

// 按实体分组（扁平布局用）
function entityFieldGroups(entity: FormEntity): string[] {
  if (!entity.fields?.length) return ['未分组']
  const groups = [...new Set(entity.fields.map(f => f.group_name || ''))]
  return groups.length ? groups : ['未分组']
}

function entityFieldsByGroup(entity: FormEntity, group: string) {
  return entity.fields?.filter(f => (f.group_name || '') === group) || []
}

function controlLabel(ct: string) {
  return CONTROL_TYPE_OPTIONS.find(o => o.value === ct)?.label || ct
}

function controlIcon(ct: string) {
  const map: Record<string, any> = {
    text: EditPen, textarea: Files, number: Histogram, date: Calendar, datetime: Calendar,
    select: Tickets, ref: Box, amount: Money, qty: Histogram, checkbox: Picture, attachment: Files
  }
  return map[ct] || EditPen
}

function containerIcon(ct: string) {
  const map: Record<string, any> = {
    subtable: Grid,
    grandchild: Operation
  }
  return map[ct] || Grid
}

function entityTypeLabel(t: EntityType) {
  return t === 'main' ? '主表' : t === 'sub' ? '子表' : '孙表'
}

function entityTagType(t: EntityType): 'primary' | 'success' | 'warning' {
  return t === 'main' ? 'primary' : t === 'sub' ? 'success' : 'warning'
}

function parentEntityOptions(entityType: EntityType): FormEntity[] {
  // 子表的父实体是主表；孙表的父实体是子表
  if (entityType === 'sub') {
    return designEntities.value.filter(e => e.entity_type === 'main')
  }
  return designEntities.value.filter(e => e.entity_type === 'sub')
}

function supportsLength(ft: FieldType) {
  return ['string', 'text'].includes(ft)
}

async function onBoChange() {
  if (!boCode.value) {
    designEntities.value = []
    currentLayout.value = null
    return
  }
  await loadEntities()
}

async function loadEntities() {
  const res = await entityApi.list(boCode.value)
  designEntities.value = res || []
  if (designEntities.value.length) {
    activeEntityCode.value = designEntities.value[0].entity_code
  }
  // 初始化分层 Tab 默认选中
  const subs = designEntities.value.filter(e => e.entity_type === 'sub')
  const gcs = designEntities.value.filter(e => e.entity_type === 'grandchild')
  if (subs.length) activeSubCode.value = subs[0].entity_code
  if (gcs.length) activeGcCode.value = gcs[0].entity_code
  activeMainGroup.value = '基本信息'
  // 预加载默认布局（用于版本追踪与保存布局时增量版本号）
  try {
    const layout = await formLayoutApi.getDefault(boCode.value)
    currentLayout.value = layout || null
  } catch {
    currentLayout.value = null
  }
}

// ============ 添加字段 ============
function onAddField(ct: { value: string; label: string }) {
  onAddFieldToEntity(ct, currentEntity.value)
}

// 向指定实体添加字段（控件库点击 / 拖拽到子表孙表用）
function onAddFieldToEntity(ct: { value: string; label: string }, entity: FormEntity | null) {
  if (!entity) {
    ElMessage.warning('请先选择实体')
    return
  }
  const idx = (entity.fields?.length || 0) + 1
  const newField: FormField = {
    id: `f_new_${Date.now()}`,
    entity_code: entity.entity_code,
    field_code: `field_${idx}`,
    field_name: `${ct.label}${idx}`,
    field_type: controlTypeToFieldType(ct.value as ControlType),
    ctrl_type: ct.value as ControlType,
    data_length: ct.value === 'text' || ct.value === 'textarea' ? 500 : 100,
    is_required: false,
    is_system: false,
    is_hidden: false,
    sort_index: idx,
    group_name: '自定义'
  }
  if (!entity.fields) entity.fields = []
  entity.fields.push(newField)
  selectedFieldId.value = newField.id
  activeEntityCode.value = entity.entity_code
}

function controlTypeToFieldType(ct: ControlType): FieldType {
  const map: Record<string, FieldType> = {
    text: 'text', textarea: 'text', number: 'number', date: 'date', datetime: 'datetime',
    select: 'enum', ref: 'ref', amount: 'amount', qty: 'qty', checkbox: 'bool', attachment: 'attachment'
  }
  return map[ct] || 'text'
}

// ============ 添加容器控件（子表/孙表） ============
function onAddContainer(ct: { value: string; label: string; desc?: string }) {
  if (!boCode.value) {
    ElMessage.warning('请先选择业务对象')
    return
  }
  if (ct.value === 'subtable') {
    addSubEntity()
  } else if (ct.value === 'grandchild') {
    addGrandchildEntity()
  }
}

function addSubEntity() {
  const existingSubs = designEntities.value.filter(e => e.entity_type === 'sub')
  const seq = existingSubs.length + 1
  const entityCode = `${boCode.value}_detail_${seq}`
  const mainEntity = designEntities.value.find(e => e.entity_type === 'main')
  const newEntity: FormEntity = {
    id: `e_new_${Date.now()}`,
    bo_code: boCode.value,
    entity_code: entityCode,
    entity_name: `子表${seq}`,
    entity_type: 'sub',
    entity_level: 1,
    parent_entity_code: mainEntity?.entity_code,
    link_field: 'parent_id',
    sort_index: designEntities.value.length,
    fields: buildDefaultSubFields(entityCode)
  }
  designEntities.value.push(newEntity)
  activeEntityCode.value = entityCode
  activeSubCode.value = entityCode
  selectedFieldId.value = ''
  ElMessage.success(`已新增子表「${newEntity.entity_name}」`)
}

function addGrandchildEntity() {
  const subEntities = designEntities.value.filter(e => e.entity_type === 'sub')
  if (!subEntities.length) {
    ElMessage.warning('请先添加子表，孙表必须挂在子表下')
    return
  }
  // 默认挂到当前激活的子表，否则第一个子表
  let parent = currentEntity.value?.entity_type === 'sub'
    ? currentEntity.value
    : subEntities[0]
  // 若当前在孙表，复用其父
  if (currentEntity.value?.entity_type === 'grandchild' && currentEntity.value.parent_entity_code) {
    parent = subEntities.find(s => s.entity_code === currentEntity.value!.parent_entity_code) || parent
  }
  const existingGcs = designEntities.value.filter(e => e.entity_type === 'grandchild' && e.parent_entity_code === parent.entity_code)
  const seq = existingGcs.length + 1
  const entityCode = `${parent.entity_code}_gc_${seq}`
  const newEntity: FormEntity = {
    id: `e_new_${Date.now()}`,
    bo_code: boCode.value,
    entity_code: entityCode,
    entity_name: `${parent.entity_name}-孙表${seq}`,
    entity_type: 'grandchild',
    entity_level: 2,
    parent_entity_code: parent.entity_code,
    link_field: 'parent_id',
    sort_index: designEntities.value.length,
    fields: buildDefaultSubFields(entityCode)
  }
  designEntities.value.push(newEntity)
  activeEntityCode.value = entityCode
  activeGcCode.value = entityCode
  selectedFieldId.value = ''
  ElMessage.success(`已新增孙表「${newEntity.entity_name}」，挂在「${parent.entity_name}」下`)
}

// 子表/孙表默认字段
function buildDefaultSubFields(entityCode: string): FormField[] {
  const now = Date.now()
  return [
    { id: `f_sys_${now}_0`, entity_code: entityCode, field_code: 'id', field_name: '主键', field_type: 'text', ctrl_type: 'text', is_required: false, is_system: true, is_hidden: true, sort_index: 0, group_name: '系统' },
    { id: `f_sys_${now}_1`, entity_code: entityCode, field_code: 'parent_id', field_name: '父级ID', field_type: 'text', ctrl_type: 'text', is_required: false, is_system: true, is_hidden: true, sort_index: 1, group_name: '系统' },
    { id: `f_sys_${now}_2`, entity_code: entityCode, field_code: 'sort_index', field_name: '排序', field_type: 'number', ctrl_type: 'number', is_required: false, is_system: true, is_hidden: true, sort_index: 2, group_name: '系统' }
  ]
}

// ============ 拖拽 ============
function onDragStart(e: DragEvent, ct: { value: string; label: string; desc?: string }, kind: 'field' | 'container') {
  dragControl.value = { value: ct.value, label: ct.label, kind }
  e.dataTransfer?.setData('text/plain', ct.value)
}

function onDragOver(e: DragEvent) {
  e.preventDefault()
}

function onDrop(e: DragEvent, entity: FormEntity) {
  e.preventDefault()
  activeEntityCode.value = entity.entity_code
  if (!dragControl.value) return
  if (dragControl.value.kind === 'container') {
    onAddContainer(dragControl.value)
  } else {
    onAddField(dragControl.value)
  }
  dragControl.value = null
}

// ============ 选择与删除 ============
function onSelectField(field: FormField) {
  selectedFieldId.value = field.id
}

function onDeleteField(entity: FormEntity, field: FormField) {
  if (!entity.fields) return
  const idx = entity.fields.findIndex(f => f.id === field.id)
  if (idx > -1) {
    entity.fields.splice(idx, 1)
    if (selectedFieldId.value === field.id) selectedFieldId.value = ''
  }
}

async function onDeleteEntity(entity: FormEntity) {
  if (entity.entity_type === 'main') {
    ElMessage.warning('主表不可删除')
    return
  }
  // 孙表可直接删；子表删除需检查是否有孙表挂在下面
  if (entity.entity_type === 'sub') {
    const children = designEntities.value.filter(e => e.entity_type === 'grandchild' && e.parent_entity_code === entity.entity_code)
    if (children.length) {
      await ElMessageBox.confirm(
        `该子表下有 ${children.length} 个孙表，删除子表将一并删除其下孙表，确定继续？`,
        '删除确认',
        { type: 'warning' }
      )
      // 一并删除孙表
      children.forEach(c => {
        const i = designEntities.value.findIndex(e => e.entity_code === c.entity_code)
        if (i > -1) designEntities.value.splice(i, 1)
      })
    } else {
      await ElMessageBox.confirm(`确定删除子表「${entity.entity_name}」及其所有字段？`, '删除确认', { type: 'warning' })
    }
  } else {
    await ElMessageBox.confirm(`确定删除孙表「${entity.entity_name}」及其所有字段？`, '删除确认', { type: 'warning' })
  }
  const idx = designEntities.value.findIndex(e => e.entity_code === entity.entity_code)
  if (idx > -1) {
    designEntities.value.splice(idx, 1)
    if (activeEntityCode.value === entity.entity_code) {
      activeEntityCode.value = designEntities.value[0]?.entity_code || ''
    }
    selectedFieldId.value = ''
    ElMessage.success('删除成功')
  }
}

async function onSave() {
  await formApi.saveMeta(boCode.value, { entities: designEntities.value })
  ElMessage.success('表单元数据已保存')
}

// ============ 布局元数据持久化（PRD 5.2.10 + 1.1.4）============
const currentLayout = ref<FormLayout | null>(null)

// 构建布局 JSON：记录实体排序与分组，作为 meta_form_layout.layout_json 持久化
function buildLayoutJson(): string {
  const tabs = designEntities.value.map((e, idx) => ({
    entity_code: e.entity_code,
    entity_type: e.entity_type,
    entity_name: e.entity_name,
    sort: idx + 1
  }))
  const groups = currentEntity.value?.fields
    ? [...new Set(currentEntity.value.fields.map(f => f.group_name || ''))].filter(Boolean)
    : []
  return JSON.stringify({ tabs, groups, version: (currentLayout.value?.version || 0) + 1 })
}

// 加载布局：从默认布局回填实体排序
async function onLoadLayout() {
  if (!boCode.value) return
  try {
    const layout = await formLayoutApi.getDefault(boCode.value)
    if (!layout) {
      ElMessage.info('当前业务对象暂无保存的布局，使用默认排序')
      return
    }
    currentLayout.value = layout
    let parsed: { tabs?: Array<{ entity_code: string; sort: number }> } = {}
    try { parsed = JSON.parse(layout.layout_json || '{}') } catch { /* ignore */ }
    if (parsed.tabs?.length) {
      const orderMap = new Map(parsed.tabs.map(t => [t.entity_code, t.sort]))
      designEntities.value.sort((a, b) => (orderMap.get(a.entity_code) ?? 99) - (orderMap.get(b.entity_code) ?? 99))
      if (designEntities.value.length) activeEntityCode.value = designEntities.value[0].entity_code
    }
    ElMessage.success(`已加载布局「${layout.layout_name || '默认布局'}」v${layout.version}`)
  } catch {
    ElMessage.warning('加载布局失败')
  }
}

// 保存布局：将当前实体排序与分组持久化到 meta_form_layout
async function onSaveLayout() {
  if (!boCode.value) {
    ElMessage.warning('请先选择业务对象')
    return
  }
  if (!designEntities.value.length) {
    ElMessage.warning('当前无可保存的实体')
    return
  }
  const layoutJson = buildLayoutJson()
  const nextVersion = (currentLayout.value?.version || 0) + 1
  try {
    if (currentLayout.value?.id) {
      // 更新已有布局
      await formLayoutApi.update(currentLayout.value.id, {
        layout_json: layoutJson,
        version: nextVersion,
        is_default: 1
      })
      currentLayout.value = {
        ...currentLayout.value,
        layout_json: layoutJson,
        version: nextVersion
      }
    } else {
      // 新增布局并设为默认
      const created: any = await formLayoutApi.save({
        bo_code: boCode.value,
        layout_code: `${boCode.value.toUpperCase()}_DEFAULT`,
        layout_name: '默认布局',
        layout_json: layoutJson,
        is_default: 1,
        version: nextVersion
      })
      currentLayout.value = created
    }
    ElMessage.success(`布局已保存（v${nextVersion}），元数据变更已版本化`)
  } catch {
    ElMessage.error('布局保存失败')
  }
}

// 预览数据（使用空数据演示）
const previewData = ref<any>({})

// 预览模式 computed
const boName = computed(() => mainEntity.value?.entity_name || '')

const totalFieldCount = computed(() =>
  designEntities.value.reduce((sum, e) => sum + (e.fields?.length || 0), 0)
)

// 孙表扁平化数据：将各子表行下的孙表数据汇总为一个数组展示
function getFlatGrandchildData(gc: FormEntity): any[] {
  const allRows: any[] = []
  const parent = designEntities.value.find(e => e.entity_code === gc.parent_entity_code)
  if (!parent) return allRows
  const subData = previewData.value[gc.parent_entity_code] || []
  subData.forEach((subRow: any, si: number) => {
    const gcRows = subRow[gc.entity_code] || []
    gcRows.forEach((gcRow: any) => {
      allRows.push({ ...gcRow, _subRowIdx: si + 1 })
    })
  })
  return allRows
}

const previewModeLabel = computed(() => {
  return { view: '查看', edit: '编辑', add: '新增' }[mode.value]
})

function previewStateLabel(code: number): string {
  const map: Record<number, string> = { 0: '暂存', 1: '已创建', 2: '已提交', 3: '已审核', 4: '已驳回' }
  return map[code] || String(code)
}

function previewStateTagType(code: number): 'info' | 'primary' | 'warning' | 'success' | 'danger' {
  const map: Record<number, string> = { 0: 'info', 1: 'primary', 2: 'warning', 3: 'success', 4: 'danger' }
  return (map[code] as any) || 'info'
}

// 初始化预览数据（模拟正式单据数据，包含系统字段）
function initPreviewData() {
  const main = designEntities.value.find(e => e.entity_type === 'main')
  const data: Record<string, any> = {
    bill_no: 'PREVIEW-20260706-001',
    pact_state: 1,
    is_closed: false,
    is_cancel: false,
    create_by: '预览用户',
    create_time: '2026-07-06 10:00:00'
  }
  if (main?.fields) {
    main.fields.filter(f => !f.is_system).forEach(f => {
      if (f.field_code === 'bill_no') return
      if (f.ctrl_type === 'checkbox') data[f.field_code] = false
      else if (f.ctrl_type === 'number' || f.ctrl_type === 'amount' || f.ctrl_type === 'qty') data[f.field_code] = 0
      else if (f.ctrl_type === 'date') data[f.field_code] = '2026-07-06'
      else data[f.field_code] = ''
    })
  }
  // 子表初始化 2 行样例数据
  designEntities.value.filter(e => e.entity_type === 'sub').forEach(sub => {
    const rows: any[] = []
    for (let i = 0; i < 2; i++) {
      const row: any = { id: `preview_row_${i}` }
      sub.fields?.filter(f => !f.is_system && !f.is_hidden).forEach(f => {
        if (f.ctrl_type === 'number' || f.ctrl_type === 'qty') row[f.field_code] = (i + 1) * 10
        else if (f.ctrl_type === 'amount') row[f.field_code] = (i + 1) * 100
        else if (f.ctrl_type === 'date') row[f.field_code] = '2026-07-06'
        else row[f.field_code] = `${f.field_name}_${i + 1}`
      })
      // 孙表数据挂载
      designEntities.value.filter(e => e.entity_type === 'grandchild' && e.parent_entity_code === sub.entity_code).forEach(gc => {
        row[gc.entity_code] = [{ id: 'gc_1', assign_qty: (i + 1) * 5 }]
      })
      rows.push(row)
    }
    data[sub.entity_code] = rows
  })
  previewData.value = data
}

// 切换预览模式时自动初始化样例数据
watch(mode, (m) => {
  if (m !== 'design' && designEntities.value.length) {
    initPreviewData()
  }
})

onMounted(async () => {
  const qBoCode = route.query.boCode as string
  if (qBoCode) {
    boCode.value = qBoCode
    await loadEntities()
  }
})
</script>

<style scoped lang="scss">
.form-designer-page {
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
.designer-body {
  flex: 1;
  display: flex;
  gap: 12px;
  overflow: hidden;
}
.control-library {
  width: 200px;
  flex-shrink: 0;
  padding: 12px;
  overflow: auto;
}
.control-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.control-group-label {
  font-size: 12px;
  font-weight: 600;
  color: #909399;
  padding: 4px 0;
  border-bottom: 1px dashed #ebeef5;
  margin-bottom: 4px;
}
.control-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 10px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  cursor: grab;
  font-size: 12px;
  transition: all 0.2s;
  &:hover { border-color: #1564ff; color: #1564ff; }
  .control-icon { font-size: 14px; color: #1564ff; }
}
.container-control {
  align-items: flex-start;
  border-color: #b3d4ff;
  background: #f0f7ff;
  &:hover { border-color: #1564ff; background: #e6f0ff; }
  .control-icon { color: #1564ff; margin-top: 2px; }
  .container-text {
    display: flex;
    flex-direction: column;
    gap: 2px;
    .container-label { font-weight: 600; }
    .container-desc { font-size: 11px; color: #909399; line-height: 1.3; }
  }
}
.canvas-panel {
  flex: 1;
  padding: 12px 16px;
  overflow: auto;
  display: flex;
  flex-direction: column;
}
.property-panel {
  width: 300px;
  flex-shrink: 0;
  padding: 12px;
  overflow: auto;
}
.panel-header {
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.panel-title { font-size: 14px; font-weight: 600; }
.entity-info { margin-left: 10px; font-size: 12px; color: #909399; }
.empty-tip { display: flex; justify-content: center; padding: 40px 0; }
.canvas-content { 
  flex: 1; 
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 4px 0;
}
// 分层区段（主表/子表/孙表三层）
.layer-section {
  border: 1px solid #ebeef5;
  border-radius: 6px;
  overflow: hidden;
  transition: border-color 0.2s;
  &.active { border-color: #1564ff; box-shadow: 0 0 0 1px #1564ff inset; }
  &:hover { border-color: #b3d4ff; }
  .layer-bar {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    background: #f5f7fa;
    border-bottom: 1px solid #ebeef5;
    font-size: 13px;
    .layer-bar-name { font-weight: 600; }
  }
  :deep(.el-tabs--card) {
    box-shadow: none;
    border: none;
    .el-tabs__header { margin: 0; border-bottom: 1px solid #ebeef5; }
    .el-tabs__content { padding: 12px; }
  }
  .drop-zone {
    border-top: 1px dashed #dcdfe6;
    margin: 0 12px 12px;
    padding: 12px;
  }
  .layer-actions {
    padding: 8px 12px;
    border-top: 1px solid #ebeef5;
    background: #fafafa;
    display: flex;
    gap: 8px;
  }
}
// 孙表区段内实体属性条
.entity-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: #f5f7fa;
  border-radius: 4px;
  margin-bottom: 12px;
  font-size: 13px;
  .entity-bar-rel { color: #909399; font-size: 12px; }
}
// 小分组标签（子表/孙表内）
.group-label-sm {
  font-size: 12px;
  font-weight: 600;
  color: #909399;
  margin-bottom: 6px;
  padding-left: 6px;
  border-left: 2px solid #c0c4cc;
}
.field-group { margin-bottom: 16px; }
.group-label {
  font-size: 13px;
  font-weight: 600;
  color: #1564ff;
  margin-bottom: 8px;
  padding-left: 8px;
  border-left: 3px solid #1564ff;
}
.group-fields {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
// 设计模式子表/孙表表格
.design-table {
  :deep(th) { padding: 4px 6px !important; }
  .design-col-header {
    display: inline-flex;
    align-items: center;
    gap: 3px;
    cursor: pointer;
    padding: 2px 4px;
    border-radius: 3px;
    white-space: nowrap;
    &:hover { background: #ecf5ff; }
    &.selected { background: #ecf5ff; border-color: #1564ff; box-shadow: 0 0 0 1px #1564ff; }
    &.system { opacity: 0.7; }
    .col-name { font-size: 12px; font-weight: 500; }
    .col-code { font-size: 10px; color: #909399; }
    .system-icon { color: #c0c4cc; font-size: 11px; }
    .required-icon { color: #f56c6c; font-size: 11px; }
  }
  .sample-cell {
    color: #c0c4cc;
    font-size: 12px;
  }
}
.field-card {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  cursor: pointer;
  background: #fff;
  transition: all 0.2s;
  &:hover { border-color: #1564ff; }
  &.selected { border-color: #1564ff; background: #ecf5ff; }
  &.system { background: #f5f7fa; }
  .field-name { font-size: 13px; font-weight: 500; }
  .field-code { font-size: 11px; color: #909399; }
  .required-icon { color: #f56c6c; font-size: 12px; }
  .system-icon { color: #c0c4cc; font-size: 12px; }
}
.drop-zone {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 20px;
  border: 2px dashed #dcdfe6;
  border-radius: 4px;
  color: #c0c4cc;
  font-size: 12px;
  margin-top: 12px;
}
.mt-8 { margin-top: 8px; }
.entity-field-summary {
  .summary-row {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 4px 6px;
    border-radius: 3px;
    cursor: pointer;
    font-size: 12px;
    &:hover { background: #f5f7fa; }
    .summary-name { flex: 1; }
    .summary-code { color: #909399; font-size: 11px; }
  }
  .summary-empty {
    text-align: center;
    color: #c0c4cc;
    font-size: 12px;
    padding: 16px 0;
  }
}
// ============ 预览模式（参照 bill/sal_order/1 布局）============
.preview-mode-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow: hidden;
}
.preview-header {
  flex-shrink: 0;
  padding: 0;
  overflow: hidden;
  .preview-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 12px;
    background: #fafafa;
    border-bottom: 1px solid #ebeef5;
    flex-wrap: wrap;
    gap: 8px;
  }
  .preview-status {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
    .mode-tip {
      font-size: 12px;
      color: #909399;
      margin-left: 8px;
    }
  }
}
.preview-main {
  flex: 1;
  display: flex;
  gap: 12px;
  min-height: 0;
}
.preview-form {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    padding: 12px;
    .form-wrapper {
      flex: 1;
      overflow: auto;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
  }
// 扁平区段
.flat-section {
  .section-title {
    font-size: 14px;
    font-weight: 600;
    color: #303133;
    padding-bottom: 6px;
    margin-bottom: 10px;
    border-bottom: 2px solid #1564ff;
    display: flex;
    align-items: baseline;
    gap: 8px;
    .section-sub {
      font-size: 12px;
      font-weight: 400;
      color: #909399;
    }
  }
}
.flat-main-form {
  .el-row {
    margin-bottom: 0;
  }
}
.flat-table {
  width: 100%;
}
.preview-side {
  width: 340px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  .side-tabs {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 0 8px;
    :deep(.el-tabs__content) {
      flex: 1;
      overflow: auto;
    }
  }
}
.info-form {
  padding: 12px 8px;
}
</style>
