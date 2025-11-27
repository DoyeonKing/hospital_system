<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">院内导航</text>
		</view>
		
		<!-- 当前位置显示 -->
		<view class="current-location">
			<view class="location-info">
				<text class="location-label">当前入口：</text>
				<text class="location-name">医院正门</text>
			</view>
		</view>
		
		<!-- 搜索目的地 -->
		<view class="search-section">
			<input 
				type="text" 
				v-model="searchKeyword" 
				placeholder="搜索目的地..."
				@confirm="searchDestination"
			/>
			<button @click="searchDestination">搜索</button>
		</view>
		
		<!-- 搜索结果 -->
		<view class="search-results" v-if="searchResults.length > 0">
			<view 
				class="result-item" 
				v-for="item in searchResults" 
				:key="item.nodeId"
				@click="selectDestination(item)"
			>
				<text class="result-name">{{ item.nodeName }}</text>
				<text class="result-floor" v-if="item.floorLevel">F{{ item.floorLevel }}</text>
			</view>
		</view>
		
		<!-- 加载中 -->
		<view class="loading-container" v-if="loading">
			<text>正在规划路径...</text>
		</view>
		
		<!-- 查看地图按钮 -->
		<view class="map-button-section" v-if="route && !loading">
			<button class="map-btn" @click="viewMap">
				<text class="map-icon">🗺️</text>
				<text>查看地图导航</text>
			</button>
		</view>
		
		<!-- 路径信息 -->
		<view class="route-info" v-if="route && !loading">
			<view class="route-summary">
				<view class="summary-item">
					<text class="summary-label">总距离</text>
					<text class="summary-value">{{ route.totalDistance ? route.totalDistance.toFixed(1) : '--' }}米</text>
				</view>
				<view class="summary-item">
					<text class="summary-label">预计时间</text>
					<text class="summary-value">{{ route.formattedWalkTime || '--' }}</text>
				</view>
			</view>
			
			<!-- 路径节点列表 -->
			<view class="path-nodes" v-if="(route.nodes && route.nodes.length > 0) || (route.pathNodes && route.pathNodes.length > 0)">
				<view class="path-node" v-for="(node, index) in (route.nodes || route.pathNodes)" :key="node.nodeId">
					<view class="node-marker" :class="{'start': index === 0, 'end': index === (route.nodes || route.pathNodes).length - 1}">
						<text v-if="index === 0">起</text>
						<text v-else-if="index === (route.nodes || route.pathNodes).length - 1">终</text>
						<text v-else>{{ index }}</text>
					</view>
					<view class="node-info">
						<text class="node-name">{{ node.nodeName }}</text>
						<text class="node-floor" v-if="node.floorLevel">F{{ node.floorLevel }}</text>
					</view>
				</view>
			</view>
		</view>
		
		<!-- 导航指引 -->
		<view class="instructions" v-if="route && route.instructions && route.instructions.length > 0">
			<view class="instructions-title">导航指引</view>
			<view class="instruction-item" v-for="(instruction, index) in route.instructions" :key="index">
				<view class="instruction-step">{{ instruction.step }}</view>
				<view class="instruction-content">
					<text class="instruction-text">{{ instruction.instruction }}</text>
					<view class="instruction-detail" v-if="instruction.distance">
						<text>距离：{{ instruction.distance.toFixed(1) }}米</text>
						<text>时间：约{{ instruction.walkTime }}秒</text>
					</view>
				</view>
			</view>
		</view>
		
		<!-- 错误提示 -->
		<view class="error-container" v-if="error">
			<text class="error-text">{{ error }}</text>
			<button class="retry-btn" @click="loadRoute">重试</button>
		</view>
	</view>
</template>

<script>
import { getNavigationRoute, searchNodes, getRouteByAppointment } from '@/api/navigation.js'
import { getDoctorSchedule } from '@/api/schedule.js'

export default {
	data() {
		return {
			searchKeyword: '',
			searchResults: [],
			currentLocation: { nodeId: 'entrance', nodeName: '医院正门', floorLevel: '1' },
			destination: null,
			route: null,
			loading: false,
			error: null,
			appointmentId: null,
			departmentId: null,
			doctorId: null
		}
	},
	onLoad(options) {
		// 保存参数，在 onReady 中处理
		if (options.appointmentId) {
			this.appointmentId = options.appointmentId;
		} else if (options.departmentId) {
			this.departmentId = options.departmentId;
		} else if (options.doctorId) {
			this.doctorId = options.doctorId;
		}
	},
	onReady() {
		// 组件完全初始化后再调用方法
		if (this.appointmentId) {
			this.loadRouteByAppointment(this.appointmentId);
		} else if (this.departmentId) {
			this.loadDepartmentInfo(this.departmentId);
		} else if (this.doctorId) {
			this.loadDoctorConsultationRoom(this.doctorId);
		}
	},
	methods: {
		// 根据预约ID加载导航路线
		async loadRouteByAppointment(appointmentId) {
			this.loading = true;
			this.error = null;
			
			try {
				const response = await getRouteByAppointment(appointmentId);
				
				// 处理响应数据 - 可能是 BaseResponse 格式
				let routeData = response;
				if (response && response.data) {
					routeData = response.data;
				}
				
				if (routeData && ((routeData.nodes && routeData.nodes.length > 0) || (routeData.pathNodes && routeData.pathNodes.length > 0))) {
					this.route = routeData;
					
					// 设置目的地为路线的终点
					const pathNodes = routeData.nodes || routeData.pathNodes || [];
					if (pathNodes.length > 0) {
						const endNode = pathNodes[pathNodes.length - 1];
						if (!this.destination || this.destination.nodeId !== endNode.nodeId) {
							this.destination = {
								nodeId: endNode.nodeId,
								nodeName: endNode.nodeName,
								floorLevel: endNode.floorLevel
							};
							this.searchKeyword = endNode.nodeName;
						}
					}
					
					// 滚动到路线显示区域
					this.$nextTick(() => {
						uni.pageScrollTo({
							scrollTop: 200,
							duration: 300
						});
					});
				} else {
					this.error = '未找到导航路线，请手动搜索目的地';
					uni.showToast({
						title: '未找到导航路线',
						icon: 'none'
					});
				}
			} catch (err) {
				console.error('加载预约导航路线失败:', err);
				this.error = err.message || '加载导航路线失败，请稍后重试';
				uni.showToast({
					title: '加载导航路线失败',
					icon: 'none'
				});
			} finally {
				this.loading = false;
			}
		},
		
		// 加载科室信息
		async loadDepartmentInfo(departmentId) {
			try {
				// 这里添加获取科室信息的API调用
				// const response = await getDepartmentDetail(departmentId);
				// if (response && response.location) {
				//     this.destination = response.location;
				//     this.searchKeyword = response.name;
				//     this.calculateRoute();
				// }
			} catch (err) {
				console.error('加载科室信息失败:', err);
				uni.showToast({
					title: '加载科室信息失败',
					icon: 'none'
				});
			}
		},
		
		// 加载医生诊室信息
		async loadDoctorConsultationRoom(doctorId) {
			this.loading = true;
			try {
				// 获取医生排班信息
				const response = await getDoctorSchedule(doctorId);
				if (response && response.consultationRoom) {
					// 设置目的地为医生诊室
					this.destination = {
						nodeId: response.consultationRoom.nodeId,
						nodeName: response.consultationRoom.roomName || '医生诊室',
						floorLevel: response.consultationRoom.floorLevel
					};
					this.searchKeyword = response.doctorName + ' 诊室';
					// 计算路线
					this.calculateRoute();
				} else {
					uni.showToast({
						title: '未找到医生诊室信息',
						icon: 'none'
					});
				}
			} catch (err) {
				console.error('加载医生诊室信息失败:', err);
				uni.showToast({
					title: '加载医生诊室信息失败',
					icon: 'none'
				});
			} finally {
				this.loading = false;
			}
		},
		
		// 搜索目的地
		async searchDestination() {
			const keyword = this.searchKeyword.trim();
			if (!keyword) {
				uni.showToast({
					title: '请输入搜索关键词',
					icon: 'none'
				})
				return
			}
			
			console.log('🔍 开始搜索目的地:', keyword);
			this.loading = true
			this.searchResults = []
			this.error = null;
			
			try {
				const response = await searchNodes(keyword)
				console.log('🔍 搜索API响应:', response);
				
				// 处理响应数据 - 检查不同的响应格式
				let results = [];
				if (response) {
					// 如果 response 本身就是数组
					if (Array.isArray(response)) {
						results = response;
					}
					// 如果 response 有 data 属性且是数组
					else if (response.data && Array.isArray(response.data)) {
						results = response.data;
					}
					// 如果 response 有 data 属性，但 data 可能有 code 等包装
					else if (response.data && response.data.data && Array.isArray(response.data.data)) {
						results = response.data.data;
					}
					// BaseResponse 格式
					else if (response.code === 200 && Array.isArray(response.data)) {
						results = response.data;
					}
				}
				
				console.log('🔍 处理后的搜索结果:', results);
				this.searchResults = results;
				
				if (results.length === 0) {
					uni.showToast({
						title: '未找到相关地点',
						icon: 'none',
						duration: 2000
					});
				} else if (results.length === 1) {
					// 如果只找到一个结果，自动选择
					console.log('✅ 找到唯一结果，自动选择:', results[0]);
					this.selectDestination(results[0]);
				} else {
					uni.showToast({
						title: `找到 ${results.length} 个结果，请选择`,
						icon: 'none',
						duration: 2000
					});
				}
			} catch (err) {
				console.error('❌ 搜索失败:', err);
				console.error('错误详情:', err.response || err.message);
				this.error = err.message || '搜索失败，请稍后重试';
				uni.showToast({
					title: '搜索失败，请稍后重试',
					icon: 'none',
					duration: 2000
				});
			} finally {
				this.loading = false;
			}
		},
		
		// 选择目的地
		selectDestination(destination) {
			this.destination = destination;
			this.searchResults = [];
			this.searchKeyword = destination.nodeName;
			this.calculateRoute();
		},
		
		// 计算路线
		async calculateRoute() {
			if (!this.destination) {
				return;
			}
			
			this.loading = true;
			this.error = null;
			
			try {
				// 获取起点节点ID
				let startNodeId = this.currentLocation.nodeId;
				
				// 如果起点是字符串 'entrance'，需要先获取入口节点的真实ID
				if (typeof startNodeId === 'string' && startNodeId === 'entrance') {
					try {
						const { getEntranceNodes } = await import('@/api/navigation.js');
						const entrances = await getEntranceNodes();
						const entranceList = Array.isArray(entrances) ? entrances : (entrances?.data || []);
						if (entranceList.length > 0) {
							startNodeId = entranceList[0].nodeId;
							// 更新当前定位信息
							this.currentLocation = {
								nodeId: startNodeId,
								nodeName: entranceList[0].nodeName || '医院正门',
								floorLevel: entranceList[0].floorLevel || 1
							};
						} else {
							throw new Error('未找到入口节点');
						}
					} catch (err) {
						console.error('获取入口节点失败:', err);
						uni.showToast({
							title: '获取起点失败，请稍后重试',
							icon: 'none'
						});
						return;
					}
				}
				
				// 确保 startNodeId 是数字
				startNodeId = Number(startNodeId);
				if (isNaN(startNodeId)) {
					throw new Error('起点节点ID无效');
				}
				
				// 调用API获取导航路线
				const response = await getNavigationRoute(
					startNodeId,
					this.destination.nodeId,
					false // 是否优先无障碍通道
				);
				
				// 处理响应数据 - 可能是 BaseResponse 格式
				let routeData = response;
				if (response && response.data) {
					routeData = response.data;
				}
				
				if (routeData && ((routeData.nodes && routeData.nodes.length > 0) || (routeData.pathNodes && routeData.pathNodes.length > 0))) {
					this.route = routeData;
					
					// 滚动到路线显示区域
					this.$nextTick(() => {
						uni.pageScrollTo({
							scrollTop: 200,
							duration: 300
						});
					});
				} else {
					this.error = '获取导航路径失败，请稍后重试';
				}
			} catch (err) {
				console.error('获取导航路径失败:', err);
				this.error = err.message || '获取导航路径失败，请稍后重试';
				uni.showToast({
					title: '获取导航路径失败',
					icon: 'none'
				});
			} finally {
				this.loading = false;
			}
		},
		
		// 重新加载路线
		loadRoute() {
			if (this.destination) {
				this.calculateRoute();
			}
		},
		
		// 查看地图导航
		viewMap() {
			if (!this.destination) {
				uni.showToast({
					title: '请先选择目的地',
					icon: 'none'
				});
				return;
			}
			
			// 跳转到地图导航页面
			uni.navigateTo({
				url: `/pages/navigation/NavigationMain?targetNodeId=${this.destination.nodeId}`
			});
		}
	}
}
</script>

<style scoped>
.container {
	min-height: 100vh;
	background-color: #f5f5f5;
	padding: 20rpx;
}

.page-header {
	padding: 30rpx 20rpx;
	text-align: center;
}

.page-title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
}

.location-section, .search-section {
	background-color: #fff;
	border-radius: 12rpx;
	padding: 30rpx;
	margin-bottom: 20rpx;
	box-shadow: 0 2rpx 10rpx rgba(0, 0, 0, 0.05);
}

.scan-btn {
	background-color: #007AFF;
	color: #fff;
	height: 80rpx;
	line-height: 80rpx;
	border-radius: 40rpx;
	font-size: 28rpx;
	display: flex;
	align-items: center;
	justify-content: center;
}

.scan-icon {
	margin-right: 10rpx;
}

.scan-tip {
	display: block;
	text-align: center;
	font-size: 24rpx;
	color: #999;
	margin-top: 20rpx;
}

.current-location {
	background-color: #fff;
	border-radius: 12rpx;
	padding: 30rpx;
	margin-bottom: 20rpx;
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.location-info {
	flex: 1;
}

.location-label {
	font-size: 28rpx;
	color: #666;
}

.location-name {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
	margin: 0 10rpx;
}

.location-floor {
	font-size: 24rpx;
	color: #999;
	background-color: #f0f0f0;
	padding: 4rpx 12rpx;
	border-radius: 20rpx;
}

.rescan-btn {
	font-size: 24rpx;
	color: #007AFF;
	background-color: #fff;
	border: 1rpx solid #007AFF;
	height: 60rpx;
	line-height: 60rpx;
	padding: 0 20rpx;
	border-radius: 30rpx;
}

.search-section {
	display: flex;
}

.search-section input {
	flex: 1;
	height: 80rpx;
	background-color: #f5f5f5;
	border-radius: 40rpx 0 0 40rpx;
	padding: 0 30rpx;
	font-size: 28rpx;
}

.search-section button {
	width: 160rpx;
	height: 80rpx;
	line-height: 80rpx;
	background-color: #007AFF;
	color: #fff;
	border-radius: 0 40rpx 40rpx 0;
	font-size: 28rpx;
}

.search-results {
	background-color: #fff;
	border-radius: 12rpx;
	margin-bottom: 20rpx;
	overflow: hidden;
}

.result-item {
	padding: 30rpx;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-bottom: 1rpx solid #f0f0f0;
}

.result-item:active {
	background-color: #f9f9f9;
}

.result-name {
	font-size: 28rpx;
	color: #333;
}

.result-floor {
	font-size: 24rpx;
	color: #999;
	background-color: #f0f0f0;
	padding: 4rpx 12rpx;
	border-radius: 20rpx;
}

.loading-container, .error-container {
	text-align: center;
	padding: 40rpx 0;
}

.error-text {
	color: #ff4d4f;
	font-size: 28rpx;
	display: block;
	margin-bottom: 20rpx;
}

.retry-btn {
	display: inline-block;
	background-color: #007AFF;
	color: #fff;
	height: 70rpx;
	line-height: 70rpx;
	padding: 0 40rpx;
	border-radius: 35rpx;
	font-size: 28rpx;
}

.map-button-section {
	padding: 20rpx;
	margin-bottom: 20rpx;
}

.map-btn {
	width: 100%;
	height: 100rpx;
	background: linear-gradient(135deg, #4FD9C3 0%, #7be6d8 100%);
	color: #fff;
	border-radius: 50rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32rpx;
	font-weight: bold;
	box-shadow: 0 4rpx 20rpx rgba(79, 209, 197, 0.3);
}

.map-icon {
	font-size: 36rpx;
	margin-right: 10rpx;
}

.route-info {
	background-color: #fff;
	border-radius: 12rpx;
	padding: 30rpx;
	margin-bottom: 20rpx;
}

.route-summary {
	display: flex;
	justify-content: space-around;
	margin-bottom: 30rpx;
}

.summary-item {
	text-align: center;
}

.summary-label {
	display: block;
	font-size: 24rpx;
	color: #999;
	margin-bottom: 10rpx;
}

.summary-value {
	display: block;
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
}

.path-nodes {
	border-left: 2rpx solid #e0e0e0;
	margin-left: 30rpx;
	padding-left: 30rpx;
}

.path-node {
	display: flex;
	align-items: center;
	margin-bottom: 30rpx;
	position: relative;
}

.path-node:last-child {
	margin-bottom: 0;
}

.node-marker {
	width: 60rpx;
	height: 60rpx;
	border-radius: 50%;
	background-color: #007AFF;
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 24rpx;
	margin-right: 20rpx;
	flex-shrink: 0;
}

.node-marker.start {
	background-color: #52c41a;
}

.node-marker.end {
	background-color: #ff4d4f;
}

.node-info {
	flex: 1;
	background-color: #f9f9f9;
	border-radius: 8rpx;
	padding: 20rpx;
}

.node-name {
	display: block;
	font-size: 28rpx;
	color: #333;
	margin-bottom: 10rpx;
}

.node-floor {
	font-size: 24rpx;
	color: #999;
}

.instructions {
	background-color: #fff;
	border-radius: 12rpx;
	padding: 30rpx;
}

.instructions-title {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
	margin-bottom: 20rpx;
	padding-bottom: 20rpx;
	border-bottom: 1rpx solid #f0f0f0;
}

.instruction-item {
	display: flex;
	margin-bottom: 30rpx;
}

.instruction-item:last-child {
	margin-bottom: 0;
}

.instruction-step {
	width: 50rpx;
	height: 50rpx;
	border-radius: 50%;
	background-color: #007AFF;
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 24rpx;
	margin-right: 20rpx;
	flex-shrink: 0;
}

.instruction-content {
	flex: 1;
}

.instruction-text {
	display: block;
	font-size: 28rpx;
	color: #333;
	margin-bottom: 10rpx;
}

.instruction-detail {
	display: flex;
	justify-content: space-between;
	font-size: 24rpx;
	color: #999;
}
</style>
