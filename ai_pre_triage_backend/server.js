/**
 * AI 智能预问诊后端服务
 * 提供热门症状、AI 分诊、医生推荐等接口
 */
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
require('dotenv').config();

// 尝试加载 config_env.js 作为环境变量的补充
try {
    const config = require('./config_env.js');
    Object.keys(config).forEach(key => {
        if (!process.env[key]) {
            process.env[key] = config[key];
        }
    });
    console.log('✅ 已加载 config_env.js 配置文件');
} catch (e) {
    console.log('ℹ️ 未找到 config_env.js，使用默认环境变量');
}

const { callQwenLLM, parseJSONResponse } = require('./utils/qwen_llm');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());

// 数据库连接池（用户说数据库已连接好，这里使用环境变量配置）
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'hospital',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 测试数据库连接
pool.getConnection()
  .then(connection => {
    console.log('✅ 数据库连接成功');
    connection.release();
  })
  .catch(err => {
    console.error('❌ 数据库连接失败:', err.message);
  });

/**
 * 接口 1: 获取热门症状
 * GET /api/symptoms/popular
 */
app.get('/api/symptoms/popular', async (req, res) => {
  try {
    // 查询 symptom_department_mapping 表，提取 symptom_keywords
    // 使用 GROUP BY 代替 DISTINCT 以兼容 ORDER BY
    const [rows] = await pool.execute(
      `SELECT symptom_keywords 
       FROM symptom_department_mapping 
       WHERE symptom_keywords IS NOT NULL AND symptom_keywords != ''
       GROUP BY symptom_keywords
       ORDER BY MIN(priority) ASC, MIN(mapping_id) ASC 
       LIMIT 10`
    );

    // 提取所有关键词并去重
    const allKeywords = new Set();
    rows.forEach(row => {
      if (row.symptom_keywords) {
        const keywords = row.symptom_keywords.split(',').map(k => k.trim()).filter(k => k);
        keywords.forEach(k => {
          if (k) allKeywords.add(k);
        });
      }
    });

    // 转换为数组并返回前 10 个
    let popularSymptoms = Array.from(allKeywords).slice(0, 10);

    // 如果数据库中没有数据，返回默认热门症状
    if (popularSymptoms.length === 0) {
      console.log('⚠️ 数据库中暂无症状数据，返回默认热门症状');
      popularSymptoms = [
        '头痛', '发热', '咳嗽', '腹痛', '皮疹', 
        '失眠', '胸闷', '头晕', '恶心', '腹泻'
      ];
    }

    res.json(popularSymptoms);
  } catch (error) {
    console.error('获取热门症状失败:', error);
    console.error('错误详情:', error.stack);
    // 即使出错也返回默认症状，保证前端可用
    const defaultSymptoms = [
      '头痛', '发热', '咳嗽', '腹痛', '皮疹', 
      '失眠', '胸闷', '头晕', '恶心', '腹泻'
    ];
    res.json(defaultSymptoms);
  }
});

/**
 * 接口 2: AI 智能分诊与科室推荐
 * POST /api/pre-triage/recommend-department
 */
app.post('/api/pre-triage/recommend-department', async (req, res) => {
  try {
    const { patient_id, symptoms } = req.body;

    if (!symptoms || !symptoms.trim()) {
      return res.status(400).json({ error: '症状描述不能为空' });
    }

    console.log('📝 收到分诊请求:', { patient_id, symptoms: symptoms.substring(0, 50) + '...' });

    // 1. 准备 Context：查询所有科室
    let departments = [];
    try {
      const [deptRows] = await pool.execute(
        `SELECT department_id as id, name, description 
         FROM departments 
         ORDER BY department_id`
      );
      departments = deptRows;
      console.log(`✅ 查询到 ${departments.length} 个科室`);
    } catch (err) {
      console.error('❌ 查询科室失败:', err.message);
      // 如果查询失败，使用降级方案
      return res.json(await fallbackDepartmentRecommendation(symptoms, []));
    }

    if (departments.length === 0) {
      console.warn('⚠️ 科室列表为空，使用降级方案');
      return res.json(await fallbackDepartmentRecommendation(symptoms, []));
    }

    // 2. 如果提供了 patient_id，查询患者病史
    let patientHistory = '';
    if (patient_id) {
      try {
        const [profiles] = await pool.execute(
          `SELECT allergies, medical_history 
           FROM patient_profiles 
           WHERE patient_id = ?`,
          [patient_id]
        );
        if (profiles.length > 0) {
          const profile = profiles[0];
          if (profile.allergies) patientHistory += `过敏史: ${profile.allergies}。`;
          if (profile.medical_history) patientHistory += `既往病史: ${profile.medical_history}。`;
        }
      } catch (err) {
        console.warn('⚠️ 查询患者病史失败:', err.message);
      }
    }

    // 3. 构建 Prompt (适配 AppBuilder)
    const departmentList = departments.map(d => `${d.id}. ${d.name}`).join('\n');
    
    // 组合成发给 AppBuilder 的完整指令
    const appBuilderQuery = `患者症状：${symptoms}

${patientHistory ? `患者病史信息：${patientHistory}\n` : ''}
医院现有科室列表：
${departmentList}

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

    // 4. 调用通义千问 API
    console.log('🤖 调用通义千问 API...');
    const llmResponse = await callQwenLLM(appBuilderQuery);
    
    // 严格检查响应
    if (llmResponse === undefined || llmResponse === null || llmResponse === '') {
        throw new Error('通义千问返回结果为空，请检查 API 配置');
    }

    const safeResponseLog = (typeof llmResponse === 'string') ? llmResponse : JSON.stringify(llmResponse);
    console.log('✅ 通义千问调用成功，响应内容:', safeResponseLog.substring(0, 200) + '...');

    // 5. 解析响应（必须成功）
    let result;
    try {
      result = parseJSONResponse(llmResponse);
      const safeJsonLog = result ? JSON.stringify(result).substring(0, 200) : 'null';
      console.log('✅ JSON 解析成功:', safeJsonLog + '...');
    } catch (e) {
      console.error('❌ JSON 解析失败:', e.message);
      console.error('原始响应内容:', llmResponse);
      throw new Error(`JSON 解析失败: ${e.message}。原始响应: ${safeResponseLog}`);
    }

    // 验证返回的科室ID是否存在（支持下划线和驼峰两种命名）
    let recommendedDept = result.recommended_department || result.recommendedDepartment;
    
    if (!result || !recommendedDept) {
      // 打印实际返回的数据结构，方便调试
      console.error('❌ 返回结果缺少 recommended_department 字段');
      console.error('实际返回的数据结构:', JSON.stringify(result, null, 2));
      console.error('可用的字段:', result ? Object.keys(result) : 'result 为空');
      throw new Error(`百度 API 返回结果格式不正确，缺少 recommended_department 字段。实际返回: ${JSON.stringify(result)}`);
    }

    // 统一使用下划线命名
    if (!result.recommended_department && result.recommendedDepartment) {
      result.recommended_department = result.recommendedDepartment;
    }
    
    const deptId = result.recommended_department.id;
    if (!deptId) {
      console.error('❌ 返回的科室对象缺少 id 字段');
      console.error('科室对象内容:', JSON.stringify(result.recommended_department, null, 2));
      throw new Error(`百度 API 返回的科室对象缺少 id 字段。科室对象: ${JSON.stringify(result.recommended_department)}`);
    }
    
    const dept = departments.find(d => d.id === deptId);
    if (!dept) {
      throw new Error(`百度 API 返回的科室ID ${deptId} 不存在于数据库中。可用科室: ${departments.map(d => `${d.id}:${d.name}`).join(', ')}`);
    }

    // 确保科室名称正确
    result.recommended_department.name = dept.name;

    console.log('✅ 分诊完成，返回结果:', JSON.stringify(result).substring(0, 200) + '...');
    res.json(result);
  } catch (error) {
    console.error('❌ AI 分诊失败:', error);
    console.error('错误堆栈:', error.stack);
    
    res.status(500).json({ 
      error: 'AI 分析失败', 
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

/**
 * 降级方案：基于关键词匹配推荐科室
 */
async function fallbackDepartmentRecommendation(symptoms, departments) {
  try {
    // 如果 departments 为空，先查询所有科室
    if (!departments || departments.length === 0) {
      try {
        const [deptRows] = await pool.execute(
          `SELECT department_id as id, name, description 
           FROM departments 
           ORDER BY department_id 
           LIMIT 10`
        );
        departments = deptRows;
      } catch (err) {
        console.warn('⚠️ 查询科室失败，使用默认值:', err.message);
      }
    }

    // 查询症状-科室映射表
    try {
      const [mappings] = await pool.execute(
        `SELECT department_id, priority 
         FROM symptom_department_mapping 
         WHERE symptom_keywords LIKE ? 
         ORDER BY priority ASC 
         LIMIT 1`,
        [`%${symptoms}%`]
      );

      if (mappings.length > 0) {
        const mapping = mappings[0];
        const dept = departments.find(d => d.id === mapping.department_id);
        if (dept) {
          return {
            analysis: `根据您的症状描述"${symptoms}"，建议前往 ${dept.name} 就诊。`,
            recommended_department: {
              id: dept.id,
              name: dept.name,
              reason: '症状匹配推荐'
            }
          };
        }
      }
    } catch (err) {
      console.warn('⚠️ 查询症状映射失败:', err.message);
    }

    // 如果都没有匹配，返回第一个科室或默认值
    const defaultDept = departments.length > 0 ? departments[0] : { id: 1, name: '内科' };
    return {
      analysis: `根据您的症状描述"${symptoms}"，建议前往 ${defaultDept.name} 就诊。如症状持续或加重，请及时就医。`,
      recommended_department: {
        id: defaultDept.id,
        name: defaultDept.name,
        reason: '默认推荐'
      }
    };
  } catch (error) {
    console.error('❌ 降级方案执行失败:', error.message);
    // 最后的兜底方案
    return {
      analysis: `根据您的症状描述，建议前往内科就诊。如症状持续或加重，请及时就医。`,
      recommended_department: {
        id: 1,
        name: '内科',
        reason: '默认推荐'
      }
    };
  }
}

/**
 * 接口 3: 医生智能推荐
 * POST /api/pre-triage/recommend-doctor
 */
app.post('/api/pre-triage/recommend-doctor', async (req, res) => {
  try {
    const { department_id, symptoms } = req.body;

    if (!department_id) {
      return res.status(400).json({ error: '科室ID不能为空' });
    }

    // 1. 查询该科室下的所有医生
    const [doctors] = await pool.execute(
      `SELECT doctor_id as id, full_name as name, title, specialty, photo_url as avatar
       FROM doctors 
       WHERE department_id = ? AND status = 'active'
       ORDER BY title_level ASC, doctor_id ASC`,
      [department_id]
    );

    if (doctors.length === 0) {
      return res.json([]);
    }

    // 2. 构建 Prompt
    const doctorList = doctors.map(d => 
      `- ${d.name}（${d.title}）：${d.specialty || '暂无擅长描述'}`
    ).join('\n');

    const userPrompt = `患者症状：${symptoms || '未提供具体症状'}

该科室有以下医生及其擅长领域：
${doctorList}

请判断哪位医生最适合该患者，并给出推荐理由。请以 JSON 格式返回结果：
{
  "recommended_doctors": [
    {
      "id": 医生ID,
      "name": "医生姓名",
      "title": "职称",
      "specialty": "擅长领域",
      "reason": "推荐理由（50字以内）"
    }
  ]
}
返回 1-3 位推荐医生，按推荐优先级排序。`;

    // 3. 调用通义千问大模型
    console.log('🤖 调用通义千问 LLM 推荐医生...');
    const llmResponse = await callQwenLLM(userPrompt);
    
    // 4. 解析响应
    let result;
    try {
      result = parseJSONResponse(llmResponse);
    } catch (e) {
      console.warn('JSON 解析失败，返回所有医生:', e.message);
      // 降级：返回所有医生
      result = {
        recommended_doctors: doctors.map(d => ({
          id: d.id,
          name: d.name,
          title: d.title,
          specialty: d.specialty || '暂无',
          reason: '科室推荐'
        }))
      };
    }

    // 验证并补充医生信息
    if (result.recommended_doctors && Array.isArray(result.recommended_doctors)) {
      result.recommended_doctors = result.recommended_doctors.map(rec => {
        const doctor = doctors.find(d => d.id === rec.id || d.name === rec.name);
        if (doctor) {
          return {
            id: doctor.id,
            name: doctor.name,
            title: doctor.title,
            specialty: doctor.specialty || rec.specialty || '暂无',
            avatar: doctor.avatar || null,
            reason: rec.reason || 'AI 推荐'
          };
        }
        return null;
      }).filter(Boolean);
    } else {
      // 如果格式不对，返回所有医生
      result.recommended_doctors = doctors.map(d => ({
        id: d.id,
        name: d.name,
        title: d.title,
        specialty: d.specialty || '暂无',
        avatar: d.avatar || null,
        reason: '科室推荐'
      }));
    }

    res.json(result.recommended_doctors || []);
  } catch (error) {
    console.error('医生推荐失败:', error);
    res.status(500).json({ error: '医生推荐失败', message: error.message });
  }
});

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'AI 预问诊服务运行正常' });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 AI 预问诊服务已启动`);
  console.log(`📍 服务地址: http://localhost:${PORT}`);
  console.log(`📝 请确保已配置 .env 文件中的数据库和通义千问 API 密钥`);
});

