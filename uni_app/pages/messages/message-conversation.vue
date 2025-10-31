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
			<view 
				class="message-bubble" 
				v-for="msg in conversation.messages" 
				:key="msg.id"
				:class="{ 'unread': !msg.isRead }"
			>
				<view class="message-time">{{ formatTime(msg.createTime) }}</view>
				<view class="message-content-wrapper">
					<view class="message-title">{{ msg.title }}</view>
					<text class="message-text">{{ msg.content }}</text>
				</view>
			</view>
		</scroll-view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				conversation: {},
				unreadCount: 0,
				scrollTop: 0
			}
		},
		onLoad(options) {
			// 从路由参数获取会话ID
			const senderId = options.senderId
			// 加载对话内容
			this.loadConversation(senderId)
		},
		onShow() {
			// 标记所有消息为已读
			this.markAllAsRead()
		},
		methods: {
			loadConversation(senderId) {
				// 从全局存储获取消息列表
				const allMessages = uni.getStorageSync('allMessages') || []
				
				// 筛选出该发送者的消息
				const messages = allMessages.filter(msg => msg.senderId === senderId)
				
				if (messages.length === 0) {
					uni.showToast({
						title: '暂无消息',
						icon: 'none'
					})
					return
				}
				
				this.conversation = {
					senderId: senderId,
					senderName: messages[0].senderName,
					messages: messages.sort((a, b) => new Date(a.createTime) - new Date(b.createTime))
				}
				
				this.unreadCount = messages.filter(msg => !msg.isRead).length
			},
			
			markAllAsRead() {
				// 将所有消息标记为已读
				if (this.conversation.messages) {
					this.conversation.messages.forEach(msg => {
						msg.isRead = true
					})
					this.unreadCount = 0
					// TODO: 调用API标记已读
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
	}
</style>

