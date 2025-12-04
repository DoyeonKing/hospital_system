<template>
  <div class="admin-management">
    <div class="page-header">
      <h2>管理员管理</h2>
      <el-button type="primary" @click="handleAdd">
        <el-icon><Plus /></el-icon>
        添加管理员
      </el-button>
    </div>

    <!-- 搜索栏 -->
    <el-card class="search-card">
      <el-form :inline="true" :model="searchForm">
        <el-form-item label="用户名">
          <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="searchForm.fullName" placeholder="请输入姓名" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="请选择状态" clearable>
            <el-option label="正常" value="active" />
            <el-option label="已禁用" value="inactive" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 管理员列表 -->
    <el-card class="table-card">
      <el-table :data="adminList" v-loading="loading" stripe>
        <el-table-column prop="adminId" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" width="150" />
        <el-table-column prop="fullName" label="姓名" width="120" />
        <el-table-column label="角色" width="200">
          <template #default="{ row }">
            <el-tag 
              v-for="role in row.roles" 
              :key="role.roleId" 
              :type="getRoleTagType(role.roleName)"
              size="small"
              style="margin-right: 5px;">
              {{ getRoleDisplayName(role.roleName) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'">
              {{ row.status === 'active' ? '正常' : '已禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button 
              type="primary" 
              size="small" 
              @click="handleViewPermissions(row)"
              link>
              <el-icon><View /></el-icon>
              查看权限
            </el-button>
            <el-button 
              type="warning" 
              size="small" 
              @click="handleEdit(row)"
              link>
              <el-icon><Edit /></el-icon>
              编辑
            </el-button>
            <el-button 
              :type="row.status === 'active' ? 'danger' : 'success'" 
              size="small" 
              @click="handleToggleStatus(row)"
              link>
              <el-icon><Switch /></el-icon>
              {{ row.status === 'active' ? '禁用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 添加/编辑对话框 -->
    <el-dialog 
      v-model="dialogVisible" 
      :title="dialogTitle"
      width="600px"
      @close="handleDialogClose">
      <el-form 
        ref="formRef" 
        :model="form" 
        :rules="rules" 
        label-width="100px">
        <el-form-item label="用户名" prop="username">
          <el-input 
            v-model="form.username" 
            placeholder="请输入用户名"
            :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="姓名" prop="fullName">
          <el-input v-model="form.fullName" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!isEdit">
          <el-input 
            v-model="form.password" 
            type="password" 
            placeholder="请输入密码"
            show-password />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword" v-if="!isEdit">
          <el-input 
            v-model="form.confirmPassword" 
            type="password" 
            placeholder="请再次输入密码"
            show-password />
        </el-form-item>
        <el-form-item label="角色" prop="roleIds">
          <el-select 
            v-model="form.roleIds" 
            multiple 
            placeholder="请选择角色"
            style="width: 100%;">
            <el-option 
              v-for="role in roleList" 
              :key="role.roleId" 
              :label="role.description" 
              :value="role.roleId">
              <span>{{ role.description }}</span>
              <span style="float: right; color: #8492a6; font-size: 13px;">
                {{ role.roleName }}
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="active">正常</el-radio>
            <el-radio label="inactive">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          确定
        </el-button>
      </template>
    </el-dialog>

    <!-- 权限查看对话框 -->
    <el-dialog 
      v-model="permissionDialogVisible" 
      title="管理员权限详情"
      width="700px">
      <div class="permission-detail">
        <div class="admin-info">
          <h3>{{ currentAdmin?.fullName }} ({{ currentAdmin?.username }})</h3>
          <div class="roles">
            <el-tag 
              v-for="role in currentAdmin?.roles" 
              :key="role.roleId"
              :type="getRoleTagType(role.roleName)"
              size="large"
              style="margin-right: 10px;">
              {{ getRoleDisplayName(role.roleName) }}
            </el-tag>
          </div>
        </div>
        <el-divider />
        <div class="permissions-list">
          <h4>拥有的权限 ({{ permissionList.length }})</h4>
          <el-row :gutter="20">
            <el-col 
              :span="12" 
              v-for="permission in permissionList" 
              :key="permission.permissionId"
              style="margin-bottom: 10px;">
              <el-card shadow="hover" class="permission-card">
                <div class="permission-item">
                  <el-icon color="#409EFF" :size="20"><Key /></el-icon>
                  <div class="permission-info">
                    <div class="permission-name">{{ permission.permissionName }}</div>
                    <div class="permission-desc">{{ permission.description }}</div>
                  </div>
                </div>
              </el-card>
            </el-col>
          </el-row>
          <el-empty v-if="permissionList.length === 0" description="该管理员暂无权限" />
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Plus, Edit, View, Switch, Key } from '@element-plus/icons-vue';
import request from '@/utils/request';

// 数据
const loading = ref(false);
const submitting = ref(false);
const adminList = ref([]);
const roleList = ref([]);
const permissionList = ref([]);
const currentAdmin = ref(null);

// 搜索表单
const searchForm = reactive({
  username: '',
  fullName: '',
  status: ''
});

// 分页
const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
});

// 对话框
const dialogVisible = ref(false);
const permissionDialogVisible = ref(false);
const isEdit = ref(false);
const formRef = ref(null);

// 表单
const form = reactive({
  adminId: null,
  username: '',
  fullName: '',
  password: '',
  confirmPassword: '',
  roleIds: [],
  status: 'active'
});

// 表单验证规则
const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 50, message: '用户名长度在 3 到 50 个字符', trigger: 'blur' }
  ],
  fullName: [
    { required: true, message: '请输入姓名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度至少 6 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    { 
      validator: (rule, value, callback) => {
        if (value !== form.password) {
          callback(new Error('两次输入密码不一致'));
        } else {
          callback();
        }
      }, 
      trigger: 'blur' 
    }
  ],
  roleIds: [
    { required: true, message: '请至少选择一个角色', trigger: 'change' }
  ],
  status: [
    { required: true, message: '请选择状态', trigger: 'change' }
  ]
};

// 计算属性
const dialogTitle = computed(() => isEdit.value ? '编辑管理员' : '添加管理员');

// 方法
const fetchAdminList = async () => {
  loading.value = true;
  try {
    const params = {
      page: pagination.page,
      size: pagination.size,
      ...searchForm
    };
    
    const res = await request.get('/api/admin/list', { params });
    
    if (res.code === '200') {
      adminList.value = res.data.records || res.data;
      pagination.total = res.data.total || adminList.value.length;
    }
  } catch (error) {
    ElMessage.error('获取管理员列表失败');
  } finally {
    loading.value = false;
  }
};

const fetchRoleList = async () => {
  try {
    const res = await request.get('/api/role/list');
    if (res.code === '200') {
      roleList.value = res.data;
    }
  } catch (error) {
    ElMessage.error('获取角色列表失败');
  }
};

const handleSearch = () => {
  pagination.page = 1;
  fetchAdminList();
};

const handleReset = () => {
  searchForm.username = '';
  searchForm.fullName = '';
  searchForm.status = '';
  handleSearch();
};

const handleAdd = () => {
  isEdit.value = false;
  resetForm();
  dialogVisible.value = true;
};

const handleEdit = (row) => {
  isEdit.value = true;
  form.adminId = row.adminId;
  form.username = row.username;
  form.fullName = row.fullName;
  form.roleIds = row.roles?.map(r => r.roleId) || [];
  form.status = row.status;
  dialogVisible.value = true;
};

const handleSubmit = async () => {
  if (!formRef.value) return;
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return;
    
    submitting.value = true;
    try {
      const data = {
        username: form.username,
        fullName: form.fullName,
        roleIds: form.roleIds,
        status: form.status // 保持小写：active 或 inactive
      };
      
      if (!isEdit.value) {
        data.password = form.password;
      }
      
      const url = isEdit.value ? `/api/admin/${form.adminId}` : '/api/admin';
      const method = isEdit.value ? 'put' : 'post';
      
      console.log('提交数据:', data);
      
      const res = await request[method](url, data);
      
      if (res.code === '200') {
        ElMessage.success(isEdit.value ? '编辑成功' : '添加成功');
        dialogVisible.value = false;
        fetchAdminList();
      } else {
        ElMessage.error(res.msg || '操作失败');
      }
    } catch (error) {
      console.error('提交失败:', error);
      const errorMsg = error.response?.data?.msg || error.message || '操作失败';
      ElMessage.error(errorMsg);
    } finally {
      submitting.value = false;
    }
  });
};

const handleToggleStatus = async (row) => {
  const action = row.status === 'active' ? '禁用' : '启用';
  const newStatus = row.status === 'active' ? 'inactive' : 'active'; // 使用小写枚举值
  
  try {
    await ElMessageBox.confirm(
      `确定要${action}管理员 "${row.fullName}" 吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    );
    
    const res = await request.put(`/api/admin/${row.adminId}`, {
      fullName: row.fullName,
      status: newStatus,
      roleIds: row.roles?.map(r => r.roleId) || []
    });
    
    if (res.code === '200') {
      ElMessage.success(`${action}成功`);
      fetchAdminList();
    } else {
      ElMessage.error(res.msg || `${action}失败`);
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(`${action}失败`);
    }
  }
};

const handleViewPermissions = (row) => {
  currentAdmin.value = row;
  permissionDialogVisible.value = true;
  
  // 从角色中提取所有权限并去重
  const permissionMap = new Map();
  if (row.roles && row.roles.length > 0) {
    row.roles.forEach(role => {
      if (role.permissions && role.permissions.length > 0) {
        role.permissions.forEach(permission => {
          if (!permissionMap.has(permission.permissionId)) {
            permissionMap.set(permission.permissionId, permission);
          }
        });
      }
    });
  }
  
  permissionList.value = Array.from(permissionMap.values());
  console.log('权限列表:', permissionList.value);
};

const handleDialogClose = () => {
  resetForm();
  if (formRef.value) {
    formRef.value.resetFields();
  }
};

const resetForm = () => {
  form.adminId = null;
  form.username = '';
  form.fullName = '';
  form.password = '';
  form.confirmPassword = '';
  form.roleIds = [];
  form.status = 'active';
};

const handleSizeChange = (size) => {
  pagination.size = size;
  fetchAdminList();
};

const handlePageChange = (page) => {
  pagination.page = page;
  fetchAdminList();
};

// 工具方法
const getRoleTagType = (roleName) => {
  const typeMap = {
    'super_admin': 'danger',
    'medical_admin': 'primary',
    'financial_admin': 'warning',
    'patient_admin': 'success',
    'system_operator': 'info'
  };
  return typeMap[roleName] || '';
};

const getRoleDisplayName = (roleName) => {
  const nameMap = {
    'super_admin': '超级管理员',
    'medical_admin': '医务管理员',
    'financial_admin': '财务管理员',
    'patient_admin': '患者管理员',
    'system_operator': '系统操作员'
  };
  return nameMap[roleName] || roleName;
};

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-';
  return new Date(dateTime).toLocaleString('zh-CN');
};

// 生命周期
onMounted(() => {
  fetchAdminList();
  fetchRoleList();
});
</script>

<style scoped>
.admin-management {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  font-size: 24px;
  color: #303133;
}

.search-card {
  margin-bottom: 20px;
}

.table-card {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.permission-detail {
  padding: 10px;
}

.admin-info h3 {
  margin: 0 0 10px 0;
  color: #303133;
}

.roles {
  margin-top: 10px;
}

.permissions-list h4 {
  margin: 10px 0;
  color: #606266;
}

.permission-card {
  height: 100%;
}

.permission-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.permission-info {
  flex: 1;
}

.permission-name {
  font-weight: bold;
  color: #303133;
  margin-bottom: 4px;
}

.permission-desc {
  font-size: 12px;
  color: #909399;
}
</style>
