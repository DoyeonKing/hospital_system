#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
疾病类型到科室名称的映射

简单直接的映射字典，只返回科室名称（不是ID）
"""

# 疾病类型到科室名称的映射字典
DISEASE_TO_DEPARTMENT = {
    # 呼吸系统疾病 -> 呼吸内科
    'Allergy': '呼吸内科',
    'Bronchitis': '呼吸内科',
    'Influenza': '呼吸内科',
    'Common Cold': '呼吸内科',
    'Pneumonia': '呼吸内科',
    'Tuberculosis': '呼吸内科',
    'Asthma': '呼吸内科',
    'Sinusitis': '呼吸内科',
    'COVID-19': '呼吸内科',
    
    # 心血管疾病 -> 心血管内科
    'Heart Disease': '心血管内科',
    'Hypertension': '心血管内科',
    'Arrhythmia': '心血管内科',
    
    # 消化系统疾病 -> 消化内科
    'Gastritis': '消化内科',
    'IBS': '消化内科',  # 肠易激综合征
    'Food Poisoning': '消化内科',
    'GERD': '消化内科',  # 胃食管反流病
    'Liver Disease': '消化内科',
    'Hepatitis': '消化内科',
    
    # 内分泌疾病 -> 消化内科（如果没有单独的内分泌科）
    'Diabetes': '消化内科',  # 糖尿病通常看内分泌科
    'Thyroid Disorder': '消化内科',  # 甲状腺疾病看内分泌科
    'Obesity': '消化内科',  # 肥胖症看内分泌科
    'Anemia': '消化内科',  # 贫血看血液科或内科
    
    # 神经系统疾病 -> 神经内科
    'Stroke': '神经内科',
    'Migraine': '神经内科',
    'Epilepsy': '神经内科',
    'Parkinson\'s': '神经内科',
    'Dementia': '神经内科',
    'Depression': '神经内科',
    'Anxiety': '神经内科',
    
    # 骨科疾病 -> 骨科
    'Arthritis': '骨科',
    'Osteoporosis': '骨科',
    'Fracture': '骨科',
    
    # 皮肤疾病 -> 普外科（如果没有皮肤科）
    'Dermatitis': '普外科',
    
    # 其他疾病
    # 可以根据需要继续添加
}


def get_department_by_disease(disease: str) -> str:
    """
    根据疾病类型获取科室名称
    
    Args:
        disease: 疾病类型名称（如 "Allergy", "Heart Disease"）
    
    Returns:
        科室名称（如 "呼吸内科", "心血管内科"），如果无法映射则返回 None
    """
    # 去除首尾空格
    disease = disease.strip()
    
    # 直接查找
    if disease in DISEASE_TO_DEPARTMENT:
        return DISEASE_TO_DEPARTMENT[disease]
    
    # 模糊匹配（处理可能的变体）
    disease_lower = disease.lower()
    for key, dept_name in DISEASE_TO_DEPARTMENT.items():
        if key.lower() in disease_lower or disease_lower in key.lower():
            return dept_name
    
    # 如果无法映射，返回None
    return None


def map_disease_to_department(disease: str) -> str:
    """
    映射疾病到科室（带默认值）
    
    Args:
        disease: 疾病类型名称
    
    Returns:
        科室名称，如果无法映射则返回 "未分类"
    """
    result = get_department_by_disease(disease)
    return result if result else "未分类"


# 使用示例
if __name__ == '__main__':
    # 测试示例
    test_diseases = [
        'Allergy',
        'Heart Disease',
        'Diabetes',
        'Stroke',
        'Arthritis',
        'Unknown Disease'  # 不存在的疾病
    ]
    
    print("疾病类型 -> 科室名称映射示例：")
    print("-" * 50)
    for disease in test_diseases:
        department = map_disease_to_department(disease)
        print(f"{disease:20} -> {department}")
    
    print("\n" + "=" * 50)
    print("所有可用的疾病类型：")
    print("-" * 50)
    for disease, dept in sorted(DISEASE_TO_DEPARTMENT.items()):
        print(f"{disease:25} -> {dept}")

