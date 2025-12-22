# Node.js AI 预问诊后端 Dockerfile
FROM node:18-alpine

WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装依赖（如果没有 package-lock.json，使用 npm install）
RUN npm install --only=production --no-audit --no-fund

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["npm", "start"]

