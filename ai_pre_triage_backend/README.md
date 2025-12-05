# AI 智能预问诊后端服务

## 快速开始

### 1. 安装依赖

```bash
cd ai_pre_triage_backend
npm install
```

### 2. 配置环境变量

编辑 `.env` 文件，填入您的数据库配置：

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=hospital

BAIDU_API_KEY=your_api_key
BAIDU_SECRET_KEY=your_secret_key

PORT=3000
```

### 3. 启动服务

```bash
# 生产模式
npm start

# 开发模式（自动重启）
npm run dev
```

服务将在 `http://localhost:3000` 启动。

## API 接口

### 1. 获取热门症状
- **GET** `/api/symptoms/popular`
- **响应**: `["头痛", "发热", "咳嗽", ...]`

### 2. AI 智能分诊
- **POST** `/api/pre-triage/recommend-department`
- **请求体**:
  ```json
  {
    "patient_id": 1,  // 可选
    "symptoms": "头痛，伴有恶心"
  }
  ```
- **响应**:
  ```json
  {
    "analysis": "病情分析...",
    "recommended_department": {
      "id": 1,
      "name": "神经内科",
      "reason": "推荐理由"
    }
  }
  ```

### 3. 医生智能推荐
- **POST** `/api/pre-triage/recommend-doctor`
- **请求体**:
  ```json
  {
    "department_id": 1,
    "symptoms": "头痛"
  }
  ```
- **响应**: 医生数组
  ```json
  [
    {
      "id": 1,
      "name": "张医生",
      "title": "主任医师",
      "specialty": "擅长...",
      "reason": "推荐理由"
    }
  ]
  ```

## 注意事项

1. 确保 MySQL 数据库已启动并可以连接
2. 确保已配置百度文心一言 API 密钥
3. 如果遇到连接问题，检查防火墙和端口占用




