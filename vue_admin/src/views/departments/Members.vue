<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <el-card shadow="always">
      <template #header>
        <div class="card-header">
          <span>科室成员管理</span>
        </div>
      </template>
      <p>在这里，您可以为每个科室添加或移除医生信息。</p>

      <!-- 科室列表循环 -->
      <div v-for="dept in departments" :key="dept.id" class="department-section">
        <div class="department-header">
          <h3 class="department-name">{{ dept.name }}</h3>
          <el-button type="primary" :icon="Plus" @click="openAddDialog(dept.id)">
            添加成员
          </el-button>
        </div>
        <el-table :data="dept.members" border stripe>
          <el-table-column prop="id" label="医生ID" width="150" />
          <el-table-column prop="name" label="医生姓名" width="180" />
          <el-table-column prop="title" label="职称" />
          <el-table-column label="操作" width="120" align="center">
            <template #default="{ row }">
              <el-button
                  type="danger"
                  size="small"
                  :icon="Delete"
                  @click="handleDelete(dept.id, row.id)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!dept.members || dept.members.length === 0" description="该科室暂无成员" />
      </div>
    </el-card>

    <!-- 添加新成员的对话框 -->
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
import { ref, reactive } from 'vue';
import { Plus, Delete } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import BackButton from '@/components/BackButton.vue';

const addFormRef = ref(null);

// 模拟的科室及成员数据
const departments = ref([
  {
    id: 'DEPT_001',
    name: '心血管内科',
    members: [
      { id: 'DOC_101', name: '王伟', title: '主任医师' },
      { id: 'DOC_102', name: '李静', title: '副主任医师' }
    ]
  },
  {
    id: 'DEPT_002',
    name: '神经外科',
    members: [
      { id: 'DOC_201', name: '张磊', title: '主治医师' }
    ]
  },
  {
    id: 'DEPT_003',
    name: '儿科',
    members: []
  },
]);

// 添加成员对话框相关
const addDialogVisible = ref(false);
const currentDeptId = ref(null);
const addForm = reactive({
  id: '',
  name: '',
  title: ''
});
const addRules = reactive({
  id: [{ required: true, message: '医生ID不能为空', trigger: 'blur' }],
  name: [{ required: true, message: '医生姓名不能为空', trigger: 'blur' }],
  title: [{ required: true, message: '医生职称不能为空', trigger: 'blur' }]
});

// 打开添加对话框
const openAddDialog = (deptId) => {
  currentDeptId.value = deptId;
  // 重置表单
  if(addFormRef.value) {
    addFormRef.value.resetFields();
  }
  addForm.id = '';
  addForm.name = '';
  addForm.title = '';
  addDialogVisible.value = true;
};

// 确认添加成员
const handleAddMember = () => {
  addFormRef.value.validate((valid) => {
    if (valid) {
      const department = departments.value.find(d => d.id === currentDeptId.value);
      if (department) {
        department.members.push({ ...addForm });
        ElMessage.success('成员添加成功！');
        addDialogVisible.value = false;
      }
    } else {
      ElMessage.error('请检查输入项！');
    }
  });
};

// 删除成员
const handleDelete = (deptId, memberId) => {
  ElMessageBox.confirm(
      '确定要从该科室移除这位成员吗？',
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
  ).then(() => {
    const department = departments.value.find(d => d.id === deptId);
    if (department) {
      department.members = department.members.filter(m => m.id !== memberId);
      ElMessage.success('成员删除成功！');
    }
  }).catch(() => {
    // 用户取消操作
  });
};
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.card-header {
  font-size: 18px;
  font-weight: bold;
}
.department-section {
  margin-bottom: 30px;
}
.department-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #ebeef5;
}
.department-name {
  margin: 0;
  font-size: 1.1em;
  color: #303133;
}
</style>
