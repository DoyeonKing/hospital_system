import csv
from collections import Counter, defaultdict

# 读取CSV文件
input_file = r'd:\桌面\data\儿科-symptoms_extracted.csv'

# 用于按科室统计词的出现次数：{department: Counter}
department_word_counters = defaultdict(Counter)

# 读取CSV文件
with open(input_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        department = row.get('department', '').strip()
        symptoms_combined = row.get('symptoms_combined', '').strip()
        
        # 如果科室和症状都不为空，按逗号分割并统计
        if department and symptoms_combined:
            # 按逗号分割，去除空格
            words = [word.strip() for word in symptoms_combined.split(',') if word.strip()]
            # 统计该科室每个词的出现次数
            department_word_counters[department].update(words)

# 按科室输出前100个最常见的词（以逗号分隔）
for department in sorted(department_word_counters.keys()):
    word_counter = department_word_counters[department]
    top_100_words = word_counter.most_common(100)
    
    # 提取前100个词（只要词本身，不要计数）
    words_list = [word for word, count in top_100_words]
    # 用逗号连接
    words_str = ','.join(words_list)
    
    print(f"\n{'='*60}")
    print(f"科室: {department}")
    print(f"总共统计了 {len(word_counter)} 个不同的词")
    print(f"总词频: {sum(word_counter.values())} 次")
    print(f"\n前100个最常见的词（逗号分隔）:")
    print(words_str)

