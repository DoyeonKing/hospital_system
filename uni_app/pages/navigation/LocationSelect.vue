<template>
	<view class="container">
		<view class="header">
			<text class="title">选择当前位置</text>
		</view>

		<!-- 楼层切换 -->
		<view class="floor-selector">
			<scroll-view scroll-x class="floor-scroll">
				<view class="floor-tabs">
					<view
						v-for="floor in availableFloors"
						:key="floor"
						:class="['floor-tab', { active: currentFloor === floor }]"
						@click="selectFloor(floor)"
					>
						<text>{{ floor > 0 ? floor + 'F' : 'B' + Math.abs(floor) }}</text>
					</view>
				</view>
			</scroll-view>
		</view>

		<!-- 楼层平面图 -->
		<view class="map-container">
			<canvas
				canvas-id="locationCanvas"
				:style="{ width: canvasWidth + 'px', height: canvasHeight + 'px' }"
				class="location-canvas"
				@tap="onCanvasTap"
			/>
		</view>

		<!-- 位置列表 -->
		<view class="location-list-container">
			<text class="list-title">点击地图或选择位置：</text>
			<scroll-view scroll-y class="location-list">
				<view
					class="location-item"
					v-for="node in floorNodes"
					:key="node.nodeId"
					@click="selectNode(node)"
					:class="{ selected: selectedNode && selectedNode.nodeId === node.nodeId }"
				>
					<view class="location-icon">
						<text v-if="node.entry">🚪</text>
						<text v-else-if="node.elevator">🛗</text>
						<text v-else-if="node.stairs">🪜</text>
						<text v-else>📍</text>
					</view>
					<view class="location-info">
						<text class="location-name">{{ node.nodeName }}</text>
						<text class="location-type" v-if="node.nodeType">{{ node.nodeType }}</text>
					</view>
				</view>
			</scroll-view>
		</view>

		<!-- 确认按钮 -->
		<view class="confirm-section">
			<button 
				class="confirm-btn"
				:disabled="!selectedNode"
				@click="confirmLocation"
			>
				确认位置
			</button>
		</view>
	</view>
</template>

<script>
import { getFloorMap, searchNodes } from '@/api/navigation.js'

export default {
	data() {
		return {
			currentFloor: 1,
			availableFloors: [1, 2, 3],
			floorNodes: [],
			selectedNode: null,
			canvasWidth: 375,
			canvasHeight: 400,
			floorMapData: null
		}
	},
	
	onLoad(options) {
		if (options.currentFloor) {
			this.currentFloor = parseInt(options.currentFloor);
		}
		
		// 加载当前楼层数据
		this.loadFloorData();
	},
	
	methods: {
		/**
		 * 加载楼层数据（平面图和节点）
		 */
		async loadFloorData() {
			try {
				// 加载平面图
				const mapResponse = await getFloorMap('主楼', this.currentFloor);
				if (mapResponse && mapResponse.code === 200) {
					this.floorMapData = mapResponse.data;
					this.drawFloorMap();
				}
				
				// 加载该楼层的所有节点（通过搜索楼层名称）
				// 这里简化处理，实际应该有一个专门的API获取指定楼层的所有节点
				const nodesResponse = await searchNodes(`${this.currentFloor}楼`);
				if (nodesResponse && nodesResponse.code === 200) {
					// 过滤出当前楼层的节点
					this.floorNodes = (nodesResponse.data || []).filter(node => 
						node.floorLevel === this.currentFloor
					);
					
					// 绘制节点标记
					this.drawNodes();
				}
			} catch (err) {
				console.error('加载楼层数据失败:', err);
				uni.showToast({
					title: '加载数据失败',
					icon: 'none'
				});
			}
		},
		
		/**
		 * 选择楼层
		 */
		async selectFloor(floor) {
			if (this.currentFloor === floor) {
				return;
			}
			
			this.currentFloor = floor;
			this.selectedNode = null;
			await this.loadFloorData();
		},
		
		/**
		 * 绘制楼层平面图
		 */
		drawFloorMap() {
			if (!this.floorMapData || !this.floorMapData.mapImageUrl) {
				return;
			}
			
			const ctx = uni.createCanvasContext('locationCanvas', this);
			
			uni.getImageInfo({
				src: this.floorMapData.mapImageUrl,
				success: (res) => {
					this.canvasWidth = res.width;
					this.canvasHeight = res.height;
					
					ctx.drawImage(res.path, 0, 0, res.width, res.height);
					ctx.draw();
					
					// 绘制节点
					this.drawNodes();
				},
				fail: (err) => {
					console.error('加载平面图失败:', err);
				}
			});
		},
		
		/**
		 * 绘制节点标记
		 */
		drawNodes() {
			if (!this.floorNodes || this.floorNodes.length === 0) {
				return;
			}
			
			const ctx = uni.createCanvasContext('locationCanvas', this);
			
			this.floorNodes.forEach(node => {
				if (node.coordinate) {
					const x = node.coordinate.x;
					const y = node.coordinate.y;
					
					// 绘制节点标记
					ctx.setFillStyle(node.selected ? '#ff4d4f' : '#007AFF');
					ctx.beginPath();
					ctx.arc(x, y, 6, 0, 2 * Math.PI);
					ctx.fill();
					
					// 绘制节点名称
					ctx.setFillStyle('#333');
					ctx.setFontSize(12);
					ctx.fillText(node.nodeName, x + 10, y);
				}
			});
			
			ctx.draw();
		},
		
		/**
		 * Canvas点击事件（选择位置）
		 */
		onCanvasTap(e) {
			const x = e.detail.x;
			const y = e.detail.y;
			
			// 找到点击位置最近的节点
			let nearestNode = null;
			let minDistance = Infinity;
			
			this.floorNodes.forEach(node => {
				if (node.coordinate) {
					const dx = node.coordinate.x - x;
					const dy = node.coordinate.y - y;
					const distance = Math.sqrt(dx * dx + dy * dy);
					
					if (distance < minDistance && distance < 30) { // 30像素内视为点击
						minDistance = distance;
						nearestNode = node;
					}
				}
			});
			
			if (nearestNode) {
				this.selectNode(nearestNode);
			}
		},
		
		/**
		 * 选择节点
		 */
		selectNode(node) {
			this.selectedNode = node;
			// 重新绘制标记（高亮选中节点）
			this.drawFloorMap();
			this.drawNodes();
		},
		
		/**
		 * 确认位置
		 */
		confirmLocation() {
			if (!this.selectedNode) {
				uni.showToast({
					title: '请选择一个位置',
					icon: 'none'
				});
				return;
			}
			
			// 返回导航页面，传递选中的节点信息
			uni.navigateBack({
				delta: 1,
				success: () => {
					uni.$emit('locationSelected', {
						nodeId: this.selectedNode.nodeId,
						nodeName: this.selectedNode.nodeName,
						floorLevel: this.selectedNode.floorLevel
					});
				}
			});
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

.header {
	background-color: white;
	padding: 30rpx;
	text-align: center;
	border-bottom: 1rpx solid #e0e0e0;
}

.title {
	font-size: 36rpx;
	font-weight: bold;
	color: #333;
}

.floor-selector {
	background-color: white;
	padding: 20rpx 0;
	border-bottom: 1rpx solid #e0e0e0;
}

.floor-scroll {
	white-space: nowrap;
}

.floor-tabs {
	display: flex;
	padding: 0 20rpx;
	gap: 20rpx;
}

.floor-tab {
	padding: 15rpx 30rpx;
	border-radius: 30rpx;
	background-color: #f0f0f0;
	font-size: 28rpx;
	color: #666;
}

.floor-tab.active {
	background-color: #007AFF;
	color: white;
}

.map-container {
	flex: 1;
	background-color: white;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 20rpx;
	min-height: 400rpx;
}

.location-canvas {
	width: 100%;
	height: 100%;
	background-color: #f9f9f9;
}

.location-list-container {
	background-color: white;
	border-top: 1rpx solid #e0e0e0;
	padding: 30rpx;
	max-height: 400rpx;
}

.list-title {
	display: block;
	font-size: 28rpx;
	color: #666;
	margin-bottom: 20rpx;
}

.location-list {
	max-height: 300rpx;
}

.location-item {
	display: flex;
	align-items: center;
	padding: 25rpx;
	border-bottom: 1rpx solid #f0f0f0;
	border-radius: 12rpx;
	margin-bottom: 10rpx;
}

.location-item.selected {
	background-color: #e6f7ff;
	border: 2rpx solid #007AFF;
}

.location-icon {
	font-size: 40rpx;
	margin-right: 20rpx;
}

.location-info {
	flex: 1;
	display: flex;
	flex-direction: column;
}

.location-name {
	font-size: 30rpx;
	color: #333;
	margin-bottom: 5rpx;
}

.location-type {
	font-size: 24rpx;
	color: #999;
}

.confirm-section {
	padding: 30rpx;
	background-color: white;
	border-top: 1rpx solid #e0e0e0;
}

.confirm-btn {
	width: 100%;
	height: 88rpx;
	line-height: 88rpx;
	background-color: #007AFF;
	color: white;
	border-radius: 44rpx;
	font-size: 32rpx;
}

.confirm-btn[disabled] {
	background-color: #d9d9d9;
	color: #999;
}
</style>



