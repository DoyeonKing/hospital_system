<template>
  <div class="login-container">
    <!-- 左侧装饰区域 -->
    <div class="decoration-section">
      <div class="decoration-content">
        <h1>医生工作台</h1>
        <p>专业医疗，高效服务</p>
        <div class="decoration-image">
          <img src="@/assets/doctor.jpg" alt="医生工作台" />
        </div>
        <div class="features">
          <div class="feature-item">
            <span class="feature-icon">🏥</span>
            <span>患者管理</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📋</span>
            <span>病历记录</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">📊</span>
            <span>数据统计</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧登录表单 -->
    <div class="form-section">
      <div class="form-container">
        <div class="form-header">
          <h2>医生登录</h2>
          <p>{{ isActivation ? '账户激活' : '请输入您的医生账户信息' }}</p>
        </div>

        <!-- 登录表单 -->
        <div v-if="!isActivation" class="login-form">
          <el-form 
            ref="loginFormRef" 
            :model="loginForm" 
            :rules="loginRules" 
            @submit.prevent="handleLogin"
          >
            <el-form-item prop="identifier">
              <el-input
                v-model="loginForm.identifier"
                placeholder="请输入工号"
                size="large"
                prefix-icon="User"
                clearable
              />
            </el-form-item>

            <el-form-item prop="password">
              <el-input
                v-model="loginForm.password"
                type="password"
                placeholder="请输入密码"
                size="large"
                prefix-icon="Lock"
                show-password
                clearable
                @keyup.enter="handleLogin"
              />
            </el-form-item>

            <el-form-item>
              <el-button
                type="primary"
                size="large"
                class="login-btn"
                :loading="loading"
                @click="handleLogin"
              >
                {{ loading ? '登录中...' : '登录' }}
              </el-button>
            </el-form-item>
          </el-form>

          <div class="form-footer">
            <el-button type="text" @click="switchToActivation">
              首次使用？点击激活账户
            </el-button>
          </div>
        </div>

        <!-- 激活表单 -->
        <div v-else class="activation-form">
          <!-- 激活步骤指示器 -->
          <div class="step-indicator">
            <div class="step" :class="{ active: activationStep >= 1, completed: activationStep > 1 }">
              <div class="step-number">1</div>
              <div class="step-text">验证信息</div>
            </div>
            <div class="step-line" :class="{ active: activationStep > 1 }"></div>
            <div class="step" :class="{ active: activationStep >= 2, completed: activationStep > 2 }">
              <div class="step-number">2</div>
              <div class="step-text">身份验证</div>
            </div>
          </div>

          <!-- 第一步：验证初始信息 -->
          <div v-if="activationStep === 1" class="step-content">
            <h3 class="step-title">第一步：验证初始信息</h3>
            <el-form 
              ref="activationFormRef" 
              :model="activationForm" 
              :rules="activationRules1"
            >
              <el-form-item prop="identifier">
                <el-input
                  v-model="activationForm.identifier"
                  placeholder="请输入工号"
                  size="large"
                  prefix-icon="User"
                  clearable
                />
              </el-form-item>

              <el-form-item prop="initialPassword">
                <el-input
                  v-model="activationForm.initialPassword"
                  type="password"
                  placeholder="请输入初始密码"
                  size="large"
                  prefix-icon="Lock"
                  show-password
                  clearable
                />
              </el-form-item>

              <el-form-item>
                <el-button
                  type="primary"
                  size="large"
                  class="login-btn"
                  :loading="loading"
                  @click="handleActivationStep1"
                >
                  {{ loading ? '验证中...' : '下一步' }}
                </el-button>
              </el-form-item>
            </el-form>
          </div>

          <!-- 第二步：身份验证 -->
          <div v-if="activationStep === 2" class="step-content">
            <h3 class="step-title">第二步：身份验证</h3>
            <div class="info-desc">
              <el-icon><Lock /></el-icon>
              <span>为了您的账户安全，请输入您的身份证号进行验证</span>
            </div>
            
            <el-form 
              ref="activationFormRef2" 
              :model="activationForm" 
              :rules="activationRules2"
            >
              <el-form-item prop="idCardInput">
                <el-input
                  v-model="activationForm.idCardInput"
                  placeholder="请输入身份证号后6位"
                  size="large"
                  prefix-icon="CreditCard"
                  maxlength="6"
                  clearable
                />
              </el-form-item>

              <el-form-item prop="newPassword">
                <el-input
                  v-model="activationForm.newPassword"
                  type="password"
                  placeholder="请输入新密码（6-20位）"
                  size="large"
                  prefix-icon="Lock"
                  show-password
                  clearable
                />
              </el-form-item>

              <el-form-item prop="confirmPassword">
                <el-input
                  v-model="activationForm.confirmPassword"
                  type="password"
                  placeholder="请再次输入新密码"
                  size="large"
                  prefix-icon="Lock"
                  show-password
                  clearable
                />
              </el-form-item>

              <el-form-item>
                <el-button
                  type="primary"
                  size="large"
                  class="login-btn"
                  :loading="loading"
                  @click="handleActivationStep2"
                >
                  {{ loading ? '激活中...' : '完成激活' }}
                </el-button>
              </el-form-item>
            </el-form>
          </div>

          <div class="form-footer">
            <el-button type="text" @click="switchToLogin">
              返回登录
            </el-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, Check } from '@element-plus/icons-vue'
import { useDoctorStore } from '@/stores/doctorStore'
import request from '@/utils/request'

const router = useRouter()
const doctorStore = useDoctorStore()

// 表单引用
const loginFormRef = ref(null)
const activationFormRef = ref(null)
const activationFormRef2 = ref(null)
const loading = ref(false)

// 激活状态
const isActivation = ref(false)
const activationStep = ref(1)

// 登录表单
const loginForm = reactive({
  identifier: '',
  password: ''
})

// 激活表单
const activationForm = reactive({
  identifier: '',
  initialPassword: '',
  idCard: '',           // 从后端获取的脱敏身份证号
  idCardInput: '',      // 用户输入的身份证号后6位
  newPassword: '',
  confirmPassword: ''
})

// 登录表单验证规则
const loginRules = reactive({
  identifier: [
    { required: true, message: '请输入工号', trigger: 'blur' },
    { min: 3, max: 20, message: '工号长度在3-20个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在6-20个字符', trigger: 'blur' }
  ]
})

// 激活表单验证规则 - 第一步
const activationRules1 = reactive({
  identifier: [
    { required: true, message: '请输入工号', trigger: 'blur' },
    { min: 3, max: 20, message: '工号长度在3-20个字符', trigger: 'blur' }
  ],
  initialPassword: [
    { required: true, message: '请输入初始密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在6-20个字符', trigger: 'blur' }
  ]
})

// 激活表单验证规则 - 第二步
const activationRules2 = reactive({
  idCardInput: [
    { required: true, message: '请输入身份证号后6位', trigger: 'blur' },
    { len: 6, message: '请输入完整的6位数字', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '身份证号后6位必须为数字', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在6-20个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== activationForm.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
})

// 切换到激活模式
const switchToActivation = () => {
  isActivation.value = true
  activationStep.value = 1
  // 清空激活表单
  Object.assign(activationForm, {
    identifier: '',
    initialPassword: '',
    idCard: '',
    newPassword: '',
    confirmPassword: ''
  })
}

// 切换到登录模式
const switchToLogin = () => {
  isActivation.value = false
  activationStep.value = 1
  // 清空登录表单
  Object.assign(loginForm, {
    identifier: '',
    password: ''
  })
}

// 医生正常登录
const handleLogin = async () => {
  if (!loginFormRef.value) return
  
  try {
    const valid = await loginFormRef.value.validate()
    if (!valid) return
  } catch (error) {
    return
  }

  loading.value = true

  try {
    const response = await request({
      url: '/api/doctor/auth/login',
      method: 'POST',
      data: {
        identifier: loginForm.identifier,
        password: loginForm.password
      }
    })

    if (response.code === '200') {
      // 保存登录信息到store
      const loginData = response.data
      doctorStore.loginSuccess(response.data, {
        identifier: loginForm.identifier
      })

      ElMessage.success('登录成功')
      
      // 立即跳转到医生工作台
      router.push('/doctor-dashboard')
    } else {
      ElMessage.error(response.msg || '登录失败')
    }
  } catch (error) {
    console.error('登录请求失败:', error)
    ElMessage.error('网络错误，请稍后重试')
  } finally {
    loading.value = false
  }
}

// 激活第一步：验证初始登录信息
const handleActivationStep1 = async () => {
  if (!activationFormRef.value) return
  
  try {
    const valid = await activationFormRef.value.validate()
    if (!valid) return
  } catch (error) {
    return
  }

  loading.value = true

  try {
    const response = await request({
      url: '/api/doctor/auth/verify',
      method: 'POST',
      data: {
        identifier: activationForm.identifier,
        initialPassword: activationForm.initialPassword
      }
    })

    // 后端返回的是简单的 JSON 对象，不是标准的 response 格式
    // 成功返回: {"message": "初始信息验证成功，请继续身份验证"}
    // 失败返回: {"error": "错误信息"}
    console.log('第一步验证响应:', response)
    
    if (response && response.message) {
      // 验证成功，进入第二步
      activationStep.value = 2
      ElMessage.success('初始信息验证成功')
    } else if (response && response.error) {
      ElMessage.error(response.error)
    } else {
      ElMessage.error('验证失败，响应格式错误')
    }
  } catch (error) {
    console.error('验证请求失败:', error)
    // 错误已经在响应拦截器中处理过了，这里不需要再显示
    if (!error.response) {
      ElMessage.error('无法连接到服务器，请检查后端是否启动')
    }
  } finally {
    loading.value = false
  }
}

// 激活第二步：身份验证和密码设置
const handleActivationStep2 = async () => {
  if (!activationFormRef2.value) return
  
  try {
    const valid = await activationFormRef2.value.validate()
    if (!valid) return
  } catch (error) {
    return
  }

  loading.value = true

  try {
    const response = await request({
      url: '/api/doctor/auth/activate',
      method: 'POST',
      data: {
        identifier: activationForm.identifier,
        idCardEnding: activationForm.idCardInput,  // 发送用户输入的后6位
        newPassword: activationForm.newPassword,
        confirmPassword: activationForm.confirmPassword
      }
    })

    // 后端返回的是简单的 JSON 对象
    // 成功返回: {"message": "账户激活成功，请返回登录"}
    // 失败返回: {"error": "错误信息"}
    console.log('第二步激活响应:', response)
    
    if (response && response.message) {
      ElMessage.success('账户激活成功！请使用新密码登录。')
      // 返回登录界面
      setTimeout(() => {
        switchToLogin()
      }, 2000)
    } else if (response && response.error) {
      ElMessage.error(response.error)
    } else {
      ElMessage.error('激活失败，响应格式错误')
    }
  } catch (error) {
    console.error('激活请求失败:', error)
    // 错误已经在响应拦截器中处理过了，这里不需要再显示
    if (!error.response) {
      ElMessage.error('无法连接到服务器，请检查后端是否启动')
    }
  } finally {
    loading.value = false
  }
}

// 页面加载时检查是否已登录
onMounted(() => {
  if (doctorStore.isAuthenticated) {
    router.push('/doctor-dashboard')
  }
})
</script>

<style scoped>
.login-container {
  display: flex;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.decoration-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.decoration-content {
  text-align: center;
  color: white;
  padding: 40px;
}

.decoration-content h1 {
  font-size: 2.5rem;
  font-weight: bold;
  margin-bottom: 20px;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.decoration-content p {
  font-size: 1.2rem;
  margin-bottom: 40px;
  opacity: 0.9;
}

.decoration-image {
  margin: 40px 0;
}

.decoration-image img {
  width: 300px;
  height: 300px;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.features {
  display: flex;
  justify-content: space-around;
  margin-top: 40px;
}

.feature-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
}

.feature-icon {
  font-size: 2rem;
}

.form-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.form-container {
  width: 100%;
  max-width: 400px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 50px 40px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
}

.form-header {
  text-align: center;
  margin-bottom: 40px;
}

.form-header h2 {
  font-size: 2rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.form-header p {
  color: #666;
  font-size: 1rem;
}

.login-form .el-form-item {
  margin-bottom: 25px;
}

.login-form .el-input {
  height: 50px;
}

.login-form .el-input__wrapper {
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 2px solid transparent;
  transition: all 0.3s ease;
}

.login-form .el-input__wrapper:hover {
  border-color: #667eea;
}

.login-form .el-input__wrapper.is-focus {
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.login-btn {
  width: 100%;
  height: 50px;
  border-radius: 12px;
  background: linear-gradient(45deg, #667eea, #764ba2);
  border: none;
  font-size: 1.1rem;
  font-weight: bold;
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
  transition: all 0.3s ease;
}

.login-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 32px rgba(102, 126, 234, 0.6);
}

.login-btn:active {
  transform: translateY(0);
}

/* 激活步骤指示器 */
.step-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 40px;
}

.step {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.step-number {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background-color: #e9ecef;
  color: #6c757d;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: bold;
  margin-bottom: 8px;
  transition: all 0.3s ease;
}

.step.active .step-number {
  background-color: #667eea;
  color: #ffffff;
}

.step.completed .step-number {
  background-color: #28a745;
  color: #ffffff;
}

.step-text {
  font-size: 14px;
  color: #6c757d;
  transition: all 0.3s ease;
}

.step.active .step-text {
  color: #667eea;
  font-weight: bold;
}

.step.completed .step-text {
  color: #28a745;
  font-weight: bold;
}

.step-line {
  width: 80px;
  height: 3px;
  background-color: #e9ecef;
  margin: 0 15px;
  margin-top: -20px;
  transition: all 0.3s ease;
}

.step-line.active {
  background-color: #667eea;
}

/* 步骤内容 */
.step-content {
  margin-bottom: 30px;
}

.step-title {
  font-size: 1.2rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 30px;
  text-align: center;
}

.verification-desc {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-bottom: 30px;
  padding: 15px;
  background-color: #e8f5e8;
  border-radius: 8px;
  border-left: 4px solid #28a745;
  color: #28a745;
  font-size: 0.9rem;
}

.info-desc {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-bottom: 30px;
  padding: 15px;
  background-color: #eff6ff;
  border-radius: 8px;
  border-left: 4px solid #667eea;
  color: #667eea;
  font-size: 0.9rem;
}

.form-footer {
  text-align: center;
  margin-top: 20px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .login-container {
    flex-direction: column;
  }
  
  .decoration-section {
    flex: none;
    height: 200px;
  }
  
  .decoration-content h1 {
    font-size: 1.8rem;
  }
  
  .decoration-image img {
    width: 120px;
    height: 120px;
  }
  
  .features {
    margin-top: 20px;
  }
  
  .form-section {
    flex: 1;
    padding: 20px;
  }
  
  .form-container {
    padding: 30px 20px;
  }
}
</style>
