<template>
  <div class="bo-page">
    <!-- 查询条 -->
    <div class="query-bar panel-card">
      <el-form :model="query" inline size="small">
        <el-form-item label="编码">
          <el-input v-model="query.bo_code" placeholder="业务对象编码" clearable @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item label="名称">
          <el-input v-model="query.bo_name" placeholder="业务对象名称" clearable @keyup.enter="onSearch" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="query.bo_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="o in BO_TYPE_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSearch">查询</el-button>
          <el-button @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格 -->
    <div class="table-wrap panel-card">
      <div class="table-toolbar">
        <span class="panel-title">业务对象列表</span>
        <el-button type="primary" size="small" @click="onAdd">新增</el-button>
      </div>
      <div class="table-body">
        <el-table :data="tableData" v-loading="loading" size="small" border stripe @row-dblclick="onEdit">
          <el-table-column prop="bo_code" label="编码" width="140" fixed />
          <el-table-column prop="bo_name" label="名称" min-width="120" />
          <el-table-column label="类型" width="90" align="center">
            <template #default="{ row }">
              <el-tag :type="boTypeTag(row.bo_type)" size="small">{{ boTypeLabel(row.bo_type) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="main_table" label="主表" width="140" />
          <el-table-column label="状态机" width="70" align="center">
            <template #default="{ row }">
              <el-switch :model-value="row.is_stateful" disabled />
            </template>
          </el-table-column>
          <el-table-column label="下推" width="60" align="center">
            <template #default="{ row }">
              <el-switch :model-value="row.is_pushable" disabled />
            </template>
          </el-table-column>
          <el-table-column label="打印" width="60" align="center">
            <template #default="{ row }">
              <el-switch :model-value="row.is_printable" disabled />
            </template>
          </el-table-column>
          <el-table-column label="组织类型" width="90" align="center">
            <template #default="{ row }">{{ orgTypeLabel(row.org_type) }}</template>
          </el-table-column>
          <el-table-column label="状态" width="80" align="center">
            <template #default="{ row }">
              <el-switch :model-value="row.status === 1" @change="onToggleStatus(row as any)" />
            </template>
          </el-table-column>
          <el-table-column label="操作" width="160" fixed="right" align="center">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
              <el-button link type="primary" size="small" @click="onView(row as any)">查看</el-button>
              <el-button link :type="row.status === 1 ? 'danger' : 'success'" size="small" @click="onToggleStatus(row as any)">
                {{ row.status === 1 ? '停用' : '启用' }}
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <div class="pager-wrap">
        <el-pagination
          v-model:current-page="page.pageNum"
          v-model:page-size="page.pageSize"
          :total="page.total"
          :page-sizes="[20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadList"
          @current-change="loadList"
        />
      </div>
    </div>

    <!-- 新增弹窗 -->
    <el-dialog v-model="dialogVisible" title="新增业务对象" width="560px" append-to-body>
      <el-form :model="form" label-width="100px" size="small">
        <el-form-item label="编码" required>
          <el-input v-model="form.bo_code" placeholder="如：sal_order（保存后不可修改）" />
        </el-form-item>
        <el-form-item label="名称" required>
          <el-input v-model="form.bo_name" placeholder="如：销售订单" />
        </el-form-item>
        <el-form-item label="类型" required>
          <el-radio-group v-model="form.bo_type">
            <el-radio v-for="o in BO_TYPE_OPTIONS" :key="o.value" :value="o.value">{{ o.label }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="主表名" required>
          <el-input v-model="form.main_table" placeholder="如：sal_order" />
        </el-form-item>
        <el-form-item label="主键策略">
          <el-select v-model="form.pk_strategy" style="width:100%">
            <el-option v-for="o in PK_STRATEGY_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="适用组织">
          <el-select v-model="form.org_type" style="width:100%">
            <el-option v-for="o in ORG_TYPE_OPTIONS" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="行为特性">
          <el-checkbox v-model="form.is_stateful">启用状态机</el-checkbox>
          <el-checkbox v-model="form.is_pushable">支持下推</el-checkbox>
          <el-checkbox v-model="form.is_printable">启用打印</el-checkbox>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { boApi } from '@/api/bo'
import { BO_TYPE_OPTIONS, PK_STRATEGY_OPTIONS, ORG_TYPE_OPTIONS } from '@/utils/enum'
import type { BusinessObject, BoType } from '@/types/bo'

const router = useRouter()

const loading = ref(false)
const tableData = ref<BusinessObject[]>([])
const dialogVisible = ref(false)

const query = reactive({ bo_code: '', bo_name: '', bo_type: '' as '' | BoType, status: '' as '' | number })
const page = reactive({ pageNum: 1, pageSize: 20, total: 0 })

const form = reactive<Partial<BusinessObject>>({
  bo_code: '', bo_name: '', bo_type: 'bill', main_table: '',
  pk_strategy: 'snowflake', org_type: 'company',
  is_stateful: true, is_pushable: false, is_printable: true, remark: ''
})

function boTypeLabel(t: BoType) {
  return BO_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}
function boTypeTag(t: BoType): 'primary' | 'success' | 'warning' {
  if (t === 'bill') return 'primary'
  if (t === 'master') return 'success'
  return 'warning'
}
function orgTypeLabel(t: string) {
  return ORG_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}

async function loadList() {
  loading.value = true
  try {
    const res: any = await boApi.list({
      bo_type: query.bo_type || undefined,
      keyword: query.bo_code || query.bo_name || undefined,
      pageNum: page.pageNum,
      pageSize: page.pageSize
    })
    let list = res?.list || res || []
    // 前端过滤
    if (query.bo_code) list = list.filter((b: BusinessObject) => b.bo_code.includes(query.bo_code))
    if (query.bo_name) list = list.filter((b: BusinessObject) => b.bo_name.includes(query.bo_name))
    if (query.status !== '' && query.status !== undefined) list = list.filter((b: BusinessObject) => b.status === query.status)
    tableData.value = list
    page.total = res?.total || list.length
  } finally {
    loading.value = false
  }
}

function onSearch() {
  page.pageNum = 1
  loadList()
}
function onReset() {
  query.bo_code = ''
  query.bo_name = ''
  query.bo_type = ''
  query.status = ''
  onSearch()
}

function onAdd() {
  Object.assign(form, {
    bo_code: '', bo_name: '', bo_type: 'bill', main_table: '',
    pk_strategy: 'snowflake', org_type: 'company',
    is_stateful: true, is_pushable: false, is_printable: true, remark: ''
  })
  dialogVisible.value = true
}

async function onSave() {
  if (!form.bo_code || !form.bo_name || !form.main_table) {
    ElMessage.warning('请填写编码、名称和主表名')
    return
  }
  const res: any = await boApi.create({ ...form })
  ElMessage.success('新增成功，已自动初始化主实体与系统字段')
  dialogVisible.value = false
  await loadList()
  // 保存成功后跳转 entity-model 页面展示初始化结果（GAP-D01-012 / RISK-D01-003）
  const boCode = res?.bo_code || form.bo_code
  if (boCode) {
    router.push({ path: '/bos/entity-model', query: { boCode, initialized: '1' } })
  }
}

function onEdit(row: BusinessObject) {
  router.push({ path: '/bos/entity-model', query: { boCode: row.bo_code } })
}

function onView(row: BusinessObject) {
  router.push({ path: '/bos/entity-model', query: { boCode: row.bo_code, readonly: '1' } })
}

async function onToggleStatus(row: BusinessObject) {
  const newStatus = row.status === 1 ? 0 : 1
  const action = newStatus === 0 ? '停用' : '启用'
  await ElMessageBox.confirm(`确认${action}业务对象「${row.bo_name}」？`, '提示', { type: 'warning' })
  await boApi.toggleStatus(row.bo_code, newStatus)
  ElMessage.success(`${action}成功`)
  await loadList()
}

onMounted(loadList)
</script>

<style scoped lang="scss">
.bo-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.query-bar {
  padding: 12px 16px 0;
  .el-form-item { margin-bottom: 12px; }
}
.table-wrap {
  flex: 1;
  padding: 12px 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.table-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.table-body {
  flex: 1;
  overflow: auto;
}
.panel-title { font-size: 14px; font-weight: 600; }
.pager-wrap {
  margin-top: 10px;
  display: flex;
  justify-content: flex-end;
}
</style>
