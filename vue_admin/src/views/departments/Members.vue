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
          <el-table-column prop="identifier" label="医生工号" width="150" />
          <el-table-column prop="fullName" label="医生姓名" width="180" />
          <el-table-column prop="title" label="职称" />
          <el-table-column prop="phoneNumber" label="联系电话" width="150" />
          <el-table-column label="操作" width="120" align="center">
            <template #default="{ row }">
              <el-button
                  type="danger"
                  size="small"
                  :icon="Delete"
                  @click="handleDelete(row.identifier)"
              >
                移除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!currentDepartment.members || currentDepartment.members.length === 0" description="该科室暂无成员" />
      </div>
    </el-card>

    <el-empty v-else-if="!loading" description="未找到指定的科室信息或获取失败" />

    <el-dialog v-model="addDialogVisible" title="添加新成员" width="500px">
      <el-form :model="addMemberForm" :rules="addMemberRules" ref="addMemberFormRef" label-width="100px">
        <el-form-item label="医生工号" prop="identifier">
          <el-input v-model="addMemberForm.identifier" placeholder="请输入医生工号" />
        </el-form-item>
        <el-form-item label="医生姓名" prop="fullName">
          <el-input v-model="addMemberForm.fullName" placeholder="请输入医生姓名" />
        </el-form-item>
        <el-form-item label="职称" prop="title">
          <el-input v-model="addMemberForm.title" placeholder="请输入职称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="addDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitAddMember" :loading="addingMember">确定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Plus, Delete } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
import { useRoute, useRouter } from 'vue-router';

// 导入 API 服务
import { getDepartmentById, addDepartmentMember, deleteDepartmentMember, getDoctorsByDepartmentId } from '@/api/department';

const route = useRoute();
const router = useRouter();

// 数据状态
const currentDepartment = ref(null);
const loading = ref(false);
const addDialogVisible = ref(false);
const addingMember = ref(false);

// 添加成员表单
const addMemberForm = reactive({
  identifier: '',
  fullName: '',
  title: ''
});

const addMemberRules = {
  identifier: [
    { required: true, message: '请输入医生工号', trigger: 'blur' }
  ],
  fullName: [
    { required: true, message: '请输入医生姓名', trigger: 'blur' }
  ],
  title: [
    { required: true, message: '请输入职称', trigger: 'blur' }
  ]
};

const addMemberFormRef = ref(null);

// 获取科室信息
const fetchDepartmentInfo = async () => {
  const departmentId = route.params.id;
  if (!departmentId) {
    ElMessage.error('缺少科室ID参数');
    router.back();
    return;
  }

  loading.value = true;
  try {
    // 并行获取科室信息和医生列表
    const [departmentResponse, doctorsResponse] = await Promise.all([
      getDepartmentById(departmentId),
      getDoctorsByDepartmentId(departmentId)
    ]);
    
    if (departmentResponse) {
      currentDepartment.value = departmentResponse;
      // 设置医生列表
      currentDepartment.value.members = doctorsResponse || [];
    } else {
      ElMessage.error('科室不存在');
      router.back();
    }
  } catch (error) {
    console.error('获取科室信息失败:', error);
    ElMessage.error('获取科室信息失败: ' + (error.message || '未知错误'));
  } finally {
    loading.value = false;
  }
};

// 打开添加成员对话框
const openAddDialog = () => {
  addMemberForm.identifier = '';
  addMemberForm.fullName = '';
  addMemberForm.title = '';
  addDialogVisible.value = true;
};

// 提交添加成员
const submitAddMember = async () => {
  if (!addMemberFormRef.value) return;

  try {
    await addMemberFormRef.value.validate();
    
    addingMember.value = true;
    
    await addDepartmentMember(currentDepartment.value.departmentId, addMemberForm);
    
    ElMessage.success('医生添加成功');
    addDialogVisible.value = false;
    
    // 刷新科室信息
    await fetchDepartmentInfo();
    
  } catch (error) {
    console.error('添加医生失败:', error);
    ElMessage.error('添加医生失败: ' + (error.message || '未知错误'));
  } finally {
    addingMember.value = false;
  }
};

// 删除成员
const handleDelete = async (doctorIdentifier) => {
  try {
    await ElMessageBox.confirm(
      '确定要从该科室移除该医生吗？医生将被移动到未分配科室。',
      '确认移除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
    );

    await deleteDepartmentMember(currentDepartment.value.departmentId, doctorIdentifier);
    ElMessage.success('医生移除成功');
    
    // 刷新科室信息
    await fetchDepartmentInfo();
    
  } catch (error) {
    if (error !== 'cancel') {
      console.error('移除医生失败:', error);
      ElMessage.error('移除医生失败: ' + (error.message || '未知错误'));
    }
  }
};

// 组件挂载时获取数据
onMounted(() => {
  fetchDepartmentInfo();
});
</script>

<style scoped>
.app-container {
  padding: 20px;
}

.back-area {
  margin-bottom: 12px;
}

.card-header-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.department-name-title {
  margin: 0;
  color: #303133;
}

.member-management-section {
  margin-top: 20px;
}

.dialog-footer {
  text-align: right;
}
</style>