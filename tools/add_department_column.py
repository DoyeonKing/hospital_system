#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import csv

# 疾病类型到科室名称的映射
DISEASE_TO_DEPARTMENT = {
    'Allergy': '呼吸内科',
    'Bronchitis': '呼吸内科',
    'Influenza': '呼吸内科',
    'Common Cold': '呼吸内科',
    'Pneumonia': '呼吸内科',
    'Tuberculosis': '呼吸内科',
    'Asthma': '呼吸内科',
    'Sinusitis': '呼吸内科',
    'COVID-19': '呼吸内科',
    'Heart Disease': '心血管内科',
    'Hypertension': '心血管内科',
    'Arrhythmia': '心血管内科',
    'Gastritis': '消化内科',
    'IBS': '消化内科',
    'Food Poisoning': '消化内科',
    'GERD': '消化内科',
    'Liver Disease': '消化内科',
    'Hepatitis': '消化内科',
    'Diabetes': '消化内科',
    'Thyroid Disorder': '消化内科',
    'Obesity': '消化内科',
    'Anemia': '消化内科',
    'Stroke': '神经内科',
    'Migraine': '神经内科',
    'Epilepsy': '神经内科',
    'Parkinson\'s': '神经内科',
    'Dementia': '神经内科',
    'Depression': '神经内科',
    'Anxiety': '神经内科',
    'Arthritis': '骨科',
    'Osteoporosis': '骨科',
    'Fracture': '骨科',
    'Dermatitis': '普外科',
}

# 读取CSV文件
input_file = r'd:\桌面\Healthcare.csv'
output_file = r'd:\桌面\Healthcare_with_department.csv'

with open(input_file, 'r', encoding='utf-8') as f_in, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.DictReader(f_in)
    fieldnames = reader.fieldnames + ['Department']
    writer = csv.DictWriter(f_out, fieldnames=fieldnames)
    
    writer.writeheader()
    
    for row in reader:
        disease = row['Disease'].strip()
        department = DISEASE_TO_DEPARTMENT.get(disease, '未分类')
        row['Department'] = department
        writer.writerow(row)

print(f'处理完成！输出文件: {output_file}')

