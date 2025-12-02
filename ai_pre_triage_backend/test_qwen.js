/**
 * 测试通义千问 API
 */
require('dotenv').config();
const { callQwenLLM, parseJSONResponse } = require('./utils/qwen_llm');

async function test() {
  console.log('🔍 开始测试通义千问 API...');
  
  let config = {};
  try {
    config = require('./config_env.js');
  } catch (e) {
    console.log('未找到 config_env.js, 使用默认环境变量');
  }

  const apiKey = process.env.QWEN_API_KEY || config.QWEN_API_KEY;
  
  if (!apiKey) {
    console.error('❌ 请配置 QWEN_API_KEY');
    console.log('请在 .env 文件或 config_env.js 中添加:');
    console.log('QWEN_API_KEY=你的API密钥');
    return;
  }

  console.log('🔑 API Key:', apiKey.substring(0, 10) + '...');
  
  try {
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
    
    console.log(`❓ 发送问题...`);
    const result = await callQwenLLM(query);
    
    console.log('\n✅ 测试成功！');
    console.log('🤖 AI 回复:');
    console.log(result);
    
    // 尝试解析 JSON
    try {
      const jsonResult = parseJSONResponse(result);
      console.log('\n✅ JSON 解析成功:');
      console.log(JSON.stringify(jsonResult, null, 2));
    } catch (e) {
      console.log('\n⚠️ JSON 解析失败:', e.message);
    }
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
  }
}

test();

