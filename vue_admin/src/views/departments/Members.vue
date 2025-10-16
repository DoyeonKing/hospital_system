<template>
  <div class="member-management-dashboard">
    <!-- 左侧科室导航 -->
    <div class="department-sidebar">
      <el-menu :default-active="activeParent" class="department-menu" @select="handleParentSelect">
        <el-menu-item v-for="parent in departments" :key="parent.id" :index="parent.id">
          <span>{{ parent.name }}</span>
        </el-menu-item>
      </el-menu>

      <div class="sub-department-panel" v-if="subDepartments.length > 0">
        <div v-for="sub in subDepartments" :key="sub.id" class="sub-department-item" :class="{ 'active': activeSub === sub.id }" @click="handleSubSelect(sub.id)">
          {{ sub.name }}
        </div>
      </div>
    </div>

    <!-- 右侧成员展示区 -->
    <div class="member-content">
      <el-card shadow="always" class="member-card">
        <template #header>
          <div class="card-header">
            <span>{{ selectedDepartmentName }} - 成员列表</span>
            <el-button type="primary" :icon="Plus" @click="openAddDialog" :disabled="!activeSub">添加新成员</el-button>
          </div>
        </template>

        <div v-if="activeSub" class="doctor-grid">
          <el-card v-for="doc in currentDoctors" :key="doc.id" class="doctor-profile-card">
            <div class="doctor-card-header">
              <img :src="doc.gender === 'male' ? doctorMaleImg : doctorFemaleImg" class="doctor-avatar">
              <div class="doctor-info">
                <span class="doctor-name">{{ doc.full_name }}</span>
                <span class="doctor-title">{{ doc.title }}</span>
              </div>
              <el-tag :type="doc.status === 'active' ? 'success' : 'danger'" size="small" class="status-tag">{{ doc.status }}</el-tag>
            </div>
            <div class="doctor-details">
              <div class="detail-item"><strong>医生工号:</strong> {{ doc.identifier }}</div>
              <div class="detail-item"><strong>专业领域:</strong> {{ doc.specialty }}</div>
            </div>
            <div class="card-actions">
              <el-button type="danger" :icon="Delete" size="small" @click="handleDelete(doc)">移除</el-button>
            </div>
          </el-card>
          <el-empty v-if="!currentDoctors.length" description="该科室暂无成员" />
        </div>
        <div v-else class="placeholder">
          <el-empty description="请在左侧选择一个科室以查看成员" />
        </div>

      </el-card>
    </div>

    <!-- 添加新成员弹窗 -->
    <el-dialog v-model="dialogVisible" title="添加新成员" width="500px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="医生工号" prop="identifier"><el-input v-model="form.identifier" placeholder="例如：D001" /></el-form-item>
        <el-form-item label="医生姓名" prop="full_name"><el-input v-model="form.full_name" placeholder="请输入医生姓名" /></el-form-item>
        <el-form-item label="职称" prop="title"><el-input v-model="form.title" placeholder="例如：主任医师" /></el-form-item>
        <el-form-item label="专业领域" prop="specialty"><el-input v-model="form.specialty" placeholder="例如：呼吸系统疾病" /></el-form-item>
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="form.gender">
            <el-radio label="male">男</el-radio>
            <el-radio label="female">女</el-radio>
          </el-radio-group>
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
};

onMounted(() => {
  if (departments.value.length > 0) {
    handleParentSelect(departments.value[0].id);
  }
});
</script>

<style scoped>
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
  display: flex;
  justify-content: space-between;
  align-items: center;
}
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
</style>

