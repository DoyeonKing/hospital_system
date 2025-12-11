/**
 * 百度千帆 AppBuilder API 封装模块
 */
const axios = require('axios');
require('dotenv').config();

/**
 * 创建新的对话会话
 * @param {string} token - AppBuilder Token
 * @param {string} appId - App ID
 * @returns {Promise<string>} conversationId
 */
async function createConversation(token, appId) {
  const url = 'https://qianfan.baidubce.com/v2/app/conversation';
  
  try {
    const response = await axios.post(
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
    
    if (response.data && response.data.conversation_id) {
      return response.data.conversation_id;
    }
    throw new Error('创建对话失败：响应中未找到 conversation_id');
  } catch (error) {
    if (error.response) {
      throw new Error(`创建对话失败: ${JSON.stringify(error.response.data)}`);
    }
    throw error;
  }
}

/**
 * 尝试使用 GET 方法获取对话历史或结果
 * @param {string} token - AppBuilder Token
 * @param {string} appId - App ID
 * @param {string} conversationId - 会话ID
 * @returns {Promise<{answer: string|null, success: boolean}>}
 */
async function tryGetConversationHistory(token, appId, conversationId) {
  // 尝试使用可能的 API 端点获取对话历史
  const possibleEndpoints = [
    `https://qianfan.baidubce.com/v2/app/conversation/${conversationId}/messages`,
    `https://qianfan.baidubce.com/v2/app/conversation/${conversationId}`,
    `https://qianfan.baidubce.com/v2/app/conversation/history`,
  ];
  
  for (const endpoint of possibleEndpoints) {
    try {
      console.log(`🔍 尝试 GET 端点: ${endpoint}`);
      const response = await axios.get(endpoint, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        params: {
          app_id: appId,
          conversation_id: conversationId
        },
        timeout: 10000
      });
      
      console.log(`📥 GET 响应:`, JSON.stringify(response.data).substring(0, 500));
      
      if (response.data) {
        // 尝试从响应中提取最后一条消息
        if (response.data.messages && Array.isArray(response.data.messages)) {
          const assistantMessages = response.data.messages.filter(m => m.role === 'assistant');
          if (assistantMessages.length > 0) {
            const lastMessage = assistantMessages[assistantMessages.length - 1];
            if (lastMessage && lastMessage.content) {
              return { answer: lastMessage.content, success: true };
            }
          }
        }
        if (response.data.content) {
          return { answer: response.data.content, success: true };
        }
        if (response.data.answer) {
          return { answer: response.data.answer, success: true };
        }
      }
    } catch (error) {
      // 端点不存在或失败，继续尝试下一个
      console.log(`⚠️ GET 端点 ${endpoint} 失败:`, error.message);
      continue;
    }
  }
  
  return { answer: null, success: false };
}

/**
 * 等待一段时间后重试获取结果（用于异步 Agent）
 * @param {string} token - AppBuilder Token
 * @param {string} appId - App ID
 * @param {string} conversationId - 会话ID
 * @param {string} originalQuery - 原始查询（用于重新发送）
 * @param {number} maxRetries - 最大重试次数
 * @param {number} delayMs - 每次重试的延迟（毫秒）
 * @returns {Promise<{result: string, conversation_id: string}>}
 */
async function waitAndRetryGetResult(token, appId, conversationId, originalQuery, maxRetries = 30, delayMs = 10000) {
  const url = 'https://qianfan.baidubce.com/v2/app/conversation';
  
  console.log(`🔄 开始轮询获取结果，最多重试 ${maxRetries} 次，每次等待 ${delayMs/1000} 秒...`);
  console.log(`📝 使用的 conversation_id: ${conversationId}`);
  
  for (let i = 0; i < maxRetries; i++) {
    const waitSeconds = delayMs / 1000;
    console.log(`⏳ [${i + 1}/${maxRetries}] 等待 ${waitSeconds} 秒后重试获取结果...`);
    await new Promise(resolve => setTimeout(resolve, delayMs));
    
    try {
      // 方法1: 尝试使用 GET 方法获取对话历史
      if (i === 1 || i % 3 === 0) { // 每3次重试尝试一次 GET 方法
        const historyResult = await tryGetConversationHistory(token, appId, conversationId);
        if (historyResult.success && historyResult.answer) {
          console.log(`✅ [${i + 1}] 从对话历史获取到答案！长度: ${historyResult.answer.length}`);
          return {
            result: historyResult.answer.trim(),
            conversation_id: conversationId
          };
        }
      }
      
      // 方法2: 尝试不发送 query，只获取对话状态
      let response;
      try {
        response = await axios.post(
          url,
          {
            app_id: appId,
            conversation_id: conversationId
            // 不发送 query，可能返回对话状态或历史消息
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            timeout: 120000
          }
        );
        
        console.log(`🔍 [${i + 1}] 方法2（不发送query）响应:`, JSON.stringify(response.data).substring(0, 500));
        
        // 如果返回了新的 conversation_id，说明创建了新对话，这不是我们想要的
        if (response.data.conversation_id && response.data.conversation_id !== conversationId) {
          console.log(`⚠️ [${i + 1}] 返回了新的 conversation_id，跳过此方法`);
          // 继续尝试方法3
        } else if (response.data && (response.data.answer || response.data.content || response.data.result)) {
          // 有答案，继续下面的处理逻辑
        } else {
          // 方法2失败，尝试方法3: 重新发送查询（但使用相同的 conversation_id）
          console.log(`🔄 [${i + 1}] 方法2未返回答案，尝试方法3（重新发送查询，但使用原始conversation_id）...`);
          response = await axios.post(
            url,
            {
              app_id: appId,
              conversation_id: conversationId, // 使用原始的 conversation_id
              query: originalQuery
            },
            {
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
              },
              timeout: 120000
            }
          );
          console.log(`🔍 [${i + 1}] 方法3（重新发送query）响应:`, JSON.stringify(response.data).substring(0, 500));
        }
      } catch (methodError) {
        // 如果方法2失败，尝试方法3
        console.log(`⚠️ [${i + 1}] 方法2失败，尝试方法3:`, methodError.message);
        response = await axios.post(
          url,
          {
            app_id: appId,
            conversation_id: conversationId,
            query: originalQuery
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            timeout: 120000
          }
        );
      }
      
      console.log(`🔍 [${i + 1}] 响应数据:`, JSON.stringify(response.data).substring(0, 500));
      
      // 检查响应中是否有答案
      if (response.data) {
        let answer = '';
        
        // 尝试从多个字段提取
        if (response.data.answer) {
          answer = response.data.answer;
        } else if (response.data.content) {
          answer = response.data.content;
        } else if (response.data.result) {
          answer = typeof response.data.result === 'string' ? response.data.result : JSON.stringify(response.data.result);
        } else if (response.data.data && response.data.data.answer) {
          answer = response.data.data.answer;
        } else if (response.data.messages && Array.isArray(response.data.messages)) {
          // 如果有消息列表，获取最后一条助手消息
          const assistantMessages = response.data.messages.filter(m => m.role === 'assistant');
          if (assistantMessages.length > 0) {
            answer = assistantMessages[assistantMessages.length - 1].content;
          }
        }
        
        if (answer && answer.trim()) {
          console.log(`✅ [${i + 1}] 成功获取到答案！长度: ${answer.length}`);
          console.log(`📄 答案预览: ${answer.substring(0, 300)}`);
          return {
            result: answer.trim(),
            conversation_id: conversationId
          };
        }
        
        // 如果还是只有元数据，继续等待
        const keys = Object.keys(response.data);
        if (keys.length <= 2 && (keys.includes('request_id') || keys.includes('conversation_id'))) {
          console.log(`⚠️ [${i + 1}] 仍只返回元数据，继续等待...`);
          
          // 每5次重试打印一次进度
          if ((i + 1) % 5 === 0) {
            const elapsedSeconds = ((i + 1) * delayMs) / 1000;
            console.log(`📊 已等待 ${elapsedSeconds} 秒，继续等待中...`);
          }
          continue;
        } else {
          // 如果响应有其他字段，打印出来看看
          console.log(`ℹ️ [${i + 1}] 响应包含其他字段:`, keys.join(', '));
        }
      }
    } catch (error) {
      console.warn(`⚠️ [${i + 1}] 重试失败:`, error.message);
      // 继续重试，不要因为一次失败就停止
    }
  }
  
  const totalWaitTime = (maxRetries * delayMs) / 1000;
  throw new Error(`重试 ${maxRetries} 次（总共等待 ${totalWaitTime} 秒）后仍未获取到答案。这可能是因为：
1. Agent 需要更长的处理时间（建议在 AppBuilder 控制台检查 Agent 配置）
2. 需要使用不同的 API 调用方式
3. 请运行 test_appbuilder_direct.js 查看详细的测试结果`);
}

/**
 * 使用流式方式调用 AppBuilder（当非流式返回空结果时使用）
 * @param {string} token - AppBuilder Token
 * @param {string} appId - App ID
 * @param {string} query - 用户输入
 * @param {string} conversationId - 会话ID
 * @returns {Promise<{result: string, conversation_id: string}>}
 */
async function callAppBuilderStream(token, appId, query, conversationId) {
  const url = 'https://qianfan.baidubce.com/v2/app/conversation';
  
  const payload = {
    app_id: appId,
    query: query,
    conversation_id: conversationId,
    stream: true
  };

  console.log('📡 使用流式响应调用 AppBuilder...');

  try {
    const response = await axios.post(url, payload, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      responseType: 'stream',
      timeout: 180000 // 3分钟超时，因为自主规划Agent需要更长时间
    });

    return new Promise((resolve, reject) => {
      let answer = '';
      let buffer = '';
      let eventCount = 0;
      let rawChunks = []; // 用于调试：保存原始数据块

      response.data.on('data', (chunk) => {
        const chunkStr = chunk.toString();
        rawChunks.push(chunkStr); // 保存原始数据用于调试
        buffer += chunkStr;
        
        // 首先检查是否是完整的 JSON 对象（非 SSE 格式）
        const trimmedBuffer = buffer.trim();
        if (trimmedBuffer.startsWith('{') && trimmedBuffer.endsWith('}')) {
          try {
            const data = JSON.parse(trimmedBuffer);
            eventCount++;
            console.log(`📦 接收到完整 JSON 对象:`, JSON.stringify(data).substring(0, 300));
            
            // 如果只包含元数据，可能需要等待
            if (data.request_id && data.conversation_id && !data.answer && !data.content && !data.result) {
              console.log('⚠️ 流式响应也只返回元数据，可能需要等待异步处理...');
              // 不清空 buffer，继续等待更多数据
              return;
            }
            
            // 尝试从多个可能的字段中提取答案
            if (data.answer) {
              answer += data.answer;
            } else if (data.content) {
              answer += data.content;
            } else if (data.result) {
              answer += typeof data.result === 'string' ? data.result : JSON.stringify(data.result);
            } else if (data.text) {
              answer += data.text;
            } else if (data.message) {
              answer += data.message;
            }
            
            if (answer) {
              console.log(`✅ 从 JSON 对象提取到答案，当前长度: ${answer.length}`);
            }
          } catch (e) {
            // JSON 解析失败，继续按 SSE 格式处理
          }
        }
        
        // 尝试解析 SSE 格式的数据
        const lines = buffer.split('\n');
        buffer = lines.pop() || ''; // 保留最后不完整的行

        for (const line of lines) {
          const trimmedLine = line.trim();
          if (!trimmedLine) continue; // 跳过空行
          
          // 调试：打印每一行
          if (eventCount < 5) { // 只打印前5行，避免日志过多
            console.log(`📥 流式数据行 ${eventCount + 1}:`, trimmedLine.substring(0, 200));
          }
          
          // SSE 格式: data: {...}
          if (trimmedLine.startsWith('data: ')) {
            try {
              const jsonStr = trimmedLine.substring(6);
              const data = JSON.parse(jsonStr);
              eventCount++;
              
              // 调试：打印解析后的数据
              if (eventCount <= 3) {
                console.log(`📦 解析的事件数据 ${eventCount}:`, JSON.stringify(data).substring(0, 300));
              }
              
              // 尝试从多个可能的字段中提取答案
              if (data.answer) {
                answer += data.answer;
                console.log(`✅ 从 answer 字段提取内容，当前长度: ${answer.length}`);
              } else if (data.content) {
                answer += data.content;
                console.log(`✅ 从 content 字段提取内容，当前长度: ${answer.length}`);
              } else if (data.result) {
                const resultStr = typeof data.result === 'string' ? data.result : JSON.stringify(data.result);
                answer += resultStr;
                console.log(`✅ 从 result 字段提取内容，当前长度: ${answer.length}`);
              } else if (data.text) {
                answer += data.text;
                console.log(`✅ 从 text 字段提取内容，当前长度: ${answer.length}`);
              } else if (data.message) {
                answer += data.message;
                console.log(`✅ 从 message 字段提取内容，当前长度: ${answer.length}`);
              } else if (typeof data === 'string') {
                answer += data;
                console.log(`✅ 数据是字符串，直接添加，当前长度: ${answer.length}`);
              } else {
                // 如果整个对象就是答案，尝试序列化
                const dataStr = JSON.stringify(data);
                if (dataStr.length > 10 && !dataStr.includes('request_id') && !dataStr.includes('conversation_id')) {
                  answer += dataStr;
                  console.log(`✅ 从对象序列化提取内容，当前长度: ${answer.length}`);
                } else {
                  console.log(`⚠️ 跳过元数据对象:`, Object.keys(data));
                }
              }
            } catch (e) {
              // 如果不是 JSON，可能是纯文本
              if (trimmedLine.length > 6) {
                const text = trimmedLine.substring(6);
                if (text && !text.startsWith('{')) {
                  answer += text;
                  console.log(`✅ 从纯文本提取内容，当前长度: ${answer.length}`);
                }
              }
              if (eventCount < 3) {
                console.warn(`⚠️ JSON 解析失败 (行 ${eventCount + 1}):`, e.message, '原始数据:', trimmedLine.substring(0, 100));
              }
            }
          } else if (trimmedLine.startsWith('{') && !trimmedLine.startsWith('data:')) {
            // 直接是 JSON 对象（非 SSE 格式）
            try {
              const data = JSON.parse(trimmedLine);
              eventCount++;
              if (data.answer) {
                answer += data.answer;
              } else if (data.content) {
                answer += data.content;
              } else if (data.result) {
                answer += typeof data.result === 'string' ? data.result : JSON.stringify(data.result);
              }
            } catch (e) {
              // 忽略解析错误
              if (eventCount < 3) {
                console.warn(`⚠️ 直接 JSON 解析失败:`, e.message);
              }
            }
          } else {
            // 其他格式，可能是纯文本
            if (trimmedLine.length > 0 && !trimmedLine.startsWith('event:') && !trimmedLine.startsWith('id:')) {
              answer += trimmedLine + '\n';
              if (eventCount < 3) {
                console.log(`✅ 添加纯文本行，当前长度: ${answer.length}`);
              }
            }
          }
        }
      });

      // 设置超时，如果30秒内没有收到数据，尝试等待后重试
      const timeoutId = setTimeout(() => {
        if (!answer || answer.trim() === '') {
          console.log('⏰ 30秒内未收到答案，流可能还在处理中...');
        }
      }, 30000);
      
      response.data.on('end', async () => {
        clearTimeout(timeoutId);
        console.log(`✅ 流式响应接收完成，共接收 ${eventCount} 个事件，答案长度: ${answer.length}`);
        console.log(`📊 原始数据块数量: ${rawChunks.length}`);
        
        // 打印所有原始数据块用于调试
        console.log('📋 所有原始数据块详情:');
        rawChunks.forEach((chunk, index) => {
          console.log(`  块 ${index + 1} (${chunk.length} 字符):`, chunk.substring(0, 300));
        });
        
        const allRaw = rawChunks.join('');
        console.log('📋 所有原始数据合并 (前1000字符):');
        console.log(allRaw.substring(0, 1000));
        
        // 如果答案为空，输出原始数据用于调试
        if (!answer || !answer.trim()) {
          console.error('❌ 流式响应中未找到答案内容');
          
          // 如果流式响应也只返回元数据，可能是异步 Agent，尝试等待后重试
          const rawData = allRaw.trim();
          if (rawData.startsWith('{') && (rawData.includes('request_id') || rawData.includes('conversation_id'))) {
            console.log('⚠️ 流式响应也只返回元数据，可能是异步 Agent，尝试等待后重试（等待更长时间）...');
            try {
              // 使用更长的等待时间和更多重试次数
              const retryResult = await waitAndRetryGetResult(token, appId, conversationId, query, 20, 5000);
              resolve(retryResult);
              return;
            } catch (retryError) {
              console.error('❌ 重试获取结果也失败:', retryError.message);
            }
          }
          
          reject(new Error(`流式响应中未找到答案内容。接收了 ${eventCount} 个事件，但答案为空。这可能是因为：
1. AppBuilder Agent 配置不正确，未正确返回答案
2. Agent 是异步处理，需要等待更长时间（已尝试等待）
3. 请运行 test_appbuilder_direct.js 测试脚本，查看实际接收到的数据

原始数据预览: ${allRaw.substring(0, 500)}`));
        } else {
          console.log('📄 答案内容预览:', answer.substring(0, 300));
          resolve({
            result: answer.trim(),
            conversation_id: conversationId
          });
        }
      });

      response.data.on('error', (error) => {
        console.error('❌ 流式响应错误:', error.message);
        reject(new Error(`流式响应错误: ${error.message}`));
      });
    });
  } catch (error) {
    console.error('❌ 流式请求失败:', error.message);
    if (error.response) {
      // 尝试读取错误响应
      if (error.response.data) {
        let errorData = '';
        error.response.data.on('data', (chunk) => {
          errorData += chunk.toString();
        });
        error.response.data.on('end', () => {
          console.error('错误响应内容:', errorData);
        });
      }
      throw new Error(`流式请求失败: ${JSON.stringify(error.response.data)}`);
    }
    throw error;
  }
}

/**
 * 调用 AppBuilder Agent
 * @param {string} query - 用户输入的问题
 * @param {string} conversationId - 会话ID（可选，用于连续对话）
 */
async function callAppBuilder(query, conversationId = null) {
  let config = {};
  try {
    config = require('../config_env.js');
  } catch (e) { console.log('未找到 config_env.js, 使用默认环境变量'); }

  const token = process.env.APPBUILDER_TOKEN || config.APPBUILDER_TOKEN;
  const appId = process.env.APPBUILDER_APP_ID || config.APPBUILDER_APP_ID;

  if (!token || !appId) {
    throw new Error('请在 .env 文件或 config_env.js 中配置 APPBUILDER_TOKEN 和 APPBUILDER_APP_ID');
  }

  // 如果没有提供 conversationId，先创建一个新的对话
  if (!conversationId) {
    console.log('📝 创建新的对话会话...');
    conversationId = await createConversation(token, appId);
    console.log('✅ 对话会话创建成功:', conversationId);
  }

  const url = 'https://qianfan.baidubce.com/v2/app/conversation';

  try {
    console.log('📤 发送请求到 AppBuilder:', {
      appId: appId,
      queryLength: query.length,
      conversationId: conversationId
    });

    // 对于"自主规划Agent"，先发送请求，然后等待并轮询获取结果
    console.log('📡 发送请求到 AppBuilder（自主规划Agent 需要异步处理）...');
    
    const payload = {
      app_id: appId,
      query: query,
      conversation_id: conversationId,
      stream: false
    };

    const response = await axios.post(url, payload, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      timeout: 120000
    });

    console.log('📥 AppBuilder 响应状态:', response.status);
    console.log('🔍 AppBuilder 原始响应数据:', JSON.stringify(response.data, null, 2));
    
    // 保存原始的 conversation_id（响应可能返回新的）
    const originalConversationId = conversationId;
    const responseConversationId = response.data.conversation_id || conversationId;
    
    // 如果只返回元数据，说明是异步处理，需要等待并轮询
    const responseKeys = Object.keys(response.data || {});
    const hasOnlyMetadata = responseKeys.length <= 2 && 
                           (responseKeys.includes('request_id') || responseKeys.includes('conversation_id')) &&
                           !response.data.answer && !response.data.content && !response.data.result;
    
    if (hasOnlyMetadata) {
      console.log('⚠️ 检测到异步响应，开始长时间等待并轮询获取结果...');
      console.log('📝 原始 conversation_id:', originalConversationId);
      console.log('📝 响应 conversation_id:', responseConversationId);
      
      // 使用响应返回的 conversation_id 或原始的 conversation_id
      const targetConversationId = responseConversationId || originalConversationId;
      
      // 等待并轮询获取结果（更长的等待时间和更多重试）
      return await waitAndRetryGetResult(token, appId, targetConversationId, query, 30, 10000); // 30次，每次10秒，总共5分钟
    }
    
    // 如果有答案，直接返回
    let answer = '';
    if (response.data.answer) {
      answer = response.data.answer;
    } else if (response.data.content) {
      answer = response.data.content;
    } else if (response.data.result) {
      answer = typeof response.data.result === 'string' ? response.data.result : JSON.stringify(response.data.result);
    }
    
    if (answer && answer.trim()) {
      return {
        result: answer.trim(),
        conversation_id: responseConversationId
      };
    }
    
    // 如果都没有，尝试流式响应
    console.log('⚠️ 非流式响应没有答案，尝试流式响应...');
    const finalConversationId = responseConversationId || originalConversationId;
    return await callAppBuilderStream(token, appId, query, finalConversationId);

  } catch (error) {
    if (error.response) {
      console.error('❌ AppBuilder HTTP 错误:', error.response.status, error.response.data);
      throw new Error(`AppBuilder 请求失败: ${JSON.stringify(error.response.data)}`);
    } else {
      console.error('❌ AppBuilder 调用失败:', error.message);
      throw error;
    }
  }
}

/**
 * 解析 JSON 响应
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
  callAppBuilder, // 导出新方法
  // 保持旧方法名兼容，但内部指向新实现（可选，或者修改调用方）
  callBaiduLLM: async (prompt) => {
      const res = await callAppBuilder(prompt);
      return res.result;
  },
  parseJSONResponse
};

