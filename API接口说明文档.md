# "挂了吗"校医院挂号系统 - 登录注册API接口说明文档

## 概述
本文档定义了"挂了吗"校医院挂号系统中患者端、管理员端、医生端的登录注册相关API接口规范。所有接口都遵循统一的响应格式。

## 前端文件对应关系

| 角色 | 登录页面文件 | 路径 |
|------|-------------|------|
| 患者 | `patient-login.vue` | `uni_app/pages/login/` |
| 管理员 | `AdminLogin.vue` | `vue_admin/src/views/` |
| 医生 | `DoctorLogin.vue` | `vue/src/views/` |

## 通用响应格式
```json
{
  "code": "200",           // 状态码：200-成功，其他-失败
  "msg": "请求成功",        // 响应消息
  "data": {}              // 响应数据（可选）
}
```

## 1. 患者端（微信小程序）- 登录激活流程

### 1.1 第一步：初始登录验证
**接口地址：** `POST /api/patient/verify-initial-login`

**请求参数：**
```json
{
  "identifier": "2023001",        // 学号/工号
  "password": "123456"            // 初始密码
}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "初始登录验证成功",
  "data": {
    "patientId": "P001",
    "name": "张三",
    "phone": "13800138000",
    "idCard": "110***********1234"
  }
}
```

**失败响应：**
```json
{
  "code": "400",
  "msg": "学号/工号或初始密码错误"
}
```

### 1.2 第二步：身份验证
**接口地址：** `POST /api/patient/verify-identity`

**请求参数：**
```json
{
  "identifier": "2023001",        // 学号/工号
  "idCardLast6": "001234",        // 身份证号后6位（用户输入）
  "newPassword": "newpass123"     // 新密码
}
```

**说明：**
- 用户需要输入完整身份证号的后6位数字进行验证
- 后端将用户输入的后6位与数据库中的身份证号进行比对
- 验证通过后才能设置新密码并激活账户

**成功响应：**
```json
{
  "code": "200",
  "msg": "身份验证成功，账户已激活"
}
```

**失败响应：**
```json
{
  "code": "400",
  "msg": "身份证号验证失败"
}
```

### 1.3 正常登录
**接口地址：** `POST /api/patient/login`

**请求参数：**
```json
{
  "identifier": "2023001",        // 学号/工号
  "password": "newpass123"        // 激活后的密码
}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "patientInfo": {
      "patientId": "P001",
      "name": "张三",
      "phone": "13800138000",
      "allergyHistory": "无",
      "pastMedicalHistory": "无"
    }
  }
}
```

## 2. 管理员端（Web）- 简单登录

### 2.1 管理员登录
**接口地址：** `POST /api/admin/login`

**请求参数：**
```json
{
  "adminId": "A001",              // 管理员ID
  "password": "admin123"          // 密码
}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "adminInfo": {
      "adminId": "A001",
      "name": "管理员",
      "permissionLevel": "super",
      "serviceArea": "全院",
      "currentPosition": "系统管理员"
    }
  }
}
```

**失败响应：**
```json
{
  "code": "400",
  "msg": "用户名或密码错误"
}
```

## 3. 医生端（Web）- 登录激活流程

### 3.1 第一步：初始登录验证
**接口地址：** `POST /api/doctor/verify-initial-login`

**请求参数：**
```json
{
  "identifier": "D001",           // 工号
  "password": "123456"            // 初始密码
}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "初始登录验证成功",
  "data": {
    "doctorId": "D001",
    "name": "李医生",
    "phone": "13900139000",
    "idCard": "110***********5678"
  }
}
```

### 3.2 第二步：身份验证
**接口地址：** `POST /api/doctor/verify-identity`

**请求参数：**
```json
{
  "identifier": "D001",           // 工号
  "idCardLast6": "005678",        // 身份证号后6位（用户输入）
  "newPassword": "doctor123"      // 新密码
}
```

**说明：**
- 医生需要输入完整身份证号的后6位数字进行验证
- 后端将用户输入的后6位与数据库中的身份证号进行比对
- 验证通过后才能设置新密码并激活账户

**成功响应：**
```json
{
  "code": "200",
  "msg": "身份验证成功，账户已激活"
}
```

### 3.3 正常登录
**接口地址：** `POST /api/doctor/login`

**请求参数：**
```json
{
  "identifier": "D001",           // 工号
  "password": "doctor123"         // 激活后的密码
}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "doctorInfo": {
      "doctorId": "D001",
      "name": "李医生",
      "department": "内科",
      "position": "主治医师",
      "phone": "13900139000"
    }
  }
}
```

## 4. 通用接口

### 4.1 检查账户激活状态
**接口地址：** `GET /api/{userType}/activation-status/{identifier}`

**路径参数：**
- `userType`: patient | doctor
- `identifier`: 学号/工号

**成功响应：**
```json
{
  "code": "200",
  "msg": "查询成功",
  "data": {
    "isActivated": true,          // true-已激活，false-未激活
    "lastLoginTime": "2024-01-15 10:30:00"
  }
}
```

### 4.2 登出
**接口地址：** `POST /api/{userType}/logout`

**请求头：**
```
Authorization: Bearer {token}
```

**成功响应：**
```json
{
  "code": "200",
  "msg": "登出成功"
}
```

## 5. 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误或业务逻辑错误 |
| 401 | 未授权或token无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

## 6. 数据库表结构参考

### 患者表 (tbl_Volunteer - 作为患者表使用)
- VolunteerID: 患者ID
- Username: 学号
- Password: 密码
- Name: 姓名
- PhoneNumber: 手机号
- IDCardNumber: 身份证号
- AccountStatus: 账户状态（active/inactive）

### 管理员表 (administrator)
- AdminID: 管理员ID
- Name: 姓名
- Password: 密码
- PermissionLevel: 权限等级
- ServiceArea: 服务区域
- CurrentPosition: 当前职位

### 医生表 (employee)
- id: 医生ID
- username: 工号
- password: 密码
- name: 姓名
- role: 角色（doctor）
- department_id: 科室ID

## 7. 测试账号

### 患者端（patient-login.vue）
**正常登录测试账号：**
- 学号：`P001` / `2023001` / `test`
- 密码：`123456` / `123456` / `test123`

**激活流程测试账号：**
- 学号：`P002` / `2023002` / `activate`
- 初始密码：`123456` / `123456` / `activate123`

### 管理员端（AdminLogin.vue）
- 用户名：`admin` / `test`
- 密码：`123456` / `test123`

### 医生端（DoctorLogin.vue）
**正常登录测试账号：**
- 工号：`D001` / `doctor` / `test`
- 密码：`123456` / `doctor123` / `test123`

**激活流程测试账号：**
- 工号：`D002` / `activate`
- 初始密码：`123456` / `activate123`

## 8. 前端实现说明

### 患者端（微信小程序）
- **框架：** uni-app
- **主题：** 白色医疗风格，蓝色高亮（#2563eb）
- **布局：** 紧凑上移布局，表单宽度 600rpx
- **特点：** 两步激活流程，步骤指示器，完整注释

### 管理员端（Web）
- **框架：** Vue 3 + Vite + Element Plus
- **主题：** 渐变蓝紫色（#667eea - #764ba2）
- **布局：** 双栏布局（左侧装饰 + 右侧表单）
- **状态管理：** Pinia + localStorage

### 医生端（Web）
- **框架：** Vue 3 + Vite + Element Plus
- **主题：** 渐变蓝紫色（#667eea - #764ba2）
- **布局：** 双栏布局，医生工作台
- **状态管理：** Pinia + localStorage
- **特点：** 两步激活流程，完整的工作台界面

## 9. 安全注意事项

1. 所有密码传输必须加密（HTTPS）
2. 身份证号在响应中需要脱敏处理
3. Token有效期设置为24小时
4. 登录失败超过5次需要锁定账户
5. 所有接口都需要进行参数校验
6. 敏感操作需要记录日志
7. 前端路由守卫验证登录状态
8. localStorage 存储加密 token
