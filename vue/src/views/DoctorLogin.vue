<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-left">
        <img src="@/assets/de3970cd7e9eae3e18cfd42895ad9c8e.jpg" alt="Hospital Background" />
      </div>

      <div class="login-right">
        <el-card class="login-card">
          <template #header>
            <div class="card-header">
              <el-icon :size="28" style="margin-right: 12px; color: #409EFF;"><DataAnalysis /></el-icon>
              <h2>医生工作台登录</h2>
            </div>
          </template>

          <el-form :model="loginForm" :rules="loginRules" ref="loginFormRef" @keyup.enter="handleLogin">
            <el-form-item prop="identifier">
              <el-input
                  v-model="loginForm.identifier"
                  placeholder="请输入工号"
                  :prefix-icon="User"
                  size="large"
              />
            </el-form-item>
            <el-form-item prop="password">
              <el-input
                  v-model="loginForm.password"
                  type="password"
                  placeholder="请输入密码"
                  show-password
                  :prefix-icon="Lock"
                  size="large"
              />
            </el-form-item>

            <el-form-item>
              <el-button
                  type="primary"
                  style="width: 100%;"
                  size="large"
                  @click="handleLogin"
                  :loading="loading"
              >
                登 录
              </el-button>
            </el-form-item>

            <el-form-item>
              <el-button
                  type="success"
                  plain
                  style="width: 100%;"
                  size="large"
                  @click="bypassLogin"
              >
                (无后端) 直接跳转到工作台
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { User, Lock, DataAnalysis } from '@element-plus/icons-vue';
import { useDoctorStore } from '@/stores/doctorStore';
// 【新增】导入默认头像
import defaultAvatar from '@/assets/doctor.jpg';

const router = useRouter();
const doctorStore = useDoctorStore();

const loading = ref(false);
const loginFormRef = ref(null);

const loginForm = reactive({
  identifier: 'D001', // 默认工号
  password: '123'    // 默认密码
});

const loginRules = reactive({
  identifier: [{ required: true, message: '请输入工号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
});

// 模拟登录
// 这个函数会*假装*登录成功，并调用 store.loginSuccess
const handleLogin = async () => {
  if (!loginFormRef.value) return;

  await loginFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true;

      // 模拟后端返回的数据
      const mockApiResponse = {
        doctorInfo: {
          doctorId: '1',
          name: `医生 (${loginForm.identifier})`, // 使用输入的工号
          department: '模拟科室',
          position: '模拟职称',
          phone: '13812345678',
          specialty: '高血压、糖尿病 (模拟)',
          bio: '这是一个模拟登录的医生简介。',
          photoUrl: defaultAvatar // 使用导入的本地头像
        }
      };

      const basicLoginInfo = {
        identifier: loginForm.identifier,
        token: 'mock-token-123456' // 模拟一个 Token
      };

      // 调用 store action 来设置状态 (使用您提供的 store)
      doctorStore.loginSuccess(mockApiResponse, basicLoginInfo);

      await new Promise(r => setTimeout(r, 500)); // 模拟网络延迟
      loading.value = false;

      ElMessage.success('登录成功 (模拟)');
      router.push('/doctor-dashboard');
    }
  });
};

// 【您要的“直接跳转”按钮】
// 这个按钮也会调用模拟登录，以确保 store 状态正确
const bypassLogin = () => {
  handleLogin();
};

</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100%;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
  overflow: hidden;
}

.login-box {
  width: 900px; /* 调整总宽度 */
  height: 550px; /* 调整总高度 */
  display: grid;
  grid-template-columns: 1.2fr 1fr; /* 左侧稍宽 */
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  background-color: #ffffff;
}

/* 左侧图片 */
.login-left {
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.login-left img {
  width: 100%;
  height: 100%;
  object-fit: cover; /* 确保图片填满容器而不变形 */
}

/* 右侧表单 */
.login-right {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.login-card {
  width: 100%;
  border: none;
  box-shadow: none;
}

.card-header {
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
  margin-bottom: 20px;
}

:deep(.el-form-item) {
  margin-bottom: 22px; /* 增加表单项间距 */
}

:deep(.el-input__inner) {
  height: 40px; /* 增加输入框高度 */
}

.el-button {
  height: 45px; /* 增加按钮高度 */
  font-size: 16px;
}
</style>