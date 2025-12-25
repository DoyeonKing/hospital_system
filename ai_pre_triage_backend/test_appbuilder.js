require('dotenv').config();
const { callAppBuilder } = require('./utils/baidu_llm');

async function test() {
  console.log('🔍 开始测试 AppBuilder 接口...');
  console.log('🔑 App ID:', process.env.APPBUILDER_APP_ID);
  
  try {
    const query = "我最近经常头痛，伴有恶心，可能是什么问题？";
    console.log(`❓ 发送问题: "${query}"`);
    
    const result = await callAppBuilder(query);
    
    console.log('✅ 测试成功！');
    console.log('🤖 AI 回复:', result.result);
    console.log('🆔 会话 ID:', result.conversation_id);
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
  }
}

test();















