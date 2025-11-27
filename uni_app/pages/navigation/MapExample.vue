<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">地图使用示例</text>
		</view>
		
		<!-- 地图容器 -->
		<view class="map-container">
			<map
				:latitude="latitude"
				:longitude="longitude"
				:markers="markers"
				:polyline="polyline"
				:scale="scale"
				:show-location="true"
				:enable-zoom="true"
				:enable-scroll="true"
				class="map"
				@tap="onMapTap"
				@regionchange="onRegionChange"
			/>
		</view>
		
		<!-- 控制按钮 -->
		<view class="control-panel">
			<button class="control-btn" @click="getCurrentLocation">📍 获取当前位置</button>
			<button class="control-btn" @click="resetMap">🗺️ 重置地图</button>
			<button class="control-btn" @click="addMarker">➕ 添加标记</button>
		</view>
		
		<!-- 位置信息显示 -->
		<view class="info-panel">
			<view class="info-item">
				<text class="info-label">纬度：</text>
				<text class="info-value">{{ latitude.toFixed(6) }}</text>
			</view>
			<view class="info-item">
				<text class="info-label">经度：</text>
				<text class="info-value">{{ longitude.toFixed(6) }}</text>
			</view>
			<view class="info-item">
				<text class="info-label">缩放级别：</text>
				<text class="info-value">{{ scale }}</text>
			</view>
		</view>
		
		<!-- 使用说明 -->
		<view class="tip-panel">
			<text class="tip-title">💡 使用说明：</text>
			<text class="tip-text">1. 点击"获取当前位置"按钮，获取GPS位置</text>
			<text class="tip-text">2. 地图会自动定位到当前位置</text>
			<text class="tip-text">3. 使用双指缩放或拖动地图查看</text>
			<text class="tip-text">4. 点击地图可以添加标记点</text>
		</view>
	</view>
</template>

<script>
export default {
	data() {
		return {
			// 地图中心位置（默认：北京天安门）
			latitude: 39.908823,
			longitude: 116.397470,
			
			// 地图缩放级别
			scale: 16,
			
			// 标记点数组
			markers: [],
			
			// 路线数组
			polyline: [],
			
			// 标记点计数器
			markerId: 1
		}
	},
	
	onLoad() {
		// 页面加载时，尝试获取当前位置
		this.getCurrentLocation();
	},
	
	methods: {
		/**
		 * 获取当前位置
		 * 关键：使用 type: 'gcj02' 高德地图坐标系
		 */
		getCurrentLocation() {
			uni.showLoading({
				title: '定位中...'
			});
			
			uni.getLocation({
				type: 'gcj02',  // ✅ 必须使用 gcj02 坐标系（高德地图）
				altitude: false,
				geocode: false,
				success: (res) => {
					console.log('获取位置成功:', res);
					
					// 更新地图中心位置
					this.latitude = res.latitude;
					this.longitude = res.longitude;
					
					// 添加当前位置标记
					this.markers = [{
						id: this.markerId++,
						latitude: res.latitude,
						longitude: res.longitude,
						iconPath: '/static/images/location.png',  // 如果图标不存在，可以不设置
						width: 30,
						height: 30,
						callout: {
							content: '我的位置',
							color: '#333',
							fontSize: 14,
							borderRadius: 4,
							bgColor: '#fff',
							padding: 5,
							display: 'BYCLICK'  // 点击标记时显示
						}
					}];
					
					uni.hideLoading();
					uni.showToast({
						title: '定位成功',
						icon: 'success'
					});
				},
				fail: (err) => {
					console.error('获取位置失败:', err);
					uni.hideLoading();
					
					// 定位失败，使用默认位置
					uni.showModal({
						title: '定位失败',
						content: '无法获取您的位置，将使用默认位置。请检查是否开启了位置权限。',
						showCancel: false,
						success: () => {
							// 使用默认位置（北京天安门）
							this.resetMap();
						}
					});
				}
			});
		},
		
		/**
		 * 重置地图到默认位置
		 */
		resetMap() {
			this.latitude = 39.908823;
			this.longitude = 116.397470;
			this.scale = 16;
			this.markers = [];
			this.polyline = [];
			this.markerId = 1;
			
			uni.showToast({
				title: '地图已重置',
				icon: 'success'
			});
		},
		
		/**
		 * 添加标记点（在地图中心添加）
		 */
		addMarker() {
			const newMarker = {
				id: this.markerId++,
				latitude: this.latitude,
				longitude: this.longitude,
				width: 30,
				height: 30,
				callout: {
					content: `标记点 ${this.markerId - 1}`,
					color: '#333',
					fontSize: 14,
					borderRadius: 4,
					bgColor: '#fff',
					padding: 5,
					display: 'BYCLICK'
				}
			};
			
			this.markers.push(newMarker);
			
			uni.showToast({
				title: '已添加标记',
				icon: 'success'
			});
		},
		
		/**
		 * 地图点击事件
		 */
		onMapTap(e) {
			console.log('地图被点击:', e);
			// 可以在这里添加点击地图添加标记的功能
			// const { latitude, longitude } = e.detail;
			// this.addMarkerAt(latitude, longitude);
		},
		
		/**
		 * 地图区域变化事件
		 */
		onRegionChange(e) {
			if (e.type === 'end') {
				console.log('地图拖动/缩放结束');
			}
		}
	}
}
</script>

<style scoped>
.container {
	min-height: 100vh;
	background-color: #f5f5f5;
}

.page-header {
	padding: 30rpx 20rpx;
	background-color: #fff;
	border-bottom: 1rpx solid #e0e0e0;
}

.page-title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
}

.map-container {
	width: 100%;
	height: 500rpx;
	background-color: #e5e5e5;
}

.map {
	width: 100%;
	height: 100%;
}

.control-panel {
	display: flex;
	gap: 20rpx;
	padding: 30rpx;
	background-color: #fff;
	border-bottom: 1rpx solid #e0e0e0;
}

.control-btn {
	flex: 1;
	height: 80rpx;
	line-height: 80rpx;
	background-color: #007AFF;
	color: #fff;
	border-radius: 40rpx;
	font-size: 28rpx;
	border: none;
}

.control-btn:active {
	background-color: #0051d5;
}

.info-panel {
	background-color: #fff;
	padding: 30rpx;
	border-bottom: 1rpx solid #e0e0e0;
}

.info-item {
	display: flex;
	align-items: center;
	margin-bottom: 20rpx;
}

.info-item:last-child {
	margin-bottom: 0;
}

.info-label {
	font-size: 28rpx;
	color: #666;
	width: 200rpx;
}

.info-value {
	font-size: 28rpx;
	color: #333;
	font-weight: bold;
	flex: 1;
}

.tip-panel {
	background-color: #fff7e6;
	padding: 30rpx;
	margin: 20rpx;
	border-radius: 12rpx;
	border: 1rpx solid #ffd591;
}

.tip-title {
	display: block;
	font-size: 30rpx;
	font-weight: bold;
	color: #d46b08;
	margin-bottom: 20rpx;
}

.tip-text {
	display: block;
	font-size: 26rpx;
	color: #d46b08;
	line-height: 1.8;
	margin-bottom: 10rpx;
}

.tip-text:last-child {
	margin-bottom: 0;
}
</style>



