<template>
  <div class="slot-application-page">
    <div class="top-navbar">
      <div class="navbar-content">
        <div class="navbar-left">
          <BackButton />
          <div class="logo-section">
            <el-icon :size="28"><DocumentAdd /></el-icon>
            <h2>我的加号申请</h2>
          </div>
        </div>
        <div class="navbar-right">
          <el-button type="primary" :icon="Plus" @click="openApplyDialog">申请加号</el-button>
          <div class="user-info">
            <el-avatar :size="36" :src="getAvatarUrl(doctorStore.detailedDoctorInfo?.photoUrl)" />
            <span class="user-name">{{ doctorStore.displayName }} 医生</span>
          </div>
        </div>
      </div>
    </div>

    <div class="main-content">
      <el-card shadow="always" class="slot-card">

      <el-table
          v-loading="recordsLoading"
          :data="applicationRecords"
          style="width: 100%; margin-top: 20px;"
          border
          stripe
      >
        <el-table-column prop="scheduleDate" label="排班日期" width="150" sortable />
        <el-table-column prop="timeSlot" label="时段" width="100">
          <template #default="{ row }">
            <el-tag :type="getTimeSlotType(row.timeSlot)" size="small">
              {{ row.timeSlot === 'MORNING' ? '上午' : '下午' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="addedSlots" label="加号数量" width="100" align="center">
          <template #default="{ row }">
            {{ row.addedSlots }} 个
          </template>
        </el-table-column>
        <el-table-column prop="urgencyLevel" label="紧急程度" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getUrgencyType(row.urgencyLevel)" size="small">
              {{ getUrgencyText(row.urgencyLevel) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="reason" label="申请理由" min-width="200" />
        <el-table-column prop="status" label="审批状态" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center">
          <template #default="{ row }">
            <el-button
                type="primary"
                link
                size="small"
                @click="viewDetail(row)">
              查看详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!recordsLoading && applicationRecords.length === 0" description="暂无加号申请记录" />

    </el-card>

    <!-- 查看详情对话框 -->
    <el-dialog
        v-model="detailDialogVisible"
        title="加号申请详情"
        width="800px"
        :close-on-click-modal="false"
    >
      <div v-if="currentDetail" class="detail-container">
        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">申请ID</span>
            <span class="detail-value">{{ currentDetail.applicationId }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">申请医生</span>
            <span class="detail-value">{{ doctorStore.displayName || '未知' }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">排班日期</span>
            <span class="detail-value">{{ currentDetail.scheduleDate }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">时段</span>
            <span class="detail-value">{{ currentDetail.timeSlot === 'MORNING' ? '上午' : '下午' }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">时间</span>
            <span class="detail-value">{{ getScheduleTime(currentDetail) }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">地点</span>
            <span class="detail-value">{{ currentDetail.location || '未知' }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">患者姓名</span>
            <span class="detail-value">{{ currentDetail.patientName || '未知' }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">患者电话</span>
            <span class="detail-value">{{ currentDetail.patientPhone || '未知' }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">加号数量</span>
            <span class="detail-value detail-highlight">+{{ currentDetail.addedSlots }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">紧急程度</span>
            <span class="detail-value">
              <el-tag :type="getUrgencyType(currentDetail.urgencyLevel)" size="small">
                {{ getUrgencyText(currentDetail.urgencyLevel) }}
              </el-tag>
            </span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item full-width">
            <span class="detail-label">申请理由</span>
            <span class="detail-value">{{ currentDetail.reason }}</span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">申请状态</span>
            <span class="detail-value">
              <el-tag :type="getStatusType(currentDetail.status)">
                {{ getStatusText(currentDetail.status) }}
              </el-tag>
            </span>
          </div>
        </div>

        <div class="detail-row">
          <div class="detail-item">
            <span class="detail-label">申请时间</span>
            <span class="detail-value">{{ formatDetailDateTime(currentDetail.createdAt) }}</span>
          </div>
        </div>

        <div class="detail-row" v-if="currentDetail.updatedAt && currentDetail.status !== 'PENDING'">
          <div class="detail-item">
            <span class="detail-label">处理时间</span>
            <span class="detail-value">{{ formatDetailDateTime(currentDetail.updatedAt) }}</span>
          </div>
        </div>

        <div class="detail-row" v-if="currentDetail.approverName">
          <div class="detail-item">
            <span class="detail-label">审批人</span>
            <span class="detail-value">{{ currentDetail.approverName }}</span>
          </div>
        </div>

        <div class="detail-row" v-if="currentDetail.approverComments">
          <div class="detail-item full-width">
            <span class="detail-label">审批意见</span>
            <span class="detail-value" :style="{ color: currentDetail.status === 'REJECTED' ? '#f56c6c' : '#67c23a', fontWeight: 500 }">
              {{ currentDetail.approverComments }}
            </span>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
        <el-button
            v-if="currentDetail && currentDetail.status === 'PENDING'"
            type="danger"
            :icon="Delete"
            @click="handleCancelFromDetail">
          撤销申请
        </el-button>
      </template>
    </el-dialog>

    <!-- 申请加号对话框 -->
    <el-dialog
        v-model="dialogVisible"
        title="申请加号"
        width="600px"
        @close="resetForm"
    >
      <el-form
          ref="applicationFormRef"
          :model="applicationForm"
          :rules="formRules"
          label-position="top"
      >
        <el-form-item label="选择加号时间" prop="scheduleId">
          <el-select 
            v-model="applicationForm.scheduleId" 
            placeholder="请选择您的排班时间" 
            style="width: 100%"
            filterable
            :loading="schedulesLoading"
            @change="handleScheduleChange"
          >
            <el-option
              v-for="schedule in availableSchedules"
              :key="schedule.scheduleId"
              :label="formatScheduleOption(schedule)"
              :value="schedule.scheduleId"
            >
              <div class="schedule-option">
                <div class="schedule-option-main">
                  <el-icon v-if="isScheduleMorning(schedule)"><Sunrise /></el-icon>
                  <el-icon v-else><Sunset /></el-icon>
                  <span class="schedule-date">{{ schedule.scheduleDate }}</span>
                  <el-tag :type="isScheduleMorning(schedule) ? 'success' : 'warning'" size="small">
                    {{ isScheduleMorning(schedule) ? '上午' : '下午' }}
                  </el-tag>
                </div>
                <div class="schedule-option-detail">
                  <span>{{ schedule.startTime }} - {{ schedule.endTime }}</span>
                  <span class="schedule-location">{{ schedule.location }}</span>
                </div>
              </div>
            </el-option>
          </el-select>
        </el-form-item>

        <el-form-item label="加号数量" prop="addedSlots">
          <el-input-number
            v-model="applicationForm.addedSlots"
            :min="1"
            :max="20"
            style="width: 100%"
            placeholder="请输入加号数量"
          />
        </el-form-item>

        <el-form-item label="紧急程度" prop="urgencyLevel">
          <el-radio-group v-model="applicationForm.urgencyLevel">
            <el-radio value="LOW">低 - 常规加号</el-radio>
            <el-radio value="MEDIUM">中 - 较为紧急</el-radio>
            <el-radio value="HIGH">高 - 非常紧急</el-radio>
            <el-radio value="CRITICAL">紧急 - 危急情况</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="申请理由" prop="reason">
          <el-input
            v-model="applicationForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请详细说明加号的原因，例如：患者病情紧急、复诊需求、特殊情况等..."
            maxlength="500"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="选择患者" prop="patientId">
          <el-select
            v-model="applicationForm.patientId"
            placeholder="输入患者姓名进行搜索"
            style="width: 100%"
            filterable
            remote
            :remote-method="searchPatients"
            :loading="patientsLoading"
            clearable
            @change="handlePatientChange"
          >
            <el-option
              v-for="patient in patientOptions"
              :key="patient.patientId"
              :label="formatPatientOption(patient)"
              :value="patient.patientId"
            >
              <div class="patient-option">
                <div class="patient-option-main">
                  <span class="patient-name">{{ patient.fullName || patient.name }}</span>
                  <el-tag v-if="patient.gender" :type="patient.gender === 'MALE' ? 'primary' : 'danger'" size="small">
                    {{ patient.gender === 'MALE' ? '男' : '女' }}
                  </el-tag>
                </div>
                <div class="patient-option-detail">
                  <span v-if="patient.phoneNumber || patient.phone">{{ patient.phoneNumber || patient.phone }}</span>
                  <span v-if="patient.idCardNumber || patient.idCard">{{ maskIdCard(patient.idCardNumber || patient.idCard) }}</span>
                </div>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitApplication" :loading="submitting">
          提交申请
        </el-button>
      </template>
    </el-dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Calendar, Sunrise, Sunset, DocumentAdd } from '@element-plus/icons-vue'
import BackButton from '@/components/BackButton.vue'
import { useDoctorStore } from '@/stores/doctorStore'
import { getSchedulesByDoctorId } from '@/api/schedule'
import { searchPatientsByName } from '@/api/patient'
import { 
  createSlotApplication, 
  getSlotApplicationsByDoctor,
  cancelSlotApplication 
} from '@/api/slotApplication'

const router = useRouter()
const doctorStore = useDoctorStore()

// --- 工具函数 ---
const getAvatarUrl = (photoUrl) => {
  if (!photoUrl) return new URL('@/assets/doctor.jpg', import.meta.url).href;
  if (photoUrl.startsWith('http')) return photoUrl;
  return `http://localhost:9090${photoUrl}`;
};

// --- 状态 ---
const recordsLoading = ref(false)
const dialogVisible = ref(false)
const detailDialogVisible = ref(false)
const applicationRecords = ref([])
const applicationFormRef = ref(null)
const currentDetail = ref(null)
const submitting = ref(false)

// 排班相关状态
const schedulesLoading = ref(false)
const availableSchedules = ref([])
const selectedSchedule = ref(null)

// 患者相关状态
const patientsLoading = ref(false)
const patientOptions = ref([])
const selectedPatient = ref(null)

// 从 localStorage 获取当前医生ID
const getCurrentDoctorId = () => {
  const savedInfo = JSON.parse(localStorage.getItem('xm-pro-doctor'))
  const doctorId = savedInfo?.doctorId
  
  if (doctorId) {
    return doctorId
  }
  
  console.error('未能从 localStorage 获取医生ID')
  return null
}

const currentDoctorId = ref(getCurrentDoctorId())

// --- 表单 ---
const applicationForm = reactive({
  scheduleId: '',
  addedSlots: 1,
  urgencyLevel: 'MEDIUM',
  reason: '',
  patientId: ''
})

const formRules = reactive({
  scheduleId: [
    { required: true, message: '请选择排班时间', trigger: 'change' }
  ],
  addedSlots: [
    { required: true, message: '请输入加号数量', trigger: 'blur' },
    { type: 'number', min: 1, max: 20, message: '加号数量必须在1-20之间', trigger: 'blur' }
  ],
  urgencyLevel: [
    { required: true, message: '请选择紧急程度', trigger: 'change' }
  ],
  reason: [
    { required: true, message: '请填写申请理由', trigger: 'blur' },
    { min: 10, max: 500, message: '申请理由长度在10-500个字符之间', trigger: 'blur' }
  ],
  patientId: [
    { required: true, message: '请选择患者', trigger: 'change' }
  ]
})

// --- 方法 ---

// 打开申请对话框
const openApplyDialog = () => {
  loadDoctorSchedules()
  dialogVisible.value = true
}

// 加载医生排班
const loadDoctorSchedules = async () => {
  const doctorId = currentDoctorId.value
  
  if (!doctorId) {
    ElMessage.error('无法获取医生ID')
    return
  }
  
  schedulesLoading.value = true
  
  try {
    const today = new Date()
    const endDate = new Date()
    endDate.setDate(today.getDate() + 30)
    
    const formatDate = (date) => {
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, '0')
      const day = date.getDate().toString().padStart(2, '0')
      return `${year}-${month}-${day}`
    }
    
    const response = await getSchedulesByDoctorId(doctorId, {
      startDate: formatDate(today),
      endDate: formatDate(endDate),
      page: 0,
      size: 100
    })
    
    if (response && response.content) {
      availableSchedules.value = response.content
    } else {
      availableSchedules.value = []
    }
  } catch (error) {
    console.error('加载排班失败:', error)
    ElMessage.error('加载排班失败')
    availableSchedules.value = []
  } finally {
    schedulesLoading.value = false
  }
}

// 判断是否为上午排班
const isScheduleMorning = (schedule) => {
  if (!schedule || !schedule.startTime) return false
  const hour = parseInt(schedule.startTime.split(':')[0])
  return hour < 12
}

// 格式化排班选项
const formatScheduleOption = (schedule) => {
  const timeSlot = isScheduleMorning(schedule) ? '上午' : '下午'
  return `${schedule.scheduleDate} ${timeSlot} ${schedule.startTime}-${schedule.endTime} (${schedule.location})`
}

// 处理排班选择
const handleScheduleChange = (scheduleId) => {
  selectedSchedule.value = availableSchedules.value.find(s => s.scheduleId === scheduleId)
}

// 搜索患者
const searchPatients = async (query) => {
  if (!query || query.trim() === '') {
    patientOptions.value = []
    return
  }
  
  patientsLoading.value = true
  
  try {
    const response = await searchPatientsByName(query.trim())
    
    if (response && response.content) {
      patientOptions.value = response.content
    } else if (Array.isArray(response)) {
      patientOptions.value = response
    } else {
      patientOptions.value = []
    }
  } catch (error) {
    console.error('搜索患者失败:', error)
    patientOptions.value = []
  } finally {
    patientsLoading.value = false
  }
}

// 格式化患者选项
const formatPatientOption = (patient) => {
  let info = patient.fullName || patient.name || ''
  // 显示患者identifier而不是电话号
  if (patient.identifier) {
    info += ` - ${patient.identifier}`
  }
  return info
}

// 处理患者选择
const handlePatientChange = (patientId) => {
  selectedPatient.value = patientOptions.value.find(p => p.patientId === patientId)
}

// 身份证号脱敏
const maskIdCard = (idCard) => {
  if (!idCard || idCard.length < 8) return idCard
  return idCard.substring(0, 6) + '********' + idCard.substring(idCard.length - 4)
}

// 提交申请
const submitApplication = async () => {
  if (!applicationFormRef.value) return

  await applicationFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        submitting.value = true

        const requestData = {
          doctorId: currentDoctorId.value,
          scheduleId: applicationForm.scheduleId,
          addedSlots: applicationForm.addedSlots,
          patientId: applicationForm.patientId,
          urgencyLevel: applicationForm.urgencyLevel,
          reason: applicationForm.reason
        }

        await createSlotApplication(requestData)
        ElMessage.success('申请提交成功，请等待审批')
        dialogVisible.value = false
        loadApplicationRecords()
      } catch (error) {
        console.error('提交失败:', error)
        ElMessage.error('提交失败：' + (error.message || error.response?.data?.message || '网络错误'))
      } finally {
        submitting.value = false
      }
    }
  })
}

// 重置表单
const resetForm = () => {
  applicationFormRef.value?.resetFields()
  applicationForm.scheduleId = ''
  applicationForm.addedSlots = 1
  applicationForm.urgencyLevel = 'MEDIUM'
  applicationForm.reason = ''
  applicationForm.patientId = ''
  selectedSchedule.value = null
  selectedPatient.value = null
  patientOptions.value = []
  availableSchedules.value = []
}

// 加载申请记录
const loadApplicationRecords = async () => {
  const doctorId = currentDoctorId.value
  
  if (!doctorId) {
    console.error('无法获取医生ID')
    return
  }
  
  recordsLoading.value = true

  try {
    const response = await getSlotApplicationsByDoctor(doctorId)
    applicationRecords.value = Array.isArray(response) ? response : []
  } catch (error) {
    console.error('加载申请记录失败:', error)
    ElMessage.error('加载申请记录失败')
    applicationRecords.value = []
  } finally {
    recordsLoading.value = false
  }
}

// 取消申请
const cancelApplication = async (applicationId) => {
  ElMessageBox.confirm(
    '确定要撤销该加号申请吗？',
    '确认撤销',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await cancelSlotApplication(applicationId, currentDoctorId.value)
      ElMessage.success('撤销成功')
      loadApplicationRecords()
    } catch (error) {
      ElMessage.error('撤销失败：' + (error.message || '未知错误'))
    }
  }).catch(() => {
    // 用户取消
  })
}

// 查看详情
const viewDetail = (row) => {
  currentDetail.value = row
  detailDialogVisible.value = true
}

// 从详情对话框撤销申请
const handleCancelFromDetail = async () => {
  if (!currentDetail.value) return
  
  ElMessageBox.confirm(
    '确定要撤销该加号申请吗？',
    '确认撤销',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      await cancelSlotApplication(currentDetail.value.applicationId, currentDoctorId.value)
      ElMessage.success('撤销成功')
      detailDialogVisible.value = false
      loadApplicationRecords()
    } catch (error) {
      ElMessage.error('撤销失败：' + (error.message || '未知错误'))
    }
  }).catch(() => {
    // 用户取消
  })
}

// 辅助函数：获取状态类型
const getStatusType = (status) => {
  const typeMap = {
    PENDING: 'warning',
    APPROVED: 'success',
    REJECTED: 'danger',
    CANCELLED: 'info'
  }
  return typeMap[status] || 'info'
}

// 辅助函数：获取状态文本
const getStatusText = (status) => {
  const textMap = {
    PENDING: '待审批',
    APPROVED: '已通过',
    REJECTED: '已拒绝',
    CANCELLED: '已取消'
  }
  return textMap[status] || status
}

// 辅助函数：获取时段类型
const getTimeSlotType = (timeSlot) => {
  return timeSlot === 'MORNING' ? 'success' : 'warning'
}

// 辅助函数：获取紧急程度类型
const getUrgencyType = (urgency) => {
  const typeMap = {
    LOW: 'info',
    MEDIUM: 'warning',
    HIGH: 'danger',
    CRITICAL: 'danger'
  }
  return typeMap[urgency] || 'info'
}

// 辅助函数：获取紧急程度文本
const getUrgencyText = (urgency) => {
  const textMap = {
    LOW: '低',
    MEDIUM: '中',
    HIGH: '高',
    CRITICAL: '紧急'
  }
  return textMap[urgency] || urgency
}

// 辅助函数：格式化日期时间
const formatDateTime = (dateTimeStr) => {
  if (!dateTimeStr) return ''
  return dateTimeStr.replace('T', ' ').substring(0, 16)
}

// 辅助函数：格式化详情页日期时间
const formatDetailDateTime = (dateTimeStr) => {
  if (!dateTimeStr) return ''
  const date = new Date(dateTimeStr)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${year}/${month}/${day} ${hours}:${minutes}`
}

// 辅助函数：获取排班时间
const getScheduleTime = (detail) => {
  if (!detail) return '未知'
  // 如果有 startTime 和 endTime 字段
  if (detail.startTime && detail.endTime) {
    return `${detail.startTime} - ${detail.endTime}`
  }
  // 否则根据时段返回默认时间
  return detail.timeSlot === 'MORNING' ? '08:00 - 12:00' : '14:00 - 18:00'
}

// --- 生命周期 ---
onMounted(() => {
  if (!currentDoctorId.value) {
    ElMessage.error('未获取到医生信息，请重新登录')
    return
  }
  
  loadApplicationRecords()
})
</script>

<style scoped>
.slot-application-page {
  min-height: 100vh;
  background: #f5f7fa;
}

/* 顶部导航栏 */
.top-navbar {
  background: #fff;
  border-bottom: 1px solid #e4e7ed;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  position: sticky;
  top: 0;
  z-index: 100;
}

.navbar-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 64px;
  max-width: 1600px;
  margin: 0 auto;
  padding: 0 32px;
}

.navbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: 8px;
}

.logo-section h2 {
  margin: 0;
  font-size: 1.4rem;
  font-weight: 600;
  color: #2c3e50;
}

.navbar-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #f5f7fa;
  border-radius: 20px;
}

.user-name {
  font-size: 0.95rem;
  font-weight: 500;
  color: #2c3e50;
}

.main-content {
  max-width: 1600px;
  margin: 0 auto;
  padding: 32px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}

:deep(.el-form-item__label) {
  font-weight: 600 !important;
  color: #303133 !important;
}

/* 详情对话框样式 */
.detail-container {
  padding: 0;
}

.detail-row {
  display: flex;
  gap: 16px;
  margin-bottom: 12px;
  border-bottom: 1px solid #f0f0f0;
  padding-bottom: 12px;
}

.detail-row:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.detail-item {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-item.full-width {
  flex: 1 1 100%;
}

.detail-label {
  min-width: 70px;
  font-weight: 500;
  color: #909399;
  background-color: #f5f7fa;
  padding: 6px 12px;
  border-radius: 4px;
  flex-shrink: 0;
  font-size: 14px;
}

.detail-value {
  flex: 1;
  color: #303133;
  padding: 6px 0;
  word-break: break-word;
  line-height: 1.5;
  font-size: 14px;
}

.detail-highlight {
  color: #f56c6c;
  font-weight: 600;
  font-size: 15px;
}

/* 排班选项样式 */
.schedule-option {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 4px 0;
}

.schedule-option-main {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 500;
}

.schedule-date {
  font-size: 0.95rem;
  color: #303133;
}

.schedule-option-detail {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.85rem;
  color: #606266;
  margin-left: 24px;
}

.schedule-location {
  color: #909399;
}

/* 患者选项样式 */
.patient-option {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 4px 0;
}

.patient-option-main {
  display: flex;
  align-items: center;
  gap: 8px;
}

.patient-name {
  font-weight: 500;
  font-size: 0.95rem;
  color: #303133;
}

.patient-option-detail {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.85rem;
  color: #909399;
  margin-left: 4px;
}
</style>
