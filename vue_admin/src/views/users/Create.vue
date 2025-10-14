<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <h2>创建新用户账户</h2>
    <el-card shadow="always">
      <el-form ref="userFormRef" :model="userForm" :rules="rules" label-width="120px" style="max-width: 600px; margin-top: 20px;">
        <el-form-item label="学号/工号" prop="id"><el-input v-model="userForm.id"></el-input></el-form-item>
        <el-form-item label="姓名" prop="name"><el-input v-model="userForm.name"></el-input></el-form-item>
        <el-form-item label="密码" prop="password"><el-input v-model="userForm.password" type="password" show-password></el-input></el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="userForm.role" placeholder="请选择角色">
            <el-option label="患者" value="patient"></el-option>
            <el-option label="医生" value="doctor"></el-option>
            <el-option label="管理员" value="admin"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="身份证号" prop="id_card"><el-input v-model="userForm.id_card"></el-input></el-form-item>
        <el-form-item label="手机号" prop="phone"><el-input v-model="userForm.phone"></el-input></el-form-item>
        <el-form-item label="过敏史" prop="allergy_history"><el-input v-model="userForm.allergy_history" type="textarea"></el-input></el-form-item>
        <el-form-item label="既往病史" prop="past_medical_history"><el-input v-model="userForm.past_medical_history" type="textarea"></el-input></el-form-item>
        <el-form-item>
          <el-button type="primary" @click="submitForm">立即创建</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import BackButton from '@/components/BackButton.vue';
import { ref, reactive } from 'vue';
import { ElMessage } from 'element-plus';

const userFormRef = ref(null);
const userForm = reactive({
  id: '', name: '', password: '', role: 'patient', id_card: '', phone: '', allergy_history: '', past_medical_history: ''
});

const rules = reactive({
  id: [{ required: true, message: '请输入学号/工号', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
  id_card: [{ required: true, message: '请输入身份证号', trigger: 'blur' }],
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }],
});

const submitForm = () => {
  userFormRef.value.validate((valid) => {
    if (valid) {
      console.log('Form data:', userForm);
      ElMessage.success('用户创建成功 (模拟)');
    } else {
      ElMessage.error('请检查输入项');
      return false;
    }
  });
};
const resetForm = () => userFormRef.value.resetFields();
</script>

<style scoped>.app-container { padding: 20px; }</style>
