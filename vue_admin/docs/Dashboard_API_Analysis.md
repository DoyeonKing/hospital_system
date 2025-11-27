# 数据大屏接口复用分析

## 概述

本文档分析数据大屏所需的数据，并评估哪些可以通过现有接口获取，哪些需要新增接口。

---

## 一、数据需求清单

### Tab 1: 运营总览
1. `todayAppointments` - 今日挂号量
2. `activeDoctorsToday` - 今日出诊医生数
3. `pendingPatients` - 当前候诊人数
4. `totalPatients` - 累计注册用户总数
5. `last7DaysDates/Counts` - 近7天挂号趋势
6. `paymentStatus` - 支付状态分布

### Tab 2: 医生资源分析
1. `totalDoctors` - 医生总数
2. `todayLeaveCount` - 今日请假人数
3. `totalDepartments` - 科室总数
4. `titleDistribution` - 职称分布
5. `departmentBusy` - 科室繁忙度 Top 5
6. `doctorWorkload` - 医生工作量 Top 5

### Tab 3: 患者群体画像
1. `monthlyNewRegistrations` - 本月新增注册
2. `studentTeacherRatio` - 师生比例系数
3. `totalNoShows` - 累计爽约次数
4. `last30DaysDates/Counts` - 近30天用户增长趋势
5. `patientType` - 患者类型构成
6. `timeSlotData` - 就诊时段热力图

---

## 二、现有接口分析

### 2.1 已存在的接口

| 接口路径 | 方法 | 功能 | 可复用性 |
|---------|------|------|---------|
| `/api/users/doctorInfo` | GET | 搜索医生（分页） | ⚠️ 部分可用 |
| `/api/users/patientInfo` | GET | 搜索患者（分页） | ⚠️ 部分可用 |
| `/api/departments` | GET | 获取科室列表（分页） | ⚠️ 部分可用 |
| `/api/schedules` | GET | 获取排班列表 | ⚠️ 部分可用 |
| `/api/reports/doctor-hours` | GET | 医生工时统计 | ✅ 可参考 |

### 2.2 缺失的接口

**预约相关统计接口** - 项目中只有预约的 CRUD 接口，没有统计接口：
- ❌ 没有获取所有预约的接口
- ❌ 没有按日期统计预约的接口
- ❌ 没有按状态统计预约的接口

**请假相关接口** - 项目中完全没有：
- ❌ 没有 `LeaveRequest` 相关的任何接口

---

## 三、详细复用分析

### 3.1 ✅ 可以复用（但建议新增）

#### 1. 科室总数 (`totalDepartments`)

**现有接口**:
```javascript
// GET /api/departments?page=0&size=1000
import { getAllDepartments } from '@/api/department'
```

**复用方式**:
```javascript
const response = await getAllDepartments()
const totalDepartments = response.data.content?.length || 0
```

**问题**:
- 需要传输所有科室数据到前端
- 前端需要计算总数
- 性能较差

**建议**: 新增统计接口，直接返回总数

---

#### 2. 医生总数和职称分布 (`totalDoctors`, `titleDistribution`)

**现有接口**:
```javascript
// GET /api/users/doctorInfo?page=1&pageSize=1000
import { searchDoctors } from '@/api/user'
```

**复用方式**:
```javascript
const response = await searchDoctors({ page: 1, pageSize: 1000 })
const doctors = response.data.content || []
const totalDoctors = doctors.length

// 前端需要自己按 title 分组
const titleDistribution = doctors.reduce((acc, doctor) => {
  const title = doctor.title || 'Unknown'
  acc[title] = (acc[title] || 0) + 1
  return acc
}, {})
```

**问题**:
- 需要传输所有医生数据
- 前端需要做复杂的聚合计算
- 如果医生数量很大，性能很差

**建议**: 新增统计接口，后端直接返回按职称分组的统计数据

---

#### 3. 患者总数和类型分布 (`totalPatients`, `patientType`)

**现有接口**:
```javascript
// GET /api/users/patientInfo?page=1
import { searchPatients } from '@/api/user'
```

**复用方式**:
```javascript
// 需要多次请求获取所有患者
let totalPatients = 0
let page = 1
let allPatients = []

while (true) {
  const response = await searchPatients({ page })
  const patients = response.data.content || []
  if (patients.length === 0) break
  allPatients.push(...patients)
  totalPatients += patients.length
  if (patients.length < 10) break // 每页固定10条
  page++
}

// 前端需要自己按 type 分组
const patientType = allPatients.reduce((acc, patient) => {
  const type = patient.type || 'Unknown'
  acc[type] = (acc[type] || 0) + 1
  return acc
}, {})
```

**问题**:
- 需要多次请求（分页）
- 需要传输所有患者数据
- 前端需要做复杂的聚合计算
- 性能极差

**建议**: 必须新增统计接口

---

#### 4. 科室繁忙度 (`departmentBusy`)

**现有接口**:
```javascript
// GET /api/schedules?startDate=xxx&endDate=xxx
import { getSchedules } from '@/api/schedule'
```

**复用方式**:
```javascript
// 获取所有排班数据
const response = await getSchedules({ 
  startDate: '2024-01-01', 
  endDate: '2024-12-31',
  size: 10000 
})
const schedules = response.data.content || []

// 前端需要按科室分组并计算 bookedAppointments 总和
const departmentBusy = schedules.reduce((acc, schedule) => {
  const deptName = schedule.departmentName
  if (!acc[deptName]) {
    acc[deptName] = 0
  }
  acc[deptName] += schedule.bookedAppointments || 0
  return acc
}, {})

// 排序并取前5
const top5 = Object.entries(departmentBusy)
  .map(([name, value]) => ({ name, value }))
  .sort((a, b) => b.value - a.value)
  .slice(0, 5)
```

**问题**:
- 需要传输大量排班数据
- 前端需要做复杂的聚合和排序
- 性能较差

**建议**: 新增统计接口，后端直接返回 Top 5

---

### 3.2 ❌ 无法复用（必须新增）

#### 1. 预约相关统计

**问题**: 项目中只有预约的 CRUD 接口，没有统计接口

**需要新增的接口**:
- 今日挂号量统计
- 当前候诊人数统计（状态为 WAITING）
- 近7天挂号趋势
- 支付状态分布
- 累计爽约次数
- 就诊时段热力图

**原因**: 
- 现有接口 `/api/appointments/patient/{id}` 只能获取单个患者的预约
- 没有获取所有预约的接口
- 没有按日期、状态、时段分组的统计接口

---

#### 2. 请假统计 (`todayLeaveCount`)

**问题**: 项目中完全没有 `LeaveRequest` 相关的接口

**需要新增的接口**:
- 今日请假人数统计

**原因**: 
- 后端有 `LeaveRequest` 实体，但没有对应的 Controller 和 API

---

#### 3. 时间序列数据

**问题**: 需要按日期分组统计，现有接口无法满足

**需要新增的接口**:
- 近30天用户增长趋势（按 `Patient.createdAt` 分组）

**原因**: 
- 现有患者接口是分页查询，无法按日期分组统计
- 需要数据库层面的聚合查询

---

#### 4. 医生工作量 Top 5 (`doctorWorkload`)

**问题**: 需要统计每个医生的接诊人数

**需要新增的接口**:
- 医生工作量统计（按医生分组统计已完成预约数）

**原因**: 
- 现有接口无法获取预约与医生的关联统计
- 需要基于 `Appointment` 表按 `doctorId` 分组统计

---

## 四、推荐方案

### 方案一：完全新增（推荐）⭐

**优点**:
- 性能最优：数据库层面直接聚合
- 接口职责清晰：统计接口专门用于数据大屏
- 前端代码简洁：直接使用返回的统计数据
- 易于维护和扩展

**缺点**:
- 需要后端开发 3 个新接口
- 开发工作量较大

**实现**:
新增 3 个统计接口：
1. `GET /api/admin/dashboard/overview`
2. `GET /api/admin/dashboard/doctors`
3. `GET /api/admin/dashboard/patients`

---

### 方案二：部分复用（临时方案）

**优点**:
- 可以快速实现，不需要等待后端开发
- 可以先展示数据大屏效果

**缺点**:
- 性能较差：需要传输大量数据
- 前端代码复杂：需要做聚合计算
- 不适合生产环境

**实现**:
- 科室总数、医生总数等可以通过现有接口获取
- 预约统计、请假统计等必须新增接口

---

### 方案三：混合方案（折中）

**实现**:
1. **必须新增的接口**（预约统计、请假统计）→ 新增
2. **可以复用的接口**（科室总数、医生总数）→ 先复用，后续优化为统计接口

---

## 五、结论

### ✅ 建议采用方案一：完全新增

**理由**:
1. 数据大屏是实时展示系统，对性能要求高
2. 统计接口可以在数据库层面优化，性能更好
3. 接口职责清晰，便于维护
4. 前端代码简洁，易于开发

### 📋 需要新增的接口清单

1. **运营总览接口** (`GET /api/admin/dashboard/overview`)
   - 必须新增：预约相关统计、支付状态分布
   - 可以复用但建议新增：患者总数

2. **医生资源分析接口** (`GET /api/admin/dashboard/doctors`)
   - 必须新增：今日请假人数、医生工作量 Top 5
   - 可以复用但建议新增：医生总数、职称分布、科室总数、科室繁忙度

3. **患者群体画像接口** (`GET /api/admin/dashboard/patients`)
   - 必须新增：近30天用户增长趋势、就诊时段热力图、累计爽约次数
   - 可以复用但建议新增：患者类型构成、本月新增注册

### ⚠️ 额外需要新增的接口

由于项目中缺少 `LeaveRequest` 相关的接口，建议同时新增：
- `GET /api/leave-requests` - 获取请假列表（可选，用于管理）
- `GET /api/admin/dashboard/doctors` - 统计接口中包含今日请假人数即可

---

## 六、实施建议

### 阶段一：快速实现（使用 Mock 数据）
- 前端已完成，使用 Mock 数据展示
- 可以立即看到效果

### 阶段二：接口开发（后端）
- 优先开发运营总览接口（使用频率最高）
- 其次开发患者群体画像接口
- 最后开发医生资源分析接口

### 阶段三：集成测试
- 前端替换 Mock 数据为真实接口
- 性能测试和优化

---

## 七、参考实现

可以参考项目中已有的统计接口：
- `GET /api/reports/doctor-hours` - 医生工时统计接口的实现方式

该接口展示了如何：
1. 接收查询参数（日期范围、科室等）
2. 在数据库层面进行聚合查询
3. 返回统计结果

可以按照类似的模式实现数据大屏的统计接口。







