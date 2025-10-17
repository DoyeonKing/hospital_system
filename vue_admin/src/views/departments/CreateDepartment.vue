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
import { useRouter } from 'vue-router'; // 导入路由，用于创建成功后跳转

// 导入 API 服务
import { createDepartment, getDepartmentPage } from '@/api/department';

const router = useRouter();

// 表单的引用
const departmentFormRef = ref(null);

// 表单数据模型
const departmentForm = reactive({
  name: '',
  // clinic_id: null, // 移除：模板中没有该字段
  parent_id: null, // 上级科室ID
  description: '',
});

// 表单验证规则
const rules = reactive({
  name: [
    { required: true, message: '请输入科室名称', trigger: 'blur' },
  ],
  // 移除 clinic_id 的规则
  // 上级科室和描述为非必填项
});

// --- 数据部分 ---
// 用于存储从后端获取的科室列表 (用于选择上级科室)
const departmentList = ref([]);

// 核心方法：从后端获取所有科室列表 (用于“上级科室”下拉框)
const fetchDepartments = async () => {
  console.log("正在获取所有科室列表...");
  try {
    // 调用分页接口，但请求 size 很大，以获取所有数据（假设最多 9999 个科室）
    const response = await getDepartmentPage({ page: 1, size: 9999 });

    // 假设后端返回的数据包含 departmentId 和 name 字段
    departmentList.value = response.content.map(dept => ({
        // 将后端返回的 departmentId 映射到 el-option 需要的 value (id)
        id: dept.departmentId,
        name: dept.name
    })) || [];

  } catch (error) {
    // 错误处理已在 request.js 中统一处理
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
      console.log('提交的表单数据:', departmentForm);
      try {
        // 构造发送给后端的数据 (parent_id 为 null 时不影响)
        const submitData = {
          name: departmentForm.name,
          description: departmentForm.description,
          // ⚠️ 确保后端能正确处理 parent_id (null 或 number)
          parent_id: departmentForm.parent_id,
        };

        // 调用创建 API
        await createDepartment(submitData);

        ElMessage.success('科室创建成功！');
        // 跳转回列表页 /departments
        router.push({ path: '/departments' });

      } catch (error) {
        // 错误信息已由 request.js 统一处理
        console.error('创建科室失败:', error);
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
};
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>