<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <el-card shadow="always">
      <template #header>
        <div class="card-header-title">
          <span>科室信息总览与管理 (层级视图)</span>
          <el-button type="success" :icon="Plus" @click="handleCreateDepartment">
            创建新科室
          </el-button>
        </div>
      </template>

      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="科室名称">
          <el-input
              v-model="searchForm.name"
              placeholder="按科室名称搜索"
              clearable
          />
        </el-form-item>
        <el-form-item label="职能描述">
          <el-input
              v-model="searchForm.description"
              placeholder="按职能描述搜索"
              clearable
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">搜索</el-button>
          <el-button :icon="Refresh" @click="resetSearch">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table
          :data="pagedDepartments"
          border
          style="width: 100%; margin-top: 15px;"
          row-key="departmentId"
          :tree-props="{ children: 'children' }"
          @sort-change="handleSortChange"
      >
        <el-table-column prop="name" label="科室名称" width="220" sortable="custom" />
        <el-table-column prop="departmentId" label="科室编号" width="120" sortable="custom" />
        <el-table-column prop="description" label="职能描述" />

        <el-table-column label="操作" width="320" fixed="right" align="center">
          <template #default="{ row }">
            <el-button size="small" :icon="View" @click="handleViewDetails(row)">
              查看成员
            </el-button>
            <el-button size="small" type="primary" :icon="Edit" @click="handleEdit(row)">
              编辑
            </el-button>
            <el-button size="small" type="danger" :icon="Delete" @click="handleDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-area">
        <el-pagination
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
            :current-page="currentPage"
            :page-sizes="[5, 10, 20, 50]"
            :page-size="pageSize"
            layout="total, sizes, prev, pager, next, jumper"
            :total="rootDepartmentCount"
        />
      </div>
    </el-card>

    <el-dialog v-model="editDialogVisible" title="编辑科室信息" width="500">
      <el-form :model="currentEditDepartment" label-width="100px">
        <el-form-item label="科室名称">
          <el-input v-model="currentEditDepartment.name" />
        </el-form-item>
        <el-form-item label="科室描述">
          <el-input v-model="currentEditDepartment.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="editDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitEdit">
            确认修改
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Edit, Delete, View, Search, Refresh, Plus } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
import { useRouter } from 'vue-router';

// 1. 导入 API 服务
import { getDepartmentPage } from '@/api/department';

const router = useRouter();

// --- 数据状态 ---
const allDepartments = ref([]); // 存放当前页的科室数据 (可能已转换成树形)
const totalElements = ref(0); // 后端返回的总记录数，用于分页组件
const loading = ref(false); // 数据加载状态

// --- 搜索和排序状态 ---
const searchForm = reactive({
  name: '',
  description: ''
});
const sortBy = ref(null);
const sortOrder = ref(null); // 'ascending' / 'descending'

// --- 分页状态 ---
const currentPage = ref(1);
const pageSize = ref(10);


// 2. 核心方法：从后端获取数据
const fetchDepartments = async () => {
    loading.value = true;
    try {
        // 构造查询对象 (与后端 queryDTO 对应)
        const queryParams = {
            name: searchForm.name,
            description: searchForm.description,
            page: currentPage.value, // 传给 API service 处理页码减一
            size: pageSize.value,
            sortBy: sortBy.value,
            sortOrder: sortOrder.value, // 传给 API service 处理 ASC/DESC 转换
        };

        // 调用后端 API
        const response = await getDepartmentPage(queryParams);

        // 【🚨 检查原始数据】
        console.log('--- 调试日志 start ---');
        console.log('1. API 原始返回的 Content:', response.content);

        // 处理后端返回的分页数据 (PageDepartmentResponseDTO)
        // 1. 更新总记录数
        totalElements.value = response.totalElements || 0;

        // 【最终保障：在 buildTree 之前进行深拷贝，以确保数据纯净】
        const safeContent = JSON.parse(JSON.stringify(response.content || []));

        // 2. 将当前页的扁平列表转换为树形结构
        allDepartments.value = buildTree(safeContent);

        // 【🚨 检查最终渲染数据】
        console.log('2. 最终用于渲染表格的数据 (allDepartments):', allDepartments.value);
        console.log('--- 调试日志 end ---');

    } catch (error) {
        // request.js 已经处理了大部分错误提示，这里做最终处理
        allDepartments.value = [];
        totalElements.value = 0;
        // 如果 request.js 没有完全阻止 Promise.reject，可以在这里捕获并提示
        if (!error.message.includes('Error')) { // 避免重复提示
            // ElMessage.error('获取科室信息失败');
        }
    } finally {
        loading.value = false;
    }
};


// 3. 辅助函数：将扁平列表转换为树形结构
const buildTree = (list) => {
    // 处于搜索模式时，后端返回的列表就是过滤后的，无需进行树形转换，直接返回
    if (searchForm.name.trim() || searchForm.description.trim()) {
        // ⚠️ 暂时返回扁平列表，让表格显示为多行（非折叠的树结构）
        return list;
    }

    const map = {};
    const tree = [];

    // 第一次遍历：将所有部门放入 map，并初始化 children 数组
    list.forEach(dept => {
      // ⚠️ map[id] 处的 { ...dept } 是浅拷贝，如果 dept 的属性值是对象，则仍是引用。
      // 但由于上层已经进行了深拷贝，这里的风险已降到最低。
      map[dept.departmentId] = { ...dept, children: [] };
    });

    // 第二次遍历：构建树
    list.forEach(dept => {
      const node = map[dept.departmentId];
      // 确保这里使用的字段名 (parentDepartmentId) 与后端返回的字段名一致！
      if (dept.parentDepartmentId && map[dept.parentDepartmentId]) {
        map[dept.parentDepartmentId].children.push(node);
      } else if (!dept.parentDepartmentId) { // 根节点
        tree.push(node);
      }
    });

    return tree;
};


// 4. 核心计算属性
const pagedDepartments = computed(() => {
  // allDepartments.value 已经是经过分页和树形转换的当前页数据
  return allDepartments.value;
});

const rootDepartmentCount = computed(() => {
    // 总数直接使用后端返回的 totalElements
    return totalElements.value;
});


// 5. 生命周期和事件处理
onMounted(() => {
    fetchDepartments();
});

const handleCreateDepartment = () => {
    router.push({ path: '/departments/create' });
}

const handleSearch = () => {
  currentPage.value = 1; // 搜索从第一页开始
  fetchDepartments();    // 触发 API 请求
};

const resetSearch = () => {
  searchForm.name = '';
  searchForm.description = '';
  currentPage.value = 1; // 重置从第一页开始
  fetchDepartments();    // 触发 API 请求
};

const handleSortChange = ({ prop, order }) => {
    sortBy.value = prop;
    sortOrder.value = order;
    currentPage.value = 1; // 排序变化，重置回第一页
    fetchDepartments();    // 触发 API 请求
};

const handleSizeChange = (val) => {
  pageSize.value = val;
  currentPage.value = 1; // 每页大小变化，重置回第一页
  fetchDepartments();    // 触发 API 请求
};

const handleCurrentChange = (val) => {
  currentPage.value = val;
  fetchDepartments();    // 触发 API 请求
};


// 6. 编辑、删除逻辑（需要改成调用后端 API，这里只做刷新处理）
const editDialogVisible = ref(false);
const currentEditDepartment = reactive({ departmentId: null, name: '', description: '' });

const handleEdit = (row) => {
  Object.assign(currentEditDepartment, row);
  editDialogVisible.value = true;
};

const submitEdit = async () => {
  try {
    // ⚠️ 实际逻辑：在这里调用后端更新 API (例如：await updateDepartment(currentEditDepartment);)
    // 假设更新成功：

    editDialogVisible.value = false;
    ElMessage.success('科室信息更新成功！');
    fetchDepartments(); // 刷新列表
  } catch (error) {
    ElMessage.error('更新失败，请检查后端服务。');
  }
};

const handleDelete = (row) => {
  ElMessageBox.confirm(
      `您确定要删除科室【${row.name}】吗？此操作不可逆！`,
      '危险操作警告',
      { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
  ).then(async () => {
    try {
      // ⚠️ 实际逻辑：在这里调用后端删除 API (例如：await deleteDepartment(row.id);)
      // 假设删除成功：

      ElMessage.success('删除成功！');
      fetchDepartments(); // 刷新列表
    } catch (error) {
      ElMessage.error('删除失败，请检查后端服务。');
    }
  });
};

const handleViewDetails = (row) => {
    router.push({ path: `/departments/members/${row.departmentId}` });
};
</script>

<style scoped>
/* 样式部分保持不变 */
.app-container {
  padding: 20px;
}
.card-header-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.card-header-title span {
  font-size: 18px;
  font-weight: bold;
}
.search-form {
  margin-bottom: 20px;
  padding: 10px;
  background-color: #f5f7fa;
  border-radius: 4px;
}
.pagination-area {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
</style>