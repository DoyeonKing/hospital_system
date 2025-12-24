<template>
  <div class="permission-manage-container">
    <!-- 页面标题 -->
    <el-card class="header-card">
      <div class="card-header">
        <span class="title">权限管理</span>
        <el-button type="primary" @click="handleAdd" :icon="Plus">新增权限</el-button>
      </div>
    </el-card>

    <!-- 权限列表 -->
    <el-card style="margin-top: 20px">
      <el-table :data="permissionList" style="width: 100%" v-loading="loading" border stripe>
        <el-table-column prop="permissionId" label="权限ID" width="100" />
        <el-table-column prop="permissionName" label="权限名称" width="200" />
        <el-table-column prop="description" label="权限描述" show-overflow-tooltip />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button type="primary" size="small" @click="handleEdit(scope.row)" :icon="Edit">
              编辑
            </el-button>
            <el-button type="danger" size="small" @click="handleDelete(scope.row)" :icon="Delete">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      @close="handleDialogClose"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px">
        <el-form-item label="权限名称" prop="permissionName">
          <el-input
            v-model="form.permissionName"
            placeholder="请输入权限名称（如：user_manage）"
            :disabled="isEdit"
          />
        </el-form-item>
        <el-form-item label="权限描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入权限描述"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitLoading">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import request from '@/utils/request'

// 权限列表
const permissionList = ref([])
const loading = ref(false)

// 对话框
const dialogVisible = ref(false)
const dialogTitle = ref('新增权限')
const isEdit = ref(false)
const submitLoading = ref(false)

// 表单
const formRef = ref(null)
const form = reactive({
  permissionId: null,
  permissionName: '',
  description: ''
})

// 表单验证规则
const rules = {
  permissionName: [
    { required: true, message: '请输入权限名称', trigger: 'blur' },
    { min: 2, max: 100, message: '长度在 2 到 100 个字符', trigger: 'blur' }
  ],
  description: [
    { required: true, message: '请输入权限描述', trigger: 'blur' }
  ]
}

// 获取权限列表
const fetchPermissions = async () => {
  loading.value = true
  try {
    const response = await request.get('/api/permissions/list')
    if (response.code === '200') {
      permissionList.value = response.data
    } else {
      ElMessage.error(response.msg || '获取权限列表失败')
    }
  } catch (error) {
    console.error('Failed to fetch permissions:', error)
    ElMessage.error('获取权限列表失败')
  } finally {
    loading.value = false
  }
}

// 新增权限
const handleAdd = () => {
  isEdit.value = false
  dialogTitle.value = '新增权限'
  resetForm()
  dialogVisible.value = true
}

// 编辑权限
const handleEdit = (row) => {
  isEdit.value = true
  dialogTitle.value = '编辑权限'
  form.permissionId = row.permissionId
  form.permissionName = row.permissionName
  form.description = row.description
  dialogVisible.value = true
}

// 删除权限
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除权限 "${row.permissionName}" 吗？此操作不可恢复！`,
      '警告',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    const response = await request.delete(`/api/permissions/${row.permissionId}`)
    if (response.code === '200') {
      ElMessage.success('删除成功')
      fetchPermissions()
    } else {
      ElMessage.error(response.msg || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to delete permission:', error)
      ElMessage.error('删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    submitLoading.value = true

    const data = {
      permissionName: form.permissionName,
      description: form.description
    }

    let response
    if (isEdit.value) {
      // 编辑
      response = await request.put(`/api/permissions/${form.permissionId}`, data)
    } else {
      // 新增
      response = await request.post('/api/permissions', data)
    }

    if (response.code === '200' || response.code === '201') {
      ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
      dialogVisible.value = false
      fetchPermissions()
    } else {
      ElMessage.error(response.msg || '操作失败')
    }
  } catch (error) {
    if (error !== false) { // 表单验证失败会返回false
      console.error('Failed to submit:', error)
      ElMessage.error('操作失败')
    }
  } finally {
    submitLoading.value = false
  }
}

// 重置表单
const resetForm = () => {
  form.permissionId = null
  form.permissionName = ''
  form.description = ''
  if (formRef.value) {
    formRef.value.clearValidate()
  }
}

// 对话框关闭
const handleDialogClose = () => {
  resetForm()
}

// 初始化
onMounted(() => {
  fetchPermissions()
})
</script>

<style scoped>
.permission-manage-container {
  padding: 20px;
}

.header-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
}
</style>







