import csv
import random

# 各科室的疾病和典型症状映射（基于医疗知识）
DEPARTMENT_DATA = {
    '妇科': [
        {
            'disease': 'Menstrual Disorder',
            'symptoms': ['irregular periods', 'abdominal pain', 'fatigue', 'mood swings', 'bloating']
        },
        {
            'disease': 'Polycystic Ovary Syndrome',
            'symptoms': ['irregular periods', 'weight gain', 'acne', 'excessive hair growth', 'fatigue']
        },
        {
            'disease': 'Endometriosis',
            'symptoms': ['pelvic pain', 'painful periods', 'abdominal pain', 'fatigue', 'nausea']
        },
        {
            'disease': 'Uterine Fibroids',
            'symptoms': ['heavy periods', 'pelvic pain', 'abdominal pain', 'back pain', 'frequent urination']
        },
        {
            'disease': 'Ovarian Cyst',
            'symptoms': ['pelvic pain', 'abdominal pain', 'bloating', 'nausea', 'irregular periods']
        },
        {
            'disease': 'Vaginal Infection',
            'symptoms': ['vaginal discharge', 'itching', 'irritation', 'pain', 'odor']
        },
        {
            'disease': 'Cervical Dysplasia',
            'symptoms': ['abnormal bleeding', 'pelvic pain', 'discharge', 'fatigue']
        },
    ],
    '普外科': [
        {
            'disease': 'Appendicitis',
            'symptoms': ['abdominal pain', 'nausea', 'vomiting', 'fever', 'loss of appetite']
        },
        {
            'disease': 'Gallstones',
            'symptoms': ['abdominal pain', 'nausea', 'vomiting', 'fever', 'jaundice']
        },
        {
            'disease': 'Hernia',
            'symptoms': ['abdominal pain', 'swelling', 'discomfort', 'nausea', 'constipation']
        },
        {
            'disease': 'Intestinal Obstruction',
            'symptoms': ['abdominal pain', 'vomiting', 'constipation', 'bloating', 'nausea']
        },
        {
            'disease': 'Cholecystitis',
            'symptoms': ['abdominal pain', 'fever', 'nausea', 'vomiting', 'tenderness']
        },
        {
            'disease': 'Diverticulitis',
            'symptoms': ['abdominal pain', 'fever', 'nausea', 'constipation', 'diarrhea']
        },
        {
            'disease': 'Pancreatitis',
            'symptoms': ['abdominal pain', 'nausea', 'vomiting', 'fever', 'tenderness']
        },
        {
            'disease': 'Abdominal Abscess',
            'symptoms': ['abdominal pain', 'fever', 'nausea', 'swelling', 'tenderness']
        },
    ],
    '眼科': [
        {
            'disease': 'Conjunctivitis',
            'symptoms': ['red eyes', 'itching', 'tearing', 'discharge', 'irritation']
        },
        {
            'disease': 'Cataract',
            'symptoms': ['blurred vision', 'cloudy vision', 'sensitivity to light', 'double vision', 'fading colors']
        },
        {
            'disease': 'Glaucoma',
            'symptoms': ['eye pain', 'blurred vision', 'headache', 'nausea', 'halos around lights']
        },
        {
            'disease': 'Dry Eye Syndrome',
            'symptoms': ['dry eyes', 'burning', 'itching', 'redness', 'blurred vision']
        },
        {
            'disease': 'Retinal Detachment',
            'symptoms': ['floaters', 'flashes of light', 'blurred vision', 'shadow in vision', 'reduced vision']
        },
        {
            'disease': 'Macular Degeneration',
            'symptoms': ['blurred vision', 'distorted vision', 'dark spots', 'difficulty reading', 'color changes']
        },
    ],
    '耳鼻喉科': [
        {
            'disease': 'Otitis Media',
            'symptoms': ['ear pain', 'hearing loss', 'fever', 'drainage', 'irritability']
        },
        {
            'disease': 'Sinusitis',
            'symptoms': ['nasal congestion', 'facial pain', 'headache', 'postnasal drip', 'cough']
        },
        {
            'disease': 'Tonsillitis',
            'symptoms': ['sore throat', 'difficulty swallowing', 'fever', 'swollen tonsils', 'headache']
        },
        {
            'disease': 'Laryngitis',
            'symptoms': ['hoarseness', 'sore throat', 'dry cough', 'difficulty speaking', 'throat irritation']
        },
        {
            'disease': 'Hearing Loss',
            'symptoms': ['hearing difficulty', 'ringing in ears', 'dizziness', 'ear pressure', 'muffled hearing']
        },
        {
            'disease': 'Nasal Polyps',
            'symptoms': ['nasal congestion', 'runny nose', 'loss of smell', 'facial pain', 'snoring']
        },
    ],
    '口腔科': [
        {
            'disease': 'Tooth Decay',
            'symptoms': ['toothache', 'sensitivity', 'pain when eating', 'visible holes', 'bad breath']
        },
        {
            'disease': 'Gingivitis',
            'symptoms': ['bleeding gums', 'swollen gums', 'red gums', 'bad breath', 'tender gums']
        },
        {
            'disease': 'Periodontitis',
            'symptoms': ['bleeding gums', 'receding gums', 'loose teeth', 'bad breath', 'pain']
        },
        {
            'disease': 'Oral Thrush',
            'symptoms': ['white patches', 'soreness', 'difficulty swallowing', 'loss of taste', 'cracking']
        },
        {
            'disease': 'Tooth Abscess',
            'symptoms': ['severe toothache', 'swelling', 'fever', 'sensitivity', 'bad taste']
        },
        {
            'disease': 'TMJ Disorder',
            'symptoms': ['jaw pain', 'difficulty chewing', 'clicking sounds', 'headache', 'ear pain']
        },
    ],
    '泌尿外科': [
        {
            'disease': 'Urinary Tract Infection',
            'symptoms': ['frequent urination', 'burning sensation', 'cloudy urine', 'pelvic pain', 'fever']
        },
        {
            'disease': 'Kidney Stones',
            'symptoms': ['severe pain', 'blood in urine', 'nausea', 'vomiting', 'frequent urination']
        },
        {
            'disease': 'Prostatitis',
            'symptoms': ['pelvic pain', 'difficulty urinating', 'frequent urination', 'painful urination', 'fever']
        },
        {
            'disease': 'Bladder Infection',
            'symptoms': ['frequent urination', 'burning sensation', 'pelvic pain', 'cloudy urine', 'urgency']
        },
        {
            'disease': 'Benign Prostatic Hyperplasia',
            'symptoms': ['difficulty urinating', 'frequent urination', 'weak stream', 'urgency', 'incomplete emptying']
        },
    ],
}

# 性别分布（某些疾病与性别相关）
GENDER_DISTRIBUTION = {
    '妇科': ['Female'],
    '普外科': ['Male', 'Female', 'Other'],
    '眼科': ['Male', 'Female', 'Other'],
    '耳鼻喉科': ['Male', 'Female', 'Other'],
    '口腔科': ['Male', 'Female', 'Other'],
    '泌尿外科': ['Male', 'Female', 'Other'],
}

def generate_patient_data(department, num_records=200):
    """为指定科室生成患者数据"""
    data = []
    diseases = DEPARTMENT_DATA[department]
    genders = GENDER_DISTRIBUTION[department]
    
    # 读取现有数据的最大Patient_ID
    max_id = 0
    try:
        with open(r'd:\桌面\Healthcare_with_department1.csv', 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                max_id = max(max_id, int(row['Patient_ID']))
    except:
        pass
    
    for i in range(num_records):
        # 选择疾病
        disease_info = random.choice(diseases)
        disease = disease_info['disease']
        
        # 随机选择3-7个症状
        num_symptoms = random.randint(3, 7)
        selected_symptoms = random.sample(disease_info['symptoms'], min(num_symptoms, len(disease_info['symptoms'])))
        symptoms_str = ', '.join(selected_symptoms)
        
        # 生成患者信息
        patient_id = max_id + i + 1
        age = random.randint(1, 90)
        gender = random.choice(genders)
        
        data.append({
            'Patient_ID': patient_id,
            'Age': age,
            'Gender': gender,
            'Symptoms': symptoms_str,
            'Symptom_Count': len(selected_symptoms),
            'Disease': disease,
            'Department': department
        })
    
    return data

# 生成缺失科室的数据
missing_departments = ['妇科', '普外科', '眼科', '耳鼻喉科', '口腔科', '泌尿外科']
records_per_dept = 200  # 每个科室生成200条记录

all_new_data = []
for dept in missing_departments:
    print(f'正在生成 {dept} 的数据...')
    new_data = generate_patient_data(dept, records_per_dept)
    all_new_data.extend(new_data)
    print(f'  - 生成了 {len(new_data)} 条记录')

# 读取现有数据
existing_data = []
try:
    with open(r'd:\桌面\Healthcare_with_department1.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        existing_data = list(reader)
    print(f'读取了 {len(existing_data)} 条现有数据')
except Exception as e:
    print(f'读取现有数据时出错: {e}')

# 合并数据并保存
output_file = r'd:\桌面\Healthcare_with_department_complete.csv'
with open(output_file, 'w', encoding='utf-8', newline='') as f:
    fieldnames = ['Patient_ID', 'Age', 'Gender', 'Symptoms', 'Symptom_Count', 'Disease', 'Department']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    
    # 写入现有数据
    for row in existing_data:
        writer.writerow(row)
    
    # 写入新生成的数据
    for row in all_new_data:
        writer.writerow(row)

print(f'\n完成！')
print(f'现有数据: {len(existing_data)} 条')
print(f'新生成数据: {len(all_new_data)} 条')
print(f'总计: {len(existing_data) + len(all_new_data)} 条')
print(f'输出文件: {output_file}')

