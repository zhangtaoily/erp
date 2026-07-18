<template>
  <div class="itp-page">
    <!-- 筛选栏 -->
    <div class="panel-card search-bar">
      <el-form :inline="true" size="small">
        <el-form-item label="业务对象">
          <el-select v-model="query.bo_code" clearable placeholder="全部" style="width:140px" @change="onSearch">
            <el-option v-for="b in boList" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px" @change="onSearch">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="关键字">
          <el-input v-model="query.keyword" clearable placeholder="编码/名称" style="width:180px" @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
          <el-button type="primary" plain @click="onAdd">新增模板</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表 -->
    <div class="panel-card table-panel">
      <div class="table-body">
        <el-table :data="tableData" size="small" border stripe v-loading="loading">
          <el-table-column type="index" label="#" width="45" />
          <el-table-column prop="template_code" label="模板编码" width="120" />
          <el-table-column prop="template_name" label="模板名称" min-width="160" />
          <el-table-column label="业务对象" width="110">
            <template #default="{ row }">{{ boLabel(row.bo_code) }}</template>
          </el-table-column>
          <el-table-column label="字段映射" width="90" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="info" effect="plain">{{ (row.field_mappings || []).length }} 项</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="unique_fields" label="唯一字段" width="140" show-overflow-tooltip />
          <el-table-column label="允许更新" width="80" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.allow_update === 1" size="small" type="success">是</el-tag>
              <el-tag v-else size="small" type="info">否</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="update_key" label="更新键" width="140" show-overflow-tooltip />
          <el-table-column label="出错策略" width="100">
            <template #default="{ row }">
              <el-tag :type="row.fail_fast === 1 ? 'danger' : 'warning'" size="small">{{ row.fail_fast === 1 ? '终止' : '跳过' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="70">
            <template #default="{ row }">
              <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
              <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="820px" append-to-body :close-on-click-modal="false">
      <el-form :model="form" label-width="110px" size="small">
        <el-row :gutter="12">
          <el-col :span="8">
            <el-form-item label="模板编码" required>
              <el-input v-model="form.template_code" :disabled="dialogMode === 'edit'" placeholder="如 material" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="模板名称" required>
              <el-input v-model="form.template_name" placeholder="如 物料导入模板" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="业务对象" required>
              <el-select v-model="form.bo_code" style="width:100%">
                <el-option v-for="b in boList" :key="b.code" :label="b.name" :value="b.code" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="8">
            <el-form-item label="唯一字段">
              <el-input v-model="form.unique_fields" placeholder="逗号分隔，如 mat_code" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="必填字段">
              <el-input v-model="form.required_fields" placeholder="逗号分隔" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="更新键">
              <el-input v-model="form.update_key" placeholder="允许更新时的匹配键" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :span="6">
            <el-form-item label="允许更新">
              <el-radio-group v-model="form.allow_update">
                <el-radio :value="1">是</el-radio>
                <el-radio :value="0">否</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="出错策略">
              <el-radio-group v-model="form.fail_fast">
                <el-radio :value="1">终止</el-radio>
                <el-radio :value="0">跳过</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="6">
            <el-form-item label="状态">
              <el-radio-group v-model="form.status">
                <el-radio :value="1">启用</el-radio>
                <el-radio :value="0">停用</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-divider content-position="left">字段映射（导入列 → 字段编码）</el-divider>
        <el-table :data="form.field_mappings" size="small" border>
          <el-table-column type="index" label="#" width="45" />
          <el-table-column label="字段编码" width="160">
            <template #default="{ row }"><el-input v-model="row.field_code" size="small" placeholder="如 mat_code" /></template>
          </el-table-column>
          <el-table-column label="列标题" width="160">
            <template #default="{ row }"><el-input v-model="row.field_name" size="small" placeholder="如 物料编码" /></template>
          </el-table-column>
          <el-table-column label="必填" width="70" align="center">
            <template #default="{ row }">
              <el-checkbox v-model="row.is_required" :true-value="1" :false-value="0" />
            </template>
          </el-table-column>
          <el-table-column label="数据类型" width="120">
            <template #default="{ row }">
              <el-select v-model="row.data_type" size="small" style="width:100%">
                <el-option label="文本" value="text" />
                <el-option label="数字" value="number" />
                <el-option label="金额" value="amount" />
                <el-option label="数量" value="qty" />
                <el-option label="日期" value="date" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column label="校验规则" min-width="140">
            <template #default="{ row }"><el-input v-model="row.validate_rule" size="small" placeholder="如 not_empty/regex" /></template>
          </el-table-column>
          <el-table-column label="默认值" width="120">
            <template #default="{ row }"><el-input v-model="row.default_value" size="small" /></template>
          </el-table-column>
          <el-table-column label="操作" width="70" align="center">
            <template #default="{ $index }">
              <el-button link type="danger" size="small" @click="onRemoveField($index)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div style="margin-top:8px">
          <el-button type="primary" plain size="small" @click="onAddField">+ 添加字段</el-button>
        </div>
        <el-form-item label="备注" style="margin-top:12px">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { importTemplateApi } from '@/api/sys-ext'
import type { ImportTemplate, ImportTemplateField } from '@/types/bo'

const loading = ref(false)
const tableData = ref<ImportTemplate[]>([])
const total = ref(0)
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const query = reactive({
  bo_code: '' as string,
  status: '' as string | number,
  keyword: '',
  pageNum: 1,
  pageSize: 10
})

const boList = [
  { code: 'material', name: '物料' },
  { code: 'customer', name: '客户' },
  { code: 'supplier', name: '供应商' },
  { code: 'sal_order', name: '销售订单' },
  { code: 'pur_order', name: '采购订单' },
  { code: 'mfg_order', name: '生产订单' }
]
function boLabel(c: string) { return boList.find(b => b.code === c)?.name || c }

const form = reactive<Partial<ImportTemplate>>({
  template_code: '', template_name: '', bo_code: 'material',
  field_mappings: [],
  unique_fields: '', required_fields: '',
  allow_update: 0, update_key: '', fail_fast: 0,
  status: 1, remark: ''
})

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增导入模板' : '编辑导入模板')

async function loadData() {
  loading.value = true
  try {
    const res: any = await importTemplateApi.list(query)
    tableData.value = res.list || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

function onSearch() { query.pageNum = 1; loadData() }
function onReset() {
  query.bo_code = ''; query.status = ''; query.keyword = ''
  query.pageNum = 1; loadData()
}

function onAdd() {
  dialogMode.value = 'add'
  Object.assign(form, {
    id: undefined, template_code: '', template_name: '', bo_code: 'material',
    field_mappings: [{ field_code: '', field_name: '', is_required: 1, data_type: 'text', sort_index: 1 }],
    unique_fields: '', required_fields: '',
    allow_update: 0, update_key: '', fail_fast: 0,
    status: 1, remark: ''
  })
  dialogVisible.value = true
}

function onEdit(row: ImportTemplate) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row, field_mappings: (row.field_mappings || []).map(f => ({ ...f })) })
  dialogVisible.value = true
}

function onAddField() {
  const next = ((form.field_mappings || []).length + 1)
  ;(form.field_mappings as ImportTemplateField[]).push({
    field_code: '', field_name: '', is_required: 0, data_type: 'text', sort_index: next
  })
}
function onRemoveField(idx: number) {
  (form.field_mappings as ImportTemplateField[]).splice(idx, 1)
}

async function onSave() {
  if (!form.template_code || !form.template_name || !form.bo_code) {
    ElMessage.warning('请填写模板编码、名称与业务对象'); return
  }
  if (!(form.field_mappings || []).length) {
    ElMessage.warning('请至少添加一个字段映射'); return
  }
  if (dialogMode.value === 'add') {
    await importTemplateApi.create({ ...form })
    ElMessage.success('新增成功')
  } else {
    await importTemplateApi.update((form as ImportTemplate).id!, { ...form })
    ElMessage.success('保存成功')
  }
  dialogVisible.value = false
  loadData()
}

async function onDelete(row: ImportTemplate) {
  await ElMessageBox.confirm(`确定删除模板「${row.template_name}」？`, '提示', { type: 'warning' })
  await importTemplateApi.delete(row.id!)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.itp-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.search-bar { padding: 12px 12px 0; }
.table-panel {
  padding: 12px;
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-body {
  flex: 1;
  overflow: auto;
}
.pagination-bar { margin-top: 12px; display: flex; justify-content: flex-end; }
:deep(.el-divider__text) { font-size: 13px; font-weight: 600; }
</style>
