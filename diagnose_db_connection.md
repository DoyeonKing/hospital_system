# 数据库连接诊断指南

## 当前配置
- **数据库地址**: `123.249.30.241:3306`
- **数据库名**: `hospital_db`
- **用户名**: `root`
- **连接超时时间**: 5秒

## 诊断步骤

### 1. 检查云服务器MySQL服务是否运行
登录云服务器后执行：
```bash
# 检查MySQL服务状态
sudo systemctl status mysql
# 或
sudo systemctl status mysqld

# 如果未运行，启动MySQL
sudo systemctl start mysql
# 或
sudo systemctl start mysqld
```

### 2. 检查MySQL是否允许远程连接
登录云服务器后，检查MySQL配置文件：
```bash
# 查看bind-address配置
sudo grep bind-address /etc/mysql/mysql.conf.d/mysqld.cnf
# 或
sudo grep bind-address /etc/my.cnf

# 如果看到 bind-address = 127.0.0.1，需要改为：
# bind-address = 0.0.0.0
```

修改后需要重启MySQL：
```bash
sudo systemctl restart mysql
```

### 3. 检查防火墙设置
确保云服务器的防火墙开放了3306端口：

**如果是云服务商的安全组（必须配置）：**
- 登录云服务器控制台
- 找到安全组规则
- 添加入站规则：端口3306，协议TCP，允许

**如果是服务器防火墙：**
```bash
# Ubuntu/Debian
sudo ufw allow 3306/tcp
sudo ufw status

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

### 4. 检查MySQL用户权限
登录MySQL后执行：
```sql
-- 检查root用户是否允许远程连接
SELECT user, host FROM mysql.user WHERE user='root';

-- 如果看到只有 localhost，需要授权
GRANT ALL PRIVILEGES ON hospital_db.* TO 'root'@'%' IDENTIFIED BY '123456';
FLUSH PRIVILEGES;
```

### 5. 本地测试连接
在本地机器上测试能否连接：
```bash
# Windows (需要安装MySQL客户端)
mysql -h 123.249.30.241 -P 3306 -u root -p

# 或使用telnet测试端口是否开放
telnet 123.249.30.241 3306
```

## 快速解决方案

如果暂时无法解决远程连接，可以：

### 方案1: 使用本地MySQL（推荐用于开发测试）
修改 `application.yml`，使用本地数据库：

```yaml
datasource:
  url: jdbc:mysql://localhost:3306/hospital_db?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf-8&allowPublicKeyRetrieval=true&connectTimeout=5000&socketTimeout=30000
  username: root
  password: "123456"
```

### 方案2: 临时禁用SSL
修改连接URL，将 `useSSL=true` 改为 `useSSL=false`：

```yaml
url: jdbc:mysql://123.249.30.241:3306/hospital_db?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf-8&allowPublicKeyRetrieval=true&connectTimeout=5000&socketTimeout=30000
```

### 方案3: 增加连接超时时间
将连接超时时间从5秒增加到30秒：

```yaml
url: jdbc:mysql://123.249.30.241:3306/hospital_db?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf-8&allowPublicKeyRetrieval=true&connectTimeout=30000&socketTimeout=30000
```








