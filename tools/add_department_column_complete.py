import csv

# 完整的疾病类型到科室名称映射（根据所有可能的疾病）
DISEASE_TO_DEPARTMENT = {
    # 呼吸内科
    'Allergy': '呼吸内科',
    'Bronchitis': '呼吸内科',
    'Influenza': '呼吸内科',
    'Common Cold': '呼吸内科',
    'Pneumonia': '呼吸内科',
    'Tuberculosis': '呼吸内科',
    'Asthma': '呼吸内科',
    'Sinusitis': '呼吸内科',
    'COVID-19': '呼吸内科',
    
    # 心血管内科
    'Heart Disease': '心血管内科',
    'Hypertension': '心血管内科',
    'Arrhythmia': '心血管内科',
    
    # 消化内科
    'Gastritis': '消化内科',
    'IBS': '消化内科',
    'Food Poisoning': '消化内科',
    'GERD': '消化内科',
    'Liver Disease': '消化内科',
    'Hepatitis': '消化内科',
    'Ulcer': '消化内科',
    'Diabetes': '消化内科',
    'Thyroid Disorder': '消化内科',
    'Obesity': '消化内科',
    'Anemia': '消化内科',
    
    # 神经内科
    'Stroke': '神经内科',
    'Migraine': '神经内科',
    'Epilepsy': '神经内科',
    'Parkinson\'s': '神经内科',
    'Dementia': '神经内科',
    'Depression': '神经内科',
    'Anxiety': '神经内科',
    
    # 骨科
    'Arthritis': '骨科',
    'Osteoporosis': '骨科',
    'Fracture': '骨科',
    
    # 皮肤科
    'Dermatitis': '皮肤科',
    
    # 泌尿外科
    'Chronic Kidney Disease': '泌尿外科',
    'Kidney Disease': '泌尿外科',
    'Urinary Tract Infection': '泌尿外科',
    'Kidney Stones': '泌尿外科',
    
    # 妇科（如果有相关疾病）
    'Gynecological Disorder': '妇科',
    'Menstrual Disorder': '妇科',
    
    # 眼科（如果有相关疾病）
    'Eye Disease': '眼科',
    'Vision Problem': '眼科',
    
    # 耳鼻喉科（如果有相关疾病）
    'Ear Infection': '耳鼻喉科',
    'Hearing Loss': '耳鼻喉科',
    
    # 口腔科（如果有相关疾病）
    'Dental Problem': '口腔科',
    'Toothache': '口腔科',
}

# 读取CSV文件并添加Department列
input_file = r'd:\桌面\Healthcare.csv'
output_file = r'd:\桌面\Healthcare_with_department.csv'

with open(input_file, 'r', encoding='utf-8') as f_in, \
     open(output_file, 'w', encoding='utf-8', newline='') as f_out:
    
    reader = csv.DictReader(f_in)
    fieldnames = list(reader.fieldnames) + ['Department']
    writer = csv.DictWriter(f_out, fieldnames=fieldnames)
    
    writer.writeheader()
    
    unmapped_diseases = set()
    
    for row in reader:
        disease = row['Disease'].strip()
        
        # 直接查找
        if disease in DISEASE_TO_DEPARTMENT:
            department = DISEASE_TO_DEPARTMENT[disease]
        else:
            # 模糊匹配（处理可能的变体）
            disease_lower = disease.lower()
            found = False
            for key, dept in DISEASE_TO_DEPARTMENT.items():
                if key.lower() in disease_lower or disease_lower in key.lower():
                    department = dept
                    found = True
                    break
            
            if not found:
                # 根据疾病名称关键词推断科室
                if any(keyword in disease_lower for keyword in ['kidney', 'renal', 'urinary', 'bladder']):
                    department = '泌尿外科'
                elif any(keyword in disease_lower for keyword in ['heart', 'cardiac', 'cardiovascular', 'hypertension']):
                    department = '心血管内科'
                elif any(keyword in disease_lower for keyword in ['lung', 'respiratory', 'breath', 'cough', 'asthma', 'bronchitis', 'pneumonia', 'tuberculosis', 'allergy', 'sinus']):
                    department = '呼吸内科'
                elif any(keyword in disease_lower for keyword in ['stomach', 'gastric', 'gastro', 'digestive', 'liver', 'hepatitis', 'diabetes', 'thyroid', 'obesity', 'anemia', 'ulcer', 'ibs']):
                    department = '消化内科'
                elif any(keyword in disease_lower for keyword in ['brain', 'neurological', 'stroke', 'epilepsy', 'parkinson', 'dementia', 'depression', 'anxiety', 'migraine', 'nerve']):
                    department = '神经内科'
                elif any(keyword in disease_lower for keyword in ['bone', 'joint', 'arthritis', 'fracture', 'orthopedic', 'spine']):
                    department = '骨科'
                elif any(keyword in disease_lower for keyword in ['skin', 'dermatitis', 'rash', 'eczema']):
                    department = '皮肤科'
                elif any(keyword in disease_lower for keyword in ['eye', 'vision', 'ophthalmic']):
                    department = '眼科'
                elif any(keyword in disease_lower for keyword in ['ear', 'nose', 'throat', 'hearing', 'sinus']):
                    department = '耳鼻喉科'
                elif any(keyword in disease_lower for keyword in ['dental', 'tooth', 'oral', 'gum']):
                    department = '口腔科'
                elif any(keyword in disease_lower for keyword in ['gynecological', 'menstrual', 'ovarian', 'uterine']):
                    department = '妇科'
                else:
                    department = '普外科'  # 默认归类到普外科
                    unmapped_diseases.add(disease)
        
        row['Department'] = department
        writer.writerow(row)

print(f'处理完成！输出文件: {output_file}')
if unmapped_diseases:
    print(f'\n未明确映射的疾病类型（已归类到普外科）: {sorted(unmapped_diseases)}')

