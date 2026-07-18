<template>
  <div class="button-config-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-label">业务对象：</span>
        <BoPicker v-model="boCode" style="width: 280px" @change="onBoChange" />
        <el-tag v-if="boCode" size="small" type="info" effect="plain">
          {{ buttons.length }} 个按钮 / 自定义 {{ customButtons.length }}
        </el-tag>
        <el-tag v-if="dirty" size="small" type="warning" effect="plain">未保存</el-tag>
      </div>
      <div class="header-right">
        <el-button size="small" :disabled="!boCode" @click="onAddCustom">
          <el-icon><Plus /></el-icon>新增自定义按钮
        </el-button>
        <el-button type="success" size="small" :disabled="!boCode" @click="onSaveAll">
          <el-icon><Check /></el-icon>保存全部
        </el-button>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body panel-card">
      <div class="panel-header">
        <span class="panel-title">按钮可用性配置</span>
        <span class="panel-tip">点击矩阵单元格循环切换可用性，点击自定义按钮行编辑属性</span>
      </div>
      <div class="config-body">
        <el-empty v-if="!boCode" description="请先选择业务对象" :image-size="60" />
        <template v-else>
          <!-- 可用性矩阵 -->
          <div class="matrix-section">
            <ButtonMatrix :buttons="buttons" @change="onMatrixChange" />
          </div>

          <!-- 自定义按钮列表 -->
          <div class="custom-section">
            <div class="section-title">
              <span>自定义按钮</span>
              <el-button type="primary" link size="small" @click="onAddCustom">
                <el-icon><Plus /></el-icon>新增
              </el-button>
            </div>
            <el-table
              :data="customButtons"
              border
              size="small"
              style="width: 100%"
              @row-click="(row: any) => onEdit(row)"
            >
              <el-table-column label="按钮编码" prop="button_code" min-width="130" />
              <el-table-column label="按钮名称" prop="button_name" min-width="130" />
              <el-table-column label="位置" width="100" align="center">
                <template #default="{ row }">
                  <el-tag size="small" :type="positionTagType(row.position)" effect="plain">
                    {{ positionLabel(row.position) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="二次确认" width="90" align="center">
                <template #default="{ row }">
                  <el-tag
                    size="small"
                    :type="row.need_confirm ? 'warning' : 'info'"
                    effect="plain"
                  >
                    {{ row.need_confirm ? '是' : '否' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="绑定插件" min-width="150">
                <template #default="{ row }">
                  <span :class="{ 'muted': !row.bind_plugin }">
                    {{ row.bind_plugin || '—' }}
                  </span>
                </template>
              </el-table-column>
              <el-table-column label="排序" prop="sort_index" width="70" align="center" />
              <el-table-column label="操作" width="130" align="center" fixed="right">
                <template #default="{ row }">
                  <el-button type="primary" link size="small" @click.stop="onEdit(row as any)">
                    编辑
                  </el-button>
                  <el-button type="danger" link size="small" @click.stop="onDeleteCustom(row as any)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
              <template #empty>
                <el-empty description="暂无自定义按钮，点击“新增”添加" :image-size="40" />
              </template>
            </el-table>
          </div>
        </template>
      </div>
    </div>

    <!-- 编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="480px"
      append-to-body
      destroy-on-close
    >
      <el-form :model="editForm" label-width="100px" size="small">
        <el-form-item label="按钮编码" required>
          <el-input
            v-model="editForm.button_code"
            placeholder="如 export"
            :disabled="!editForm.is_custom"
          />
        </el-form-item>
        <el-form-item label="按钮名称" required>
          <el-input v-model="editForm.button_name" placeholder="如 导出" />
        </el-form-item>
        <el-form-item label="图标">
          <el-input v-model="editForm.icon" placeholder="Element Plus 图标名，如 Download" />
        </el-form-item>
        <el-form-item label="位置">
          <el-select v-model="editForm.position" style="width: 100%">
            <el-option label="表单" value="form" />
            <el-option label="列表" value="list" />
            <el-option label="表单+列表" value="both" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number
            v-model="editForm.sort_index"
            :min="0"
            :max="999"
            controls-position="right"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="二次确认">
          <el-switch v-model="editForm.need_confirm" />
          <span class="form-tip">删除/审核等高危操作建议开启</span>
        </el-form-item>
        <el-form-item label="绑定插件">
          <el-input
            v-model="editForm.bind_plugin"
            placeholder="OnCustomButtonClick 插件 code"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" size="small" @click="onConfirmEdit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Check } from '@element-plus/icons-vue'
import BoPicker from '@/components/BoPicker/index.vue'
import ButtonMatrix from '@/components/ButtonMatrix/index.vue'
import { buttonApi } from '@/api/state'
import type { ButtonDef, ButtonAvailability, BusinessObject } from '@/types/bo'

const DEFAULT_AVAIL: ButtonAvailability[] = ['disabled', 'disabled', 'disabled', 'disabled', 'disabled']

const boCode = ref('')
const buttons = ref<ButtonDef[]>([])
const dirty = ref(false)

const customButtons = computed(() => buttons.value.filter(b => b.is_custom))

const dialogVisible = ref(false)
const dialogTitle = ref('编辑按钮')
const editingId = ref('')
const editForm = reactive<ButtonDef>({
  id: '',
  bo_code: '',
  button_code: '',
  button_name: '',
  icon: '',
  position: 'both',
  sort_index: 0,
  is_custom: false,
  need_confirm: false,
  bind_plugin: '',
  availability: [...DEFAULT_AVAIL]
})

function onBoChange(bo: BusinessObject | null) {
  const code = bo?.bo_code || ''
  boCode.value = code
  if (!code) {
    buttons.value = []
    dirty.value = false
    return
  }
  loadButtons()
}

async function loadButtons() {
  if (!boCode.value) return
  const res: any = await buttonApi.list(boCode.value)
  buttons.value = Array.isArray(res) ? res : []
  dirty.value = false
}

function onMatrixChange(list: ButtonDef[]) {
  buttons.value = list
  dirty.value = true
}

function positionLabel(p: string): string {
  if (p === 'form') return '表单'
  if (p === 'list') return '列表'
  return '表单+列表'
}

function positionTagType(p: string): 'primary' | 'success' | 'info' {
  if (p === 'form') return 'primary'
  if (p === 'list') return 'success'
  return 'info'
}

function resetEditForm() {
  Object.assign(editForm, {
    id: '',
    bo_code: boCode.value,
    button_code: '',
    button_name: '',
    icon: '',
    position: 'both',
    sort_index: buttons.value.length + 1,
    is_custom: false,
    need_confirm: false,
    bind_plugin: '',
    availability: [...DEFAULT_AVAIL]
  })
}

function onEdit(row: ButtonDef) {
  editingId.value = row.id
  dialogTitle.value = row.is_custom ? '编辑自定义按钮' : '编辑按钮'
  const clone = JSON.parse(JSON.stringify(row))
  Object.assign(editForm, clone)
  editForm.availability = [...(row.availability || DEFAULT_AVAIL)]
  dialogVisible.value = true
}

function onAddCustom() {
  editingId.value = ''
  dialogTitle.value = '新增自定义按钮'
  resetEditForm()
  editForm.is_custom = true
  dialogVisible.value = true
}

async function onConfirmEdit() {
  if (!editForm.button_code.trim()) {
    ElMessage.warning('请输入按钮编码')
    return
  }
  if (!editForm.button_name.trim()) {
    ElMessage.warning('请输入按钮名称')
    return
  }
  const payload: Partial<ButtonDef> = {
    bo_code: boCode.value,
    button_code: editForm.button_code,
    button_name: editForm.button_name,
    icon: editForm.icon,
    position: editForm.position,
    sort_index: editForm.sort_index,
    is_custom: editForm.is_custom,
    need_confirm: editForm.need_confirm,
    bind_plugin: editForm.bind_plugin,
    availability: [...editForm.availability]
  }
  try {
    if (!editingId.value) {
      const saved: any = await buttonApi.create(payload)
      const id = saved?.id || `btn_${Date.now()}`
      buttons.value = [...buttons.value, { id, ...payload } as ButtonDef]
      ElMessage.success('新增成功')
    } else {
      await buttonApi.update(editingId.value, payload)
      const idx = buttons.value.findIndex(b => b.id === editingId.value)
      if (idx > -1) {
        buttons.value = [
          ...buttons.value.slice(0, idx),
          { ...buttons.value[idx], ...payload },
          ...buttons.value.slice(idx + 1)
        ]
      }
      ElMessage.success('保存成功')
    }
    dirty.value = true
    dialogVisible.value = false
  } catch {
    ElMessage.error('保存失败')
  }
}

function onDeleteCustom(row: ButtonDef) {
  ElMessageBox.confirm(`确定删除自定义按钮「${row.button_name}」吗？`, '提示', {
    type: 'warning'
  })
    .then(async () => {
      try {
        await buttonApi.delete(row.id)
      } catch {
        /* mock 容错 */
      }
      buttons.value = buttons.value.filter(b => b.id !== row.id)
      ElMessage.success('删除成功')
    })
    .catch(() => {})
}

async function onSaveAll() {
  for (const btn of buttons.value) {
    try {
      await buttonApi.update(btn.id, {
        availability: btn.availability,
        position: btn.position,
        sort_index: btn.sort_index,
        need_confirm: btn.need_confirm,
        bind_plugin: btn.bind_plugin,
        icon: btn.icon,
        button_name: btn.button_name
      })
    } catch {
      /* mock 容错 */
    }
  }
  dirty.value = false
  ElMessage.success('保存成功')
}
</script>

<style scoped lang="scss">
.button-config-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  flex-shrink: 0;
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
.main-body {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.panel-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  .panel-title {
    font-size: 13px;
    font-weight: 600;
    color: #303133;
  }
  .panel-tip {
    font-size: 12px;
    color: #909399;
  }
}
.config-body {
  flex: 1;
  overflow: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.matrix-section {
  display: flex;
  flex-direction: column;
}
.custom-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  padding-left: 8px;
  border-left: 3px solid #1564ff;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.muted {
  color: #c0c4cc;
}
.form-tip {
  margin-left: 8px;
  font-size: 12px;
  color: #909399;
}
:deep(.el-empty) {
  padding: 16px;
}
</style>
