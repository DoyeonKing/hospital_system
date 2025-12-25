# Postman测试用例使用说明

## 快速使用

### 方法1：直接复制单个用例

**用例1：空值测试**
```json
{
  "patientId": null,
  "scheduleId": null,
  "appointmentNumber": null
}
```

**用例2：类型错误（字符串代替数字）**
```json
{
  "patientId": "abc",
  "scheduleId": 1,
  "appointmentNumber": 1
}
```

**用例3：类型错误（数组/对象）**
```json
{
  "patientId": [1, 2, 3],
  "scheduleId": {"test": "value"},
  "appointmentNumber": true
}
```

**用例4：超长字符串（100字符）**
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343"
}
```

**用例5：SQL注入尝试**
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "1'; DROP TABLE appointments; --"
}
```

**用例6：XSS脚本尝试**
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "<script>alert('xss')</script>"
}
```

**用例7：特殊字符**
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "!@#$%^&*()_+-=[]{}|;':\",./<>?"
}
```

**用例8：正常数据（对比用）**
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "001"
}
```

## 使用方法

1. 在Postman中打开请求 "POST 1. 创建预约（挂号）"
2. 点击 "Body" 标签
3. 选择 "raw" 和 "JSON"
4. 复制上面的任意一个用例，粘贴到Body中
5. 点击 "Send" 发送请求
6. 记录响应结果和日志

## 如果需要更长的字符串

如果需要测试1000字符或10000字符，可以使用以下方法：

### 方法1：使用Postman的Pre-request Script

1. 点击 "Scripts" 标签
2. 在 "Pre-request Script" 中输入：
```javascript
const longString = "43".repeat(1000); // 1000个字符
pm.environment.set("testLongString", longString);
```

3. 在Body中使用：
```json
{
  "patientId": 1,
  "scheduleId": 1,
  "appointmentNumber": "{{testLongString}}"
}
```

### 方法2：在线生成后复制

访问在线工具生成长字符串，然后复制到JSON中。

## 注意事项

- JSON中不能使用JavaScript函数（如 `.repeat()`）
- 所有字符串必须用双引号包裹
- 数字不需要引号
- null 不需要引号









