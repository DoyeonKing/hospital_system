/**
 * 模拟数据文件
 * 用于演示页面功能，实际开发中应删除此文件
 */

// 模拟今日可预约数据
export const mockTodaySchedules = [
	{
		id: 1,
		departmentId: 1,
		departmentName: '内科',
		availableSlots: 15
	},
	{
		id: 2,
		departmentId: 2,
		departmentName: '外科',
		availableSlots: 8
	},
	{
		id: 3,
		departmentId: 3,
		departmentName: '儿科',
		availableSlots: 12
	},
	{
		id: 4,
		departmentId: 4,
		departmentName: '妇科',
		availableSlots: 6
	}
]

// 模拟即将就诊预约数据
export const mockUpcomingAppointment = {
	id: 1,
	scheduleTime: new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString(), // 12小时后
	departmentName: '内科',
	doctorName: '张医生',
	queueNumber: 5
}

// 模拟热门科室数据
export const mockPopularDepartments = [
	{ id: 1, name: '内科' },
	{ id: 2, name: '外科' },
	{ id: 3, name: '儿科' },
	{ id: 4, name: '妇科' },
	{ id: 5, name: '眼科' },
	{ id: 6, name: '耳鼻喉科' },
	{ id: 7, name: '皮肤科' },
	{ id: 8, name: '口腔科' }
]

// 模拟患者信息
export const mockPatientInfo = {
	id: 1,
	name: '张三',
	identifier: '2021001001'
}

// 模拟消息数据（按发送者分组）
export const mockMessages = [
	{
		id: 1,
		senderId: 'system',
		senderName: '系统通知',
		type: 'system',
		title: '系统维护通知',
		content: '系统维护通知：系统将于今晚22:00-24:00进行维护升级',
		createTime: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
		isRead: true
	},
	{
		id: 2,
		senderId: 'hospital',
		senderName: '医院公告',
		type: 'notice',
		title: '春节期间医院门诊时间调整通知',
		content: '春节期间医院门诊时间调整通知：1月24日-1月30日门诊时间调整为上午8:00-12:00，下午停诊',
		createTime: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
		isRead: false
	},
	{
		id: 3,
		senderId: 'hospital',
		senderName: '医院公告',
		type: 'notice',
		title: '冬季健康提醒',
		content: '冬季来临，请注意保暖，如有不适请及时就医。',
		createTime: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
		isRead: false
	},
	{
		id: 4,
		senderId: 'appointment',
		senderName: '预约中心',
		type: 'appointment',
		title: '预约成功提醒',
		content: '您的预约已成功，就诊时间：2024年1月15日 09:30，科室：内科，医生：张医生',
		createTime: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
		isRead: false
	},
	{
		id: 5,
		senderId: 'appointment',
		senderName: '预约中心',
		type: 'reminder',
		title: '就诊提醒',
		content: '您有预约即将到期，请提前15分钟到达医院',
		createTime: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
		isRead: false
	},
	{
		id: 6,
		senderId: 'cancel',
		senderName: '停诊通知',
		type: 'cancel',
		title: '内科医生停诊通知',
		content: '内科医生今日临时停诊，已自动取消预约，请重新挂号',
		createTime: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
		isRead: false
	}
]

// 模拟预约列表数据
export const mockAppointments = [
	{
		id: 1,
		scheduleId: 1,
		departmentId: 1,
		departmentName: '内科',
		doctorId: 1,
		doctorName: '张医生',
		scheduleTime: '2024-01-15T09:30:00',
		appointmentTime: '2024-01-10T10:00:00',
		status: 'confirmed', // confirmed: 已确认, completed: 已完成, cancelled: 已取消
		queueNumber: 5,
		patientName: '张三',
		patientId: 1
	},
	{
		id: 2,
		scheduleId: 2,
		departmentId: 2,
		departmentName: '外科',
		doctorId: 2,
		doctorName: '李医生',
		scheduleTime: '2024-01-20T14:00:00',
		appointmentTime: '2024-01-12T15:30:00',
		status: 'confirmed',
		queueNumber: 3,
		patientName: '张三',
		patientId: 1
	},
	{
		id: 3,
		scheduleId: 3,
		departmentId: 3,
		departmentName: '儿科',
		doctorId: 3,
		doctorName: '王医生',
		scheduleTime: '2024-01-25T10:00:00',
		appointmentTime: '2024-01-18T11:00:00',
		status: 'confirmed',
		queueNumber: 8,
		patientName: '张三',
		patientId: 1
	},
	{
		id: 4,
		scheduleId: 4,
		departmentId: 1,
		departmentName: '内科',
		doctorId: 1,
		doctorName: '张医生',
		scheduleTime: '2024-01-05T09:00:00',
		appointmentTime: '2024-01-01T10:00:00',
		status: 'completed',
		queueNumber: 2,
		patientName: '张三',
		patientId: 1
	},
	{
		id: 5,
		scheduleId: 5,
		departmentId: 4,
		departmentName: '妇科',
		doctorId: 4,
		doctorName: '赵医生',
		scheduleTime: '2024-01-08T14:30:00',
		appointmentTime: '2024-01-03T16:00:00',
		status: 'cancelled',
		queueNumber: 1,
		patientName: '张三',
		patientId: 1
	}
]