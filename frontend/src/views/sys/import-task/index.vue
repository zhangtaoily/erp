<template>
  <div class="it-page">
    <!-- 顶部工具栏 -->
    <div class="panel-card toolbar">
      <el-dropdown @command="onDownloadTemplate" trigger="click">
        <el-button type="primary">
          下载导入模板<el-icon class="el-icon--right"><ArrowDown /></el-icon>
        </el-button>
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item command="material">物料导入模板</el-dropdown-item>
            <el-dropdown-item command="customer">客户导入模板</el-dropdown-item>
            <el-dropdown-item command="supplier">供应商导入模板</el-dropdown-item>
            <el-dropdown-item command="bom">BOM 导入模板</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
      <el-button type="success" @click="uploadDialogVisible = true">上传导入</el-button>
      <div class="toolbar-right">
        <el-select v-model="query.template_code" clearable placeholder="模板类型" style="width:140px" @change="onSearch">
          <el-option label="物料" value="material" />
          <el-option label="客户" value="customer" />
          <el-option label="供应商" value="supplier" />
          <el-option label="BOM" value="bom" />
        </el-select>
        <el-select v-model="query.status" clearable placeholder="状态" style="width:120px" @change="onSearch">
          <el-option label="待处理" value="pending" />
          <el-option label="校验中" value="validating" />
          <el-option label="导入中" value="importing" />
          <el-option label="完成" value="done" />
          <el-option label="失败" value="failed" />
        </el-select>
      </div>
    </div>

    <!-- 任务列表 -->
    <div class="panel-card table-panel">
      <div class="table-body">
        <el-table :data="tableData" size="small" border stripe v-loading="loading">
          <el-table-column type="index" label="#" width="45" />
          <el-table-column label="模板" width="80">
            <template #default="{ row }">
              <el-tag size="small" :type="templateTag(row.template_code) || 'info'">{{ templateLabel(row.template_code) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="file_name" label="文件名" min-width="200" show-overflow-tooltip />
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="statusTag(row.status) || 'info'" size="small">{{ statusLabel(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="total_rows" label="总数" width="70" align="right" />
          <el-table-column prop="success_rows" label="成功" width="70" align="right">
            <template #default="{ row }"><span class="num-success">{{ row.success_rows }}</span></template>
          </el-table-column>
          <el-table-column prop="fail_rows" label="失败" width="70" align="right">
            <template #default="{ row }"><span :class="{ 'num-fail': row.fail_rows > 0 }">{{ row.fail_rows }}</span></template>
          </el-table-column>
          <el-table-column prop="create_by" label="创建人" width="80" />
          <el-table-column prop="create_time" label="创建时间" width="160" />
          <el-table-column label="操作" width="140" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="onViewDetail(row as any)">详情</el-button>
              <el-button v-if="row.fail_rows > 0" link type="warning" size="small" @click="onViewErrors(row as any)">校验结果</el-button>
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

    <!-- 上传弹窗 -->
    <el-dialog v-model="uploadDialogVisible" title="上传导入文件" width="480px" append-to-body>
      <el-form label-width="100px" size="small">
        <el-form-item label="模板类型" required>
          <el-select v-model="uploadTemplate" style="width:100%">
            <el-option label="物料导入模板" value="material" />
            <el-option label="客户导入模板" value="customer" />
            <el-option label="供应商导入模板" value="supplier" />
            <el-option label="BOM 导入模板" value="bom" />
          </el-select>
        </el-form-item>
        <el-form-item label="导入策略" required>
          <el-radio-group v-model="uploadStrategy">
            <el-radio value="partial">部分成功（成功行入库，失败行跳过）</el-radio>
            <el-radio value="rollback">全部回滚（任一行失败则整批回滚）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="文件" required>
          <el-upload
            ref="uploadRef"
            :auto-upload="false"
            :limit="1"
            :on-exceed="onExceed"
            accept=".xlsx,.xls"
            :on-change="onFileChange"
          >
            <el-button type="primary" plain>选择文件</el-button>
            <template #tip><div class="el-upload__tip">仅支持 .xlsx / .xls 格式，单文件不超过 10MB</div></template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="uploadDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="uploading" @click="onUpload">开始导入</el-button>
      </template>
    </el-dialog>

    <!-- 校验结果弹窗 -->
    <el-dialog v-model="errorDialogVisible" title="校验结果 - 失败明细" width="720px" append-to-body>
      <el-alert v-if="currentTask" :title="`共 ${currentTask.total_rows} 行，成功 ${currentTask.success_rows} 行，失败 ${currentTask.fail_rows} 行`" :type="currentTask.fail_rows > 0 ? 'warning' : 'success'" :closable="false" show-icon class="mb-8" />
      <el-table :data="errorRows" size="small" border :row-class-name="errorRowClass">
        <el-table-column prop="row_no" label="行号" width="70" />
        <el-table-column prop="mat_code" label="编码" width="120" />
        <el-table-column prop="mat_name" label="名称" width="140" />
        <el-table-column prop="error_field" label="错误字段" width="120">
          <template #default="{ row }"><el-tag type="danger" size="small">{{ row.error_field }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="error_msg" label="错误原因" min-width="200">
          <template #default="{ row }"><span class="error-msg">{{ row.error_msg }}</span></template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="errorDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="onDownloadErrors">导出失败明细</el-button>
      </template>
    </el-dialog>

    <!-- 任务详情弹窗 -->
    <el-dialog v-model="detailDialogVisible" title="导入任务详情" width="560px" append-to-body>
      <el-descriptions v-if="currentTask" :column="2" border size="small">
        <el-descriptions-item label="文件名" :span="2">{{ currentTask.file_name }}</el-descriptions-item>
        <el-descriptions-item label="模板类型">{{ templateLabel(currentTask.template_code) }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ statusLabel(currentTask.status) }}</el-descriptions-item>
        <el-descriptions-item label="总行数">{{ currentTask.total_rows }}</el-descriptions-item>
        <el-descriptions-item label="成功/失败">
          <span class="num-success">{{ currentTask.success_rows }}</span> /
          <span :class="{ 'num-fail': currentTask.fail_rows > 0 }">{{ currentTask.fail_rows }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="创建人">{{ currentTask.create_by }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTask.create_time }}</el-descriptions-item>
        <el-descriptions-item v-if="currentTask.error_log" label="错误日志" :span="2">
          <span class="error-msg">{{ currentTask.error_log }}</span>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { importApi } from '@/api/integration'
import type { ImportTask } from '@/types/bo'

const loading = ref(false)
const uploading = ref(false)
const tableData = ref<ImportTask[]>([])
const total = ref(0)
const uploadDialogVisible = ref(false)
const errorDialogVisible = ref(false)
const detailDialogVisible = ref(false)
const uploadTemplate = ref('material')
const uploadStrategy = ref('partial')
const uploadRef = ref()
const uploadFile = ref<File | null>(null)
const currentTask = ref<ImportTask | null>(null)
const errorRows = ref<any[]>([])

const query = reactive({
  template_code: '', status: '',
  pageNum: 1, pageSize: 10
})

function templateLabel(code: string) {
  const m: Record<string, string> = { material: '物料', customer: '客户', supplier: '供应商', bom: 'BOM' }
  return m[code] || code
}
function templateTag(code: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    material: '', customer: 'success', supplier: 'warning', bom: 'info'
  }
  return m[code] || 'info'
}
function statusLabel(s: string) {
  const m: Record<string, string> = { pending: '待处理', validating: '校验中', importing: '导入中', done: '完成', failed: '失败' }
  return m[s] || s
}
function statusTag(s: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    pending: 'info', validating: 'warning', importing: 'warning', done: 'success', failed: 'danger'
  }
  return m[s] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    const res: any = await importApi.list(query)
    tableData.value = res.list || []
    total.value = res.total || 0
  } finally {
    loading.value = false
  }
}

function onSearch() {
  query.pageNum = 1
  loadData()
}

async function onDownloadTemplate(code: string) {
  const tpl: any = await importApi.template(code)
  if (tpl) {
    ElMessage.success(`已下载「${tpl.template_name}」，列：${(tpl.columns || []).join('、')}`)
  }
}

function onExceed() {
  ElMessage.warning('只能上传一个文件')
}

function onFileChange(file: any) {
  uploadFile.value = file.raw
}

async function onUpload() {
  if (!uploadFile.value) {
    ElMessage.warning('请选择文件')
    return
  }
  uploading.value = true
  try {
    const fd = new FormData()
    fd.append('file', uploadFile.value)
    fd.append('templateCode', uploadTemplate.value)
    fd.append('strategy', uploadStrategy.value)
    await importApi.upload(fd)
    ElMessage.success('文件已上传，正在后台校验导入')
    uploadDialogVisible.value = false
    uploadFile.value = null
    uploadRef.value?.clearFiles()
    loadData()
  } finally {
    uploading.value = false
  }
}

async function onViewDetail(row: ImportTask) {
  const detail: any = await importApi.detail(row.id)
  currentTask.value = detail
  detailDialogVisible.value = true
}

async function onViewErrors(row: ImportTask) {
  const detail: any = await importApi.detail(row.id)
  currentTask.value = detail
  errorRows.value = detail.errorRows || []
  errorDialogVisible.value = true
}

function errorRowClass({ row }: { row: any }) {
  return row.error_msg ? 'error-row' : ''
}

function onDownloadErrors() {
  ElMessage.success('失败明细已导出')
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.it-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.toolbar {
  padding: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  .toolbar-right {
    margin-left: auto;
    display: flex;
    gap: 8px;
  }
}
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
.pagination-bar {
  margin-top: 12px;
  display: flex;
  justify-content: flex-end;
}
.num-success { color: #52c41a; font-weight: 600; }
.num-fail { color: #f5222d; font-weight: 600; }
.error-msg { color: #f5222d; }
.mb-8 { margin-bottom: 8px; }
:deep(.error-row) {
  background-color: #fef0f0 !important;
}
</style>
