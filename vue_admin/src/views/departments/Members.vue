<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>

    <el-card shadow="always" v-if="currentDepartment" v-loading="loading">
      <template #header>
        <div class="card-header-title">
          <h2 class="department-name-title">{{ currentDepartment.name }}</h2>
          <el-button type="primary" :icon="Plus" @click="openAddDialog">
            添加成员
          </el-button>
        </div>
      </template>

      <div class="member-management-section">
        <el-table :data="currentDepartment.members" border stripe>
          <el-table-column prop="id" label="医生ID" width="150" />
          <el-table-column prop="name" label="医生姓名" width="180" />
          <el-table-column prop="title" label="职称" />
          <el-table-column label="操作" width="120" align="center">
            <template #default="{ row }">
              <el-button
                  type="danger"
                  size="small"
                  :icon="Delete"
                  @click="handleDelete(row.id)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!currentDepartment.members || currentDepartment.members.length === 0" description="该科室暂无成员" />
      </div>
    </el-card>

    <el-empty v-else-if="!loading" description="未找到指定的科室信息或获取失败" />

    <el-dialog v-model="addDialogVisible" title="添加新成员" width="500px">
      <el-form ref="addFormRef" :model="addForm" :rules="addRules" label-width="80px">
        <el-form-item label="医生ID" prop="id">
          <el-input v-model="addForm.id" placeholder="请输入医生工号" />
        </el-form-item>
        <el-form-item label="医生姓名" prop="name">
          <el-input v-model="addForm.name" placeholder="请输入医生姓名" />
        </el-form-item>
        <el-form-item label="职称" prop="title">
          <el-input v-model="addForm.title" placeholder="请输入医生职称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddMember">确认添加</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { Plus, Delete } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import BackButton from '@/components/BackButton.vue';
import { useRoute } from 'vue-router';
import { getDepartmentDoctors } from '@/api/department';

const route = useRoute();
const addFormRef = ref(null);
const currentDepartment = ref(null);
const loading = ref(true);

const fetchDepartmentDoctors = async (departmentId) => {
  if (!departmentId) {
    loading.value = false;
    ElMessage.error('无效的科室ID');
    return;
  }

  loading.value = true;
  try {
    const response = await getDepartmentDoctors(departmentId);

    // --- 关键调试步骤 ---
    // 在浏览器控制台查看API的真实返回值
    console.log("API 返回的原始 response:", response);

    // 检查并处理返回的数据
    // 许多axios封装会直接返回data，所以我们先检查 response.data 是否存在
    // 如果不存在，我们再尝试直接使用 response
    const departmentData = response.data || response;

    if (!departmentData || !departmentData.departmentId) {
      // 如果数据格式不正确或为空，则抛出错误
      throw new Error("返回的数据格式不正确或为空");
    }

    currentDepartment.value = {
      id: departmentData.departmentId,
      name: departmentData.departmentName,
      members: departmentData.doctors.map(doctor => ({
        id: doctor.identifier,
        name: doctor.fullName,
        title: doctor.title
      }))
    };
  } catch (error) {
    // 这里的日志会更详细
    console.error('获取科室医生列表失败:', error);
    ElMessage.error('获取科室医生列表失败，详情请查看控制台');
    currentDepartment.value = null;
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  const departmentId = route.params.id;
  if (departmentId) {
    fetchDepartmentDoctors(departmentId);
  } else {
    loading.value = false;
    console.error("未能从URL中获取到 departmentId");
    ElMessage.error('页面路由参数不正确，无法加载科室信息');
  }
});

// 添加成员对话框... (以下逻辑与之前相同)
const addDialogVisible = ref(false);
const addForm = reactive({ id: '', name: '', title: '' });
const addRules = reactive({
  id: [{ required: true, message: '医生ID不能为空', trigger: 'blur' }],
  name: [{ required: true, message: '医生姓名不能为空', trigger: 'blur' }],
  title: [{ required: true, message: '医生职称不能为空', trigger: 'blur' }]
});

const openAddDialog = () => {
  if (addFormRef.value) {
    addFormRef.value.resetFields();
  }
  Object.assign(addForm, { id: '', name: '', title: '' });
  addDialogVisible.value = true;
};

const handleAddMember = () => {
  addFormRef.value.validate((valid) => {
    if (valid) {
      if (currentDepartment.value) {
        if (currentDepartment.value.members.some(m => m.id === addForm.id)) {
          ElMessage.error('该医生ID已存在于本科室！');
          return;
        }
        currentDepartment.value.members.push({ ...addForm });
        ElMessage.success('成员添加成功！');
        addDialogVisible.value = false;
      }
    }
  });
};

const handleDelete = (memberId) => {
  ElMessageBox.confirm('确定要从该科室移除这位成员吗？', '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    if (currentDepartment.value) {
      currentDepartment.value.members = currentDepartment.value.members.filter(m => m.id !== memberId);
      ElMessage.success('成员删除成功！');
    }
  });
};
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.card-header-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.department-name-title {
  margin: 0;
  font-size: 18px;
  font-weight: bold;
  color: #303133;
  line-height: 1.6;
}
.member-management-section {
  margin-top: 10px;
}
</style>