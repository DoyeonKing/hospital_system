#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
从CSV文件的title和ask列中提取关键词作为symptoms，用于训练模型

使用方法:
    方法1: 直接运行（使用代码中配置的默认文件路径）
        python extract_symptoms_from_csv.py
    
    方法2: 命令行指定文件路径
        python extract_symptoms_from_csv.py <input_csv> [--output <output_file>] [--method <method>] [--topk <k>]
    
参数:
    input_csv: 输入的CSV文件路径（可选，如果不提供则使用代码中的DEFAULT_INPUT_FILE）
    --output: 输出文件路径（默认：symptoms_extracted.csv）
    --method: 提取方法，可选：tfidf, textrank, both（默认：both）
    --topk: 每个文本提取的关键词数量（默认：10）
    --limit: 处理的行数限制（用于测试，默认：全部）

注意: 可以在代码顶部的"配置区域"修改默认参数
"""
import csv
import sys
import os
import argparse
import re
from collections import Counter
from typing import List, Dict, Tuple

try:
    import jieba
    import jieba.analyse
    JIEBA_AVAILABLE = True
except ImportError:
    JIEBA_AVAILABLE = False
    print("警告: 未安装jieba库，将使用简单分词方法")
    print("建议安装: pip install jieba")

# ==================== 配置区域 ====================
# 默认输入文件路径（可以直接修改这里）
DEFAULT_INPUT_FILE = r"d:\桌面\data\儿科5-14000.csv"

# 默认输出文件路径
DEFAULT_OUTPUT_FILE = "symptoms_extracted.csv"

# 默认提取方法: 'tfidf', 'textrank', 或 'both'
DEFAULT_METHOD = 'both'

# 默认提取关键词数量
DEFAULT_TOPK = 10

# 默认处理行数限制（None表示处理全部，可以设置数字用于测试）
DEFAULT_LIMIT = None
# ==================================================

# 医疗相关的停用词（可以根据需要扩展）
MEDICAL_STOPWORDS = {
    # 基础停用词
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', 
    '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', 
    '自己', '这', '那', '他', '她', '它', '我们', '你们', '他们', '这个', '那个',
    '什么', '怎么', '为什么', '如何', '怎样', '可以', '应该', '需要', '如果',
    '但是', '然后', '所以', '因为', '而且', '还是', '或者',
    # 医疗通用词（非症状）
    '孩子', '小孩', '儿童', '患者', '病人', '医生', '医院', '治疗', '症状',
    '问题', '情况', '时候', '时间', '现在', '目前', '最近', '几天', '一年',
    '岁', '年', '月', '日', '天', '小时', '分钟',
    # 无意义的词
    '请问', '察觉', '察觉到', '发现', '观察', '观察到', '我家', '刚岁', '肉乎',
    '起来', '好像', '愿意', '特别', '非常', '一般', '平时', '同时', '而且',
    '还', '还', '还', '还', '还', '还', '还', '还', '还', '还', '还', '还',
    '男宝', '女宝', '男孩子', '女孩子', '男孩', '女孩',
    # 时间词
    '今年', '去年', '明年', '今天', '昨天', '明天', '刚才', '刚刚',
    # 语气词
    '啊', '呢', '吧', '吗', '呀', '哦', '嗯', '唉',
    # 其他无意义词
    '这个', '那个', '这样', '那样', '这样', '那样'
}

# 医疗症状关键词词典（用于提升症状相关词的权重）
MEDICAL_SYMPTOMS_DICT = {
    # 常见症状
    '发热', '发烧', '咳嗽', '咳痰', '气喘', '气短', '呼吸困难', '胸闷', '胸痛',
    '头痛', '头晕', '眩晕', '恶心', '呕吐', '腹泻', '便秘', '腹痛', '腹胀',
    '食欲不振', '食欲减退', '消化不良', '反酸', '嗳气', '打嗝',
    '皮疹', '瘙痒', '红肿', '疼痛', '酸痛', '胀痛', '刺痛', '隐痛',
    '乏力', '疲劳', '疲倦', '失眠', '多梦', '嗜睡', '精神不振',
    '心悸', '心慌', '心跳', '心律不齐',
    '尿频', '尿急', '尿痛', '血尿', '蛋白尿',
    '关节痛', '关节肿', '肌肉痛', '背痛', '腰痛',
    '视力模糊', '视力下降', '眼痛', '眼干', '流泪',
    '耳鸣', '听力下降', '耳痛', '流脓',
    '鼻塞', '流涕', '打喷嚏', '鼻痒', '嗅觉减退',
    '咽痛', '咽干', '声音嘶哑', '吞咽困难',
    '体重下降', '体重增加', '肥胖', '超重', '消瘦',
    '多汗', '盗汗', '少汗', '口干', '口苦',
    '焦虑', '抑郁', '情绪低落', '易怒', '烦躁',
    '记忆力下降', '注意力不集中', '反应迟钝',
    # 儿科常见症状
    '哭闹', '烦躁不安', '食欲差', '拒食', '厌食',
    '发育迟缓', '生长缓慢', '身高不足', '体重不足',
    '多动', '注意力不集中', '学习困难',
    '夜惊', '夜啼', '磨牙',
    # 其他
    '出血', '淤血', '瘀斑', '紫癜',
    '水肿', '浮肿', '肿胀',
    '黄疸', '皮肤发黄',
    '贫血', '面色苍白', '口唇发白'
}

# 初始化jieba词典
def init_jieba_dict():
    """初始化jieba分词器，添加医疗词典"""
    if JIEBA_AVAILABLE:
        # 添加医疗症状词典到jieba
        for word in MEDICAL_SYMPTOMS_DICT:
            jieba.add_word(word, freq=1000, tag='n')  # 设置为名词，提高权重
        
        # 注意：jieba的停用词需要在extract_tags时通过stop_words参数传入
        # 这里我们会在提取函数中处理停用词

def read_csv_file(csv_file_path: str) -> Tuple[List[str], List[List[str]], str]:
    """
    读取CSV文件，自动检测编码
    
    Returns:
        (header, rows, encoding_used) 或 None
    """
    encodings = ['gbk', 'gb18030', 'gb2312', 'utf-8-sig', 'utf-8', 'big5', 'latin-1', 'cp1252', 'iso-8859-1']
    
    for encoding in encodings:
        try:
            with open(csv_file_path, 'r', encoding=encoding, newline='') as f:
                reader = csv.reader(f)
                header = next(reader, None)
                rows = []
                for row in reader:
                    if row and len(row) > 0:
                        rows.append(row)
                return header, rows, encoding
        except UnicodeDecodeError:
            continue
        except Exception as e:
            if encoding == encodings[-1]:
                print(f"读取文件 {csv_file_path} 时出错: {e}")
            continue
    
    return None, None, None

def simple_tokenize(text: str) -> List[str]:
    """
    简单的分词方法（当jieba不可用时使用）
    """
    if not text:
        return []
    
    # 移除标点符号和数字
    text = re.sub(r'[^\u4e00-\u9fa5]', ' ', text)
    # 简单的字符级分词（每个字符作为一个词）
    words = [w for w in text.split() if len(w) > 1]
    return words

def preprocess_text(text: str) -> str:
    """
    预处理文本：清理和标准化
    """
    if not text:
        return ""
    
    # 移除多余空格
    text = re.sub(r'\s+', ' ', text)
    # 移除特殊字符但保留中文标点
    text = re.sub(r'[^\u4e00-\u9fa5\s，。！？、；：]', '', text)
    
    # 移除一些无意义的标点和连接词
    text = re.sub(r'[，。！？、；：]+', ' ', text)
    
    return text.strip()

def is_valid_keyword(word: str) -> bool:
    """
    判断关键词是否有效
    """
    if not word or len(word) < 2:
        return False
    
    # 过滤停用词
    if word in MEDICAL_STOPWORDS:
        return False
    
    # 过滤纯数字
    if word.isdigit():
        return False
    
    # 过滤单个字符
    if len(word) == 1:
        return False
    
    # 过滤无意义的通用词
    invalid_words = {
        '喜欢', '重要', '小学', '中学', '大学', '学校', '上学', '上课',
        '知道', '了解', '明白', '清楚', '记得', '忘记',
        '觉得', '认为', '以为', '希望', '想要', '需要',
        '开始', '结束', '完成', '继续', '停止',
        '可能', '也许', '大概', '应该', '必须',
        '这样', '那样', '一些', '一点', '很多', '很少', '多少',
        '今天', '明天', '昨天', '刚才', '刚刚',
        '男宝', '女宝', '男孩', '女孩', '男孩子', '女孩子',
        '我家', '你家', '他家', '大家',
        '起来', '下去', '上来', '下来',
        '请问', '察觉', '发现', '观察', '看到', '听到',
        '愿意', '不想', '特别', '非常', '一般', '平时', '同时', '而且',
        '重要', '主要', '次要', '关键',
        '治疗', '医治', '看病', '就医', '医院', '医生',
        '如何', '怎样', '怎么', '为什么',
    }
    
    if word in invalid_words:
        return False
    
    # 过滤无意义的组合词（正则模式）
    invalid_patterns = [
        r'^刚\d+岁$',      # 刚7岁
        r'^\d+岁$',        # 7岁
        r'^\d+年$',        # 2023年
        r'^\d+月$',        # 1月
        r'^\d+日$',        # 1日
        r'^第\d+$',       # 第一
    ]
    
    for pattern in invalid_patterns:
        if re.match(pattern, word):
            return False
    
    return True

def filter_keywords(keywords: List[Tuple[str, float]]) -> List[Tuple[str, float]]:
    """
    过滤和优化关键词列表
    """
    filtered = []
    seen = set()
    
    for word, weight in keywords:
        # 清理词
        word = word.strip()
        
        # 检查是否有效
        if not is_valid_keyword(word):
            continue
        
        # 去重
        if word in seen:
            continue
        seen.add(word)
        
        # 如果是症状词典中的词，大幅提高权重
        if word in MEDICAL_SYMPTOMS_DICT:
            weight *= 2.0  # 大幅提高症状词的权重，优先显示
        # 如果包含症状相关字符，适度提高权重
        elif any(char in word for char in ['痛', '热', '咳', '喘', '肿', '痒', '红', '黄', '白', '黑', '血', '炎', '病', '症']):
            weight *= 1.2
        
        filtered.append((word, weight))
    
    # 按权重排序（症状词会排在前面）
    filtered.sort(key=lambda x: x[1], reverse=True)
    
    return filtered

def extract_keywords_tfidf(text: str, topk: int = 10) -> List[Tuple[str, float]]:
    """
    使用TF-IDF方法提取关键词
    """
    if not text or not text.strip():
        return []
    
    try:
        # 使用jieba的TF-IDF提取（提取更多候选词，后续会过滤）
        # 传入停用词列表
        keywords = jieba.analyse.extract_tags(
            text, 
            topK=topk * 3,  # 提取更多候选词以便过滤
            withWeight=True,
            allowPOS=('n', 'vn', 'a', 'v')  # 只保留名词、动名词、形容词、动词
        )
        # 过滤和优化关键词
        keywords = filter_keywords(keywords)
        # 按权重排序
        keywords.sort(key=lambda x: x[1], reverse=True)
        # 返回前topk个
        return keywords[:topk]
    except Exception as e:
        print(f"TF-IDF提取出错: {e}")
        return []

def extract_keywords_textrank(text: str, topk: int = 10) -> List[Tuple[str, float]]:
    """
    使用TextRank方法提取关键词
    """
    if not text or not text.strip():
        return []
    
    try:
        # 使用jieba的TextRank提取（提取更多候选词，后续会过滤）
        keywords = jieba.analyse.textrank(
            text, 
            topK=topk * 3,  # 提取更多候选词以便过滤
            withWeight=True,
            allowPOS=('n', 'vn', 'a', 'v')  # 只保留名词、动名词、形容词、动词
        )
        # 过滤和优化关键词
        keywords = filter_keywords(keywords)
        # 按权重排序
        keywords.sort(key=lambda x: x[1], reverse=True)
        # 返回前topk个
        return keywords[:topk]
    except Exception as e:
        print(f"TextRank提取出错: {e}")
        return []

def extract_keywords_simple(text: str, topk: int = 10) -> List[str]:
    """
    简单的关键词提取（不使用jieba时）
    """
    if not text:
        return []
    
    words = simple_tokenize(text)
    # 过滤停用词
    words = [w for w in words if w not in MEDICAL_STOPWORDS and len(w) > 1]
    # 统计词频
    word_freq = Counter(words)
    # 返回频率最高的词
    top_words = [word for word, freq in word_freq.most_common(topk)]
    return top_words

def extract_symptoms_from_row(row: List[str], header: List[str], 
                              method: str = 'both', topk: int = 10) -> Dict:
    """
    从一行数据中提取symptoms
    
    Args:
        row: CSV行数据
        header: CSV表头
        method: 提取方法 (tfidf, textrank, both)
        topk: 每个文本提取的关键词数量
    
    Returns:
        包含提取结果的字典
    """
    result = {
        'department': '',
        'title': '',
        'ask': '',
        'symptoms_tfidf': '',
        'symptoms_textrank': '',
        'symptoms_combined': ''
    }
    
    # 获取列索引
    try:
        dept_idx = header.index('department') if 'department' in header else -1
        title_idx = header.index('title') if 'title' in header else -1
        ask_idx = header.index('ask') if 'ask' in header else -1
    except ValueError:
        print(f"警告: CSV文件缺少必要的列 (department, title, ask)")
        return result
    
    # 提取数据
    if dept_idx >= 0 and dept_idx < len(row):
        result['department'] = row[dept_idx].strip() if row[dept_idx] else ''
    if title_idx >= 0 and title_idx < len(row):
        result['title'] = row[title_idx].strip() if row[title_idx] else ''
    if ask_idx >= 0 and ask_idx < len(row):
        result['ask'] = row[ask_idx].strip() if row[ask_idx] else ''
    
    # 合并title和ask文本
    combined_text = f"{result['title']} {result['ask']}"
    combined_text = preprocess_text(combined_text)
    
    if not combined_text:
        return result
    
    # 提取关键词
    if JIEBA_AVAILABLE:
        if method in ['tfidf', 'both']:
            tfidf_keywords = extract_keywords_tfidf(combined_text, topk)
            result['symptoms_tfidf'] = ','.join([kw[0] for kw in tfidf_keywords])
        
        if method in ['textrank', 'both']:
            textrank_keywords = extract_keywords_textrank(combined_text, topk)
            result['symptoms_textrank'] = ','.join([kw[0] for kw in textrank_keywords])
        
        # 合并两种方法的结果
        if method == 'both':
            all_keywords = set()
            if result['symptoms_tfidf']:
                all_keywords.update(result['symptoms_tfidf'].split(','))
            if result['symptoms_textrank']:
                all_keywords.update(result['symptoms_textrank'].split(','))
            result['symptoms_combined'] = ','.join(list(all_keywords)[:topk])
        elif method == 'tfidf':
            result['symptoms_combined'] = result['symptoms_tfidf']
        elif method == 'textrank':
            result['symptoms_combined'] = result['symptoms_textrank']
    else:
        # 使用简单方法
        keywords = extract_keywords_simple(combined_text, topk)
        result['symptoms_combined'] = ','.join(keywords)
        result['symptoms_tfidf'] = result['symptoms_combined']
        result['symptoms_textrank'] = result['symptoms_combined']
    
    return result

def main():
    # 初始化jieba词典
    if JIEBA_AVAILABLE:
        init_jieba_dict()
        print("已加载医疗症状词典和停用词")
    
    parser = argparse.ArgumentParser(description='从CSV文件中提取symptoms关键词')
    parser.add_argument('input_csv', nargs='?', default=DEFAULT_INPUT_FILE,
                       help=f'输入的CSV文件路径（默认: {DEFAULT_INPUT_FILE}）')
    parser.add_argument('--output', '-o', default=DEFAULT_OUTPUT_FILE, 
                       help=f'输出文件路径（默认: {DEFAULT_OUTPUT_FILE}）')
    parser.add_argument('--method', '-m', choices=['tfidf', 'textrank', 'both'], 
                       default=DEFAULT_METHOD, help=f'提取方法（默认: {DEFAULT_METHOD}）')
    parser.add_argument('--topk', '-k', type=int, default=DEFAULT_TOPK, 
                       help=f'每个文本提取的关键词数量（默认: {DEFAULT_TOPK}）')
    parser.add_argument('--limit', '-l', type=int, default=DEFAULT_LIMIT,
                       help='处理的行数限制（用于测试，默认: 全部）')
    
    args = parser.parse_args()
    
    # 检查输入文件
    if not os.path.exists(args.input_csv):
        print(f"错误: 文件不存在: {args.input_csv}")
        print(f"\n提示: 可以在代码顶部修改 DEFAULT_INPUT_FILE 变量来设置默认文件路径")
        sys.exit(1)
    
    # 读取CSV文件
    print(f"正在读取文件: {args.input_csv}")
    header, rows, encoding = read_csv_file(args.input_csv)
    
    if header is None:
        print("错误: 无法读取CSV文件，请检查文件格式和编码")
        sys.exit(1)
    
    print(f"检测到编码: {encoding}")
    print(f"总行数: {len(rows)}")
    print(f"表头: {header}")
    
    # 限制处理行数（用于测试）
    if args.limit:
        rows = rows[:args.limit]
        print(f"限制处理行数: {args.limit}")
    
    # 提取symptoms
    print(f"\n开始提取symptoms (方法: {args.method}, 每个文本提取{args.topk}个关键词)...")
    results = []
    
    for i, row in enumerate(rows):
        if (i + 1) % 1000 == 0:
            print(f"已处理: {i + 1}/{len(rows)} 行")
        
        result = extract_symptoms_from_row(row, header, args.method, args.topk)
        results.append(result)
    
    print(f"完成! 共处理 {len(results)} 行")
    
    # 写入输出文件
    print(f"\n正在写入结果到: {args.output}")
    output_header = ['department', 'title', 'ask', 'symptoms_combined']
    if args.method == 'both':
        output_header = ['department', 'title', 'ask', 'symptoms_tfidf', 
                        'symptoms_textrank', 'symptoms_combined']
    elif args.method == 'tfidf':
        output_header = ['department', 'title', 'ask', 'symptoms_tfidf', 'symptoms_combined']
    elif args.method == 'textrank':
        output_header = ['department', 'title', 'ask', 'symptoms_textrank', 'symptoms_combined']
    
    with open(args.output, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=output_header)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"完成! 结果已保存到: {args.output}")
    
    # 统计信息
    print("\n统计信息:")
    total_symptoms = sum(1 for r in results if r['symptoms_combined'])
    print(f"成功提取symptoms的行数: {total_symptoms}/{len(results)}")
    
    # 显示一些示例
    print("\n示例结果（前5条）:")
    for i, result in enumerate(results[:5]):
        if result['symptoms_combined']:
            print(f"\n{i+1}. 科室: {result['department']}")
            print(f"   Title: {result['title'][:50]}...")
            print(f"   Symptoms: {result['symptoms_combined']}")

if __name__ == '__main__':
    main()

