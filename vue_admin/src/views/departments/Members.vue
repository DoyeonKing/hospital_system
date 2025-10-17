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
    </div>

    <el-empty v-else description="未找到指定的科室信息" />


    <el-dialog v-model="addDialogVisible" title="添加新成员" width="500px">
      <el-form ref="addFormRef" :model="addForm" :rules="addRules" label-width="80px">
        <el-form-item label="医生ID" prop="id">
          <el-input v-model="addForm.id" placeholder="请输入医生工号" />
        </el-form-item>
        <el-form-item label="账户状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="active">激活</el-radio>
            <el-radio label="inactive">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddMember">确认添加</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
<<<<<<< HEAD
import { ref, reactive, computed, onMounted } from 'vue';
import { Plus, Delete } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import doctorMaleImg from '@/assets/doctor.jpg';
import doctorFemaleImg from '@/assets/doctor1.jpg';

// --- 模拟数据 (已根据您的表结构更新) ---
const departments = ref([
  { id: '1', name: '内科', children: [
      { id: '11', name: '呼吸内科' }, { id: '12', name: '心血管科' }
    ]},
  { id: '2', name: '外科', children: [ { id: '21', name: '普外科' } ]},
  { id: '3', name: '妇产科', children: [] },
]);

const membersData = ref({
  '12': [ // 心血管科
    {id: 201, department_id: 12, identifier: 'D001', full_name: '赵医生', title: '主治医师', specialty: '呼吸系统疾病', gender: 'male', status: 'active'},
    {id: 202, department_id: 12, identifier: 'D002', full_name: '钱医生', title: '副主任医师', specialty: '牙体牙髓病治疗', gender: 'male', status: 'active'},
  ],
  '3': [ // 妇产科
    {id: 203, department_id: 3, identifier: 'D003', full_name: '孙医生', title: '主治医师', specialty: '全科诊疗', gender: 'female', status: 'inactive'}
  ],
=======
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
>>>>>>> origin/qiuyuying
});
// --- 模拟数据结束 ---

const activeParent = ref(null);
const activeSub = ref(null);
const dialogVisible = ref(false);
const formRef = ref(null);

const form = reactive({
  identifier: '',
  full_name: '',
  title: '',
  specialty: '',
  gender: 'male',
  status: 'active'
});
const rules = {
  identifier: [{ required: true, message: '医生工号不能为空', trigger: 'blur' }],
  full_name: [{ required: true, message: '医生姓名不能为空', trigger: 'blur' }],
  title: [{ required: true, message: '职称为必填项', trigger: 'blur' }],
};

const subDepartments = computed(() => {
  if (!activeParent.value) return [];
  const parent = departments.value.find(p => p.id === activeParent.value);
  return parent ? parent.children : [];
});

<<<<<<< HEAD
const selectedDepartmentName = computed(() => {
  if (!activeSub.value) return '请选择科室';
  const parentAsSub = departments.value.find(p => p.id === activeSub.value);
  if (parentAsSub) return parentAsSub.name;
  for (const parent of departments.value) {
    const sub = parent.children.find(c => c.id === activeSub.value);
    if (sub) return sub.name;
  }
  return '未知科室';
});

const currentDoctors = computed(() => {
  if (!activeSub.value) return [];
  return membersData.value[activeSub.value] || [];
});

const handleParentSelect = (index) => {
  activeParent.value = index;
  const parent = departments.value.find(p => p.id === index);
  if (parent) {
    if (parent.children && parent.children.length > 0) {
      activeSub.value = parent.children[0].id;
=======
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
>>>>>>> origin/qiuyuying
    } else {
      activeSub.value = parent.id;
    }
  } else {
    activeSub.value = null;
  }
};

const handleSubSelect = (id) => {
  activeSub.value = id;
};

const openAddDialog = () => {
  formRef.value?.resetFields();
  dialogVisible.value = true;
};

const handleAddMember = () => {
  formRef.value.validate((valid) => {
    if (valid) {
      if (!membersData.value[activeSub.value]) {
        membersData.value[activeSub.value] = [];
      }
      const newMember = { ...form, id: Date.now() }; // 使用时间戳作为临时唯一ID
      membersData.value[activeSub.value].push(newMember);
      ElMessage.success('成员添加成功 (模拟)');
      dialogVisible.value = false;
    }
  });
};

<<<<<<< HEAD
const handleDelete = (doctor) => {
  ElMessageBox.confirm(`确定要从科室移除医生 "${doctor.full_name}" 吗？`, '警告', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
  }).then(() => {
    const members = membersData.value[activeSub.value];
    if (members) {
      const index = members.findIndex(m => m.id === doctor.id);
      if (index > -1) {
        members.splice(index, 1);
        ElMessage.success('移除成功 (模拟)');
      }
    }
  }).catch(() => {});
=======
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
>>>>>>> origin/qiuyuying
};

onMounted(() => {
  if (departments.value.length > 0) {
    handleParentSelect(departments.value[0].id);
  }
});
</script>

<style scoped>
<<<<<<< HEAD
.member-management-dashboard {
  display: flex;
  height: calc(100vh - 50px);
  background-color: #f7fafc;
}
.department-sidebar {
  width: 320px;
  display: flex;
  background-color: #fff;
  border-right: 1px solid #e2e8f0;
  flex-shrink: 0;
}
.department-menu {
  width: 120px;
  border-right: none;
}
.sub-department-panel {
  flex: 1;
  padding: 8px;
  border-left: 1px solid #e2e8f0;
}
.sub-department-item {
  padding: 10px 15px;
  cursor: pointer;
  border-radius: 4px;
}
.sub-department-item:hover {
  background-color: #f5f7fa;
}
.sub-department-item.active {
  background-color: #ecf5ff;
  color: #409eff;
  font-weight: bold;
}
.member-content {
  flex: 1;
  padding: 20px;
  overflow: auto;
}
.member-card {
  height: 100%;
}
.card-header {
=======
.app-container { padding: 20px; }
.card-header-title {
>>>>>>> origin/qiuyuying
  display: flex;
  justify-content: space-between;
  align-items: center;
}
<<<<<<< HEAD
.placeholder {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 500px;
}
.doctor-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}
.doctor-profile-card {
  transition: box-shadow 0.3s;
}
.doctor-profile-card:hover {
  box-shadow: 0 8px 16px rgba(0,0,0,0.1);
}
.doctor-card-header {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
  position: relative;
}
.doctor-avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  margin-right: 16px;
  object-fit: cover;
  border: 2px solid #eee;
}
.doctor-info {
  display: flex;
  flex-direction: column;
}
.doctor-name {
  font-size: 16px;
  font-weight: bold;
}
.doctor-title {
  font-size: 14px;
  color: #606266;
}
.status-tag {
  position: absolute;
  top: 0;
  right: 0;
}
.doctor-details {
  font-size: 14px;
=======
.department-name-title {
  margin: 0;
  font-size: 18px;
  font-weight: bold;
>>>>>>> origin/qiuyuying
  color: #303133;
  line-height: 1.6;
}
.detail-item {
  margin-bottom: 8px;
}
.card-actions {
  text-align: right;
  border-top: 1px solid #f2f6fc;
  padding-top: 12px;
  margin-top: 16px;
}
<<<<<<< HEAD
</style>

=======
.member-management-section { margin-top: 10px; }
</style>
>>>>>>> origin/qiuyuying
