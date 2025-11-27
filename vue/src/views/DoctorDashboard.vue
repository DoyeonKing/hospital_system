<template>
  <div class="doctor-dashboard">
    <!-- 顶部导航栏 -->
    <div class="top-navbar">
      <div class="navbar-content">
        <div class="navbar-left">
          <div class="logo-section">
            <el-icon :size="28"><DataAnalysis /></el-icon>
            <h2>医生工作台</h2>
          </div>
        </div>
        <div class="navbar-right">
          <div class="user-info">
            <el-avatar :size="36" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" />
            <span class="user-name">{{ doctorStore.displayName }} 医生</span>
          </div>
          <el-button type="danger" size="default" :icon="SwitchButton" @click="handleLogout">退出登录</el-button>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="main-content">
      <!-- 顶部统计卡片 -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-icon patients">
            <el-icon :size="32"><User /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">今日接诊</p>
            <h3 class="stat-value">23</h3>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon appointments">
            <el-icon :size="32"><Clock /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">待处理预约</p>
            <h3 class="stat-value">8</h3>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon records">
            <el-icon :size="32"><Document /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">本周病历</p>
            <h3 class="stat-value">156</h3>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon reviews">
            <el-icon :size="32"><Star /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">患者好评率</p>
            <h3 class="stat-value">98%</h3>
          </div>
        </div>
      </div>

      <!-- 医生信息与功能区域 -->
      <div class="content-grid">
        <!-- 左侧：医生信息 -->
        <div class="left-column">
          <div class="doctor-info-card">
            <div class="card-header">
              <h3>个人信息</h3>
            </div>
            <div class="doctor-profile">
              <div class="doctor-avatar-large">
                <el-avatar :size="100" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" />
              </div>
              <div class="doctor-details">
                <h2>{{ doctorStore.detailedDoctorInfo.name || '测试医生' }}</h2>
                <div class="detail-item">
                  <el-icon><OfficeBuilding /></el-icon>
                  <span>{{ doctorStore.detailedDoctorInfo.department || '内科' }}</span>
                </div>
                <div class="detail-item">
                  <el-icon><Star /></el-icon>
                  <span>{{ doctorStore.detailedDoctorInfo.position || '主治医师' }}</span>
                </div>
                <div class="detail-item">
                  <el-icon><Phone /></el-icon>
                  <span>{{ doctorStore.detailedDoctorInfo.phone || '13900139000' }}</span>
                </div>
              </div>
              <div class="doctor-actions">
                <el-button type="primary" :icon="Edit" @click="editProfile">编辑资料</el-button>
                <el-button :icon="Key" @click="changePassword">修改密码</el-button>
              </div>
            </div>
          </div>

          <!-- 今日日程 -->
          <div class="schedule-card">
            <div class="card-header">
              <h3>今日日程</h3>
              <el-tag type="info" size="small">{{ new Date().toLocaleDateString() }}</el-tag>
            </div>
            <div class="schedule-list">
              <div class="schedule-item">
                <div class="time">08:00 - 09:00</div>
                <div class="event">上午门诊</div>
              </div>
              <div class="schedule-item">
                <div class="time">10:00 - 11:30</div>
                <div class="event">手术安排</div>
              </div>
              <div class="schedule-item">
                <div class="time">14:00 - 17:00</div>
                <div class="event">下午门诊</div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：功能模块 -->
        <div class="right-column">
          <div class="functions-section">
            <div class="card-header">
              <h3>快速功能</h3>
            </div>
            <div class="function-grid">
              <div class="function-card" @click="goToPatientManagement">
                <div class="card-icon primary">
                  <el-icon :size="36"><UserFilled /></el-icon>
                </div>
                <h4>患者管理</h4>
                <p>查看和管理患者信息</p>
              </div>

              <div class="function-card" @click="goToMedicalRecords">
                <div class="card-icon success">
                  <el-icon :size="36"><Document /></el-icon>
                </div>
                <h4>病历记录</h4>
                <p>查看和编辑病历</p>
              </div>

              <div class="function-card" @click="goToAppointmentManagement">
                <div class="card-icon warning">
                  <el-icon :size="36"><Calendar /></el-icon>
                </div>
                <h4>预约管理</h4>
                <p>管理患者预约</p>
              </div>

              <div class="function-card" @click="goToStatistics">
                <div class="card-icon danger">
                  <el-icon :size="36"><DataAnalysis /></el-icon>
                </div>
                <h4>数据统计</h4>
                <p>查看工作统计</p>
              </div>

              <div class="function-card" @click="quickAddRecord">
                <div class="card-icon info">
                  <el-icon :size="36"><Plus /></el-icon>
                </div>
                <h4>添加病历</h4>
                <p>快速录入病历</p>
              </div>

              <div class="function-card" @click="viewTodayAppointments">
                <div class="card-icon primary">
                  <el-icon :size="36"><Bell /></el-icon>
                </div>
                <h4>今日预约</h4>
                <p>查看今日预约</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 编辑资料对话框 -->
    <el-dialog v-model="editDialogVisible" title="编辑医生资料" width="500px">
      <el-form :model="editForm" :rules="editRules" ref="editFormRef" label-width="80px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="editForm.name" />
        </el-form-item>
        <el-form-item label="科室" prop="department">
          <el-input v-model="editForm.department" />
        </el-form-item>
        <el-form-item label="职位" prop="position">
          <el-input v-model="editForm.position" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="editForm.phone" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveProfile">保存</el-button>
      </template>
    </el-dialog>

    <!-- 修改密码对话框 -->
    <el-dialog v-model="passwordDialogVisible" title="修改密码" width="400px">
      <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef" label-width="80px">
        <el-form-item label="旧密码" prop="oldPassword">
          <el-input v-model="passwordForm.oldPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input v-model="passwordForm.newPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="passwordDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="savePassword">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  UserFilled, Document, Calendar, DataAnalysis, 
  User, Clock, Star, SwitchButton,
  OfficeBuilding, Phone, Edit, Key,
  Plus, Bell
} from '@element-plus/icons-vue'
import { useDoctorStore } from '@/stores/doctorStore'

const router = useRouter()
const doctorStore = useDoctorStore()

// 对话框状态
const editDialogVisible = ref(false)
const passwordDialogVisible = ref(false)

// 表单引用
const editFormRef = ref(null)
const passwordFormRef = ref(null)

// 编辑表单
const editForm = reactive({
  name: '',
  department: '',
  position: '',
  phone: ''
})

// 密码表单
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 编辑表单验证规则
const editRules = reactive({
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  department: [{ required: true, message: '请输入科室', trigger: 'blur' }],
  position: [{ required: true, message: '请输入职位', trigger: 'blur' }],
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ]
})

// 密码表单验证规则
const passwordRules = reactive({
  oldPassword: [{ required: true, message: '请输入旧密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在6-20个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
})

// 登出处理
const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要退出登录吗？',
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    
    // 清除登录状态
    doctorStore.logout()
    ElMessage.success('已退出登录')
    
    // 跳转到登录页面
    router.push('/login')
  } catch {
    // 用户取消操作
  }
}

// 编辑资料
const editProfile = () => {
  // 填充当前信息
  editForm.name = doctorStore.detailedDoctorInfo.name
  editForm.department = doctorStore.detailedDoctorInfo.department
  editForm.position = doctorStore.detailedDoctorInfo.position
  editForm.phone = doctorStore.detailedDoctorInfo.phone
  
  editDialogVisible.value = true
}

// 保存资料
const saveProfile = async () => {
  if (!editFormRef.value) return
  
  try {
    const valid = await editFormRef.value.validate()
    if (!valid) return
  } catch (error) {
    return
  }

  const success = await doctorStore.updateDoctorInfo(editForm)
  if (success) {
    ElMessage.success('资料更新成功')
    editDialogVisible.value = false
  } else {
    ElMessage.error(doctorStore.error || '更新失败')
  }
}

// 修改密码
const changePassword = () => {
  // 清空表单
  passwordForm.oldPassword = ''
  passwordForm.newPassword = ''
  passwordForm.confirmPassword = ''
  
  passwordDialogVisible.value = true
}

// 保存密码
const savePassword = async () => {
  if (!passwordFormRef.value) return
  
  try {
    const valid = await passwordFormRef.value.validate()
    if (!valid) return
  } catch (error) {
    return
  }

  const success = await doctorStore.changePassword(
    passwordForm.oldPassword,
    passwordForm.newPassword
  )
  
  if (success) {
    ElMessage.success('密码修改成功')
    passwordDialogVisible.value = false
  } else {
    ElMessage.error(doctorStore.error || '密码修改失败')
  }
}

// 功能导航方法
const goToPatientManagement = () => {
  ElMessage.info('患者管理功能开发中...')
}

const goToMedicalRecords = () => {
  ElMessage.info('病历记录功能开发中...')
}

const goToAppointmentManagement = () => {
  ElMessage.info('预约管理功能开发中...')
}

const goToStatistics = () => {
  ElMessage.info('数据统计功能开发中...')
}

const quickAddRecord = () => {
  ElMessage.info('快速添加病历功能开发中...')
}

const viewTodayAppointments = () => {
  ElMessage.info('今日预约功能开发中...')
}

const viewPatientList = () => {
  ElMessage.info('患者列表功能开发中...')
}

// 页面加载时获取医生详细信息
onMounted(() => {
  if (doctorStore.isAuthenticated && !doctorStore.detailedDoctorInfo.name) {
    doctorStore.fetchDetailedDoctorInfo()
  }
})
</script>

<style scoped>
.doctor-dashboard {
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
}

/* 顶部导航栏 - 现代化设计 */
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
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 32px;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-section h2 {
  margin: 0;
  font-size: 1.4rem;
  font-weight: 600;
  color: #2c3e50;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.logo-section .el-icon {
  color: #667eea;
  margin-right: 4px;
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
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px;
}

/* 统计卡片行 */
.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 32px;
}

.stat-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 20px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  transition: all 0.3s ease;
  border: 1px solid #f0f0f0;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}

.stat-icon.patients {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.appointments {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.records {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.reviews {
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
}

.stat-info {
  flex: 1;
}

.stat-label {
  font-size: 0.9rem;
  color: #909399;
  margin: 0 0 8px 0;
}

.stat-value {
  font-size: 2rem;
  font-weight: 600;
  color: #2c3e50;
  margin: 0;
}

/* 内容网格布局 */
.content-grid {
  display: grid;
  grid-template-columns: 380px 1fr;
  gap: 24px;
}

/* 左侧列 */
.left-column {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* 医生信息卡片 */
.doctor-info-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  border: 1px solid #f0f0f0;
  overflow: hidden;
}

.card-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
}

.doctor-profile {
  padding: 24px;
  text-align: center;
}

.doctor-avatar-large {
  margin-bottom: 20px;
}

.doctor-details h2 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 16px 0;
}

.detail-item {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin: 10px 0;
  color: #606266;
  font-size: 0.95rem;
}

.doctor-actions {
  display: flex;
  gap: 12px;
  margin-top: 24px;
  justify-content: center;
}

/* 日程卡片 */
.schedule-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  border: 1px solid #f0f0f0;
}

.schedule-list {
  padding: 16px 24px 24px;
}

.schedule-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f9fafb;
  border-radius: 8px;
  margin-bottom: 12px;
  transition: all 0.2s ease;
}

.schedule-item:hover {
  background: #eff6ff;
  transform: translateX(4px);
}

.schedule-item:last-child {
  margin-bottom: 0;
}

.schedule-item .time {
  font-weight: 500;
  color: #667eea;
}

.schedule-item .event {
  color: #606266;
}

/* 右侧功能区 */
.right-column {
  display: flex;
  flex-direction: column;
}

.functions-section {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
  border: 1px solid #f0f0f0;
  flex: 1;
}

.function-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
  padding: 16px 24px 24px;
}

.function-card {
  background: #f9fafb;
  border-radius: 12px;
  padding: 24px 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 2px solid transparent;
}

.function-card:hover {
  background: #fff;
  border-color: #667eea;
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(102, 126, 234, 0.15);
}

.card-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
  color: #fff;
}

.card-icon.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.card-icon.success {
  background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
}

.card-icon.warning {
  background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
  color: #d9822b;
}

.card-icon.danger {
  background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
  color: #f56c6c;
}

.card-icon.info {
  background: linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%);
  color: #409eff;
}

.function-card h4 {
  font-size: 1.1rem;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 8px 0;
}

.function-card p {
  font-size: 0.85rem;
  color: #909399;
  margin: 0;
  line-height: 1.4;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .main-content {
    padding: 20px;
  }
  
  .navbar-content {
    padding: 0 16px;
  }
  
  .stats-row {
    grid-template-columns: 1fr 1fr;
  }
  
  .function-grid {
    grid-template-columns: 1fr;
  }
  
  .user-name {
    display: none;
  }
}

@media (max-width: 480px) {
  .stats-row {
    grid-template-columns: 1fr;
  }
}
</style>
