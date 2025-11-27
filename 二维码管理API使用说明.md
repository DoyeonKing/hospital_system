# 二维码管理API使用说明

## 数据库配置

### 1. 执行SQL脚本

```bash
# 1. 添加二维码字段到map_nodes表
mysql -u root -p hospital_db < sql语句/修改语句/add_qrcode_to_map_nodes.sql

# 2. 为现有节点初始化二维码内容
mysql -u root -p hospital_db < sql语句/修改语句/init_qrcode_for_existing_nodes.sql
```

### 2. 配置上传目录

在 `application.yml` 中添加：

```yaml
app:
  qrcode:
    upload-dir: uploads/qrcodes  # 二维码图片上传目录
```

## API接口说明

### 1. 生成二维码内容

**接口：** `POST /api/qrcode/generate/{nodeId}`

**说明：** 为指定节点生成二维码内容（格式：HOSPITAL_NODE_{nodeId}）

**示例：**
```bash
curl -X POST http://localhost:8080/api/qrcode/generate/1
```

**响应：**
```json
{
  "code": "200",
  "msg": "操作成功",
  "data": {
    "nodeId": 1,
    "nodeName": "医院大门",
    "qrcodeContent": "HOSPITAL_NODE_1",
    "qrcodeStatus": "PENDING"
  }
}
```

### 2. 上传二维码图片

**接口：** `POST /api/qrcode/upload/{nodeId}`

**说明：** 上传二维码图片文件

**参数：**
- `file`: 图片文件（multipart/form-data）

**示例：**
```bash
curl -X POST \
  http://localhost:8080/api/qrcode/upload/1 \
  -F "file=@qrcode_node_1.png"
```

**响应：**
```json
{
  "code": "200",
  "msg": "操作成功",
  "data": {
    "nodeId": 1,
    "nodeName": "医院大门",
    "qrcodeContent": "HOSPITAL_NODE_1",
    "qrcodeImagePath": "uploads/qrcodes/qrcode_node_1_xxx.png",
    "qrcodeStatus": "ACTIVE"
  }
}
```

### 3. 扫码定位（根据二维码内容查找节点）

**接口：** `GET /api/qrcode/scan/{qrcodeContent}`

**说明：** 根据二维码内容查找对应的节点（前端扫码后调用）

**示例：**
```bash
curl http://localhost:8080/api/qrcode/scan/HOSPITAL_NODE_1
```

**响应：**
```json
{
  "code": "200",
  "msg": "操作成功",
  "data": {
    "nodeId": 1,
    "nodeName": "医院大门",
    "coordinatesX": 20.0,
    "coordinatesY": 29.0,
    "qrcodeContent": "HOSPITAL_NODE_1",
    "qrcodeStatus": "ACTIVE"
  }
}
```

### 4. 获取所有节点的二维码信息

**接口：** `GET /api/qrcode/nodes`

**说明：** 获取所有节点及其二维码信息

**示例：**
```bash
curl http://localhost:8080/api/qrcode/nodes
```

### 5. 获取已激活的二维码节点

**接口：** `GET /api/qrcode/nodes/active`

**说明：** 获取所有已激活二维码的节点列表

**示例：**
```bash
curl http://localhost:8080/api/qrcode/nodes/active
```

### 6. 更新二维码状态

**接口：** `PUT /api/qrcode/status/{nodeId}`

**参数：**
- `status`: 状态值（ACTIVE, INACTIVE, PENDING）

**示例：**
```bash
curl -X PUT \
  "http://localhost:8080/api/qrcode/status/1?status=ACTIVE"
```

### 7. 删除二维码（软删除）

**接口：** `DELETE /api/qrcode/{nodeId}`

**说明：** 将二维码状态设置为INACTIVE

**示例：**
```bash
curl -X DELETE http://localhost:8080/api/qrcode/1
```

### 8. 下载二维码图片

**接口：** `GET /api/qrcode/image/{nodeId}`

**说明：** 下载指定节点的二维码图片

**示例：**
```bash
curl -O http://localhost:8080/api/qrcode/image/1
```

## 使用流程

### 步骤1：生成二维码内容

```bash
POST /api/qrcode/generate/1
```

### 步骤2：生成二维码图片

使用前端工具或Python脚本生成二维码图片（内容：HOSPITAL_NODE_1）

### 步骤3：上传二维码图片

```bash
POST /api/qrcode/upload/1
# 上传生成的二维码图片
```

### 步骤4：打印并张贴

下载二维码图片，打印后张贴在医院对应位置

### 步骤5：扫码定位

用户在前端扫码后，调用：
```bash
GET /api/qrcode/scan/HOSPITAL_NODE_1
```

## 前端集成示例

### 扫码定位后调用后端API

```javascript
// 在 uni_app/pages/navigation/index.vue 中
async scanLocationCode() {
    try {
        const res = await uni.scanCode({
            scanType: ['qrCode', 'barCode']
        })
        
        const qrcodeContent = res.result
        
        // 调用后端API获取节点信息
        const response = await uni.request({
            url: 'http://your-api-domain/api/qrcode/scan/' + encodeURIComponent(qrcodeContent),
            method: 'GET'
        })
        
        if (response.data.code === '200') {
            const node = response.data.data
            // 使用节点信息定位
            this.currentLocation = { x: node.coordinatesX, y: node.coordinatesY }
            // ... 其他定位逻辑
        }
    } catch (error) {
        console.error('扫码失败:', error)
    }
}
```

## 文件存储

二维码图片存储在：`uploads/qrcodes/` 目录下

文件命名格式：`qrcode_node_{nodeId}_{uuid}.png`

## 注意事项

1. **文件上传大小限制**：默认Spring Boot限制为10MB，可在`application.yml`中调整
2. **文件类型验证**：只接受图片文件（image/*）
3. **目录权限**：确保`uploads/qrcodes`目录有写入权限
4. **生产环境**：建议使用对象存储（OSS）替代本地文件存储








