# 数据大屏 API 接口文档

## 概述

本文档描述了医院运营数据大屏所需的所有后端 API 接口。数据大屏分为三个标签页：**运营总览**、**医生资源分析**、**患者群体画像**。

**基础路径**: `/api/admin/dashboard`

## 接口复用分析

### ✅ 可复用的现有接口

以下数据可以通过现有接口获取，但**建议新增专门的统计接口**以提高性能和减少前端计算：

1. **科室总数** (`totalDepartments`)
   - 可复用：`GET /api/departments` (获取所有科室后计算总数)
   - 建议：新增统计接口，直接返回总数

2. **医生列表** (用于职称分布统计)
   - 可复用：`GET /api/users/doctorInfo` (搜索所有医生)
   - 建议：新增统计接口，直接返回按职称分组的统计数据

3. **患者列表** (用于类型统计)
   - 可复用：`GET /api/users/patientInfo` (搜索所有患者)
   - 建议：新增统计接口，直接返回按类型分组的统计数据

4. **排班数据** (用于科室繁忙度统计)
   - 可复用：`GET /api/schedules` (获取排班列表)
   - 建议：新增统计接口，直接返回按科室聚合的已预约数

### ❌ 需要新增的接口

以下数据**必须新增专门的统计接口**，因为现有接口无法满足需求：

1. **预约相关统计** - 需要基于 `Appointment` 表的聚合查询
2. **时间趋势数据** - 需要按日期分组统计
3. **支付状态分布** - 需要按状态分组统计
4. **请假数据统计** - 需要基于 `LeaveRequest` 表的统计
5. **时段热力图数据** - 需要按时间段分组统计

---

## 推荐方案

**建议新增 3 个专门的统计接口**，而不是复用现有接口，原因：
1. **性能优化**：统计接口可以在数据库层面直接聚合，避免传输大量数据
2. **减少前端计算**：后端直接返回统计结果，前端无需处理
3. **接口职责清晰**：统计接口专门用于数据大屏，查询接口用于业务操作

---

## 1. 运营总览数据接口

### 1.1 获取运营总览数据

**接口路径**: `GET /api/admin/dashboard/overview`

**接口描述**: 获取运营总览页面的所有核心指标和图表数据

**请求参数**: 无

**响应示例**:
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "todayAppointments": 128,
    "activeDoctorsToday": 24,
    "pendingPatients": 15,
    "totalPatients": 3450,
    "last7DaysDates": ["11-16", "11-17", "11-18", "11-19", "11-20", "11-21", "11-22"],
    "last7DaysCounts": [120, 132, 101, 134, 90, 230, 210],
    "paymentStatus": [
      {
        "name": "已支付",
        "value": 245
      },
      {
        "name": "待支付",
        "value": 38
      },
      {
        "name": "退款",
        "value": 12
      }
    ]
  }
}
```

**响应字段说明**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| todayAppointments | Integer | 今日挂号量 |
| activeDoctorsToday | Integer | 今日出诊医生数 |
| pendingPatients | Integer | 当前候诊人数（状态为 WAITING 的预约数） |
| totalPatients | Integer | 累计注册用户总数 |
| last7DaysDates | Array<String> | 近7天日期数组，格式：MM-dd |
| last7DaysCounts | Array<Integer> | 近7天每日挂号量数组，与日期数组一一对应 |
| paymentStatus | Array<Object> | 支付状态分布数据 |
| paymentStatus[].name | String | 支付状态名称（已支付/待支付/退款） |
| paymentStatus[].value | Integer | 该状态的数量 |

**数据来源说明**:
- `todayAppointments`: 统计 `Appointment` 表中 `appointmentDate` 为今天的记录数
- `activeDoctorsToday`: 统计 `Schedule` 表中今天有排班的医生数（去重）
- `pendingPatients`: 统计 `Appointment` 表中状态为 `WAITING` 的记录数
- `totalPatients`: 统计 `Patient` 表中的总记录数
- `last7DaysDates/Counts`: 统计近7天每天的 `Appointment` 记录数
- `paymentStatus`: 根据 `Appointment` 的 `AppointmentStatus` 枚举统计（PAID/UNPAID/REFUNDED）

---

## 2. 医生资源分析数据接口

### 2.1 获取医生资源分析数据

**接口路径**: `GET /api/admin/dashboard/doctors`

**接口描述**: 获取医生资源分析页面的所有指标和图表数据

**请求参数**: 无

**响应示例**:
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "totalDoctors": 156,
    "todayLeaveCount": 8,
    "totalDepartments": 12,
    "titleDistribution": [
      {
        "name": "Chief Physician",
        "value": 28
      },
      {
        "name": "Associate Chief Physician",
        "value": 45
      },
      {
        "name": "Attending Physician",
        "value": 58
      },
      {
        "name": "Resident Physician",
        "value": 25
      }
    ],
    "departmentBusy": [
      {
        "name": "Internal Medicine",
        "value": 342
      },
      {
        "name": "Surgery",
        "value": 298
      },
      {
        "name": "Pediatrics",
        "value": 267
      },
      {
        "name": "Orthopedics",
        "value": 189
      },
      {
        "name": "Cardiology",
        "value": 156
      }
    ],
    "doctorWorkload": [
      {
        "name": "Dr. Zhang Wei",
        "department": "Internal Medicine",
        "value": 89
      },
      {
        "name": "Dr. Li Ming",
        "department": "Surgery",
        "value": 76
      },
      {
        "name": "Dr. Wang Fang",
        "department": "Pediatrics",
        "value": 68
      },
      {
        "name": "Dr. Liu Gang",
        "department": "Orthopedics",
        "value": 54
      },
      {
        "name": "Dr. Chen Yu",
        "department": "Cardiology",
        "value": 47
      }
    ]
  }
}
```

**响应字段说明**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| totalDoctors | Integer | 医生总数 |
| todayLeaveCount | Integer | 今日请假人数（`LeaveRequest` 表中今天状态为 APPROVED 的记录数） |
| totalDepartments | Integer | 科室总数 |
| titleDistribution | Array<Object> | 职称分布数据（按 `Doctor.title` 枚举统计） |
| titleDistribution[].name | String | 职称名称（Chief Physician / Associate Chief Physician / Attending Physician / Resident Physician） |
| titleDistribution[].value | Integer | 该职称的医生数量 |
| departmentBusy | Array<Object> | 科室繁忙度 Top 5（按已预约数排序） |
| departmentBusy[].name | String | 科室名称 |
| departmentBusy[].value | Integer | 该科室的已预约数（`Schedule.bookedAppointments` 总和） |
| doctorWorkload | Array<Object> | 医生工作量 Top 5（按接诊人数排序） |
| doctorWorkload[].name | String | 医生姓名 |
| doctorWorkload[].department | String | 所属科室名称 |
| doctorWorkload[].value | Integer | 接诊人数（统计该医生相关的已完成预约数） |

**数据来源说明**:
- `totalDoctors`: 统计 `Doctor` 表中的总记录数
- `todayLeaveCount`: 统计 `LeaveRequest` 表中 `leaveDate` 为今天且 `status` 为 `APPROVED` 的记录数
- `totalDepartments`: 统计 `Department` 表中的总记录数
- `titleDistribution`: 按 `Doctor.title` 字段分组统计
- `departmentBusy`: 按科室分组，统计每个科室所有 `Schedule` 的 `bookedAppointments` 总和，取前5名
- `doctorWorkload`: 统计每个医生相关的已完成预约（`Appointment.status = COMPLETED`）数量，取前5名

---

## 3. 患者群体画像数据接口

### 3.1 获取患者群体画像数据

**接口路径**: `GET /api/admin/dashboard/patients`

**接口描述**: 获取患者群体画像页面的所有指标和图表数据

**请求参数**: 无

**响应示例**:
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "monthlyNewRegistrations": 287,
    "studentTeacherRatio": "4.3:1",
    "totalNoShows": 156,
    "last30DaysDates": ["10-24", "10-25", "10-26", ..., "11-22"],
    "last30DaysCounts": [12, 15, 8, 20, 18, ..., 14],
    "patientType": [
      {
        "name": "Student",
        "value": 2800
      },
      {
        "name": "Teacher",
        "value": 650
      }
    ],
    "timeSlotData": [
      {
        "time": "08:00-09:00",
        "count": 45
      },
      {
        "time": "09:00-10:00",
        "count": 78
      },
      {
        "time": "10:00-11:00",
        "count": 92
      },
      {
        "time": "11:00-12:00",
        "count": 65
      },
      {
        "time": "12:00-13:00",
        "count": 28
      },
      {
        "time": "13:00-14:00",
        "count": 38
      },
      {
        "time": "14:00-15:00",
        "count": 56
      },
      {
        "time": "15:00-16:00",
        "count": 72
      },
      {
        "time": "16:00-17:00",
        "count": 48
      }
    ]
  }
}
```

**响应字段说明**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| monthlyNewRegistrations | Integer | 本月新增注册用户数（根据 `Patient.createdAt` 统计本月） |
| studentTeacherRatio | String | 师生比例系数，格式：`"X.X:1"`（学生数:教职工数） |
| totalNoShows | Integer | 累计爽约次数（`Appointment.status = NO_SHOW` 的记录数） |
| last30DaysDates | Array<String> | 近30天日期数组，格式：MM-dd |
| last30DaysCounts | Array<Integer> | 近30天每日新增用户数数组，与日期数组一一对应 |
| patientType | Array<Object> | 患者类型构成数据 |
| patientType[].name | String | 患者类型（Student / Teacher） |
| patientType[].value | Integer | 该类型的患者数量 |
| timeSlotData | Array<Object> | 就诊时段热力图数据（8:00-17:00，每小时一个时段） |
| timeSlotData[].time | String | 时段字符串，格式：`"HH:mm-HH:mm"` |
| timeSlotData[].count | Integer | 该时段的挂号量 |

**数据来源说明**:
- `monthlyNewRegistrations`: 统计 `Patient` 表中 `createdAt` 在本月的记录数
- `studentTeacherRatio`: 计算 `PatientType.STUDENT` 数量与 `PatientType.TEACHER` 数量的比例
- `totalNoShows`: 统计 `Appointment` 表中 `status = NO_SHOW` 的记录数
- `last30DaysDates/Counts`: 按 `Patient.createdAt` 统计近30天每天的新增用户数
- `patientType`: 按 `Patient.type` 枚举分组统计
- `timeSlotData`: 根据 `Appointment.appointmentTime` 或 `Schedule.timeSlot` 统计每个时段的挂号量（8:00-17:00，共9个时段）

---

## 4. 统一响应格式

所有接口遵循统一的响应格式：

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    // 具体数据内容
  }
}
```

**响应字段说明**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| code | Integer | 状态码，200 表示成功 |
| msg | String | 响应消息 |
| data | Object | 具体的数据内容 |

**错误响应示例**:
```json
{
  "code": 500,
  "msg": "服务器内部错误",
  "data": null
}
```

---

## 5. 权限要求

所有接口需要管理员权限认证，请求头需包含有效的认证 Token：

```
Authorization: Bearer <token>
```

---

## 6. 数据更新频率建议

- **运营总览数据**: 建议实时更新或每5分钟刷新一次
- **医生资源分析数据**: 建议每小时更新一次
- **患者群体画像数据**: 建议每小时更新一次

---

## 7. 注意事项

1. 所有日期格式统一使用 `MM-dd` 格式（如：`11-22`）
2. 时间格式统一使用 `HH:mm-HH:mm` 格式（如：`08:00-09:00`）
3. 所有统计数据应基于当前时间进行计算
4. 排序规则：
   - `departmentBusy`: 按 `value` 降序排列，取前5名
   - `doctorWorkload`: 按 `value` 降序排列，取前5名
5. 如果某个统计数据为空，应返回空数组 `[]` 或 `0`，而不是 `null`

---

## 8. 接口调用示例

### 前端调用示例（Vue 3 + Axios）

```javascript
import request from '@/utils/request'

// 获取运营总览数据
export function getOverviewStats() {
  return request({
    url: '/api/admin/dashboard/overview',
    method: 'get'
  })
}

// 获取医生资源分析数据
export function getDoctorsStats() {
  return request({
    url: '/api/admin/dashboard/doctors',
    method: 'get'
  })
}

// 获取患者群体画像数据
export function getPatientsStats() {
  return request({
    url: '/api/admin/dashboard/patients',
    method: 'get'
  })
}
```

---

## 9. 版本信息

- **文档版本**: v1.0
- **最后更新**: 2024-11-22
- **维护者**: 前端开发团队

---

## 10. 现有接口复用说明

### 10.1 可以部分复用的接口

虽然建议新增专门的统计接口，但如果后端暂时无法实现，前端可以通过以下方式临时获取部分数据：

#### 获取科室总数
```javascript
// 使用现有接口
import { getAllDepartments } from '@/api/department'

async function getTotalDepartments() {
  const response = await getAllDepartments()
  return response.data.content?.length || 0
}
```

#### 获取医生列表（用于职称统计）
```javascript
// 使用现有接口
import { searchDoctors } from '@/api/user'

async function getDoctorsForTitleStats() {
  const response = await searchDoctors({ page: 1, pageSize: 1000 })
  // 前端需要自己按 title 分组统计
  return response.data.content || []
}
```

**注意**：这种方式存在以下问题：
- 需要传输大量数据到前端
- 前端需要做复杂的聚合计算
- 性能较差，不适合实时数据大屏

### 10.2 必须新增的接口

以下数据**无法通过现有接口获取**，必须新增：

1. **预约统计相关**：
   - 今日挂号量
   - 当前候诊人数
   - 近7天挂号趋势
   - 支付状态分布
   - 累计爽约次数
   - 就诊时段热力图

2. **时间序列数据**：
   - 近30天用户增长趋势

3. **请假统计**：
   - 今日请假人数

4. **聚合统计数据**：
   - 科室繁忙度 Top 5
   - 医生工作量 Top 5

---

## 11. 实现优先级建议

### 高优先级（必须实现）
1. ✅ 运营总览数据接口 (`/api/admin/dashboard/overview`)
2. ✅ 患者群体画像数据接口 (`/api/admin/dashboard/patients`)

### 中优先级（建议实现）
3. ✅ 医生资源分析数据接口 (`/api/admin/dashboard/doctors`)

### 低优先级（可延后）
- 如果暂时无法实现，可以先使用 Mock 数据展示

---

## 12. 联系方式

如有接口相关问题，请联系后端开发团队。

