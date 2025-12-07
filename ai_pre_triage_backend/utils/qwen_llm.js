/**
 * 通义千问 (Qwen) API 封装模块
 * 使用阿里云 DashScope API
 */
const axios = require('axios');
require('dotenv').config();

/**
 * 调用通义千问 API
 * @param {string} prompt - 用户输入的提示词
 * @returns {Promise<string>} AI 返回的文本内容
 */
async function callQwenLLM(prompt) {
  let config = {};
  try {
    config = require('../config_env.js');
  } catch (e) {
    console.log('未找到 config_env.js, 使用默认环境变量');
  }

  // 从环境变量或配置文件获取 API Key
  const apiKey = process.env.QWEN_API_KEY || config.QWEN_API_KEY;
  const model = process.env.QWEN_MODEL || config.QWEN_MODEL || 'qwen-turbo'; // 默认使用 qwen-turbo

  if (!apiKey) {
    throw new Error('请在 .env 文件或 config_env.js 中配置 QWEN_API_KEY');
  }

  // 使用 OpenAI 兼容模式的 API 端点
  const url = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

  try {
    console.log('📤 发送请求到通义千问 (OpenAI 兼容模式):', {
      model: model,
      promptLength: prompt.length
    });

    // 使用 OpenAI 兼容格式的请求
    const payload = {
      model: model,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 2000
    };

    const response = await axios.post(url, payload, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      timeout: 60000 // 60秒超时
    });

    console.log('📥 通义千问响应状态:', response.status);

    // OpenAI 兼容格式的响应处理
    if (response.data.error) {
      throw new Error(`通义千问 API 错误: ${response.data.error.message || JSON.stringify(response.data.error)}`);
    }

    // 提取返回内容（OpenAI 兼容格式）
    let answer = '';
    if (response.data.choices && response.data.choices.length > 0) {
      const choice = response.data.choices[0];
      if (choice.message && choice.message.content) {
        answer = choice.message.content;
      } else if (choice.text) {
        answer = choice.text;
      }
    } else if (response.data.output && response.data.output.choices && response.data.output.choices.length > 0) {
      const choice = response.data.output.choices[0];
      if (choice.message && choice.message.content) {
        answer = choice.message.content;
      }
    } else if (response.data.output && response.data.output.text) {
      answer = response.data.output.text;
    }

    if (!answer || answer.trim() === '') {
      console.error('❌ 通义千问返回内容为空');
      console.error('响应数据:', JSON.stringify(response.data, null, 2));
      throw new Error('通义千问返回内容为空');
    }

    console.log('✅ 通义千问调用成功, 响应长度:', answer.length);
    console.log('📄 答案内容预览:', answer.substring(0, 300));

    return answer.trim();
  } catch (error) {
    if (error.response) {
      console.error('❌ 通义千问 HTTP 错误:', error.response.status, error.response.data);
      throw new Error(`通义千问请求失败: ${JSON.stringify(error.response.data)}`);
    } else {
      console.error('❌ 通义千问调用失败:', error.message);
      throw error;
    }
  }
}

/**
 * 解析 JSON 响应（从文本中提取 JSON）
 */
function parseJSONResponse(text) {
  if (!text || typeof text !== 'string') {
    throw new Error('响应内容为空或不是字符串');
  }

  try {
    // 移除 Markdown 代码块标记 (```json ... ``` 或 ``` ... ```)
    let cleanText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    // 尝试直接解析
    return JSON.parse(cleanText);
  } catch (e) {
    console.warn('⚠️ 第一次 JSON 解析失败，尝试提取 JSON 部分...');
    console.warn('原始文本前200字符:', text.substring(0, 200));

    // 如果失败，尝试提取 JSON 部分（匹配第一个完整的 JSON 对象）
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      try {
        return JSON.parse(jsonMatch[0]);
      } catch (e2) {
        console.error('❌ 提取的 JSON 部分也无法解析:', e2.message);
        console.error('提取的内容:', jsonMatch[0].substring(0, 500));
        throw new Error(`JSON 解析失败: ${e2.message}。原始响应前200字符: ${text.substring(0, 200)}`);
      }
    }

    throw new Error(`无法从响应中提取 JSON 对象。原始响应前200字符: ${text.substring(0, 200)}`);
  }
}

module.exports = {
  callQwenLLM,
  parseJSONResponse
};

