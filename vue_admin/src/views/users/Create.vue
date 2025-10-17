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
            <el-option label="患者" value="PATIENT"></el-option>
            <el-option label="医生" value="DOCTOR"></el-option>
          </el-select>
        </el-form-item>
        
        <!-- 患者特有字段 -->
        <template v-if="userForm.role === 'PATIENT'">
          <el-form-item label="患者类型" prop="patientType">
            <el-select v-model="userForm.patientType" placeholder="请选择患者类型">
              <el-option label="学生" value="student"></el-option>
              <el-option label="教师" value="teacher"></el-option>
              <el-option label="职工" value="staff"></el-option>
            </el-select>
          </el-form-item>
        </template>
        
        <!-- 医生特有字段 -->
        <template v-if="userForm.role === 'DOCTOR'">
          <el-form-item label="科室ID" prop="departmentId">
            <el-input v-model="userForm.departmentId" type="number" placeholder="请输入科室ID"></el-input>
          </el-form-item>
        </template>
        <el-form-item label="身份证号" prop="id_card"><el-input v-model="userForm.id_card"></el-input></el-form-item>
        <el-form-item label="手机号" prop="phone"><el-input v-model="userForm.phone"></el-input></el-form-item>
        
        <!-- 患者特有字段 -->
        <template v-if="userForm.role === 'PATIENT'">
          <el-form-item label="过敏史"><el-input v-model="userForm.allergy_history" type="textarea" placeholder="请输入过敏史（可选）"></el-input></el-form-item>
          <el-form-item label="既往病史"><el-input v-model="userForm.past_medical_history" type="textarea" placeholder="请输入既往病史（可选）"></el-input></el-form-item>
        </template>
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
import { createUser } from '@/api/user';

const userFormRef = ref(null);
const userForm = reactive({
  id: '', 
  name: '', 
  password: '', 
  role: 'PATIENT', 
  id_card: '', 
  phone: '', 
  allergy_history: '', 
  past_medical_history: '',
  patientType: 'student',
  departmentId: 1
});

const rules = reactive({
  id: [{ required: true, message: '请输入学号/工号', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }],
  id_card: [{ required: true, message: '请输入身份证号', trigger: 'blur' }],
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }],
});

const submitForm = async () => {
  try {
    const valid = await userFormRef.value.validate();
    if (!valid) return;

    // 构建创建用户请求数据
    const createData = {
      role: userForm.role,
      id: userForm.id,
      name: userForm.name,
      password: userForm.password,
      id_card: userForm.id_card,
      phone: userForm.phone
    };

    // 根据角色添加特定字段
    if (userForm.role === 'PATIENT') {
      createData.patientType = userForm.patientType;
      createData.patientStatus = 'inactive'; // 默认未激活
      createData.allergy_history = userForm.allergy_history;
      createData.past_medical_history = userForm.past_medical_history;
    } else if (userForm.role === 'DOCTOR') {
      createData.doctorStatus = 'inactive'; // 默认未激活
      createData.departmentId = userForm.departmentId;
      // 医生可以后续通过编辑功能添加职称、专长等信息
    }

    await createUser(createData);
    ElMessage.success('用户创建成功！');
    resetForm();
    
  } catch (error) {
    ElMessage.error('创建失败：' + (error.response?.data?.message || error.message));
  }
};

const resetForm = () => {
  userFormRef.value.resetFields();
  userForm.role = 'PATIENT';
  userForm.patientType = 'student';
  userForm.departmentId = 1;
};
</script>

<style scoped>.app-container { padding: 20px; }</style>
