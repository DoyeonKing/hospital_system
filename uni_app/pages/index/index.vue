<template>
	<view class="container">
		<!-- 头部欢迎区域 -->
		<view class="header">
			<view class="header-bg"></view>
			<view class="welcome-section">
				<image class="logo" src="/static/logo.png" mode="aspectFit"></image>
				<text class="welcome-title">欢迎使用 Uni-App</text>
				<text class="welcome-subtitle">跨平台开发解决方案</text>
			</view>
		</view>

		<!-- 功能卡片区域 -->
		<view class="cards-section">
			<view class="card" @click="showToast('点击了功能卡片')">
				<view class="card-icon">🚀</view>
				<text class="card-title">快速开发</text>
				<text class="card-desc">一套代码，多端运行</text>
			</view>
			
			<view class="card" @click="showToast('点击了性能卡片')">
				<view class="card-icon">⚡</view>
				<text class="card-title">高性能</text>
				<text class="card-desc">原生渲染，流畅体验</text>
			</view>
			
			<view class="card" @click="showToast('点击了生态卡片')">
				<view class="card-icon">🌟</view>
				<text class="card-title">丰富生态</text>
				<text class="card-desc">插件丰富，社区活跃</text>
			</view>
		</view>

		<!-- 统计信息 -->
		<view class="stats-section">
			<view class="stat-item">
				<text class="stat-number">{{stats.apps}}</text>
				<text class="stat-label">应用数量</text>
			</view>
			<view class="stat-item">
				<text class="stat-number">{{stats.users}}</text>
				<text class="stat-label">开发者</text>
			</view>
			<view class="stat-item">
				<text class="stat-number">{{stats.platforms}}</text>
				<text class="stat-label">支持平台</text>
			</view>
		</view>

		<!-- 操作按钮 -->
		<view class="actions-section">
			<button class="btn-primary" @click="startDemo">开始体验</button>
			<button class="btn-secondary" @click="showAbout">了解更多</button>
		</view>

		<!-- 底部信息 -->
		<view class="footer">
			<text class="footer-text">© 2024 Uni-App 测试页面</text>
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				title: '你好',
				stats: {
					apps: '50万+',
					users: '100万+',
					platforms: '10+'
				}
			}
		},
		onLoad() {
			console.log('页面加载完成')
		},
		methods: {
			showToast(message) {
				uni.showToast({
					title: message,
					icon: 'success',
					duration: 2000
				})
			},
			startDemo() {
				uni.showModal({
					title: '开始体验',
					content: '这是一个演示页面，展示了 Uni-App 的基本功能',
					success: (res) => {
						if (res.confirm) {
							this.showToast('开始体验功能')
						}
					}
				})
			},
			showAbout() {
				uni.showActionSheet({
					itemList: ['查看文档', '社区论坛', 'GitHub'],
					success: (res) => {
						const actions = ['查看文档', '社区论坛', 'GitHub']
						this.showToast(`选择了：${actions[res.tapIndex]}`)
					}
				})
			}
		}
	}
</script>

<style>
	.container {
		min-height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		position: relative;
	}

	/* 头部样式 */
	.header {
		position: relative;
		padding: 80rpx 40rpx 60rpx;
		text-align: center;
	}

	.header-bg {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(255, 255, 255, 0.1);
		border-radius: 0 0 40rpx 40rpx;
	}

	.welcome-section {
		position: relative;
		z-index: 1;
	}

	.logo {
		width: 120rpx;
		height: 120rpx;
		margin-bottom: 30rpx;
		border-radius: 20rpx;
		box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
	}

	.welcome-title {
		display: block;
		font-size: 48rpx;
		font-weight: bold;
		color: #ffffff;
		margin-bottom: 16rpx;
		text-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.3);
	}

	.welcome-subtitle {
		display: block;
		font-size: 28rpx;
		color: rgba(255, 255, 255, 0.8);
	}

	/* 卡片区域 */
	.cards-section {
		padding: 40rpx;
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		gap: 20rpx;
	}

	.card {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 24rpx;
		padding: 40rpx 30rpx;
		width: calc(50% - 10rpx);
		text-align: center;
		box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
		backdrop-filter: blur(10rpx);
		transition: all 0.3s ease;
	}

	.card:active {
		transform: scale(0.95);
		box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.2);
	}

	.card-icon {
		font-size: 48rpx;
		margin-bottom: 20rpx;
	}

	.card-title {
		display: block;
		font-size: 32rpx;
		font-weight: bold;
		color: #333333;
		margin-bottom: 12rpx;
	}

	.card-desc {
		display: block;
		font-size: 24rpx;
		color: #666666;
		line-height: 1.4;
	}

	/* 统计区域 */
	.stats-section {
		background: rgba(255, 255, 255, 0.95);
		margin: 40rpx;
		border-radius: 24rpx;
		padding: 40rpx;
		display: flex;
		justify-content: space-around;
		box-shadow: 0 8rpx 32rpx rgba(0, 0, 0, 0.1);
	}

	.stat-item {
		text-align: center;
	}

	.stat-number {
		display: block;
		font-size: 40rpx;
		font-weight: bold;
		color: #667eea;
		margin-bottom: 8rpx;
	}

	.stat-label {
		display: block;
		font-size: 24rpx;
		color: #666666;
	}

	/* 按钮区域 */
	.actions-section {
		padding: 40rpx;
		display: flex;
		flex-direction: column;
		gap: 20rpx;
	}

	.btn-primary {
		background: linear-gradient(45deg, #667eea, #764ba2);
		color: #ffffff;
		border: none;
		border-radius: 50rpx;
		padding: 24rpx 0;
		font-size: 32rpx;
		font-weight: bold;
		box-shadow: 0 8rpx 24rpx rgba(102, 126, 234, 0.4);
		transition: all 0.3s ease;
	}

	.btn-primary:active {
		transform: translateY(2rpx);
		box-shadow: 0 4rpx 12rpx rgba(102, 126, 234, 0.6);
	}

	.btn-secondary {
		background: rgba(255, 255, 255, 0.9);
		color: #667eea;
		border: 2rpx solid #667eea;
		border-radius: 50rpx;
		padding: 24rpx 0;
		font-size: 32rpx;
		font-weight: bold;
		transition: all 0.3s ease;
	}

	.btn-secondary:active {
		background: #667eea;
		color: #ffffff;
	}

	/* 底部 */
	.footer {
		padding: 40rpx;
		text-align: center;
	}

	.footer-text {
		font-size: 24rpx;
		color: rgba(255, 255, 255, 0.6);
	}
</style>
