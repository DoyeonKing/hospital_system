<template>
	<view class="conversation-container">
		<!-- 对话头 -->
		<view class="conversation-header">
			<text class="sender-name">{{ conversation.senderName }}</text>
			<text class="unread-count" v-if="unreadCount > 0">{{ unreadCount }}条未读</text>
		</view>
		
		<!-- 消息列表 -->
		<scroll-view 
			class="messages-scroll" 
			scroll-y 
			:scroll-top="scrollTop"
			@scrolltolower="loadMoreMessages"
		>
			<!-- 有通知时显示 -->
			<view 
				class="message-bubble" 
				v-for="(notification, index) in conversation.messages" 
				:key="getNotificationKey(notification, index)"
				v-if="notification"
				:class="{ 'unread': notification && notification.status === 'unread', 'clickable': notification && isClickableNotification(notification) }"
				@click="handleNotificationClick(notification, index)"
			>
				<view class="message-time" v-if="notification">{{ formatTime(notification.sentAt || notification.createTime) }}</view>
				<view class="message-content-wrapper" v-if="notification">
					<view class="message-title" v-if="notification.title">{{ notification.title }}</view>
					<text class="message-text" v-if="notification.content">{{ notification.content }}</text>
					<!-- 候补通知显示操作提示 -->
					<view class="action-hint" v-if="notification && notification.type === 'waitlist_available'">
						<text class="hint-text">点击查看详情并支付</text>
					</view>
				</view>
			</view>
			
			<!-- 空状态 -->
			<view class="empty-state" v-if="conversation.messages.length === 0">
				<text class="empty-icon">📭</text>
				<text class="empty-text">暂无通知</text>
			</view>
		</scroll-view>
	</view>
</template>

<script>
	import { getUserNotifications, markAsRead, markAllAsRead } from '../../api/notification.js'
	
	export default {
		data() {
			return {
				conversation: {
					senderId: '',
					senderName: '',
					messages: []
				},
				unreadCount: 0,
				scrollTop: 0,
				notificationType: '' // 通知类型
			}
		},
		onLoad(options) {
			console.log('[消息详情] onLoad 参数:', options)
			console.log('[消息详情] options.senderId:', options.senderId)
			
			// 从路由参数获取通知类型（senderId实际上是通知类型）
			const senderId = options.senderId || ''
			console.log('[消息详情] senderId原始值:', senderId)
			
			const notificationType = decodeURIComponent(senderId)
			console.log('[消息详情] notificationType解码后:', notificationType)
			
			if (!notificationType) {
				console.error('[消息详情] notificationType为空')
				uni.showToast({
					title: '缺少消息类型参数',
					icon: 'none'
				})
				setTimeout(() => {
					uni.navigateBack()
				}, 1500)
				return
			}
			
			this.notificationType = notificationType
			// 加载对话内容
			this.loadConversation(notificationType)
		},
		onShow() {
			// 标记所有消息为已读
			this.markAllAsRead()
		},
		methods: {
			async loadConversation(notificationType) {
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					if (!patientInfo || !patientInfo.id) {
						uni.showToast({
							title: '请先登录',
							icon: 'none'
						})
						return
					}
					
					// 从全局存储获取通知列表，如果没有则调用API
					let allNotifications = uni.getStorageSync('allNotifications') || []
					
					// 如果存储中没有数据，调用API获取
					if (allNotifications.length === 0) {
						const notifications = await getUserNotifications(patientInfo.id, 'patient')
						if (Array.isArray(notifications)) {
							allNotifications = notifications
						} else if (notifications && notifications.data && Array.isArray(notifications.data)) {
							allNotifications = notifications.data
						}
						uni.setStorageSync('allNotifications', allNotifications)
					}
					
					// 筛选出该类型的通知，同时过滤掉无效的通知
					const notifications = allNotifications.filter(notif => {
						// 确保通知对象存在且有type属性
						if (!notif || !notif.type) {
							console.warn('[消息详情] 发现无效通知:', notif)
							return false
						}
						return notif.type === notificationType
					})
					
					if (notifications.length === 0) {
						uni.showToast({
							title: '暂无通知',
							icon: 'none'
						})
						this.conversation = {
							senderId: notificationType,
							senderName: this.getTypeName(notificationType),
							messages: []
						}
						return
					}
					
					// 按时间排序（最新的在前），再次过滤无效项
					const sortedNotifications = notifications
						.filter(notif => notif != null) // 再次确保没有null或undefined
						.sort((a, b) => {
							const timeA = new Date(a.sentAt || a.createTime || 0)
							const timeB = new Date(b.sentAt || b.createTime || 0)
							return timeB - timeA // 降序，最新的在前
						})
					
					this.conversation = {
						senderId: notificationType,
						senderName: this.getTypeName(notificationType),
						messages: sortedNotifications
					}
					
					this.unreadCount = notifications.filter(notif => notif.status === 'unread').length
				} catch (error) {
					console.error('加载通知详情失败:', error)
					uni.showToast({
						title: '加载失败，请重试',
						icon: 'none'
					})
				}
			},
			
			// 获取通知类型名称
			getTypeName(type) {
				const typeMap = {
					'payment_success': '支付通知',
					'appointment_success': '预约成功',
					'appointment_reminder': '预约提醒',
					'cancellation': '取消通知',
					'waitlist_available': '候补通知',
					'schedule_change': '排班变更',
					'system_notice': '系统通知'
				}
				return typeMap[type] || '系统通知'
			},
			
			// 获取通知的唯一key（小程序不支持表达式，需要使用方法）
			getNotificationKey(notification, index) {
				// 如果通知对象无效，返回索引
				if (!notification) {
					return `notification-${index}`
				}
				// 优先使用 notificationId，其次使用 id，最后使用索引
				return notification.notificationId || notification.id || `notification-${index}`
			},
			
			// 判断通知是否可点击
			isClickableNotification(notification) {
				if (!notification) {
					console.log('[消息详情] isClickableNotification: notification为空')
					return false
				}
				
				// 候补通知可点击：type为waitlist_available，且有相关ID
				const isWaitlistAvailable = notification.type === 'waitlist_available'
				const hasWaitlistId = notification.waitlistId != null || 
					(notification.relatedEntity === 'waitlist' && notification.relatedId != null)
				
				// 预约相关通知也可以点击（如果有appointmentId）
				// 注意：relatedId 可能是 0，所以不能直接用 || 判断，需要明确检查是否为 null/undefined
				const hasAppointmentId = notification.appointmentId != null || 
					(notification.relatedEntity === 'appointment' && notification.relatedId != null)
				const isAppointmentRelated = notification.type === 'payment_success' || 
											notification.type === 'appointment_success' ||
											notification.type === 'appointment_reminder' || 
											notification.type === 'cancellation'
				
				const result = (isWaitlistAvailable && hasWaitlistId) || (isAppointmentRelated && hasAppointmentId)
				
				console.log('[消息详情] ========== 判断通知是否可点击 ==========')
				console.log('[消息详情] 通知类型:', notification.type)
				console.log('[消息详情] relatedEntity:', notification.relatedEntity)
				console.log('[消息详情] relatedId:', notification.relatedId, ', 类型:', typeof notification.relatedId)
				console.log('[消息详情] appointmentId:', notification.appointmentId)
				console.log('[消息详情] waitlistId:', notification.waitlistId)
				console.log('[消息详情] isWaitlistAvailable:', isWaitlistAvailable)
				console.log('[消息详情] hasWaitlistId:', hasWaitlistId)
				console.log('[消息详情] isAppointmentRelated:', isAppointmentRelated)
				console.log('[消息详情] hasAppointmentId计算:', {
					'appointmentId存在': !!notification.appointmentId,
					'relatedEntity === appointment': notification.relatedEntity === 'appointment',
					'relatedId存在': !!notification.relatedId,
					'relatedId值': notification.relatedId,
					'最终hasAppointmentId': hasAppointmentId
				})
				console.log('[消息详情] 最终结果:', result)
				console.log('[消息详情] ==========================================')
				
				return result
			},
			
			// 处理通知点击
			handleNotificationClick(notification, index) {
				console.log('[消息详情] 点击通知 - notification:', notification, ', index:', index)
				
				// 如果 notification 为空，尝试从数组中获取
				if (!notification && index != null && this.conversation.messages) {
					console.log('[消息详情] notification为空，尝试从数组获取，index:', index)
					notification = this.conversation.messages[index]
					console.log('[消息详情] 从数组获取的notification:', notification)
				}
				
				if (!notification) {
					console.warn('[消息详情] 通知对象为空，无法处理点击')
					console.warn('[消息详情] conversation.messages:', this.conversation.messages)
					console.warn('[消息详情] index:', index)
					return
				}
				
				console.log('[消息详情] 通知详情:', {
					type: notification.type,
					relatedEntity: notification.relatedEntity,
					relatedId: notification.relatedId,
					waitlistId: notification.waitlistId,
					isClickable: this.isClickableNotification(notification),
					fullNotification: JSON.stringify(notification, null, 2)
				})
				
				if (!this.isClickableNotification(notification)) {
					console.log('[消息详情] 通知不可点击，忽略')
					console.log('[消息详情] 通知详情:', {
						type: notification.type,
						relatedEntity: notification.relatedEntity,
						relatedId: notification.relatedId
					})
					return
				}
				
				// 候补通知：跳转到候补详情页
				if (notification.type === 'waitlist_available') {
					// 优先使用 waitlistId，如果没有则使用 relatedId（当 relatedEntity 为 'waitlist' 时）
					const waitlistId = notification.waitlistId || (notification.relatedEntity === 'waitlist' ? notification.relatedId : null)
					
					if (waitlistId) {
						console.log('[消息详情] 跳转到候补详情页，waitlistId:', waitlistId)
						uni.navigateTo({
							url: `/pages/waitlist/waitlist-detail?waitlistId=${waitlistId}`,
							success: () => {
								console.log('[消息详情] 跳转成功')
								// 标记该通知为已读
								this.markNotificationAsRead(notification)
							},
							fail: (err) => {
								console.error('[消息详情] 跳转失败:', err)
								uni.showToast({
									title: '跳转失败',
									icon: 'none'
								})
							}
						})
					} else {
						console.warn('[消息详情] 候补通知缺少waitlistId')
						uni.showToast({
							title: '候补信息不完整',
							icon: 'none'
						})
					}
				}
				// 预约相关通知：跳转到预约详情页
				else if (notification.type === 'payment_success' || 
						 notification.type === 'appointment_success' ||
						 notification.type === 'appointment_reminder' || 
						 notification.type === 'cancellation') {
					// 优先使用 appointmentId，如果没有则使用 relatedId（当 relatedEntity 为 'appointment' 时）
					const appointmentId = notification.appointmentId || (notification.relatedEntity === 'appointment' ? notification.relatedId : null)
					
					console.log('[消息详情] 处理预约相关通知:', {
						type: notification.type,
						appointmentId: notification.appointmentId,
						relatedEntity: notification.relatedEntity,
						relatedId: notification.relatedId,
						finalAppointmentId: appointmentId
					})
					
					if (appointmentId) {
						console.log('[消息详情] 跳转到预约详情页，appointmentId:', appointmentId)
						const url = `/pages/appointment/detail?appointmentId=${appointmentId}`
						console.log('[消息详情] 跳转URL:', url)
						
						// 先标记为已读，避免跳转失败时通知状态不对
						this.markNotificationAsRead(notification)
						
						// 使用 setTimeout 延迟跳转，避免页面加载冲突
						setTimeout(() => {
							uni.navigateTo({
								url: url,
								success: () => {
									console.log('[消息详情] 跳转成功')
								},
								fail: (err) => {
									console.error('[消息详情] 跳转失败:', err)
									console.error('[消息详情] 错误详情:', JSON.stringify(err, null, 2))
									
									// 如果是超时错误，尝试使用 redirectTo
									if (err.errMsg && err.errMsg.includes('timeout')) {
										console.log('[消息详情] navigateTo超时，尝试使用redirectTo')
										uni.redirectTo({
											url: url,
											success: () => {
												console.log('[消息详情] redirectTo成功')
											},
											fail: (redirectErr) => {
												console.error('[消息详情] redirectTo也失败:', redirectErr)
												uni.showToast({
													title: '页面加载失败，请稍后重试',
													icon: 'none',
													duration: 3000
												})
											}
										})
									} else {
										uni.showToast({
											title: '跳转失败: ' + (err.errMsg || '未知错误'),
											icon: 'none',
											duration: 3000
										})
									}
								}
							})
						}, 100) // 延迟100ms，确保当前页面状态稳定
					} else {
						console.warn('[消息详情] 预约通知缺少appointmentId')
						console.warn('[消息详情] 通知详情:', {
							type: notification.type,
							appointmentId: notification.appointmentId,
							relatedEntity: notification.relatedEntity,
							relatedId: notification.relatedId
						})
						uni.showToast({
							title: '预约信息不完整',
							icon: 'none'
						})
					}
				} else {
					console.warn('[消息详情] 未知的通知类型，无法处理:', notification.type)
				}
			},
			
			// 标记单个通知为已读
			async markNotificationAsRead(notification) {
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					if (patientInfo && patientInfo.id && notification.notificationId) {
						await markAsRead(notification.notificationId)
						// 更新本地状态
						notification.status = 'read'
						this.unreadCount = Math.max(0, this.unreadCount - 1)
					}
				} catch (error) {
					console.error('标记通知为已读失败:', error)
				}
			},
			
			async markAllAsRead() {
				// 调用API标记该类型的所有通知为已读
				if (this.conversation.messages && this.conversation.messages.length > 0) {
					try {
						const patientInfo = uni.getStorageSync('patientInfo')
						if (patientInfo && patientInfo.id) {
							// 标记该类型的所有未读通知为已读
							const unreadNotifications = this.conversation.messages.filter(
								notif => notif.status === 'unread'
							)
							
							// 批量标记为已读
							for (const notification of unreadNotifications) {
								try {
									await markAsRead(notification.notificationId || notification.id)
									notification.status = 'read'
								} catch (error) {
									console.error('标记通知已读失败:', error)
								}
							}
							
							this.unreadCount = 0
							
							// 更新全局存储
							const allNotifications = uni.getStorageSync('allNotifications') || []
							allNotifications.forEach(notif => {
								if (notif.type === this.notificationType && notif.status === 'unread') {
									notif.status = 'read'
								}
							})
							uni.setStorageSync('allNotifications', allNotifications)
						}
					} catch (error) {
						console.error('标记已读失败:', error)
					}
				}
			},
			
			loadMoreMessages() {
				// TODO: 加载更多历史消息
			},
			
			formatTime(timeString) {
				if (!timeString) return ''
				const date = new Date(timeString)
				const now = new Date()
				const diff = now - date
				const days = Math.floor(diff / (1000 * 60 * 60 * 24))
				
				if (days === 0) {
					return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
				} else if (days === 1) {
					return '昨天'
				} else if (days < 7) {
					return `${days}天前`
				} else {
					return `${date.getMonth() + 1}月${date.getDate()}日`
				}
			}
		}
	}
</script>

<style lang="scss">
	.conversation-container {
		min-height: 100vh;
		background-color: #f7fafc;
		display: flex;
		flex-direction: column;
	}
	
	.conversation-header {
		background: #ffffff;
		padding: 30rpx;
		display: flex;
		justify-content: space-between;
		align-items: center;
		border-bottom: 1rpx solid #e2e8f0;
		box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.05);
	}
	
	.sender-name {
		font-size: 32rpx;
		font-weight: 600;
		color: #1A202C;
	}
	
	.unread-count {
		font-size: 24rpx;
		color: #FF6B6B;
		font-weight: 500;
	}
	
	.messages-scroll {
		flex: 1;
		padding: 30rpx;
	}
	
	.message-bubble {
		margin-bottom: 30rpx;
		padding: 24rpx;
		background: #ffffff;
		border-radius: 16rpx;
		box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.06);
	}
	
	.message-bubble.unread {
		background: linear-gradient(135deg, #ffffff 0%, #F0FDFA 100%);
		border-left: 4rpx solid $color-primary;
	}
	
	.message-bubble.clickable {
		cursor: pointer;
		transition: all 0.3s ease;
		
		&:active {
			transform: scale(0.98);
			box-shadow: 0 1rpx 4rpx rgba(0, 0, 0, 0.1);
		}
	}
	
	.action-hint {
		margin-top: 12rpx;
		padding: 12rpx;
		background: #FFF7E6;
		border-radius: 8rpx;
		border-left: 3rpx solid #FFA500;
	}
	
	.hint-text {
		font-size: 24rpx;
		color: #FF8C00;
		font-weight: 500;
	}
	
	.message-time {
		font-size: 22rpx;
		color: #A0AEC0;
		margin-bottom: 12rpx;
	}
	
	.message-content-wrapper {
		display: flex;
		flex-direction: column;
	}
	
	.message-title {
		font-size: 28rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 8rpx;
	}
	
	.message-text {
		font-size: 26rpx;
		color: #718096;
		line-height: 1.6;
		white-space: pre-wrap;
		word-break: break-word;
	}
	
	.empty-state {
		padding: 120rpx 40rpx;
		text-align: center;
	}
	
	.empty-icon {
		display: block;
		font-size: 120rpx;
		margin-bottom: 30rpx;
		opacity: 0.5;
	}
	
	.empty-text {
		display: block;
		font-size: 28rpx;
		color: #718096;
	}
</style>

