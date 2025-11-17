<template>
  <div class="login-container">
    <el-card class="login-card">
      <template #header>
        <div class="card-header">
          <el-icon :size="28" style="margin-right: 12px;"><DataAnalysis /></el-icon>
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
</template>

<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { User, Lock, DataAnalysis } from '@element-plus/icons-vue';
import { useDoctorStore } from '@/stores/doctorStore';

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

// 【已修改】模拟登录
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
          specialty: '模拟擅长领域',
          bio: '这是一个模拟登录的医生简介。',
          photoUrl: '@/assets/doctor.jpg'
        }
      };

      const basicLoginInfo = {
        identifier: loginForm.identifier,
        token: 'mock-token-123456' // 模拟一个 Token
      };

      // 调用 store action 来设置状态
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
}

.login-card {
  width: 400px;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}
</style>