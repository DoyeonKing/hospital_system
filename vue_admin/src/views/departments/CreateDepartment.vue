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


        <el-form-item label="上级科室" prop="parentDepartmentName">
          <el-select
              v-model="departmentForm.parentDepartmentName"
              placeholder="请选择上级科室 (可不选)"
              style="width: 100%;"
              filterable
              clearable
          >
            <el-option
                v-for="department in departmentList"
                :key="department.id"
                :label="department.name"
                :value="department.name" />
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
import { useRouter } from 'vue-router'; // 导入路由，用于提交成功后跳转
import { createDepartment, getDepartmentPage } from '@/api/department'; // 导入新增接口和列表接口

const router = useRouter();
// 表单的引用
const departmentFormRef = ref(null);

// 表单数据模型
const departmentForm = reactive({
  name: '',
  // 匹配 API 字段：parentDepartmentName
  parentDepartmentName: null,
  description: '',
  // 移除了 clinic_id 和 parent_id
});

// 表单验证规则
const rules = reactive({
  name: [
    { required: true, message: '请输入科室名称', trigger: 'blur' },
  ],
  // 移除了 clinic_id 的校验。parentDepartmentName 和 description 为非必填项
});

// --- 数据部分 ---
// 用于存储从后端获取的科室列表 (用于选择上级科室)
const departmentList = ref([]);

// 真实从后端API获取所有科室列表
const fetchDepartments = async () => {
    try {
        // 调用分页接口获取所有数据（假设 size 足够大，或使用专门的全列表接口）
        const response = await getDepartmentPage({ page: 1, size: 100, name: '', description: '' });

        // 只获取原始的扁平列表
        departmentList.value = response.content || [];

    } catch (error) {
        console.error("获取科室列表失败:", error);
    }
};

// 在组件挂载后，自动获取下拉框所需的数据
onMounted(() => {
  fetchDepartments();
});


// 提交表单的方法
const submitForm = () => {
  departmentFormRef.value.validate(async (valid) => {
    if (valid) {
      // 构造符合后端API要求的DTO
      const departmentDTO = {
        name: departmentForm.name,
        // 如果 parentDepartmentName 为 null 或空字符串，则传 null
        parentDepartmentName: departmentForm.parentDepartmentName || null,
        description: departmentForm.description,
      };

      try {
        await createDepartment(departmentDTO); // <--- 调用新增接口
        ElMessage.success('科室创建成功！');
        // 成功后跳转回列表页
        router.push({ path: '/departments' });
      } catch (error) {
        // 错误处理由 request.js 拦截器和 Promise 捕获负责
        console.error("创建科室失败:", error);
      }

    } else {
      ElMessage.error('请检查必填项！');
      return false;
    }
  });
};

// 重置表单的方法
const resetForm = () => {
  departmentFormRef.value.resetFields();
  // 重置字段为 null
  departmentForm.parentDepartmentName = null;
};

// 移除了 fetchClinics 的模拟代码
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>