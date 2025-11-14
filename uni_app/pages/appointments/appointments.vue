<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">我的预约</text>
		</view>
		
		<view class="content">
			<!-- 候补入口 -->
			<view class="waitlist-entry" @click="navigateToWaitlist">
				<view class="entry-icon">⏳</view>
				<view class="entry-info">
					<text class="entry-title">我的候补</text>
					<text class="entry-desc">查看候补排队情况</text>
				</view>
				<text class="entry-arrow">></text>
			</view>
			
			<!-- 预约列表 -->
			<view class="appointment-list" v-if="hasAppointments" :key="'appointment-list-' + listKey">
				<view 
					class="appointment-item" 
					v-for="(appointment, index) in appointmentList" 
					:key="getAppointmentKey(appointment, index)"
					:class="{
						completed: isCompletedStatus(appointment.status),
						cancelled: isCancelledStatus(appointment.status)
					}"
					@click="navigateToDetail(getAppointmentId(appointment))"
				>
					<view class="appointment-header">
						<view class="department-info">
							<text class="department-name" :class="{ 'cancelled-line': isCancelledStatus(appointment.status) }">
								{{ appointment.departmentName || '未知科室' }}
							</text>
							<text class="doctor-name">{{ appointment.doctorName || '未知医生' }}</text>
						</view>
						<view class="status-badge-wrapper">
							<view class="status-badge cancelled-label" v-if="isCancelledStatus(appointment.status)">
								<text class="status-text">已取消</text>
							</view>
							<view class="status-badge" :class="{
								confirmed: isConfirmedStatus(appointment.status),
								completed: isCompletedStatus(appointment.status),
								cancelled: isCancelledStatus(appointment.status)
							}" v-else>
								<text class="status-text">{{ getStatusText(appointment.status) }}</text>
							</view>
						</view>
					</view>
					<view class="appointment-content">
						<view class="info-row">
							<text class="info-label">就诊时间：</text>
							<text class="info-value">{{ formatDateTime(appointment.scheduleTime) || '待定' }}</text>
						</view>
						<view class="info-row">
							<text class="info-label">预约时间：</text>
							<text class="info-value">{{ formatDateTime(appointment.appointmentTime) || '待定' }}</text>
						</view>
						<view class="info-row" v-if="isConfirmedStatus(appointment.status) && appointment.queueNumber">
							<text class="info-label">排队号：</text>
							<text class="info-value queue-number">第{{ appointment.queueNumber }}号</text>
						</view>
					</view>
					<view class="appointment-actions" v-if="!isCancelledStatus(appointment.status)">
						<!-- 已确认/已预约/待支付状态：显示取消预约按钮 -->
						<view class="action-btn cancel-btn" v-if="isConfirmedStatus(appointment.status)" @click.stop="handleCancel(getAppointmentId(appointment))">
							<text class="btn-text">取消预约</text>
						</view>
						<!-- 已完成状态：同时显示取消预约和查看详情按钮 -->
						<template v-if="isCompletedStatus(appointment.status)">
							<view class="action-btn cancel-btn" @click.stop="handleCancel(getAppointmentId(appointment))">
								<text class="btn-text">取消预约</text>
							</view>
							<view class="action-btn view-btn" @click.stop="navigateToDetail(getAppointmentId(appointment))">
								<text class="btn-text">查看详情</text>
							</view>
						</template>
				</view>
				<!-- 已取消状态：显示改约按钮 -->
				<view class="appointment-actions" v-if="isCancelledStatus(appointment.status)">
					<view 
						class="action-btn reschedule-btn" 
						:data-index="index"
						:data-appointment-id="getAppointmentId(appointment)"
						@click.stop="handleReschedule"
					>
						<text class="btn-text reschedule-text">改约</text>
					</view>
				</view>
				</view>
			</view>
			
			<!-- 空状态 -->
			<view class="empty-state" v-else-if="!loading">
				<text class="empty-icon">🩺</text>
				<text class="empty-text">暂无预约记录</text>
				<text class="empty-desc">快去预约挂号吧～</text>
				<view class="empty-btn" @click="navigateToDepartments">
					<text class="empty-btn-text">去挂号</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	import { getPatientAppointments, cancelAppointment } from '../../api/appointment.js'
	
	export default {
		data() {
			return {
				appointmentList: [],
				loading: false,
				listKey: 0 // 用于强制重新渲染
			}
		},
		computed: {
			hasAppointments() {
				const result = this.appointmentList && Array.isArray(this.appointmentList) && this.appointmentList.length > 0
				console.log('[hasAppointments computed] 计算结果:', result, '列表长度:', this.appointmentList?.length)
				return result
			}
		},
		onLoad() {
			this.loadAppointments()
		},
		onShow() {
			// 页面显示时刷新数据
			this.loadAppointments()
		},
		methods: {
			// 加载预约列表
			async loadAppointments() {
				this.loading = true
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					console.log('[loadAppointments] 患者信息:', patientInfo)
					
					if (!patientInfo || !patientInfo.id) {
						console.warn('[loadAppointments] 患者信息不完整')
						uni.showToast({
							title: '请先登录',
							icon: 'none'
						})
						this.loading = false
						return
					}
					
					console.log('[loadAppointments] 开始调用API，patientId:', patientInfo.id)
					
					// 调用 appointment API
					const response = await getPatientAppointments(patientInfo.id)
					
					console.log('[loadAppointments] API返回的完整响应:', response)
					console.log('[loadAppointments] 响应类型检查:', {
						isArray: Array.isArray(response),
						hasCode: response?.code,
						hasData: response?.data,
						responseKeys: response ? Object.keys(response) : [],
						responseType: typeof response
					})
					
					// 处理不同的响应格式
					let finalList = []
					
					if (response && response.code === '200' && response.data) {
						// 标准格式：{code: '200', data: [...]}
						finalList = Array.isArray(response.data) ? response.data : []
						console.log('[loadAppointments] 使用标准格式，预约列表长度:', finalList.length)
						console.log('[loadAppointments] 适配后的预约列表:', finalList)
					} else if (Array.isArray(response)) {
						// 直接返回数组（Spring Boot ResponseEntity直接返回数组）
						finalList = response
						console.log('[loadAppointments] 使用直接数组格式，预约列表长度:', finalList.length)
						console.log('[loadAppointments] 直接数组格式的预约列表:', finalList)
					} else if (response && response.data && Array.isArray(response.data)) {
						// 其他包装格式
						finalList = response.data
						console.log('[loadAppointments] 使用其他格式，预约列表长度:', finalList.length)
						console.log('[loadAppointments] 其他格式的预约列表:', finalList)
					} else {
						console.error('[loadAppointments] 响应格式异常，无法解析:', response)
						console.error('[loadAppointments] 响应详情:', JSON.stringify(response, null, 2))
						uni.showToast({
							title: response?.msg || response?.message || '加载失败，未找到预约数据',
							icon: 'none',
							duration: 3000
						})
						finalList = []
					}
					
					// 过滤掉 null 或无效的数据
					finalList = finalList.filter(item => item !== null && item !== undefined)
					
					// 验证数据完整性
					console.log('[loadAppointments] 过滤后的预约列表长度:', finalList.length)
					if (finalList.length > 0) {
						const firstAppointment = finalList[0]
						const firstAppointmentStr = JSON.parse(JSON.stringify(firstAppointment))
						console.log('[loadAppointments] 第一个预约数据（序列化）:', firstAppointmentStr)
						console.log('[loadAppointments] 第一个预约字段检查:', {
							id: firstAppointment.id,
							appointmentId: firstAppointment.appointmentId,
							departmentName: firstAppointment.departmentName,
							doctorName: firstAppointment.doctorName,
							status: firstAppointment.status,
							scheduleTime: firstAppointment.scheduleTime,
							appointmentTime: firstAppointment.appointmentTime,
							hasDepartmentName: !!firstAppointment.departmentName,
							hasDoctorName: !!firstAppointment.doctorName,
							departmentNameLength: firstAppointment.departmentName ? firstAppointment.departmentName.length : 0,
							doctorNameLength: firstAppointment.doctorName ? firstAppointment.doctorName.length : 0
						})
					}
					
					// 直接替换整个数组，确保 Vue 响应式更新
					// 直接赋值，在 Vue 2 中应该能触发响应式更新
					this.appointmentList = finalList
					
					// 更新列表 key 强制重新渲染
					this.listKey++
					
					// 验证赋值后的状态
					console.log('[loadAppointments] 赋值后的预约列表长度:', this.appointmentList.length)
					console.log('[loadAppointments] hasAppointments computed:', this.hasAppointments)
					console.log('[loadAppointments] 数组内容（序列化）:', JSON.parse(JSON.stringify(this.appointmentList)))
					
					// 立即检查模板条件
					const condition = this.appointmentList && this.appointmentList.length > 0
					console.log('[loadAppointments] 立即检查模板条件:', condition)
					console.log('[loadAppointments] this.appointmentList存在:', !!this.appointmentList)
					console.log('[loadAppointments] this.appointmentList.length:', this.appointmentList.length)
					console.log('[loadAppointments] computed hasAppointments:', this.hasAppointments)
					
					// 使用 nextTick 确保 DOM 更新
					this.$nextTick(() => {
						console.log('[loadAppointments] $nextTick 后的状态，列表长度:', this.appointmentList.length)
						console.log('[loadAppointments] $nextTick hasAppointments computed:', this.hasAppointments)
						console.log('[loadAppointments] $nextTick 模板条件检查 - appointmentList存在:', !!this.appointmentList)
						console.log('[loadAppointments] $nextTick 模板条件检查 - length > 0:', this.appointmentList.length > 0)
						console.log('[loadAppointments] $nextTick 模板条件检查 - 最终条件:', this.appointmentList && this.appointmentList.length > 0)
						
						// 再次检查数据
						if (this.appointmentList.length > 0) {
							const first = JSON.parse(JSON.stringify(this.appointmentList[0]))
							console.log('[loadAppointments] $nextTick 第一个预约:', first)
						console.log('[loadAppointments] $nextTick 第一个预约字段:', {
							id: first.id,
							appointmentId: first.appointmentId,
							departmentName: first.departmentName,
							doctorName: first.doctorName,
							status: first.status,
							isConfirmed: this.isConfirmedStatus(first.status),
							isPending: this.isPendingStatus(first.status),
							isCompleted: this.isCompletedStatus(first.status),
							isCancelled: this.isCancelledStatus(first.status)
						})
						}
						
						// 强制触发视图更新
						this.$forceUpdate()
						console.log('[loadAppointments] 已调用 $forceUpdate()')
					})
				} catch (error) {
					console.error('[loadAppointments] 加载预约列表失败:', error)
					console.error('[loadAppointments] 错误堆栈:', error.stack)
					uni.showToast({
						title: error.message || '加载失败，请重试',
						icon: 'none',
						duration: 3000
					})
					this.appointmentList = []
				} finally {
					this.loading = false
				}
			},
			
			// 获取状态文本（兼容大小写）
			getStatusText(status) {
				if (!status) return '未知'
				const statusLower = status.toLowerCase()
				const statusMap = {
					'confirmed': '已确认',
					'scheduled': '已确认',
					'completed': '已完成',
					'cancelled': '已取消',
					'pending': '待支付'
				}
				return statusMap[statusLower] || statusMap[status] || '未知'
			},
			
			// 判断是否为已确认状态（兼容大小写）
			// 包括：confirmed, scheduled, pending_payment（待支付状态也可以取消）
			isConfirmedStatus(status) {
				if (!status) {
					console.log('[isConfirmedStatus] status 为空')
					return false
				}
				const statusLower = status.toLowerCase()
				const result = statusLower === 'confirmed' || 
							   statusLower === 'scheduled' || 
							   statusLower === 'pending_payment' ||
							   statusLower === 'pending'
				console.log('[isConfirmedStatus] 状态:', status, '转换为:', statusLower, '结果:', result)
				return result
			},
			
			// 判断是否为已完成状态
			isCompletedStatus(status) {
				if (!status) return false
				return status.toLowerCase() === 'completed'
			},
			
			// 判断是否为已取消状态
			isCancelledStatus(status) {
				if (!status) return false
				return status.toLowerCase() === 'cancelled'
			},
			
			// 判断是否为待支付状态
			isPendingStatus(status) {
				if (!status) return false
				const statusLower = status.toLowerCase()
				return statusLower === 'pending' || statusLower === 'pending_payment'
			},
			
			// 获取状态样式类名（用于 :class）
			getStatusClassForBadge(status) {
				if (!status) return {}
				const statusLower = status.toLowerCase()
				const classes = {}
				if (statusLower === 'confirmed' || statusLower === 'scheduled') {
					classes.confirmed = true
				} else if (statusLower === 'completed') {
					classes.completed = true
				} else if (statusLower === 'cancelled') {
					classes.cancelled = true
				}
				return classes
			},
			
			// 格式化日期时间
			formatDateTime(dateString) {
				try {
					if (!dateString) return ''
					const date = new Date(dateString)
					// 检查日期是否有效
					if (isNaN(date.getTime())) {
						console.warn('无效的日期:', dateString)
						return ''
					}
					const month = date.getMonth() + 1
					const day = date.getDate()
					const hours = date.getHours().toString().padStart(2, '0')
					const minutes = date.getMinutes().toString().padStart(2, '0')
					return month + '月' + day + '日 ' + hours + ':' + minutes
				} catch (error) {
					console.error('格式化日期失败:', error, dateString)
					return ''
				}
			},
			
			// 获取预约的 key（用于 v-for）
			getAppointmentKey(appointment, index) {
				return appointment.id || appointment.appointmentId || `appointment-${index}`
			},
			
			// 获取预约的 ID
			getAppointmentId(appointment) {
				return appointment.id || appointment.appointmentId
			},
			
			// 获取预约的 class（用于 :class）
			getAppointmentClass(appointment) {
				const classes = {}
				if (this.isCompletedStatus(appointment.status)) {
					classes.completed = true
				}
				if (this.isCancelledStatus(appointment.status)) {
					classes.cancelled = true
				}
				return classes
			},
			
			// 获取取消线的 class
			getCancelledLineClass(appointment) {
				return this.isCancelledStatus(appointment.status) ? { 'cancelled-line': true } : {}
			},
			
		// 处理改约
		handleReschedule(e) {
			// 从事件对象中获取 data 属性
			const index = e.currentTarget.dataset.index
			const appointmentId = e.currentTarget.dataset.appointmentId
			
			// 通过索引或ID获取 appointment
			let appointment = null
			if (index !== undefined && index !== null && this.appointmentList[index]) {
				appointment = this.appointmentList[index]
			} else if (appointmentId) {
				appointment = this.appointmentList.find(apt => 
					(apt.id && apt.id == appointmentId) || 
					(apt.appointmentId && apt.appointmentId == appointmentId)
				)
			}
			
			// 检查 appointment 是否存在
			if (!appointment) {
				console.error('handleReschedule: appointment 为空', { 
					index, 
					appointmentId, 
					listLength: this.appointmentList.length,
					appointmentList: this.appointmentList
				})
				uni.showToast({
					title: '预约信息错误',
					icon: 'none'
				})
				return
			}
			
			console.log('handleReschedule: 预约信息', {
				appointmentId: appointment.appointmentId || appointment.id,
				departmentId: appointment.departmentId,
				departmentName: appointment.departmentName
			})
			
			// 保存科室信息到局部变量，避免回调中访问不到
			const departmentId = appointment.departmentId
			const departmentName = appointment.departmentName
			
			uni.showActionSheet({
				itemList: ['换科室', '换时间段', '换医生'],
				success: (res) => {
					if (res.tapIndex === 0) {
						// 换科室：跳转到科室选择页面
						this.navigateToDepartments()
					} else if (res.tapIndex === 1) {
						// 换时间段：同一医生，选择不同时间段
						if (departmentId && departmentName && appointment.doctorId) {
							// 获取当前预约的日期
							let scheduleDate = ''
							if (appointment.scheduleTime) {
								const date = new Date(appointment.scheduleTime)
								if (!isNaN(date.getTime())) {
									const year = date.getFullYear()
									const month = String(date.getMonth() + 1).padStart(2, '0')
									const day = String(date.getDate()).padStart(2, '0')
									scheduleDate = `${year}-${month}-${day}`
								}
							}
							
							// 跳转到排班页面，默认选中原医生，只显示该医生的时间段
							const params = {
								departmentId: departmentId,
								departmentName: departmentName,
								reschedule: 'true',
								rescheduleType: 'time', // 换时间段
								appointmentId: appointment.appointmentId || appointment.id,
								doctorId: appointment.doctorId
							}
							
							// 如果有日期信息，也传递过去
							if (scheduleDate) {
								params.scheduleDate = scheduleDate
							}
							
							const queryString = Object.keys(params)
								.map(key => `${key}=${encodeURIComponent(params[key])}`)
								.join('&')
							
							uni.navigateTo({
								url: `/pages/schedules/schedules?${queryString}`
							})
						} else {
							// 如果没有完整信息，跳转到排班页面显示所有选项
							this.navigateToRescheduleSchedules(departmentId, departmentName, appointment)
						}
					} else if (res.tapIndex === 2) {
						// 换医生：同一科室，可以选择不同医生和时间段
						if (departmentId && departmentName) {
							// 获取当前预约的日期
							let scheduleDate = ''
							if (appointment.scheduleTime) {
								const date = new Date(appointment.scheduleTime)
								if (!isNaN(date.getTime())) {
									const year = date.getFullYear()
									const month = String(date.getMonth() + 1).padStart(2, '0')
									const day = String(date.getDate()).padStart(2, '0')
									scheduleDate = `${year}-${month}-${day}`
								}
							}
							
							// 跳转到排班页面，显示该科室的所有医生和时间段
							const params = {
								departmentId: departmentId,
								departmentName: departmentName,
								reschedule: 'true',
								rescheduleType: 'doctor', // 换医生
								appointmentId: appointment.appointmentId || appointment.id
							}
							
							// 如果有日期信息，也传递过去
							if (scheduleDate) {
								params.scheduleDate = scheduleDate
							}
							
							const queryString = Object.keys(params)
								.map(key => `${key}=${encodeURIComponent(params[key])}`)
								.join('&')
							
							uni.navigateTo({
								url: `/pages/schedules/schedules?${queryString}`
							})
						} else {
							// 如果没有科室信息，提示并跳转到科室选择页面
							uni.showToast({
								title: '请先选择科室',
								icon: 'none'
							})
							setTimeout(() => {
								this.navigateToDepartments()
							}, 1500)
						}
					}
				}
			})
		},
		
		// 导航到改约排班页面（通用方法）
		navigateToRescheduleSchedules(departmentId, departmentName, appointment) {
			if (!departmentId || !departmentName) {
				uni.showToast({
					title: '请先选择科室',
					icon: 'none'
				})
				setTimeout(() => {
					this.navigateToDepartments()
				}, 1500)
				return
			}
			
			// 获取当前预约的日期
			let scheduleDate = ''
			if (appointment.scheduleTime) {
				const date = new Date(appointment.scheduleTime)
				if (!isNaN(date.getTime())) {
					const year = date.getFullYear()
					const month = String(date.getMonth() + 1).padStart(2, '0')
					const day = String(date.getDate()).padStart(2, '0')
					scheduleDate = `${year}-${month}-${day}`
				}
			}
			
			const params = {
				departmentId: departmentId,
				departmentName: departmentName,
				reschedule: 'true',
				appointmentId: appointment.appointmentId || appointment.id
			}
			
			if (scheduleDate) {
				params.scheduleDate = scheduleDate
			}
			
			const queryString = Object.keys(params)
				.map(key => `${key}=${encodeURIComponent(params[key])}`)
				.join('&')
			
			uni.navigateTo({
				url: `/pages/schedules/schedules?${queryString}`
			})
		},
		
		// 导航到科室列表
		navigateToDepartments() {
			uni.navigateTo({
				url: '/pages/departments/departments'
			})
		},
		
		// 导航到候补列表
		navigateToWaitlist() {
			uni.navigateTo({
				url: '/pages/waitlist/waitlist'
			})
		},
		
		// 导航到预约详情
		navigateToDetail(appointmentId) {
			if (!appointmentId) {
				console.warn('[navigateToDetail] appointmentId 为空')
				return
			}
			console.log('[navigateToDetail] 导航到预约详情，appointmentId:', appointmentId)
			uni.navigateTo({
				url: `/pages/appointment/detail?appointmentId=${appointmentId}`
			})
		},
		
		// 取消预约
		async handleCancel(appointmentId) {
				uni.showModal({
					title: '确认取消',
					content: '确定要取消这个预约吗？',
				success: async (res) => {
						if (res.confirm) {
						try {
							uni.showLoading({ title: '取消中...' })
							// 调用取消预约 API
							const response = await cancelAppointment(appointmentId)
							console.log('取消预约响应:', response)
							
							if (response && response.code === '200') {
								uni.showToast({
									title: '预约已取消',
									icon: 'success'
								})
								// 重新加载列表
								await this.loadAppointments()
							} else {
								uni.showToast({
									title: response?.msg || '取消失败',
									icon: 'none'
								})
							}
						} catch (error) {
							console.error('取消预约失败:', error)
							uni.showToast({
								title: '取消失败，请重试',
								icon: 'none'
							})
						} finally {
							uni.hideLoading()
						}
						}
					}
				})
			}
		}
	}
</script>

<style lang="scss">
	.container {
		min-height: 100vh;
		background-color: #f7fafc;
	}

	.page-header {
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		padding: 40rpx 30rpx 30rpx;
	}

	.page-title {
		font-size: 36rpx;
		font-weight: 700;
		color: #ffffff;
	}

	.content {
		padding: 40rpx 30rpx;
	}

	.waitlist-entry {
		background: linear-gradient(135deg, rgba(255, 165, 0, 0.1) 0%, rgba(255, 165, 0, 0.05) 100%);
		border: 2rpx solid rgba(255, 165, 0, 0.3);
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 30rpx;
		display: flex;
		align-items: center;
		transition: all 0.3s ease;
	}

	.waitlist-entry:active {
		transform: scale(0.98);
	}

	.entry-icon {
		font-size: 48rpx;
		margin-right: 20rpx;
	}

	.entry-info {
		flex: 1;
	}

	.entry-title {
		display: block;
		font-size: 28rpx;
		font-weight: 700;
		color: #1A202C;
		margin-bottom: 8rpx;
	}

	.entry-desc {
		display: block;
		font-size: 24rpx;
		color: #718096;
	}

	.entry-arrow {
		font-size: 32rpx;
		color: #A0AEC0;
		font-weight: bold;
	}

	.empty-state {
		text-align: center;
		padding: 120rpx 40rpx;
	}

	.empty-icon {
		display: block;
		font-size: 120rpx;
		margin-bottom: 30rpx;
		opacity: 0.5;
	}

	.empty-text {
		display: block;
		font-size: 32rpx;
		color: #718096;
		margin-bottom: 16rpx;
	}

	.empty-desc {
		display: block;
		font-size: 26rpx;
		color: #A0AEC0;
		margin-bottom: 24rpx;
	}
	
	.empty-btn {
		margin-top: 24rpx;
		padding: 16rpx 48rpx;
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		border-radius: 24rpx;
		display: inline-block;
	}
	
	.empty-btn-text {
		font-size: 28rpx;
		color: #ffffff;
		font-weight: 600;
	}

	.appointment-list {
		padding: 20rpx 0;
	}

	.appointment-item {
		background: #ffffff;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.appointment-item.completed {
		opacity: 0.7;
	}

	.appointment-item.cancelled {
		opacity: 0.6;
		background: #f7f7f7;
	}
	
	.department-name.cancelled-line {
		text-decoration: line-through;
		text-decoration-color: #DC2626;
		text-decoration-thickness: 2rpx;
	}
	
	.status-badge-wrapper {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 8rpx;
	}
	
	.status-badge.cancelled-label {
		background: #FEF2F2;
		color: #DC2626;
		border: 1rpx solid #FCA5A5;
	}

	.appointment-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 20rpx;
		padding-bottom: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.department-info {
		flex: 1;
	}

	.department-name {
		display: block;
		font-size: 32rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 8rpx;
	}

	.doctor-name {
		display: block;
		font-size: 26rpx;
		color: #718096;
	}

	.status-badge {
		padding: 8rpx 16rpx;
		border-radius: 20rpx;
		font-size: 22rpx;
	}

	.status-badge.confirmed {
		background: #E6FFFA;
		color: #38A2AC;
	}

	.status-badge.completed {
		background: #F0FDF4;
		color: #16A34A;
	}

	.status-badge.cancelled {
		background: #FEF2F2;
		color: #DC2626;
	}

	.status-text {
		font-size: 22rpx;
		font-weight: 600;
	}

	.appointment-content {
		margin-bottom: 20rpx;
	}

	.info-row {
		display: flex;
		align-items: center;
		margin-bottom: 12rpx;
	}

	.info-label {
		font-size: 26rpx;
		color: #718096;
		margin-right: 8rpx;
	}

	.info-value {
		font-size: 26rpx;
		color: #1A202C;
	}

	.queue-number {
		color: #4FD9C3;
		font-weight: 600;
	}

	.appointment-actions {
		padding-top: 20rpx;
		border-top: 1rpx solid #f0f0f0;
		display: flex;
		gap: 16rpx;
	}

	.action-btn {
		flex: 1;
		padding: 16rpx 32rpx;
		border-radius: 8rpx;
		text-align: center;
	}

	.cancel-btn {
		background: #FFF5F5;
		border: 1rpx solid #FED7D7;
	}

	.view-btn {
		background: #E6FFFA;
		border: 1rpx solid #7be6d8;
	}

	.view-btn .btn-text {
		color: #38A2AC;
	}

	.reschedule-btn {
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		border: none;
	}

	.reschedule-text {
		color: #ffffff;
		font-weight: 600;
	}

	.btn-text {
		font-size: 26rpx;
		color: #DC2626;
		font-weight: 600;
	}
</style>
