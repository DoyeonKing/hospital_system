import csv
from collections import defaultdict

# 读取CSV文件（使用原始字符串避免转义问题）
input_file = r'd:\桌面\data\儿科-symptoms_extracted.csv'
output_file = r'd:\桌面\data\儿科-deduplicated_symptoms.csv'

# 用于存储去重后的数据：{department: set(symptoms_combined)}
department_symptoms = defaultdict(set)

# 读取CSV文件
with open(input_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    
    for row in reader:
        department = row.get('department', '').strip()
        symptoms_combined = row.get('symptoms_combined', '').strip()
        
        # 如果科室和症状都不为空，添加到集合中（自动去重）
        if department and symptoms_combined:
            department_symptoms[department].add(symptoms_combined)

# 转换为列表格式用于写入CSV
result = []
for department, symptoms_set in department_symptoms.items():
    for symptoms in symptoms_set:
        result.append({
            'department': department,
            'symptoms_combined': symptoms
        })

# 写入结果CSV文件
with open(output_file, 'w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['department', 'symptoms_combined'])
    writer.writeheader()
    writer.writerows(result)

# 统计信息
print(f"去重完成！共 {len(result)} 条记录")
print(f"结果已保存到: {output_file}")
print("\n各科室统计:")
for department, symptoms_set in sorted(department_symptoms.items()):
    print(f"  {department}: {len(symptoms_set)} 条")

