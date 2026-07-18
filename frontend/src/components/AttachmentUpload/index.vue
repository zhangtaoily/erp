<template>
  <div class="attachment-upload">
    <div class="att-header">
      <span class="att-title">附件管理</span>
      <el-upload
        ref="uploadRef"
        :show-file-list="false"
        :auto-upload="true"
        :http-request="customUpload"
        multiple
      >
        <el-button type="primary" size="small" :icon="Upload">上传附件</el-button>
      </el-upload>
    </div>
    <el-table :data="attachments" size="small" border v-loading="loading" empty-text="暂无附件">
      <el-table-column type="index" label="#" width="45" />
      <el-table-column label="文件名" min-width="180">
        <template #default="{ row }">
          <el-icon class="file-icon"><Document /></el-icon>
          <span class="file-name">{{ row.file_name }}</span>
        </template>
      </el-table-column>
      <el-table-column label="大小" width="90" align="right">
        <template #default="{ row }">{{ formatSize(row.file_size) }}</template>
      </el-table-column>
      <el-table-column label="类型" width="70">
        <template #default="{ row }">
          <el-tag size="small" effect="plain">{{ row.file_type }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="版本" width="60" align="center">
        <template #default="{ row }">v{{ row.version }}</template>
      </el-table-column>
      <el-table-column prop="upload_by" label="上传人" width="90" />
      <el-table-column prop="upload_time" label="上传时间" width="150" />
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" size="small" @click="onPreview(row as any)">预览</el-button>
          <el-button link type="primary" size="small" @click="onDownload(row as any)">下载</el-button>
          <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Upload, Document } from '@element-plus/icons-vue'
import { attachmentApi } from '@/api/integration'
import type { Attachment } from '@/types/bo'

const props = defineProps<{
  billType: string
  billId: string
}>()

const loading = ref(false)
const attachments = ref<Attachment[]>([])
const uploadRef = ref()

async function loadList() {
  if (!props.billType || !props.billId) return
  loading.value = true
  try {
    attachments.value = await attachmentApi.list(props.billType, props.billId)
  } finally {
    loading.value = false
  }
}

async function customUpload(options: any) {
  const fd = new FormData()
  fd.append('file', options.file)
  fd.append('billType', props.billType)
  fd.append('billId', props.billId)
  try {
    await attachmentApi.upload(props.billType, props.billId, fd)
    ElMessage.success(`${options.file.name} 上传成功`)
    await loadList()
  } catch {
    ElMessage.error('上传失败')
  }
}

function formatSize(bytes: number) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(2) + ' MB'
}

function onPreview(row: Attachment) {
  if (row.file_type === 'pdf' || row.file_type === 'xlsx' || row.file_type === 'docx') {
    ElMessage.info(`预览文件：${row.file_name}`)
  } else {
    ElMessage.warning('该文件类型暂不支持预览')
  }
}

function onDownload(row: Attachment) {
  ElMessage.success(`下载文件：${row.file_name}`)
}

async function onDelete(row: Attachment) {
  await ElMessageBox.confirm(`确定删除附件「${row.file_name}」吗？`, '提示', { type: 'warning' })
  await attachmentApi.delete(row.id)
  ElMessage.success('删除成功')
  loadList()
}

watch(() => [props.billType, props.billId], loadList)
onMounted(loadList)
</script>

<style scoped lang="scss">
.attachment-upload {
  .att-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 10px;
  }
  .att-title {
    font-size: 13px;
    font-weight: 600;
  }
  .file-icon {
    color: #1564ff;
    margin-right: 4px;
    vertical-align: middle;
  }
  .file-name {
    vertical-align: middle;
  }
}
</style>
