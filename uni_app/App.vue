<script>
	export default {
		waitlistCheckTimer: null, // 候补检查定时器
		waitlistCheckRetryCount: 0, // 连续失败次数
		maxRetryCount: 3, // 最大连续失败次数，超过后延长检查间隔
		
		onLaunch: function() {
			console.log('App Launch')
			// 启动候补通知监听
			this.startWaitlistNotificationCheck()
		},
		onShow: function() {
			console.log('App Show')
			// 应用显示时启动候补通知监听
			this.startWaitlistNotificationCheck()
		},
		onHide: function() {
			console.log('App Hide')
			// 应用隐藏时停止候补通知监听（可选）
			// this.stopWaitlistNotificationCheck()
		},
		methods: {
			// 启动候补通知检查
			startWaitlistNotificationCheck() {
				// 清除旧的定时器
				if (this.waitlistCheckTimer) {
					clearInterval(this.waitlistCheckTimer)
				}
				
				// 重置失败计数
				this.waitlistCheckRetryCount = 0
				
				// 每30秒检查一次候补通知
				this.waitlistCheckTimer = setInterval(() => {
					this.checkWaitlistNotifications()
				}, 30000)
				
				// 立即检查一次
				this.checkWaitlistNotifications()
			},
			
			// 停止候补通知检查
			stopWaitlistNotificationCheck() {
				if (this.waitlistCheckTimer) {
					clearInterval(this.waitlistCheckTimer)
					this.waitlistCheckTimer = null
				}
			},
			
			// 检查候补通知
			async checkWaitlistNotifications() {
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					if (!patientInfo || !patientInfo.id) {
						return
					}
					
					// 检查Token是否存在
					const token = uni.getStorageSync('patientToken')
					if (!token) {
						// 没有Token，停止检查
						this.stopWaitlistNotificationCheck()
						return
					}
					
					// 动态导入 API
					const { getPatientWaitlist } = await import('./api/appointment.js')
					
					// 获取候补列表（使用静默模式，不显示错误提示，设置较短的超时时间）
					// 后台检查不应该阻塞太久，设置10秒超时
					const waitlistResponse = await getPatientWaitlist(patientInfo.id, {
						silentError: true, // 静默错误，不显示toast
						timeout: 10000, // 10秒超时（后台检查不需要等太久）
						showLoading: false // 不显示加载提示
					})
					
					// 请求成功，重置失败计数
					this.waitlistCheckRetryCount = 0
					
					let waitlistList = []
					if (waitlistResponse && waitlistResponse.code === '200' && waitlistResponse.data) {
						waitlistList = Array.isArray(waitlistResponse.data) ? waitlistResponse.data : []
					} else if (Array.isArray(waitlistResponse)) {
						waitlistList = waitlistResponse
					}
					
					// 查找 notified 状态的候补（已通知但未支付）
					const notifiedWaitlists = waitlistList.filter(w => {
						const status = (w.status || '').toLowerCase()
						return status === 'notified'
					})
					
					// 如果有已通知的候补，显示弹窗提醒
					if (notifiedWaitlists.length > 0) {
						// 检查是否已经显示过提醒（避免重复提醒）
						const lastRemindTime = uni.getStorageSync('lastWaitlistRemindTime')
						const now = Date.now()
						
						// 如果上次提醒时间超过5分钟，或者没有记录，则显示提醒
						if (!lastRemindTime || (now - lastRemindTime) > 5 * 60 * 1000) {
							this.showWaitlistNotification(notifiedWaitlists[0])
							uni.setStorageSync('lastWaitlistRemindTime', now)
						}
					}
				} catch (error) {
					// 处理403错误（权限不足，可能是Token过期或无效）
					if (error.statusCode === 403 || (error.data && error.data.status === 403)) {
						console.warn('候补通知检查失败：权限不足（403），可能Token已过期')
						// 停止检查，避免重复请求
						this.stopWaitlistNotificationCheck()
						return
					}
					
					// 处理401错误（未授权，Token无效）
					if (error.statusCode === 401 || (error.data && error.data.status === 401)) {
						console.warn('候补通知检查失败：未授权（401），Token无效')
						// 停止检查，避免重复请求
						this.stopWaitlistNotificationCheck()
						return
					}
					
					// 静默处理其他错误，只记录日志
					this.waitlistCheckRetryCount++
					
					// 如果连续失败次数过多，延长检查间隔
					if (this.waitlistCheckRetryCount >= this.maxRetryCount) {
						console.warn(`候补通知检查连续失败${this.waitlistCheckRetryCount}次，延长检查间隔`)
						
						// 清除当前定时器
						if (this.waitlistCheckTimer) {
							clearInterval(this.waitlistCheckTimer)
						}
						
						// 延长到2分钟检查一次
						this.waitlistCheckTimer = setInterval(() => {
							this.checkWaitlistNotifications()
						}, 120000)
						
						// 重置失败计数，避免重复延长
						this.waitlistCheckRetryCount = 0
					}
					
					// 只在开发环境或首次失败时记录详细错误
					if (this.waitlistCheckRetryCount === 1) {
						console.warn('检查候补通知失败（后台静默）:', error.statusCode || error.errMsg || error)
					}
				}
			},
			
			// 显示候补通知弹窗
			showWaitlistNotification(waitlist) {
				const waitlistId = waitlist.id || waitlist.waitlistId
				const departmentName = waitlist.departmentName || '科室'
				const doctorName = waitlist.doctorName || '医生'
				
				uni.showModal({
					title: '🔔 候补通知',
					content: `您有候补号源可用！\n${departmentName} - ${doctorName}\n请在15分钟内完成支付`,
					confirmText: '立即支付',
					cancelText: '稍后',
					success: (res) => {
						if (res.confirm) {
							// 跳转到候补详情页
							uni.navigateTo({
								url: `/pages/waitlist/waitlist-detail?waitlistId=${waitlistId}`
							})
						}
					}
				})
			}
		}
	}
</script>

<style>
	/*每个页面公共css */
</style>
