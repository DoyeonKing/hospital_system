<template>
	<view class="container">
		<!-- 导航状态栏 -->
		<view class="nav-status-bar">
			<text class="status-text">{{ navStatusText }}</text>
		</view>

		<!-- 地图容器 -->
		<view class="map-container">
			<!-- 室外地图：使用uni-app的map组件（高德地图） -->
			<map
				v-if="isOutdoorNavigation"
				:latitude="userLocation.latitude"
				:longitude="userLocation.longitude"
				:markers="outdoorMarkers"
				:polyline="outdoorPolyline"
				:scale="16"
				:show-location="true"
				:enable-zoom="true"
				:enable-scroll="true"
				:enable-rotate="false"
				class="outdoor-map"
				@tap="onMapTap"
				@regionchange="onRegionChange"
			/>

			<!-- 室内地图：使用Canvas绘制楼层平面图和路径 -->
			<view v-else class="indoor-map-container">
				<canvas
					canvas-id="floorCanvas"
					:style="{ width: canvasWidth + 'px', height: canvasHeight + 'px' }"
					class="floor-canvas"
					@tap="onCanvasTap"
				/>
				<!-- 楼层切换按钮 -->
				<view class="floor-switcher">
					<button 
						v-for="floor in availableFloors" 
						:key="floor"
						:class="['floor-btn', { active: currentFloor === floor }]"
						@click="switchFloor(floor)"
					>
						{{ floor > 0 ? floor + 'F' : 'B' + Math.abs(floor) }}
					</button>
				</view>
			</view>
		</view>

		<!-- 导航指引区域 -->
		<view class="instructions-panel">
			<view class="instructions-header">
				<text class="instructions-title">导航指引</text>
				<text class="distance-text" v-if="route">{{ route.totalDistance.toFixed(0) }}米</text>
			</view>
			
			<!-- 当前步骤指引 -->
			<view class="current-step" v-if="currentStep">
				<text class="step-text">{{ currentStep.instruction }}</text>
				<text class="step-distance" v-if="currentStep.distance">
					距离：{{ currentStep.distance.toFixed(0) }}米
				</text>
			</view>

			<!-- 跨楼层提示 -->
			<view class="floor-change-hint" v-if="showFloorChangeHint">
				<text class="hint-text">{{ floorChangeHint }}</text>
				<button class="arrived-btn" @click="confirmArrived">
					{{ confirmButtonText }}
				</button>
			</view>

			<!-- 路径步骤列表 -->
			<scroll-view scroll-y class="steps-list" v-if="route && route.instructions">
				<view 
					class="step-item"
					v-for="(instruction, index) in route.instructions"
					:key="index"
					:class="{ active: index === currentStepIndex }"
				>
					<view class="step-number">{{ instruction.step }}</view>
					<view class="step-content">
						<text class="step-instruction">{{ instruction.instruction }}</text>
						<text class="step-distance" v-if="instruction.distance">
							{{ instruction.distance.toFixed(0) }}米
						</text>
					</view>
				</view>
			</scroll-view>
		</view>

		<!-- 底部操作栏 -->
		<view class="bottom-actions">
			<!-- 扫码定位按钮 -->
			<button class="action-btn scan-btn" @click="openScanPage">
				<text class="btn-icon">📷</text>
				<text class="btn-text">扫码定位</text>
			</button>

			<!-- 手动选择位置按钮 -->
			<button class="action-btn select-btn" @click="openLocationSelectPage">
				<text class="btn-icon">📍</text>
				<text class="btn-text">选择位置</text>
			</button>

			<!-- 开始导航按钮（室外导航时显示） -->
			<button 
				v-if="isOutdoorNavigation && targetLocation"
				class="action-btn navigate-btn"
				@click="startOutdoorNavigation"
			>
				<text class="btn-text">开始导航</text>
			</button>
		</view>
	</view>
</template>

<script>
import { 
	getNavigationRoute, 
	searchNodes, 
	getRouteByAppointment,
	scanLocation,
	getFloorMap,
	getEntranceNodes
} from '@/api/navigation.js'

export default {
	data() {
		return {
			// 导航状态
			isOutdoorNavigation: false,
			navStatusText: '正在定位...',
			
			// 用户位置
			userLocation: {
				latitude: 39.908823,
				longitude: 116.397470
			},
			
			// 目标位置
			targetLocation: null,
			targetNodeId: null,
			hospitalLocation: {
				latitude: 39.908823,  // 医院位置（示例坐标，需要替换为实际医院坐标）
				longitude: 116.397470,
				name: '医院'
			},
			
			// 室外地图标记和路线
			outdoorMarkers: [],
			outdoorPolyline: [],
			locationUpdateTimer: null,  // 位置更新定时器
			
			// 室内地图相关
			currentFloor: 1,
			availableFloors: [],
			canvasWidth: 375,
			canvasHeight: 500,
			floorMapImage: null,
			floorMapData: null,
			
			// 路径和指引
			route: null,
			currentStepIndex: 0,
			currentStep: null,
			showFloorChangeHint: false,
			floorChangeHint: '',
			confirmButtonText: '',
			nextFloor: null,
			
			// 加载状态
			loading: false
		}
	},
	
	onLoad(options) {
		// 获取用户GPS位置
		this.initUserLocation();
		
		// 如果从预约页面跳转过来
		if (options.appointmentId) {
			this.loadRouteByAppointment(options.appointmentId);
		}
		
		// 如果指定了目标节点
		if (options.targetNodeId) {
			this.targetNodeId = parseInt(options.targetNodeId);
			this.startIndoorNavigation();
		}
	},
	
	onUnload() {
		// 页面卸载时，停止位置更新
		this.stopLocationUpdate();
	},
	
	methods: {
		/**
		 * 初始化用户位置（GPS定位）
		 */
		async initUserLocation() {
			try {
				// 先请求位置权限
				uni.authorize({
					scope: 'scope.userLocation',
					success: () => {
						this.getCurrentLocation();
					},
					fail: () => {
						// 用户拒绝了授权，提示手动开启
						uni.showModal({
							title: '需要位置权限',
							content: '导航功能需要获取您的位置信息，请在设置中开启位置权限',
							showCancel: false,
							confirmText: '知道了'
						});
					}
				});
			} catch (err) {
				console.error('请求位置权限错误:', err);
				// 直接尝试获取位置（某些平台可能不需要显式授权）
				this.getCurrentLocation();
			}
		},
		
		/**
		 * 获取当前位置
		 */
		getCurrentLocation() {
			uni.getLocation({
				type: 'gcj02',  // 使用高德地图坐标系（GCJ-02）
				altitude: false,  // 不需要海拔信息
				geocode: false,  // 不需要地址解析
				success: (res) => {
					console.log('获取位置成功:', res);
					this.userLocation = {
						latitude: res.latitude,
						longitude: res.longitude
					};
					
					// 更新地图标记
					this.updateOutdoorMarkers();
					
					// 判断是否在医院内，决定使用室外还是室内导航
					this.checkLocationType();
					
					// 开始定期更新位置（室外导航时）
					if (this.isOutdoorNavigation) {
						this.startLocationUpdate();
					}
				},
				fail: (err) => {
					console.error('获取位置失败:', err);
					uni.showToast({
						title: '定位失败，请检查定位权限或手动选择位置',
						icon: 'none',
						duration: 2000
					});
					
					// 定位失败时，使用默认位置（医院位置）
					this.userLocation = {
						latitude: this.hospitalLocation.latitude,
						longitude: this.hospitalLocation.longitude
					};
					this.updateOutdoorMarkers();
				}
			});
		},
		
		/**
		 * 更新室外地图标记点
		 */
		updateOutdoorMarkers() {
			this.outdoorMarkers = [
				// 用户位置标记
				{
					id: 1,
					latitude: this.userLocation.latitude,
					longitude: this.userLocation.longitude,
					iconPath: '/static/images/location-user.png',  // 需要提供用户位置图标
					width: 30,
					height: 30,
					callout: {
						content: '我的位置',
						color: '#333',
						fontSize: 14,
						borderRadius: 4,
						bgColor: '#fff',
						padding: 5,
						display: 'BYCLICK'
					}
				}
			];
			
			// 如果有目标位置，添加目标标记
			if (this.targetLocation) {
				this.outdoorMarkers.push({
					id: 2,
					latitude: this.targetLocation.latitude,
					longitude: this.targetLocation.longitude,
					iconPath: '/static/images/location-target.png',  // 需要提供目标位置图标
					width: 30,
					height: 30,
					callout: {
						content: this.targetLocation.name || '目标位置',
						color: '#333',
						fontSize: 14,
						borderRadius: 4,
						bgColor: '#fff',
						padding: 5,
						display: 'BYCLICK'
					}
				});
				
				// 添加医院入口标记（如果没有目标位置）
			} else {
				this.outdoorMarkers.push({
					id: 3,
					latitude: this.hospitalLocation.latitude,
					longitude: this.hospitalLocation.longitude,
					iconPath: '/static/images/location-hospital.png',  // 需要提供医院位置图标
					width: 40,
					height: 40,
					callout: {
						content: this.hospitalLocation.name,
						color: '#333',
						fontSize: 16,
						borderRadius: 4,
						bgColor: '#fff',
						padding: 8,
						display: 'BYCLICK'
					}
				});
			}
		},
		
		/**
		 * 开始定期更新位置（室外导航时）
		 */
		startLocationUpdate() {
			// 清除之前的定时器
			if (this.locationUpdateTimer) {
				clearInterval(this.locationUpdateTimer);
			}
			
			// 每30秒更新一次位置
			this.locationUpdateTimer = setInterval(() => {
				if (this.isOutdoorNavigation) {
					this.getCurrentLocation();
				} else {
					// 切换到室内导航时，停止位置更新
					this.stopLocationUpdate();
				}
			}, 30000);
		},
		
		/**
		 * 停止位置更新
		 */
		stopLocationUpdate() {
			if (this.locationUpdateTimer) {
				clearInterval(this.locationUpdateTimer);
				this.locationUpdateTimer = null;
			}
		},
		
		/**
		 * 检查当前位置类型（室外/室内）
		 * 根据距离医院的距离判断是否在医院内
		 */
		async checkLocationType() {
			const distance = this.calculateDistance(
				this.userLocation.latitude,
				this.userLocation.longitude,
				this.hospitalLocation.latitude,
				this.hospitalLocation.longitude
			);
			
			// 如果距离医院小于50米，认为是室内导航
			if (distance < 50) {
				this.isOutdoorNavigation = false;
				this.navStatusText = '您在医院内，请扫码或选择位置开始室内导航';
				this.stopLocationUpdate();
			} else {
				this.isOutdoorNavigation = true;
				this.navStatusText = '正在规划室外导航路线...';
			}
		},
		
		/**
		 * 计算两点之间的距离（米）
		 * 使用 Haversine 公式
		 */
		calculateDistance(lat1, lon1, lat2, lon2) {
			const R = 6371000; // 地球半径（米）
			const dLat = (lat2 - lat1) * Math.PI / 180;
			const dLon = (lon2 - lon1) * Math.PI / 180;
			const a = 
				Math.sin(dLat / 2) * Math.sin(dLat / 2) +
				Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
				Math.sin(dLon / 2) * Math.sin(dLon / 2);
			const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
			return R * c;
		},
		
		/**
		 * 根据预约ID加载导航路径
		 */
		async loadRouteByAppointment(appointmentId) {
			this.loading = true;
			try {
				const response = await getRouteByAppointment(appointmentId);
				if (response && response.code === 200) {
					const info = response.data;
					
					// 如果有经纬度坐标，先进行室外导航
					if (info.latitude && info.longitude) {
						this.targetLocation = {
							latitude: info.latitude,
							longitude: info.longitude,
							name: info.locationName
						};
						this.targetNodeId = info.mapNodeId;
						this.isOutdoorNavigation = true;
						this.startOutdoorNavigation();
					} else if (info.mapNodeId) {
						// 只有室内节点，直接进入室内导航
						this.targetNodeId = info.mapNodeId;
						this.startIndoorNavigation();
					}
				}
			} catch (err) {
				console.error('加载导航信息失败:', err);
				uni.showToast({
					title: '加载导航信息失败',
					icon: 'none'
				});
			} finally {
				this.loading = false;
			}
		},
		
		/**
		 * 开始室外导航（使用高德地图）
		 */
		startOutdoorNavigation() {
			if (!this.targetLocation) {
				// 如果没有目标位置，导航到医院入口
				this.navigateToHospital();
				return;
			}
			
			// 计算路线（在地图上显示）
			this.updateOutdoorRoute();
			
			// 使用uni.openLocation打开系统地图应用进行导航（可选）
			// 用户可以选择使用系统地图导航，或者在当前页面查看路线
			uni.showActionSheet({
				itemList: ['使用系统地图导航', '在当前页面查看路线'],
				success: (res) => {
					if (res.tapIndex === 0) {
						// 使用系统地图导航
						uni.openLocation({
							latitude: this.targetLocation.latitude,
							longitude: this.targetLocation.longitude,
							name: this.targetLocation.name || '目标位置',
							address: '',  // 地址信息
							scale: 18,
							success: () => {
								this.navStatusText = '已打开地图导航';
								// 提示用户到达后切换到室内导航
								setTimeout(() => {
									this.showArrivalHint();
								}, 3000);
							},
							fail: (err) => {
								console.error('打开地图失败:', err);
								uni.showToast({
									title: '打开地图失败，将在当前页面显示路线',
									icon: 'none'
								});
								this.updateOutdoorRoute();
							}
						});
					} else {
						// 在当前页面查看路线
						this.updateOutdoorRoute();
					}
				}
			});
		},
		
		/**
		 * 导航到医院入口
		 */
		navigateToHospital() {
			this.targetLocation = {
				latitude: this.hospitalLocation.latitude,
				longitude: this.hospitalLocation.longitude,
				name: this.hospitalLocation.name
			};
			this.updateOutdoorMarkers();
			this.updateOutdoorRoute();
		},
		
		/**
		 * 更新室外地图路线
		 */
		updateOutdoorRoute() {
			if (!this.userLocation || !this.targetLocation) {
				return;
			}
			
			// 更新标记点
			this.updateOutdoorMarkers();
			
			// 绘制路线（使用polyline）
			this.outdoorPolyline = [{
				points: [
					{
						latitude: this.userLocation.latitude,
						longitude: this.userLocation.longitude
					},
					{
						latitude: this.targetLocation.latitude,
						longitude: this.targetLocation.longitude
					}
				],
				color: '#007AFF',  // 路线颜色
				width: 5,  // 路线宽度
				arrowLine: true  // 显示路线方向箭头
			}];
			
			this.navStatusText = '正在导航中...';
			
			// 计算距离和预计时间
			const distance = this.calculateDistance(
				this.userLocation.latitude,
				this.userLocation.longitude,
				this.targetLocation.latitude,
				this.targetLocation.longitude
			);
			
			// 如果是导航到医院，提示到达后切换到室内导航
			if (distance < 100) {
				setTimeout(() => {
					this.showArrivalHint();
				}, 2000);
			}
		},
		
		/**
		 * 显示到达医院提示
		 */
		showArrivalHint() {
			uni.showModal({
				title: '到达医院',
				content: '您已到达医院，请切换到室内导航模式',
				confirmText: '开始室内导航',
				cancelText: '稍后',
				success: (res) => {
					if (res.confirm) {
						this.switchToIndoorNavigation();
					}
				}
			});
		},
		
		/**
		 * 切换到室内导航
		 */
		async switchToIndoorNavigation() {
			if (!this.targetNodeId) {
				uni.showToast({
					title: '未设置目标位置',
					icon: 'none'
				});
				return;
			}
			
			this.isOutdoorNavigation = false;
			this.navStatusText = '室内导航模式';
			
			// 获取默认入口节点作为起点
			try {
				const entrancesResponse = await getEntranceNodes();
				if (entrancesResponse && entrancesResponse.data && entrancesResponse.data.length > 0) {
					const entrance = entrancesResponse.data[0];
					this.currentLocationNodeId = entrance.nodeId;
					this.currentFloor = entrance.floorLevel || 1;
					
					// 加载当前楼层平面图
					await this.loadFloorMap(this.currentFloor);
					
					// 规划路径
					await this.planIndoorRoute(entrance.nodeId, this.targetNodeId);
				} else {
					// 如果没有入口节点，提示用户手动选择位置
					this.showSelectLocationHint();
				}
			} catch (err) {
				console.error('切换室内导航失败:', err);
				this.showSelectLocationHint();
			}
		},
		
		/**
		 * 显示选择位置提示
		 */
		showSelectLocationHint() {
			uni.showModal({
				title: '请选择当前位置',
				content: '请扫码或手动选择您的当前位置，以开始室内导航',
				showCancel: false,
				success: () => {
					// 不自动打开选择页面，让用户主动点击按钮
				}
			});
		},
		
		/**
		 * 开始室内导航
		 */
		async startIndoorNavigation() {
			this.isOutdoorNavigation = false;
			this.navStatusText = '室内导航模式';
			
			// 获取当前位置（如果已有）
			if (!this.currentLocationNodeId) {
				// 提示用户选择当前位置
				this.showSelectLocationHint();
				return;
			}
			
			// 加载楼层平面图
			await this.loadFloorMap(this.currentFloor);
			
			// 规划路径
			if (this.targetNodeId) {
				await this.planIndoorRoute(this.currentLocationNodeId, this.targetNodeId);
			}
		},
		
		/**
		 * 规划室内路径
		 */
		async planIndoorRoute(startNodeId, endNodeId) {
			this.loading = true;
			this.navStatusText = '正在规划路径...';
			
			try {
				const response = await getNavigationRoute(startNodeId, endNodeId, false);
				if (response && response.code === 200) {
					this.route = response.data;
					this.currentStepIndex = 0;
					this.updateCurrentStep();
					
					// 检查是否需要跨楼层
					if (this.route.requiresFloorChange && this.route.crossFloorHints) {
						const firstHint = this.route.crossFloorHints[0];
						this.showFloorChangeHint = true;
						this.floorChangeHint = firstHint.hint;
						this.nextFloor = firstHint.toFloor;
						this.confirmButtonText = `我已到达${firstHint.toFloor}楼`;
					}
					
					// 绘制路径到Canvas
					this.drawIndoorPath();
					
					this.navStatusText = '导航进行中';
				} else {
					throw new Error(response.message || '路径规划失败');
				}
			} catch (err) {
				console.error('路径规划失败:', err);
				uni.showToast({
					title: '路径规划失败: ' + err.message,
					icon: 'none'
				});
			} finally {
				this.loading = false;
			}
		},
		
		/**
		 * 更新当前步骤
		 */
		updateCurrentStep() {
			if (this.route && this.route.instructions && this.route.instructions.length > 0) {
				this.currentStep = this.route.instructions[this.currentStepIndex];
			}
		},
		
		/**
		 * 加载楼层平面图
		 */
		async loadFloorMap(floorLevel) {
			try {
				const response = await getFloorMap('主楼', floorLevel);
				if (response && response.code === 200) {
					this.floorMapData = response.data;
					this.currentFloor = floorLevel;
					
					// 加载图片到Canvas
					this.drawFloorMap();
				}
			} catch (err) {
				console.error('加载楼层平面图失败:', err);
				uni.showToast({
					title: '加载平面图失败',
					icon: 'none'
				});
			}
		},
		
		/**
		 * 绘制楼层平面图底图
		 */
		drawFloorMap() {
			const ctx = uni.createCanvasContext('floorCanvas', this);
			
			if (this.floorMapData && this.floorMapData.mapImageUrl) {
				// 加载图片
				uni.getImageInfo({
					src: this.floorMapData.mapImageUrl,
					success: (res) => {
						// 计算Canvas尺寸
						this.canvasWidth = res.width;
						this.canvasHeight = res.height;
						
						// 绘制图片
						ctx.drawImage(res.path, 0, 0, res.width, res.height);
						ctx.draw();
						
						// 绘制路径（如果有）
						if (this.route) {
							this.drawIndoorPath();
						}
					},
					fail: (err) => {
						console.error('加载平面图图片失败:', err);
					}
				});
			}
		},
		
		/**
		 * 在Canvas上绘制导航路径
		 */
		drawIndoorPath() {
			if (!this.route || !this.route.pathSegments) {
				return;
			}
			
			const ctx = uni.createCanvasContext('floorCanvas', this);
			
			// 先重新绘制底图
			this.drawFloorMap();
			
			// 绘制路径线条（高亮显示）
			ctx.setStrokeStyle('#007AFF');
			ctx.setLineWidth(4);
			ctx.beginPath();
			
			// 绘制路径节点
			if (this.route.nodes && this.route.nodes.length > 0) {
				this.route.nodes.forEach((node, index) => {
					if (node.floorLevel === this.currentFloor && node.coordinate) {
						const x = node.coordinate.x;
						const y = node.coordinate.y;
						
						if (index === 0) {
							ctx.moveTo(x, y);
							// 绘制起点标记
							ctx.setFillStyle('#52c41a');
							ctx.beginPath();
							ctx.arc(x, y, 8, 0, 2 * Math.PI);
							ctx.fill();
						} else if (index === this.route.nodes.length - 1) {
							// 绘制终点标记
							ctx.setFillStyle('#ff4d4f');
							ctx.beginPath();
							ctx.arc(x, y, 8, 0, 2 * Math.PI);
							ctx.fill();
						} else {
							ctx.lineTo(x, y);
							// 绘制中间节点
							ctx.setFillStyle('#007AFF');
							ctx.beginPath();
							ctx.arc(x, y, 5, 0, 2 * Math.PI);
							ctx.fill();
							ctx.moveTo(x, y);
						}
					}
				});
			}
			
			// 绘制路径线段
			if (this.route.pathSegments) {
				this.route.pathSegments.forEach(segment => {
					// 根据path_points绘制路径（如果有）
					if (segment.pathPoints && segment.pathPoints.length > 0) {
						segment.pathPoints.forEach((point, index) => {
							if (index === 0) {
								ctx.moveTo(point.x, point.y);
							} else {
								ctx.lineTo(point.x, point.y);
							}
						});
					}
				});
			}
			
			ctx.stroke();
			ctx.draw();
		},
		
		/**
		 * 切换楼层
		 */
		async switchFloor(floorLevel) {
			if (this.currentFloor === floorLevel) {
				return;
			}
			
			this.currentFloor = floorLevel;
			await this.loadFloorMap(floorLevel);
			
			// 如果当前有路径，重新绘制
			if (this.route) {
				this.drawIndoorPath();
			}
		},
		
		/**
		 * 确认已到达指定楼层
		 */
		async confirmArrived() {
			if (this.nextFloor) {
				// 切换到下一楼层
				await this.switchFloor(this.nextFloor);
				
				// 重新规划路径（从当前楼层的起点到目标）
				const currentNode = this.route.nodes[this.currentStepIndex];
				if (currentNode && this.targetNodeId) {
					await this.planIndoorRoute(currentNode.nodeId, this.targetNodeId);
				}
				
				this.showFloorChangeHint = false;
			}
		},
		
		/**
		 * 打开扫码页面
		 */
		openScanPage() {
			uni.navigateTo({
				url: '/pages/navigation/ScanCode'
			});
		},
		
		/**
		 * 打开位置选择页面
		 */
		openLocationSelectPage() {
			uni.navigateTo({
				url: `/pages/navigation/LocationSelect?currentFloor=${this.currentFloor}`
			});
		},
		
		/**
		 * 地图点击事件
		 */
		onMapTap(e) {
			// 可以添加地图点击交互
		},
		
		/**
		 * 地图区域变化事件
		 */
		onRegionChange(e) {
			// 地图拖动或缩放时的回调
			if (e.type === 'end') {
				// 地图拖动结束
			}
		},
		
		/**
		 * Canvas点击事件
		 */
		onCanvasTap(e) {
			// 可以添加Canvas点击交互
		}
	}
}
</script>

<style scoped>
.container {
	min-height: 100vh;
	background-color: #f5f5f5;
	display: flex;
	flex-direction: column;
}

.nav-status-bar {
	background-color: #4FD9C3;
	color: white;
	padding: 20rpx;
	text-align: center;
}

.status-text {
	font-size: 28rpx;
	font-weight: bold;
}

.map-container {
	flex: 1;
	position: relative;
	background-color: #e5e5e5;
}

.outdoor-map {
	width: 100%;
	height: 100%;
}

.indoor-map-container {
	width: 100%;
	height: 100%;
	position: relative;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
}

.floor-canvas {
	width: 100%;
	height: 100%;
	background-color: #fff;
}

.floor-switcher {
	position: absolute;
	top: 20rpx;
	right: 20rpx;
	display: flex;
	flex-direction: column;
	gap: 10rpx;
}

.floor-btn {
	width: 80rpx;
	height: 80rpx;
	border-radius: 50%;
	background-color: rgba(255, 255, 255, 0.9);
	border: 2rpx solid #007AFF;
	font-size: 24rpx;
}

.floor-btn.active {
	background-color: #007AFF;
	color: white;
}

.instructions-panel {
	background-color: white;
	border-top: 1rpx solid #e0e0e0;
	padding: 30rpx;
	max-height: 400rpx;
}

.instructions-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 20rpx;
}

.instructions-title {
	font-size: 32rpx;
	font-weight: bold;
	color: #333;
}

.distance-text {
	font-size: 28rpx;
	color: #007AFF;
	font-weight: bold;
}

.current-step {
	background-color: #f0f8ff;
	padding: 30rpx;
	border-radius: 12rpx;
	margin-bottom: 20rpx;
}

.step-text {
	display: block;
	font-size: 30rpx;
	color: #333;
	margin-bottom: 10rpx;
}

.step-distance {
	font-size: 24rpx;
	color: #999;
}

.floor-change-hint {
	background-color: #fff7e6;
	padding: 30rpx;
	border-radius: 12rpx;
	margin-bottom: 20rpx;
	border: 2rpx solid #ffa940;
}

.hint-text {
	display: block;
	font-size: 28rpx;
	color: #d46b08;
	margin-bottom: 20rpx;
}

.arrived-btn {
	width: 100%;
	height: 80rpx;
	line-height: 80rpx;
	background-color: #ffa940;
	color: white;
	border-radius: 40rpx;
	font-size: 28rpx;
}

.steps-list {
	max-height: 300rpx;
}

.step-item {
	display: flex;
	align-items: center;
	padding: 20rpx 0;
	border-bottom: 1rpx solid #f0f0f0;
}

.step-item.active {
	background-color: #e6f7ff;
}

.step-number {
	width: 60rpx;
	height: 60rpx;
	border-radius: 50%;
	background-color: #007AFF;
	color: white;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 24rpx;
	margin-right: 20rpx;
}

.step-content {
	flex: 1;
}

.step-instruction {
	display: block;
	font-size: 28rpx;
	color: #333;
	margin-bottom: 5rpx;
}

.bottom-actions {
	display: flex;
	gap: 20rpx;
	padding: 30rpx;
	background-color: white;
	border-top: 1rpx solid #e0e0e0;
}

.action-btn {
	flex: 1;
	height: 88rpx;
	border-radius: 44rpx;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28rpx;
}

.scan-btn {
	background-color: #007AFF;
	color: white;
}

.select-btn {
	background-color: #52c41a;
	color: white;
}

.navigate-btn {
	background-color: #ff4d4f;
	color: white;
}

.btn-icon {
	margin-right: 10rpx;
	font-size: 32rpx;
}
</style>

