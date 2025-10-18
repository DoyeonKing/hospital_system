<template>
  <div class="regulations-management">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <el-card shadow="always" v-loading="loading">
      <template #header>
        <div class="card-header">
          <span>就医规范管理</span>
          <el-button type="primary" :icon="Plus" @click="handleCreate">新增规范</el-button>
        </div>
      </template>

      <!-- 搜索筛选 -->
      <div class="search-bar">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索规范标题或内容"
          :prefix-icon="Search"
          style="width: 300px; margin-right: 15px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="filterCategory"
          placeholder="选择分类"
          style="width: 200px; margin-right: 15px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="全部分类" value="" />
          <el-option
            v-for="cat in categories"
            :key="cat"
            :label="cat"
            :value="cat"
          />
        </el-select>
        <el-select
          v-model="filterStatus"
          placeholder="选择状态"
          style="width: 150px; margin-right: 15px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="全部状态" value="" />
          <el-option label="启用" value="active" />
          <el-option label="禁用" value="inactive" />
        </el-select>
        <el-button type="primary" :icon="Search" @click="handleSearch">搜索</el-button>
        <el-button :icon="Refresh" @click="handleReset">重置</el-button>
      </div>

      <!-- 规范列表 -->
      <el-table :data="filteredRegulations" border stripe style="margin-top: 20px;">
        <el-table-column prop="title" label="规范标题" min-width="200" />
        <el-table-column prop="category" label="分类" width="150">
          <template #default="{ row }">
            <el-tag :type="getCategoryTagType(row.category)">
              {{ row.category }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="内容摘要" min-width="300" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
              {{ row.status === 'active' ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdByName" label="创建人" width="120" />
        <el-table-column prop="createdAt" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" :icon="View" @click="handleView(row)" link>
              查看
            </el-button>
            <el-button type="primary" size="small" :icon="Edit" @click="handleEdit(row)" link>
              编辑
            </el-button>
            <el-button
              :type="row.status === 'active' ? 'warning' : 'success'"
              size="small"
              @click="toggleStatus(row)"
              link
            >
              {{ row.status === 'active' ? '禁用' : '启用' }}
            </el-button>
            <el-button type="danger" size="small" :icon="Delete" @click="handleDelete(row)" link>
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="totalRegulations"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 查看规范对话框 -->
    <el-dialog
      v-model="viewDialogVisible"
      :title="currentRegulation.title"
      width="700px"
    >
      <div class="regulation-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="分类">
            <el-tag :type="getCategoryTagType(currentRegulation.category)">
              {{ currentRegulation.category }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentRegulation.status === 'active' ? 'success' : 'info'">
              {{ currentRegulation.status === 'active' ? '启用' : '禁用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建人">
            {{ currentRegulation.createdByName }}
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">
            {{ formatDate(currentRegulation.createdAt) }}
          </el-descriptions-item>
          <el-descriptions-item label="更新时间" :span="2">
            {{ formatDate(currentRegulation.updatedAt) }}
          </el-descriptions-item>
        </el-descriptions>

        <el-divider>规范内容</el-divider>
        <div class="regulation-content" v-html="currentRegulation.content"></div>
      </div>
      <template #footer>
        <el-button @click="viewDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="handleEditFromView">编辑</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { Plus, Search, Refresh, Edit, Delete, View } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import BackButton from '@/components/BackButton.vue';
// import { getGuidelines, deleteGuideline, updateGuideline } from '@/api/guideline'; // 等后端接口完成后启用

const router = useRouter();

// --- 数据 ---
// 模拟数据（等后端接口完成后删除）
const regulations = ref([
  {
    guidelineId: 1,
    title: '挂号就诊流程',
    category: '就医流程',
    content: '<h3>挂号流程</h3><p>1. 选择科室和医生</p><p>2. 选择就诊时间</p><p>3. 填写就诊人信息</p><p>4. 支付挂号费</p><p>5. 等待就诊</p>',
    status: 'active',
    createdBy: 1,
    createdByName: '系统管理员',
    createdAt: '2025-10-15 10:30:00',
    updatedAt: '2025-10-15 10:30:00'
  },
  {
    guidelineId: 2,
    title: '退号规则说明',
    category: '退号政策',
    content: '<h3>退号规则</h3><p>1. 就诊当天不能退号</p><p>2. 线上支付不退款</p><p>3. 超过三次不签到将进入黑名单</p>',
    status: 'active',
    createdBy: 1,
    createdByName: '系统管理员',
    createdAt: '2025-10-14 14:20:00',
    updatedAt: '2025-10-14 14:20:00'
  },
  {
    guidelineId: 3,
    title: '患者签到须知',
    category: '就医须知',
    content: '<h3>签到须知</h3><p>1. 患者需提前15分钟到达医院</p><p>2. 通过扫码完成签到</p><p>3. 签到后请在候诊区等待</p>',
    status: 'active',
    createdBy: 2,
    createdByName: '王医生',
    createdAt: '2025-10-13 09:15:00',
    updatedAt: '2025-10-16 16:00:00'
  },
  {
    guidelineId: 4,
    title: '就诊注意事项（已废弃）',
    category: '就医须知',
    content: '<h3>注意事项</h3><p>旧版本，已停用</p>',
    status: 'inactive',
    createdBy: 3,
    createdByName: '李医生',
    createdAt: '2025-09-20 11:00:00',
    updatedAt: '2025-10-10 10:00:00'
  },
]);

const loading = ref(false);

const categories = ref([
  '就医流程',
  '就医须知',
  '退号政策',
  '支付说明',
  '候补规则',
  '其他'
]);

// --- 搜索筛选 ---
const searchKeyword = ref('');
const filterCategory = ref('');
const filterStatus = ref('');

// --- 分页 ---
const currentPage = ref(1);
const pageSize = ref(10);

// --- 对话框 ---
const viewDialogVisible = ref(false);
const currentRegulation = ref({});

// --- 计算属性 ---
const filteredRegulations = computed(() => {
  let result = regulations.value;

  // 关键词搜索
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase();
    result = result.filter(reg =>
      reg.title.toLowerCase().includes(keyword) ||
      reg.content.toLowerCase().includes(keyword)
    );
  }

  // 分类筛选
  if (filterCategory.value) {
    result = result.filter(reg => reg.category === filterCategory.value);
  }

  // 状态筛选
  if (filterStatus.value) {
    result = result.filter(reg => reg.status === filterStatus.value);
  }

  return result;
});

const totalRegulations = computed(() => filteredRegulations.value.length);

// --- 方法 ---

// 【暂时注释】等后端接口完成后启用
// /**
//  * 加载规范列表（后端分页）
//  */
// const loadGuidelines = async () => {
//   loading.value = true;
//   try {
//     const response = await getGuidelines({
//       page: currentPage.value,
//       pageSize: pageSize.value,
//       keyword: searchKeyword.value,
//       category: filterCategory.value,
//       status: filterStatus.value
//     });
//     
//     // Spring Boot 分页响应格式
//     regulations.value = response.data.content || [];
//     totalRegulations.value = response.data.totalElements || 0;
//     
//   } catch (error) {
//     ElMessage.error('加载规范列表失败：' + (error.message || '未知错误'));
//     regulations.value = [];
//     totalRegulations.value = 0;
//   } finally {
//     loading.value = false;
//   }
// };

const formatDate = (dateStr) => {
  if (!dateStr) return '';
  return dateStr;
};

const getCategoryTagType = (category) => {
  const types = {
    '就医流程': 'primary',
    '就医须知': 'success',
    '退号政策': 'warning',
    '支付说明': 'info',
    '候补规则': 'danger',
    '其他': ''
  };
  return types[category] || '';
};

const handleCreate = () => {
  router.push('/regulations/create');
};

const handleEdit = (row) => {
  router.push(`/regulations/edit/${row.guidelineId}`);
};

const handleView = (row) => {
  currentRegulation.value = { ...row };
  viewDialogVisible.value = true;
};

const handleEditFromView = () => {
  viewDialogVisible.value = false;
  handleEdit(currentRegulation.value);
};

const toggleStatus = (row) => {
  const action = row.status === 'active' ? '禁用' : '启用';
  ElMessageBox.confirm(
    `确定要${action}规范"${row.title}"吗？`,
    '确认操作',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    // 【模拟操作】等后端接口完成后替换为真实API调用
    row.status = row.status === 'active' ? 'inactive' : 'active';
    ElMessage.success(`${action}成功`);
    
    // 【后端接口完成后启用】
    // const newStatus = row.status === 'active' ? 'inactive' : 'active';
    // await updateGuideline(row.guidelineId, {
    //   title: row.title,
    //   content: row.content,
    //   category: row.category,
    //   status: newStatus
    // });
    // ElMessage.success(`${action}成功`);
    // loadGuidelines(); // 重新加载列表
  }).catch(() => {});
};

const handleDelete = (row) => {
  ElMessageBox.confirm(
    `确定要删除规范"${row.title}"吗？删除后不可恢复！`,
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'error',
    }
  ).then(() => {
    // 【模拟删除】等后端接口完成后替换为真实API调用
    const index = regulations.value.findIndex(r => r.guidelineId === row.guidelineId);
    if (index !== -1) {
      regulations.value.splice(index, 1);
      ElMessage.success('删除成功');
    }
    
    // 【后端接口完成后启用】
    // await deleteGuideline(row.guidelineId);
    // ElMessage.success('删除成功');
    // if (regulations.value.length === 1 && currentPage.value > 1) {
    //   currentPage.value--;
    // }
    // loadGuidelines(); // 重新加载列表
  }).catch(() => {});
};

const handleSearch = () => {
  currentPage.value = 1; // 搜索时重置到第一页
  // loadGuidelines();    // 【后端接口完成后启用】
};

const handleReset = () => {
  searchKeyword.value = '';
  filterCategory.value = '';
  filterStatus.value = '';
  currentPage.value = 1;
  // loadGuidelines();    // 【后端接口完成后启用】
};

const handleSizeChange = () => {
  currentPage.value = 1;
  // loadGuidelines();    // 【后端接口完成后启用】
};

const handleCurrentChange = () => {
  // loadGuidelines();    // 【后端接口完成后启用】
};

onMounted(() => {
  // loadGuidelines();    // 【后端接口完成后启用】初始化时加载数据
});
</script>

<style scoped>
.regulations-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}

.search-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

.regulation-detail {
  max-height: 600px;
  overflow-y: auto;
}

.regulation-content {
  padding: 15px;
  background-color: #f9fafb;
  border-radius: 8px;
  min-height: 200px;
  line-height: 1.8;
}

.regulation-content h3 {
  color: #303133;
  margin-bottom: 15px;
}

.regulation-content p {
  margin-bottom: 10px;
  color: #606266;
}
</style>

