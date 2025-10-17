<template>
  <div class="app-container">
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

        <!-- 所属诊所 -> 改为选择框 -->
        <el-form-item label="所属诊所" prop="clinic_id">
          <el-select
              v-model="departmentForm.clinic_id"
              placeholder="请选择所属诊所"
              style="width: 100%;"
              filterable
              clearable
          >
            <el-option
                v-for="clinic in clinicList"
                :key="clinic.id"
                :label="clinic.name"
                :value="clinic.id"
            />
          </el-select>
        </el-form-item>

        <!-- 新增：上级科室 -->
        <el-form-item label="上级科室" prop="parent_id">
          <el-select
              v-model="departmentForm.parent_id"
              placeholder="请选择上级科室 (可不选)"
              style="width: 100%;"
              filterable
              clearable
          >
            <el-option
                v-for="department in departmentList"
                :key="department.id"
                :label="department.name"
                :value="department.id"
            />
          </el-select>
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
import { ref, reactive, onMounted } from 'vue';
import { ElMessage } from 'element-plus';

// 表单的引用
const departmentFormRef = ref(null);

// 表单数据模型
const departmentForm = reactive({
  name: '',
  clinic_id: null, // 改为null以匹配选择器
  parent_id: null, // 新增
  description: '',
});

// 表单验证规则
const rules = reactive({
  name: [
    { required: true, message: '请输入科室名称', trigger: 'blur' },
  ],
  clinic_id: [
    { required: true, message: '请选择所属诊所', trigger: 'change' },
  ],
  // 上级科室和描述为非必填项
});

// --- 数据部分 ---
// 用于存储从后端获取的诊所列表
const clinicList = ref([]);
// 用于存储从后端获取的科室列表 (用于选择上级科室)
const departmentList = ref([]);

// 模拟从后端API获取数据
const fetchClinics = async () => {
  // === 在这里编写您调用后端API获取诊所列表的真实代码 ===
  // const response = await yourApi.getClinics();
  // clinicList.value = response.data;

  // 目前使用模拟数据
  console.log("正在获取诊所列表...");
  clinicList.value = [
    { id: 'CLI_A', name: 'A诊所 (总院)' },
    { id: 'CLI_B', name: 'B诊所 (南校区)' },
    { id: 'CLI_C', name: 'C诊所 (北校区)' },
  ];
};

const fetchDepartments = async () => {
  // === 在这里编写您调用后端API获取科室列表的真实代码 ===
  // const response = await yourApi.getDepartments();
  // departmentList.value = response.data;

  console.log("正在获取科室列表...");
  departmentList.value = [
    { id: 'DEPT_001', name: '心血管内科' },
    { id: 'DEPT_002', name: '神经外科' },
    { id: 'DEPT_003', name: '儿科' },
  ];
};

// 在组件挂载后，自动获取下拉框所需的数据
onMounted(() => {
  fetchClinics();
  fetchDepartments();
});


// 提交表单的方法
const submitForm = () => {
  departmentFormRef.value.validate((valid) => {
    if (valid) {
      console.log('提交的表单数据:', departmentForm);
      ElMessage.success('科室创建成功 (模拟)');
    } else {
      ElMessage.error('请检查必填项！');
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
