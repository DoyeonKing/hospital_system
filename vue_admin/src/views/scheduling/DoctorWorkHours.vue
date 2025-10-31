<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>

    <el-card shadow="always">
      <template #header>
        <div class="card-header-title">
          <span>医生工时统计</span>
          <div>
            <el-button :loading="loading" type="primary" @click="loadAndCompute">查询</el-button>
            <el-button @click="exportCsv" :disabled="!rows.length">导出 CSV</el-button>
          </div>
        </div>
      </template>

      <el-form :inline="true" :model="filters" class="search-form">
        <el-form-item label="日期范围">
          <el-date-picker
            v-model="filters.dateRange"
            type="daterange"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            range-separator="至"
            :unlink-panels="true"
          />
        </el-form-item>

        <el-form-item label="上级科室">
          <el-select v-model="filters.parentDeptId" placeholder="选择上级科室" style="width: 220px" @change="onParentChange">
            <el-option v-for="pd in parentDepartments" :key="pd.value" :label="pd.label" :value="pd.value" />
          </el-select>
        </el-form-item>

        <el-form-item label="科室">
          <el-select v-model="filters.deptId" placeholder="选择科室" style="width: 220px" @change="onDeptChange">
            <el-option v-for="d in subDepartments" :key="d.value" :label="d.label" :value="d.value" />
          </el-select>
        </el-form-item>

        <el-form-item label="医生">
          <el-select v-model="filters.doctorId" placeholder="全部医生" clearable filterable style="width: 220px">
            <el-option v-for="doc in doctors" :key="doc.value" :label="doc.label" :value="doc.value" />
          </el-select>
        </el-form-item>

        <el-form-item label="汇总维度">
          <el-select v-model="filters.groupBy" style="width: 160px">
            <el-option label="按医生" value="doctor" />
            <el-option label="按医生+日期" value="doctor_date" />
          </el-select>
        </el-form-item>
      </el-form>

      <el-table :data="rows" v-loading="loading" border style="width: 100%; margin-top: 8px;">
        <el-table-column prop="doctorName" label="医生" min-width="140" />
        <el-table-column prop="date" label="日期" min-width="120" v-if="filters.groupBy === 'doctor_date'" />
        <el-table-column prop="sessions" label="出诊次数" width="110" />
        <el-table-column prop="hours" label="工时(小时)" width="120" />
        <el-table-column prop="locations" label="地点" min-width="160" />
      </el-table>

      <div class="stats-bar" v-if="rows.length" style="margin-top: 12px; display: flex; gap: 16px; color: #606266;">
        <div>统计医生数：{{ statDistinctDoctors }}</div>
        <div>总出诊次数：{{ statTotalSessions }}</div>
        <div>总工时：{{ statTotalHours }} 小时</div>
      </div>
    </el-card>
  </div>
  
</template>

<script setup>
import BackButton from '@/components/BackButton.vue';
import { ref, computed, onMounted } from 'vue';
import { ElMessage } from 'element-plus';
import { getAllParentDepartments, getDepartmentsByParentId, getDoctorsByDepartmentId } from '@/api/department';
import { getSchedules } from '@/api/schedule';
import { getDoctorHours } from '@/api/report';

const loading = ref(false);

const parentDepartments = ref([]); // [{ label, value }]
const subDepartments = ref([]); // [{ label, value }]
const doctors = ref([]); // [{ label, value }]

const filters = ref({
  dateRange: [],
  parentDeptId: null,
  deptId: null,
  doctorId: null,
  groupBy: 'doctor',
});

const rows = ref([]);

const HOURS_PER_SESSION = 4; // 上午/下午默认各4小时，如需调整请改此值

const formatDate = (d) => d;

const onParentChange = async () => {
  filters.value.deptId = null;
  subDepartments.value = [];
  doctors.value = [];
  if (!filters.value.parentDeptId) return;
  try {
    const children = await getDepartmentsByParentId(filters.value.parentDeptId);
    subDepartments.value = Array.isArray(children)
      ? children.map(c => ({
          label: c.name || c.label || '',
          value: c.departmentId ?? c.id ?? c.value,
        })).filter(c => c.value != null)
      : [];
  } catch (e) {
    ElMessage.error('加载子科室失败');
  }
};

const onDeptChange = async () => {
  filters.value.doctorId = null;
  doctors.value = [];
  if (!filters.value.deptId) return;
  try {
    const list = await getDoctorsByDepartmentId(filters.value.deptId);
    doctors.value = Array.isArray(list)
      ? list.map(d => ({
          label: d.fullName || d.name || d.label || d.identifier || '',
          value: d.doctorId ?? d.id ?? d.value ?? d.identifier,
        })).filter(d => d.value != null)
      : [];
  } catch (e) {
    ElMessage.error('加载医生列表失败');
  }
};

const statDistinctDoctors = computed(() => new Set(rows.value.map(r => r.doctorId)).size);
const statTotalSessions = computed(() => rows.value.reduce((s, r) => s + (r.sessions || 0), 0));
const statTotalHours = computed(() => rows.value.reduce((s, r) => s + (r.hours || 0), 0));

const loadAndCompute = async () => {
  if (!filters.value.dateRange || filters.value.dateRange.length !== 2) {
    ElMessage.warning('请选择日期范围');
    return;
  }
  if (!filters.value.deptId) {
    ElMessage.warning('请选择科室');
    return;
  }

  loading.value = true;
  try {
    const [startDate, endDate] = filters.value.dateRange;
    // 优先调用后端聚合接口
    try {
      const backend = await getDoctorHours({
        departmentId: filters.value.deptId,
        startDate,
        endDate,
        doctorId: filters.value.doctorId || undefined,
        groupBy: filters.value.groupBy,
      });
      if (Array.isArray(backend)) {
        rows.value = backend.map(x => ({
          doctorId: x.doctorId,
          doctorName: x.doctorName,
          date: x.date || '',
          sessions: x.sessions || 0,
          hours: Number(x.hours ?? 0),
          locations: x.locations || ''
        }));
        return; // 成功使用后端数据
      }
    } catch (_) {
      // 后端接口不可用时回退到前端本地汇总
    }

    // 回退方案：前端本地汇总
    const params = { departmentId: filters.value.deptId, startDate, endDate, page: 0, size: 1000 };
    const resp = await getSchedules(params);
    const data = Array.isArray(resp?.content) ? resp.content : (Array.isArray(resp) ? resp : []);

    const filtered = filters.value.doctorId
      ? data.filter(x => String(x.doctorId) === String(filters.value.doctorId))
      : data;

    const map = new Map();
    for (const item of filtered) {
      const key = filters.value.groupBy === 'doctor_date'
        ? `${item.doctorId}|${item.doctorName}|${item.scheduleDate}`
        : `${item.doctorId}|${item.doctorName}`;

      if (!map.has(key)) {
        map.set(key, { doctorId: item.doctorId, doctorName: item.doctorName, date: filters.value.groupBy === 'doctor_date' ? item.scheduleDate : '', sessions: 0, hours: 0, locationsSet: new Set() });
      }
      const rec = map.get(key);
      rec.sessions += 1;
      rec.hours += HOURS_PER_SESSION;
      if (item.location) rec.locationsSet.add(item.location);
    }

    rows.value = Array.from(map.values()).map(r => ({ doctorId: r.doctorId, doctorName: r.doctorName, date: r.date, sessions: r.sessions, hours: r.hours, locations: Array.from(r.locationsSet).join('、') }));
  } catch (e) {
    ElMessage.error('加载或计算工时失败');
  } finally {
    loading.value = false;
  }
};

const exportCsv = () => {
  if (!rows.value.length) return;
  const headers = ['医生', '日期', '出诊次数', '工时(小时)', '地点'];
  const dataLines = rows.value.map(r => [
    wrapCsv(r.doctorName),
    wrapCsv(r.date || ''),
    String(r.sessions || 0),
    String(r.hours || 0),
    wrapCsv(r.locations || ''),
  ].join(','));
  const csv = [headers.join(','), ...dataLines].join('\n');
  const blob = new Blob(["\uFEFF" + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `医生工时统计-${Date.now()}.csv`;
  a.click();
  URL.revokeObjectURL(url);
};

const wrapCsv = (text) => {
  if (text == null) return '';
  const s = String(text).replaceAll('"', '""');
  if (/,|\n|\r|"/.test(s)) return `"${s}"`;
  return s;
};

onMounted(async () => {
  try {
    const parents = await getAllParentDepartments();
    parentDepartments.value = Array.isArray(parents)
      ? parents.map(p => ({
          label: p.name || p.label || '',
          value: p.parentDepartmentId ?? p.id ?? p.value,
        })).filter(p => p.value != null)
      : [];
  } catch (e) {
    // 忽略
  }
});
</script>

<style scoped>
.app-container { padding: 16px; }
.card-header-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.search-form { margin-bottom: 8px; }
</style>


