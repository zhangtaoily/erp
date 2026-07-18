<template>
  <div class="st-page page-container">
    <!-- 当前激活存储 -->
    <div class="panel-card active-panel">
      <div class="panel-header">
        <span class="panel-title">当前附件存储</span>
        <el-button type="primary" size="small" @click="onAdd">新增存储配置</el-button>
      </div>
      <el-alert v-if="activeConfig" type="success" :closable="false" show-icon>
        <template #title>
          当前激活：<b>{{ storageTypeLabel(activeConfig.storage_type) }}</b>
          <span v-if="activeConfig.storage_type === 'local'">（路径：{{ activeConfig.base_path }}）</span>
          <span v-else>（{{ activeConfig.endpoint }} / bucket：{{ activeConfig.bucket }}）</span>
          ；单文件上限 {{ activeConfig.max_file_size }} MB；允许类型：{{ activeConfig.allowed_types }}
        </template>
      </el-alert>
      <el-alert v-else type="warning" :closable="false" show-icon title="尚未激活任何存储配置" />
    </div>

    <!-- 存储配置列表 -->
    <div class="panel-card table-panel">
      <div class="panel-header">
        <span class="panel-title">存储配置列表</span>
      </div>
      <el-table :data="tableData" size="small" border stripe v-loading="loading">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column label="存储类型" width="120">
          <template #default="{ row }">
            <el-tag :type="storageTypeTag(row.storage_type) || 'info'" size="small">{{ storageTypeLabel(row.storage_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="端点/路径" min-width="200">
          <template #default="{ row }">
            <span v-if="row.storage_type === 'local'">{{ row.base_path }}</span>
            <span v-else>{{ row.endpoint }}<span v-if="row.region"> / {{ row.region }}</span></span>
          </template>
        </el-table-column>
        <el-table-column prop="bucket" label="Bucket" width="140">
          <template #default="{ row }">{{ row.bucket || '-' }}</template>
        </el-table-column>
        <el-table-column label="允许文件类型" min-width="180" show-overflow-tooltip>
          <template #default="{ row }">
            <el-tag v-for="t in (row.allowed_types || '').split(',').filter(Boolean)" :key="t" size="small" type="info" effect="plain" class="type-tag">{{ t }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="单文件上限" width="110" align="right">
          <template #default="{ row }">{{ row.max_file_size }} MB</template>
        </el-table-column>
        <el-table-column label="总上限" width="100" align="right">
          <template #default="{ row }">{{ row.max_total_size ? row.max_total_size + ' MB' : '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '激活' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button v-if="row.status !== 1" link type="success" size="small" @click="onActivate(row as any)">激活</el-button>
            <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
            <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" append-to-body>
      <el-form :model="form" label-width="120px" size="small">
        <el-form-item label="存储类型" required>
          <el-select v-model="form.storage_type" style="width:100%" :disabled="dialogMode === 'edit'">
            <el-option label="本地存储（local）" value="local" />
            <el-option label="阿里云 OSS（oss）" value="oss" />
            <el-option label="MinIO（minio）" value="minio" />
            <el-option label="AWS S3（s3）" value="s3" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.storage_type === 'local'" label="存储路径" required>
          <el-input v-model="form.base_path" placeholder="如 /data/attachments" />
        </el-form-item>
        <template v-else>
          <el-form-item label="Endpoint" required>
            <el-input v-model="form.endpoint" placeholder="如 oss-cn-hangzhou.aliyuncs.com" />
          </el-form-item>
          <el-form-item label="AccessKey">
            <el-input v-model="form.access_key" placeholder="AccessKey" />
          </el-form-item>
          <el-form-item label="SecretKey">
            <el-input v-model="form.secret_key" type="password" show-password placeholder="SecretKey" />
          </el-form-item>
          <el-form-item label="Bucket" required>
            <el-input v-model="form.bucket" placeholder="bucket 名称" />
          </el-form-item>
          <el-form-item label="Region">
            <el-input v-model="form.region" placeholder="如 cn-hangzhou" />
          </el-form-item>
        </template>
        <el-divider content-position="left">文件限制</el-divider>
        <el-form-item label="允许文件类型" required>
          <el-input v-model="form.allowed_types" placeholder="逗号分隔，如 pdf,docx,xlsx,jpg,png" />
          <div class="form-tip">上传时按扩展名白名单校验</div>
        </el-form-item>
        <el-form-item label="单文件上限（MB）" required>
          <el-input-number v-model="form.max_file_size" :min="1" :max="2048" controls-position="right" style="width:100%" />
        </el-form-item>
        <el-form-item label="单据总上限（MB）">
          <el-input-number v-model="form.max_total_size" :min="0" :max="10240" controls-position="right" style="width:100%" />
          <div class="form-tip">单业务对象附件总上限，0 表示不限</div>
        </el-form-item>
        <el-form-item label="备注">
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
import { storageApi } from '@/api/sys-ext'
import type { StorageConfig } from '@/types/bo'

const loading = ref(false)
const tableData = ref<StorageConfig[]>([])
const activeConfig = ref<StorageConfig | null>(null)
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const form = reactive<Partial<StorageConfig>>({
  storage_type: 'local',
  base_path: '/data/attachments',
  endpoint: '', access_key: '', secret_key: '', bucket: '', region: '',
  allowed_types: 'pdf,doc,docx,xls,xlsx,jpg,jpeg,png,zip',
  max_file_size: 20,
  max_total_size: 500,
  remark: ''
})

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增存储配置' : '编辑存储配置')

const TYPE_LABELS: Record<string, string> = { local: '本地存储', oss: '阿里云 OSS', minio: 'MinIO', s3: 'AWS S3' }
function storageTypeLabel(t: string) { return TYPE_LABELS[t] || t }
function storageTypeTag(t: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = { local: 'info', oss: 'success', minio: 'warning', s3: 'danger' }
  return m[t] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    tableData.value = await storageApi.list()
    activeConfig.value = await storageApi.active()
  } finally {
    loading.value = false
  }
}

function onAdd() {
  dialogMode.value = 'add'
  Object.assign(form, {
    id: undefined, storage_type: 'local', base_path: '/data/attachments',
    endpoint: '', access_key: '', secret_key: '', bucket: '', region: '',
    allowed_types: 'pdf,doc,docx,xls,xlsx,jpg,jpeg,png,zip',
    max_file_size: 20, max_total_size: 500, remark: ''
  })
  dialogVisible.value = true
}

function onEdit(row: StorageConfig) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

async function onSave() {
  if (form.storage_type === 'local' && !form.base_path) {
    ElMessage.warning('请填写存储路径'); return
  }
  if (form.storage_type !== 'local' && (!form.endpoint || !form.bucket)) {
    ElMessage.warning('请填写 Endpoint 和 Bucket'); return
  }
  if (!form.allowed_types || !form.max_file_size) {
    ElMessage.warning('请填写文件类型白名单与单文件上限'); return
  }
  if (dialogMode.value === 'add') {
    await storageApi.create({ ...form })
    ElMessage.success('新增成功')
  } else {
    await storageApi.update((form as StorageConfig).id!, { ...form })
    ElMessage.success('保存成功')
  }
  dialogVisible.value = false
  loadData()
}

async function onActivate(row: StorageConfig) {
  await ElMessageBox.confirm(`确认切换激活的存储为「${storageTypeLabel(row.storage_type)}」？切换后新附件将写入该存储。`, '提示', { type: 'warning' })
  await storageApi.activate(row.id!)
  ElMessage.success('已切换激活')
  loadData()
}

async function onDelete(row: StorageConfig) {
  if (row.status === 1) {
    ElMessage.warning('激活中的存储不可删除，请先切换激活')
    return
  }
  await ElMessageBox.confirm('确定删除该存储配置？', '提示', { type: 'warning' })
  await storageApi.delete(row.id!)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>

<style scoped lang="scss">
.st-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.active-panel { padding: 12px 16px; }
.table-panel { padding: 12px; flex: 1; }
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title { font-size: 14px; font-weight: 600; }
.type-tag { margin-right: 4px; margin-bottom: 2px; }
.form-tip { font-size: 12px; color: #909399; line-height: 1.4; margin-top: 2px; }
:deep(.el-divider__text) { font-size: 13px; font-weight: 600; }
</style>
