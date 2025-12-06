require('dotenv').config();
const axios = require('axios');

async function testBaiduAPI() {
  console.log('🔍 开始测试百度 API...');
  console.log('🔑 BAIDU_API_KEY:', process.env.BAIDU_API_KEY ? '已配置' : '未配置');
  console.log('🔑 BAIDU_SECRET_KEY:', process.env.BAIDU_SECRET_KEY ? '已配置' : '未配置');

  if (!process.env.BAIDU_API_KEY || !process.env.BAIDU_SECRET_KEY) {
    console.error('❌ 环境变量缺失，请检查 .env 文件');
    return;
  }

  try {
    // 1. 获取 Access Token
    console.log('⏳ 正在获取 Access Token...');
    const tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
    const tokenParams = {
      grant_type: 'client_credentials',
      client_id: process.env.BAIDU_API_KEY,
      client_secret: process.env.BAIDU_SECRET_KEY
    };

    const tokenRes = await axios.post(tokenUrl, null, { params: tokenParams });
    
    if (tokenRes.data.error) {
      throw new Error(`获取 Token 失败: ${JSON.stringify(tokenRes.data)}`);
    }

    const accessToken = tokenRes.data.access_token;
    console.log('✅ Access Token 获取成功');

    // 2. 调用文心一言
    console.log('⏳ 正在调用文心一言 (ernie-speed-8k)...');
    const chatUrl = `https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/ernie-speed-8k?access_token=${accessToken}`;
    
    const chatBody = {
      messages: [
        { role: 'user', content: '你好，这是一个测试请求。请回复“API调用成功”。' }
      ],
      temperature: 0.7
    };

    const chatRes = await axios.post(chatUrl, chatBody, { headers: { 'Content-Type': 'application/json' } });

    console.log('📥 API 响应状态:', chatRes.status);
    console.log('📥 API 响应数据:', JSON.stringify(chatRes.data));

    if (chatRes.data.error_code) {
      throw new Error(`调用模型失败: ${chatRes.data.error_msg}`);
    }

    console.log('✅ 百度 API 测试通过！');
    console.log('🤖 回复:', chatRes.data.result);

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.response) {
      console.error('HTTP 错误数据:', error.response.data);
    }
  }
}

testBaiduAPI();




