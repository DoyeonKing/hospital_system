/**
 * 直接测试 AppBuilder API 调用
 * 用于验证是否能从 Agent 获取答案
 */
require('dotenv').config();
const axios = require('axios');

let config = {};
try {
  config = require('./config_env.js');
} catch (e) {
  console.log('未找到 config_env.js, 使用默认环境变量');
}

const token = process.env.APPBUILDER_TOKEN || config.APPBUILDER_TOKEN;
const appId = process.env.APPBUILDER_APP_ID || config.APPBUILDER_APP_ID;

if (!token || !appId) {
  console.error('❌ 请配置 APPBUILDER_TOKEN 和 APPBUILDER_APP_ID');
  process.exit(1);
}

const url = 'https://qianfan.baidubce.com/v2/app/conversation';

async function testNonStream() {
  console.log('\n=== 测试 1: 非流式响应 ===');
  
  try {
    // 1. 创建对话
    console.log('📝 步骤 1: 创建对话...');
    const createResponse = await axios.post(
      url,
      { app_id: appId },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        timeout: 30000
      }
    );
    
    const conversationId = createResponse.data.conversation_id;
    console.log('✅ 对话创建成功:', conversationId);
    
    // 2. 发送查询
    console.log('\n📝 步骤 2: 发送查询...');
    const query = `患者症状：咳嗽，咳痰，气喘

医院现有科室列表：
1. 内科
2. 呼吸内科
3. 心血管内科

请作为医疗分诊助手，分析病情并推荐1个科室。
【重要】必须只返回 JSON 格式，不要包含 Markdown 标记，格式如下：
{
  "analysis": "病情分析（100字左右）",
  "recommended_department": {
    "id": 科室ID（数字）,
    "name": "科室名称",
    "reason": "推荐理由"
  }
}`;
    
    const queryResponse = await axios.post(
      url,
      {
        app_id: appId,
        conversation_id: conversationId,
        query: query,
        stream: false
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        timeout: 120000 // 2分钟超时
      }
    );
    
    console.log('📥 响应状态:', queryResponse.status);
    console.log('📥 响应数据:', JSON.stringify(queryResponse.data, null, 2));
    
    // 3. 如果只返回元数据，等待并重试
    if (queryResponse.data.request_id && queryResponse.data.conversation_id && 
        !queryResponse.data.answer && !queryResponse.data.content && !queryResponse.data.result) {
      console.log('\n⚠️ 只返回元数据，等待 10 秒后重试...');
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      const retryResponse = await axios.post(
        url,
        {
          app_id: appId,
          conversation_id: conversationId,
          query: query,
          stream: false
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          timeout: 120000
        }
      );
      
      console.log('📥 重试响应数据:', JSON.stringify(retryResponse.data, null, 2));
      
      // 如果还是只有元数据，尝试等待更长时间并多次重试
      if (retryResponse.data.request_id && retryResponse.data.conversation_id && 
          !retryResponse.data.answer && !retryResponse.data.content && !retryResponse.data.result) {
        console.log('\n⚠️ 重试后仍只返回元数据，尝试等待更长时间（30秒）并多次重试...');
        
        for (let i = 0; i < 5; i++) {
          await new Promise(resolve => setTimeout(resolve, 30000)); // 等待30秒
          console.log(`\n⏳ 第 ${i + 1} 次长时间等待后重试...`);
          
          const longRetryResponse = await axios.post(
            url,
            {
              app_id: appId,
              conversation_id: conversationId, // 使用原始的 conversationId
              query: query,
              stream: false
            },
            {
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
              },
              timeout: 120000
            }
          );
          
          console.log(`📥 长时间等待重试 ${i + 1} 响应数据:`, JSON.stringify(longRetryResponse.data, null, 2));
          
          // 检查是否有答案
          if (longRetryResponse.data.answer || longRetryResponse.data.content || longRetryResponse.data.result) {
            console.log('✅ 找到答案！');
            break;
          }
        }
      }
    }
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.response) {
      console.error('响应数据:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

async function testStream() {
  console.log('\n=== 测试 2: 流式响应 ===');
  
  try {
    // 1. 创建对话
    console.log('📝 步骤 1: 创建对话...');
    const createResponse = await axios.post(
      url,
      { app_id: appId },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        timeout: 30000
      }
    );
    
    const conversationId = createResponse.data.conversation_id;
    console.log('✅ 对话创建成功:', conversationId);
    
    // 2. 发送流式查询
    console.log('\n📝 步骤 2: 发送流式查询...');
    const query = `患者症状：咳嗽，咳痰，气喘

医院现有科室列表：
1. 内科
2. 呼吸内科
3. 心血管内科

请作为医疗分诊助手，分析病情并推荐1个科室。
【重要】必须只返回 JSON 格式，不要包含 Markdown 标记，格式如下：
{
  "analysis": "病情分析（100字左右）",
  "recommended_department": {
    "id": 科室ID（数字）,
    "name": "科室名称",
    "reason": "推荐理由"
  }
}`;
    
    const streamResponse = await axios.post(
      url,
      {
        app_id: appId,
        conversation_id: conversationId,
        query: query,
        stream: true
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        responseType: 'stream',
        timeout: 120000 // 2分钟超时
      }
    );
    
    console.log('📥 开始接收流式数据...');
    let allData = '';
    let eventCount = 0;
    
    return new Promise((resolve, reject) => {
      streamResponse.data.on('data', (chunk) => {
        const chunkStr = chunk.toString();
        allData += chunkStr;
        eventCount++;
        console.log(`📦 数据块 ${eventCount} (${chunkStr.length} 字符):`, chunkStr.substring(0, 200));
      });
      
      streamResponse.data.on('end', () => {
        console.log(`\n✅ 流式响应接收完成，共 ${eventCount} 个数据块`);
        console.log('📄 所有数据合并:');
        console.log(allData);
        resolve();
      });
      
      streamResponse.data.on('error', (error) => {
        console.error('❌ 流式响应错误:', error.message);
        reject(error);
      });
      
      // 设置超时（延长到2分钟）
      setTimeout(() => {
        console.log('\n⏰ 2分钟超时，当前接收到的数据:');
        console.log(allData);
        console.log('\n⚠️ 如果只收到元数据，说明流式响应可能也需要等待异步处理');
        resolve();
      }, 120000);
    });
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.response) {
      console.error('响应数据:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

async function main() {
  console.log('🧪 开始测试 AppBuilder API...');
  console.log('🔑 App ID:', appId);
  console.log('🔑 Token:', token.substring(0, 20) + '...');
  
  await testNonStream();
  await testStream();
  
  console.log('\n✅ 测试完成');
}

main().catch(console.error);

