<template>
  <div class="verification-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    
    <el-card shadow="always">
      <template #header>
        <div class="card-header">
          <span>身份验证审核管理</span>
          <el-button type="primary" @click="loadPendingVerifications" :loading="loading">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </template>

      <el-tabs v-model="activeTab" @tab-change="handleTabChange">
        <el-tab-pane label="待审核" name="pending">
          <el-table :data="pendingVerifications" v-loading="loading" stripe>
            <el-table-column prop="identifier" label="学号/工号" width="150" />
            <el-table-column prop="fullName" label="姓名" width="120" />
            <el-table-column prop="patientType" label="身份类型" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.patientType === 'student'" type="success">学生</el-tag>
                <el-tag v-else-if="scope.row.patientType === 'teacher'" type="warning">教师</el-tag>
                <el-tag v-else type="info">职工</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="phoneNumber" label="手机号" width="130" />
            <el-table-column prop="idCardNumber" label="身份证号" width="180" />
            <el-table-column label="身份证照片" width="220">
              <template #default="scope">
                <div style="display: flex; gap: 10px; align-items: center;">
                  <div v-if="scope.row.idCardFrontUrl" style="text-align: center;">
                    <el-image 
                      :src="getImageUrl(scope.row.idCardFrontUrl)" 
                      :preview-src-list="[getImageUrl(scope.row.idCardFrontUrl), scope.row.idCardBackUrl ? getImageUrl(scope.row.idCardBackUrl) : '']"
                      style="width: 80px; height: 50px; cursor: pointer; border: 1px solid #ddd;"
                      fit="cover"
                      :preview-teleported="true"
                    />
                    <div style="font-size: 12px; color: #666; margin-top: 4px;">正面</div>
                  </div>
                  <div v-if="scope.row.idCardBackUrl" style="text-align: center;">
                    <el-image 
                      :src="getImageUrl(scope.row.idCardBackUrl)" 
                      :preview-src-list="[getImageUrl(scope.row.idCardFrontUrl), getImageUrl(scope.row.idCardBackUrl)]"
                      style="width: 80px; height: 50px; cursor: pointer; border: 1px solid #ddd;"
                      fit="cover"
                      :preview-teleported="true"
                    />
                    <div style="font-size: 12px; color: #666; margin-top: 4px;">背面</div>
                  </div>
                  <span v-if="!scope.row.idCardFrontUrl && !scope.row.idCardBackUrl" style="color: #999;">未上传</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="申请时间" width="180">
              <template #default="scope">
                {{ formatDateTime(scope.row.createdAt) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200" fixed="right">
              <template #default="scope">
                <el-button type="success" size="small" @click="approve(scope.row)">
                  通过
                </el-button>
                <el-button type="danger" size="small" @click="showRejectDialog(scope.row)">
                  拒绝
                </el-button>
              </template>
            </el-table-column>
          </el-table>
          
          <div v-if="pendingVerifications.length === 0 && !loading" class="empty-state">
            <el-empty description="暂无待审核的申请" />
          </div>
        </el-tab-pane>
        
        <el-tab-pane label="全部记录" name="all">
          <el-table :data="allVerifications" v-loading="loading" stripe>
            <el-table-column prop="identifier" label="学号/工号" width="150" />
            <el-table-column prop="fullName" label="姓名" width="120" />
            <el-table-column prop="patientType" label="身份类型" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.patientType === 'student'" type="success">学生</el-tag>
                <el-tag v-else-if="scope.row.patientType === 'teacher'" type="warning">教师</el-tag>
                <el-tag v-else type="info">职工</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="审核状态" width="100">
              <template #default="scope">
                <el-tag v-if="scope.row.status === 'pending'" type="warning">待审核</el-tag>
                <el-tag v-else-if="scope.row.status === 'approved'" type="success">已通过</el-tag>
                <el-tag v-else type="danger">已拒绝</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="reviewedByName" label="审核人" width="120" />
            <el-table-column prop="reviewedAt" label="审核时间" width="180">
              <template #default="scope">
                {{ scope.row.reviewedAt ? formatDateTime(scope.row.reviewedAt) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="rejectionReason" label="拒绝原因" min-width="200" show-overflow-tooltip />
            <el-table-column label="身份证照片" width="220">
              <template #default="scope">
                <div style="display: flex; gap: 10px; align-items: center;">
                  <div v-if="scope.row.idCardFrontUrl" style="text-align: center;">
                    <el-image 
                      :src="getImageUrl(scope.row.idCardFrontUrl)" 
                      :preview-src-list="[getImageUrl(scope.row.idCardFrontUrl), scope.row.idCardBackUrl ? getImageUrl(scope.row.idCardBackUrl) : '']"
                      style="width: 80px; height: 50px; cursor: pointer; border: 1px solid #ddd;"
                      fit="cover"
                      :preview-teleported="true"
                    />
                    <div style="font-size: 12px; color: #666; margin-top: 4px;">正面</div>
                  </div>
                  <div v-if="scope.row.idCardBackUrl" style="text-align: center;">
                    <el-image 
                      :src="getImageUrl(scope.row.idCardBackUrl)" 
                      :preview-src-list="[getImageUrl(scope.row.idCardFrontUrl), getImageUrl(scope.row.idCardBackUrl)]"
                      style="width: 80px; height: 50px; cursor: pointer; border: 1px solid #ddd;"
                      fit="cover"
                      :preview-teleported="true"
                    />
                    <div style="font-size: 12px; color: #666; margin-top: 4px;">背面</div>
                  </div>
                  <span v-if="!scope.row.idCardFrontUrl && !scope.row.idCardBackUrl" style="color: #999;">未上传</span>
                </div>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>
    
    <!-- 拒绝原因对话框 -->
    <el-dialog v-model="rejectDialogVisible" title="拒绝审核" width="500px">
      <el-form :model="rejectForm" label-width="100px">
        <el-form-item label="拒绝原因" required>
          <el-input 
            v-model="rejectForm.rejectionReason" 
            type="textarea" 
            :rows="4"
            placeholder="请输入拒绝原因"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rejectDialogVisible = false">取消</el-button>
        <el-button type="danger" @click="reject" :loading="submitting">确认拒绝</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import BackButton from '@/components/BackButton.vue'
import request from '@/utils/request'

const activeTab = ref('pending')
const loading = ref(false)
const submitting = ref(false)
const pendingVerifications = ref([])
const allVerifications = ref([])
const rejectDialogVisible = ref(false)
const currentVerification = ref(null)
const rejectForm = ref({
  rejectionReason: ''
})

const getImageUrl = (url) => {
  if (!url) return ''
  
  // 如果是完整URL，直接返回
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url
  }
  
  // 如果是相对路径（以 / 开头）
  // 在开发环境中，Vite 代理会处理 /api 路径，所以可以直接使用相对路径
  // 在生产环境中，需要拼接完整的后端地址
  if (import.meta.env.DEV) {
    // 开发环境：使用 Vite 代理，直接返回相对路径即可
    // Vite 代理配置会将 /api 路径代理到 http://localhost:8080
    return url.startsWith('/') ? url : '/' + url
  } else {
    // 生产环境：拼接完整的后端地址
    const baseURL = 'http://123.249.30.241:8080'
    const imagePath = url.startsWith('/') ? url : '/' + url
    return baseURL + imagePath
  }
}

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-'
  const date = new Date(dateTime)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

const loadPendingVerifications = async () => {
  loading.value = true
  try {
    const res = await request.get('/api/admin/verifications/pending')
    if (res.code === '200') {
      pendingVerifications.value = res.data || []
    } else {
      ElMessage.error(res.msg || '获取待审核列表失败')
    }
  } catch (error) {
    console.error('获取待审核列表失败:', error)
    ElMessage.error('获取待审核列表失败')
  } finally {
    loading.value = false
  }
}

const loadAllVerifications = async () => {
  loading.value = true
  try {
    const res = await request.get('/api/admin/verifications')
    if (res.code === '200') {
      allVerifications.value = res.data || []
    } else {
      ElMessage.error(res.msg || '获取审核列表失败')
    }
  } catch (error) {
    console.error('获取审核列表失败:', error)
    ElMessage.error('获取审核列表失败')
  } finally {
    loading.value = false
  }
}

const handleTabChange = (tabName) => {
  if (tabName === 'pending') {
    loadPendingVerifications()
  } else if (tabName === 'all') {
    loadAllVerifications()
  }
}

const approve = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确认通过 ${row.fullName}（${row.identifier}）的身份验证申请吗？`,
      '确认审核',
      {
        confirmButtonText: '确认通过',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    submitting.value = true
    const res = await request.post(`/api/admin/verifications/${row.verificationId}/review`, {
      approved: true
    })
    
    if (res.code === '200') {
      ElMessage.success('审核通过')
      loadPendingVerifications()
      if (activeTab.value === 'all') {
        loadAllVerifications()
      }
    } else {
      ElMessage.error(res.msg || '审核失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('审核失败:', error)
      ElMessage.error('审核失败')
    }
  } finally {
    submitting.value = false
  }
}

const showRejectDialog = (row) => {
  currentVerification.value = row
  rejectForm.value.rejectionReason = ''
  rejectDialogVisible.value = true
}

const reject = async () => {
  if (!rejectForm.value.rejectionReason || !rejectForm.value.rejectionReason.trim()) {
    ElMessage.warning('请输入拒绝原因')
    return
  }
  
  submitting.value = true
  try {
    const res = await request.post(`/api/admin/verifications/${currentVerification.value.verificationId}/review`, {
      approved: false,
      rejectionReason: rejectForm.value.rejectionReason.trim()
    })
    
    if (res.code === '200') {
      ElMessage.success('已拒绝')
      rejectDialogVisible.value = false
      loadPendingVerifications()
      if (activeTab.value === 'all') {
        loadAllVerifications()
      }
    } else {
      ElMessage.error(res.msg || '审核失败')
    }
  } catch (error) {
    console.error('审核失败:', error)
    ElMessage.error('审核失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadPendingVerifications()
})
</script>

<style scoped>
.verification-container {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.empty-state {
  padding: 40px 0;
  text-align: center;
}
</style>

