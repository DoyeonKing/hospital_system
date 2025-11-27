<template>
	<view class="container">
		<view class="header">
			<text class="title">扫码定位</text>
		</view>

		<view class="scan-area">
			<text class="tip-text">请将二维码放入扫描框内</text>
			<!-- 扫码框（实际使用相机） -->
			<view class="scan-frame">
				<!-- 实际扫码需要使用相机，这里仅作UI展示 -->
				<image src="/static/scan-frame.png" class="scan-frame-img" mode="aspectFit" />
			</view>
		</view>

		<view class="hint-section">
			<text class="hint-title">扫码提示：</text>
			<text class="hint-content">
				请在医院内的关键位置找到二维码标识牌，扫描后即可自动定位到当前位置。
				二维码通常张贴在大厅、电梯口、楼梯口、诊室门口等位置。
			</text>
		</view>

		<view class="actions">
			<button class="primary-btn" @click="startScan">开始扫码</button>
			<button class="secondary-btn" @click="goToManualSelect">手动选择位置</button>
		</view>
	</view>
</template>

<script>
import { scanLocation } from '@/api/navigation.js'

export default {
	data() {
		return {
			scanning: false
		}
	},
	
	methods: {
		/**
		 * 开始扫码
		 */
		async startScan() {
			this.scanning = true;
			
			try {
				uni.scanCode({
					success: async (res) => {
						const qrCode = res.result;
						console.log('扫描到二维码:', qrCode);
						
						// 验证二维码格式：HOSPITAL_NODE_{nodeId}
						if (!qrCode.startsWith('HOSPITAL_NODE_')) {
							uni.showModal({
								title: '二维码无效',
								content: '请扫描医院内的定位二维码',
								showCancel: false
							});
							this.scanning = false;
							return;
						}
						
						// 调用后端接口获取节点信息
						try {
							const response = await scanLocation(qrCode);
							if (response && response.code === 200) {
								const node = response.data;
								
								// 返回导航页面，并传递当前位置节点ID
								uni.navigateBack({
									delta: 1,
									success: () => {
										// 通过事件总线或全局状态传递当前位置
										uni.$emit('locationScanned', {
											nodeId: node.nodeId,
											nodeName: node.nodeName,
											floorLevel: node.floorLevel
										});
									}
								});
							} else {
								throw new Error(response.message || '获取位置信息失败');
							}
						} catch (apiErr) {
							console.error('API调用失败:', apiErr);
							uni.showToast({
								title: '定位失败: ' + apiErr.message,
								icon: 'none'
							});
						}
					},
					fail: (err) => {
						console.error('扫码失败:', err);
						uni.showToast({
							title: '扫码失败，请重试',
							icon: 'none'
						});
					},
					complete: () => {
						this.scanning = false;
					}
				});
			} catch (err) {
				console.error('扫码错误:', err);
				this.scanning = false;
				uni.showToast({
					title: '扫码失败',
					icon: 'none'
				});
			}
		},
		
		/**
		 * 跳转到手动选择位置页面
		 */
		goToManualSelect() {
			uni.navigateTo({
				url: '/pages/navigation/LocationSelect'
			});
		}
	}
}
</script>

<style scoped>
.container {
	min-height: 100vh;
	background-color: #f5f5f5;
	padding: 40rpx;
}

.header {
	text-align: center;
	padding: 40rpx 0;
}

.title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
}

.scan-area {
	background-color: white;
	border-radius: 20rpx;
	padding: 60rpx 40rpx;
	margin-bottom: 40rpx;
	display: flex;
	flex-direction: column;
	align-items: center;
}

.tip-text {
	font-size: 28rpx;
	color: #666;
	margin-bottom: 40rpx;
}

.scan-frame {
	width: 500rpx;
	height: 500rpx;
	border: 4rpx dashed #007AFF;
	border-radius: 20rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	background-color: #f9f9f9;
}

.scan-frame-img {
	width: 100%;
	height: 100%;
}

.hint-section {
	background-color: white;
	border-radius: 20rpx;
	padding: 30rpx;
	margin-bottom: 40rpx;
}

.hint-title {
	display: block;
	font-size: 30rpx;
	font-weight: bold;
	color: #333;
	margin-bottom: 20rpx;
}

.hint-content {
	display: block;
	font-size: 26rpx;
	color: #666;
	line-height: 1.6;
}

.actions {
	display: flex;
	flex-direction: column;
	gap: 20rpx;
}

.primary-btn {
	width: 100%;
	height: 88rpx;
	line-height: 88rpx;
	background-color: #007AFF;
	color: white;
	border-radius: 44rpx;
	font-size: 32rpx;
}

.secondary-btn {
	width: 100%;
	height: 88rpx;
	line-height: 88rpx;
	background-color: white;
	color: #007AFF;
	border: 2rpx solid #007AFF;
	border-radius: 44rpx;
	font-size: 32rpx;
}
</style>



