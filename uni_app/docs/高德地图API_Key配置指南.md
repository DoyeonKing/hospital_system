# 高德地图 API Key 配置指南

## 📍 获取高德地图 API Key 详细步骤

### 步骤一：注册/登录高德开放平台

1. **访问高德开放平台**
   - 网址：https://lbs.amap.com/
   - 点击右上角"登录"或"注册"

2. **注册账号**
   - 可以使用支付宝账号快速登录
   - 或者使用邮箱/手机号注册

### 步骤二：创建应用

1. **进入控制台**
   - 登录后，点击右上角"控制台"
   - 或直接访问：https://console.amap.com/

2. **创建新应用**
   - 点击左侧菜单"应用管理" → "我的应用"
   - 点击右上角"创建新应用"按钮
   - 填写应用信息：
     ```
     应用名称：医院导航系统
     应用类型：生活服务（或其他）
     ```
   - 点击"创建"按钮

### 步骤三：添加 Key（API密钥）

1. **在应用下添加 Key**
   - 找到刚创建的应用，点击"添加"按钮
   - 选择服务平台：
     - **Web端（JS API）**：用于H5网页
     - **Android平台**：用于Android原生APP
     - **iOS平台**：用于iOS原生APP
     - **通用**：开发测试阶段可以使用

2. **填写 Key 信息**
   ```
   Key名称：医院导航-Android（或iOS/Web）
   服务平台：选择对应平台
   
   对于Android：
   - 填写应用包名（Bundle ID）
   - 例如：com.example.hospital_navigation
   
   对于iOS：
   - 填写Bundle ID
   - 例如：com.example.hospitalNavigation
   
   对于Web端：
   - 绑定域名：开发阶段可以填 *
   - 生产环境填写实际域名
   ```

3. **获取 Key 值**
   - 保存后，即可看到生成的 Key（一串字母数字组合）
   - **重要**：请妥善保管此 Key，不要泄露

### 步骤四：在 uni-app 项目中配置

#### 方式一：Android/iOS APP 配置

编辑 `manifest.json` 文件：

```json
{
  "app-plus": {
    "modules": {
      "Maps": {
        "gaode": {
          "appkey_android": "你的Android平台Key",
          "appkey_ios": "你的iOS平台Key"
        }
      }
    }
  }
}
```

#### 方式二：微信小程序配置

微信小程序使用腾讯地图（内置），无需配置高德 Key。

如果需要在小程序中使用高德地图，需要：
1. 在小程序管理后台配置"第三方服务"
2. 或使用高德地图小程序插件

#### 方式三：H5 网页配置

如果项目需要发布为H5网页：

```html
<!-- 在index.html中引入高德地图JS API -->
<script type="text/javascript" src="https://webapi.amap.com/maps?v=2.0&key=你的Web端Key"></script>
```

或者在 `manifest.json` 的 `h5` 配置中添加。

### 步骤五：权限配置

#### Android 权限（已配置）

`manifest.json` 中已包含必要权限：
- `ACCESS_COARSE_LOCATION`：粗略位置权限
- `ACCESS_FINE_LOCATION`：精确位置权限

#### iOS 权限配置

在 `manifest.json` 中添加：

```json
{
  "app-plus": {
    "distribute": {
      "ios": {
        "privacyDescription": {
          "NSLocationWhenInUseUsageDescription": "此应用需要获取您的位置信息，用于提供导航服务",
          "NSLocationAlwaysUsageDescription": "此应用需要获取您的位置信息，用于提供导航服务"
        }
      }
    }
  }
}
```

### 步骤六：代码中使用

#### 在页面中使用地图组件

```vue
<template>
  <map
    :latitude="latitude"
    :longitude="longitude"
    :markers="markers"
    :scale="16"
    :show-location="true"
    class="map"
  />
</template>

<script>
export default {
  data() {
    return {
      latitude: 39.908823,
      longitude: 116.397470,
      markers: []
    }
  },
  onLoad() {
    // 获取位置
    uni.getLocation({
      type: 'gcj02', // 使用国测局坐标系（高德地图坐标系）
      success: (res) => {
        this.latitude = res.latitude;
        this.longitude = res.longitude;
      }
    });
  }
}
</script>
```

### 常见问题

#### 1. Key 不生效怎么办？

- 检查 Key 是否正确复制（没有多余空格）
- 检查应用包名是否匹配
- 检查 Key 的服务平台是否正确
- 等待几分钟后重试（新创建的 Key 可能需要时间生效）

#### 2. 开发阶段推荐配置

- **Android/iOS APP**：使用"通用"类型的 Key，绑定域名填写 `*`
- **Web端**：绑定域名填写 `localhost` 或 `*`

#### 3. 生产环境注意事项

- **必须**将绑定域名改为实际域名
- **不要**将 Key 提交到公开的代码仓库
- 建议使用环境变量或配置文件管理 Key

### 高德地图坐标系统说明

高德地图使用 **GCJ-02** 坐标系（国测局坐标系），也被称为"火星坐标系"。

在 uni-app 中使用 `uni.getLocation()` 时，需要指定坐标系类型：

```javascript
uni.getLocation({
  type: 'gcj02', // 高德地图坐标系
  success: (res) => {
    console.log(res.latitude, res.longitude);
  }
});
```

### 相关文档链接

- 高德开放平台：https://lbs.amap.com/
- 高德地图 JS API 文档：https://lbs.amap.com/api/javascript-api/summary
- uni-app 地图组件文档：https://uniapp.dcloud.net.cn/component/map.html

### 配置示例

完整的 `manifest.json` 配置示例：

```json
{
  "app-plus": {
    "modules": {
      "Maps": {
        "gaode": {
          "appkey_android": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
          "appkey_ios": "i1o2s3k4e5y6a7p8p9l0e1d2e3v4e5l6"
        }
      }
    },
    "distribute": {
      "android": {
        "permissions": [
          "<uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\"/>",
          "<uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\"/>"
        ]
      },
      "ios": {
        "privacyDescription": {
          "NSLocationWhenInUseUsageDescription": "需要获取您的位置信息，用于提供导航服务",
          "NSLocationAlwaysUsageDescription": "需要获取您的位置信息，用于提供导航服务"
        }
      }
    }
  }
}
```

---

**提示**：获取到 API Key 后，请将其填入 `manifest.json` 对应位置，然后重新打包应用即可使用高德地图功能。



