<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>

    <el-card shadow="always" v-if="currentDepartment">
      <template #header>
        <div class="card-header-title">
          <h2 class="department-name-title">{{ currentDepartment.name }}</h2>
          <el-button type="primary" :icon="Plus" @click="openAddDialog(currentDepartment.id)">
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
                  @click="handleDelete(currentDepartment.id, row.id)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!currentDepartment.members || currentDepartment.members.length === 0" description="该科室暂无成员" />
      </div>
    </el-card>

    <el-empty v-else description="未找到指定的科室信息" />


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
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { Plus, Delete } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import BackButton from '@/components/BackButton.vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const addFormRef = ref(null);

// 模拟的科室及成员数据 (ID 与 Index.vue 保持同步)
const allDepartmentsData = ref([
  // 有成员的科室 (子科室)
  {
    id: 101, // 对应 Index.vue 中的心血管内科
    name: '心血管内科',
    members: [
      { id: 'DOC_101', name: '王伟', title: '主任医师' }, // 对应 image_5cc57d.png
      { id: 'DOC_102', name: '李静', title: '副主任医师' } // 对应 image_5cc57d.png
    ]
  },
  {
    id: 102, // 对应 Index.vue 中的神经外科
    name: '神经外科',
    members: [
      { id: 'DOC_201', name: '张磊', title: '主治医师' }
    ]
  },
  {
    id: 201, // 对应 Index.vue 中的儿科
    name: '儿科',
    members: [
        { id: 'DOC_301', name: '赵小琴', title: '儿科医师' }
    ]
  },
  // 无成员的科室 (根科室)
  { id: 1, name: '总院行政部', description: '负责总院的行政管理', parent_id: null, members: [] }, // 对应 image_5c4cdd.png
  { id: 2, name: '门诊部', description: '负责日常门诊接待和初步诊断', parent_id: null, members: [] }, // 对应 image_5c4cdd.png
  { id: 3, name: '后勤保障部', description: '负责设备维护和物资采购', parent_id: null, members: [] }, // 对应 image_5c4cdd.png
  { id: 4, name: '财务部', description: '负责医院财务核算与管理', parent_id: null, members: [] }, // 对应 image_5c4cdd.png
  { id: 202, name: '皮肤科', members: [] },
]);


const deptIdFromRoute = ref(route.params.id);

watch(
    () => route.params.id,
    (newId) => {
        deptIdFromRoute.value = newId;
    }
);

const currentDepartment = computed(() => {
    // 查找科室，ID可能为字符串（路由参数）或数字（模拟数据），使用 == 比较
    return allDepartmentsData.value.find(d => d.id == deptIdFromRoute.value);
});


// 添加成员对话框相关
const addDialogVisible = ref(false);
const currentDeptId = ref(null);
const addForm = reactive({
  id: '', name: '', title: ''
});
const addRules = reactive({
  id: [{ required: true, message: '医生ID不能为空', trigger: 'blur' }],
  name: [{ required: true, message: '医生姓名不能为空', trigger: 'blur' }],
  title: [{ required: true, message: '医生职称不能为空', trigger: 'blur' }]
});

const openAddDialog = (deptId) => {
  currentDeptId.value = deptId;
  if(addFormRef.value) addFormRef.value.resetFields();
  Object.assign(addForm, { id: '', name: '', title: '' });
  addDialogVisible.value = true;
};

const handleAddMember = () => {
  addFormRef.value.validate((valid) => {
    if (valid) {
      const department = allDepartmentsData.value.find(d => d.id == currentDeptId.value);
      if (department) {
        if (department.members.some(m => m.id === addForm.id)) {
             ElMessage.error('该医生ID已存在于本科室！');
             return;
        }
        department.members.push({ ...addForm });
        ElMessage.success('成员添加成功！');
        addDialogVisible.value = false;
      }
    } else {
      ElMessage.error('请检查输入项！');
    }
  });
};

const handleDelete = (deptId, memberId) => {
  ElMessageBox.confirm(
      '确定要从该科室移除这位成员吗？',
      '警告',
      { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    const department = allDepartmentsData.value.find(d => d.id == deptId);
    if (department) {
      department.members = department.members.filter(m => m.id !== memberId);
      ElMessage.success('成员删除成功！');
    }
  });
};
</script>

<style scoped>
.app-container { padding: 20px; }
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
}
.member-management-section { margin-top: 10px; }
</style>