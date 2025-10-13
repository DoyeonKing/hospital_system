<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <h2>创建新科室</h2>
    <el-card shadow="always">
      <el-form
          ref="departmentFormRef"
          :model="departmentForm"
          :rules="rules"
          label-width="120px"
          style="max-width: 600px; margin-top: 20px;"
      >
        <el-form-item label="科室名称" prop="name">
          <el-input v-model="departmentForm.name" placeholder="请输入科室名称"></el-input>
        </el-form-item>
        <el-form-item label="诊所编号" prop="clinic_id">
          <el-input v-model="departmentForm.clinic_id" placeholder="请输入诊所编号"></el-input>
        </el-form-item>
        <el-form-item label="科室描述" prop="description">
          <el-input
              v-model="departmentForm.description"
              type="textarea"
              :rows="4"
              placeholder="请输入科室的详细描述"
          ></el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="submitForm">立即创建</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { ElMessage } from 'element-plus';
import BackButton from '@/components/BackButton.vue';

// 表单的引用，用于后续的表单验证和重置
const departmentFormRef = ref(null);

// 表单数据模型
const departmentForm = reactive({
  name: '',
  clinic_id: '',
  description: '',
});

// 表单验证规则
const rules = reactive({
  name: [
    { required: true, message: '请输入科室名称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在 2 到 20 个字符', trigger: 'blur' },
  ],
  clinic_id: [
    { required: true, message: '请输入诊所编号', trigger: 'blur' },
  ],
  description: [
    { required: false, message: '请输入科室描述', trigger: 'blur' },
  ],
});

// 提交表单的方法
const submitForm = () => {
  departmentFormRef.value.validate((valid) => {
    if (valid) {
      // 在这里，您之后可以添加调用后端 API 的逻辑
      // 目前，我们只在控制台打印表单数据
      console.log('Form data:', departmentForm);

      ElMessage({
        message: '科室创建成功（模拟）!',
        type: 'success',
      });

      // 成功后可以重置表单
      // resetForm();
    } else {
      console.log('error submit!!');
      ElMessage({
        message: '请检查输入项!',
        type: 'error',
      });
      return false;
    }
  });
};

// 重置表单的方法
const resetForm = () => {
  departmentFormRef.value.resetFields();
};
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>