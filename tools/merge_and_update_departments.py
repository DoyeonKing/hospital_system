#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
合并和更新科室数据：
1. 从男科文件中随机选择10000条，departments改为"男科"，插入外科
2. 从肿瘤科文件中随机选择10000条，departments改为"肿瘤科"，插入外科
3. 将外科中departments为"肛肠"的改为"肛肠科"
"""
import csv
import sys
import os
import random

def read_csv_file(csv_file_path):
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
    
    return None

def merge_and_update_departments(surgery_file, male_file, oncology_file, output_file=None):
    """
    合并和更新科室数据
    
    Args:
        surgery_file: 外科CSV文件路径
        male_file: 男科CSV文件路径
        oncology_file: 肿瘤科CSV文件路径
        output_file: 输出文件路径（如果为None，则自动生成）
    """
    try:
        # 设置输出编码为UTF-8
        if sys.platform == 'win32':
            import io
            try:
                import ctypes
                kernel32 = ctypes.windll.kernel32
                kernel32.SetConsoleOutputCP(65001)
                kernel32.SetConsoleCP(65001)
            except:
                pass
            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
        
        print("=" * 60)
        print("开始处理文件...")
        print("=" * 60)
        
        # 1. 读取外科文件
        print(f"\n1. 读取外科文件: {surgery_file}")
        result = read_csv_file(surgery_file)
        if result is None:
            print(f"错误：无法读取外科文件 {surgery_file}")
            return None
        surgery_header, surgery_rows, surgery_encoding = result
        print(f"   成功读取，编码: {surgery_encoding}, 共 {len(surgery_rows)} 行数据")
        
        # 2. 读取男科文件
        print(f"\n2. 读取男科文件: {male_file}")
        result = read_csv_file(male_file)
        if result is None:
            print(f"错误：无法读取男科文件 {male_file}")
            return None
        male_header, male_rows, male_encoding = result
        print(f"   成功读取，编码: {male_encoding}, 共 {len(male_rows)} 行数据")
        
        # 3. 读取肿瘤科文件
        print(f"\n3. 读取肿瘤科文件: {oncology_file}")
        result = read_csv_file(oncology_file)
        if result is None:
            print(f"错误：无法读取肿瘤科文件 {oncology_file}")
            return None
        oncology_header, oncology_rows, oncology_encoding = result
        print(f"   成功读取，编码: {oncology_encoding}, 共 {len(oncology_rows)} 行数据")
        
        # 4. 从男科中随机选择10000条，修改departments为"男科"
        print(f"\n4. 从男科数据中随机选择10000条...")
        if len(male_rows) < 10000:
            print(f"   警告：男科数据只有 {len(male_rows)} 条，将使用全部数据")
            selected_male_rows = male_rows.copy()
        else:
            selected_male_rows = random.sample(male_rows, 10000)
        
        # 修改第一列（departments）为"男科"
        for row in selected_male_rows:
            if row and len(row) > 0:
                row[0] = "男科"
        print(f"   已选择 {len(selected_male_rows)} 条，departments已改为'男科'")
        
        # 5. 从肿瘤科中随机选择10000条，修改departments为"肿瘤科"
        print(f"\n5. 从肿瘤科数据中随机选择10000条...")
        if len(oncology_rows) < 10000:
            print(f"   警告：肿瘤科数据只有 {len(oncology_rows)} 条，将使用全部数据")
            selected_oncology_rows = oncology_rows.copy()
        else:
            selected_oncology_rows = random.sample(oncology_rows, 10000)
        
        # 修改第一列（departments）为"肿瘤科科"
        for row in selected_oncology_rows:
            if row and len(row) > 0:
                row[0] = "肿瘤科科"
        print(f"   已选择 {len(selected_oncology_rows)} 条，departments已改为'肿瘤科科'")
        
        # 6. 修改外科中departments为"肛肠"的改为"肛肠科"
        print(f"\n6. 修改外科数据中departments为'肛肠'的改为'肛肠科'...")
        changed_count = 0
        for row in surgery_rows:
            if row and len(row) > 0:
                department = row[0].strip()
                if department == "肛肠":
                    row[0] = "肛肠科"
                    changed_count += 1
        print(f"   已修改 {changed_count} 条记录")
        
        # 7. 合并所有数据
        print(f"\n7. 合并所有数据...")
        all_rows = surgery_rows + selected_male_rows + selected_oncology_rows
        print(f"   外科数据: {len(surgery_rows)} 条")
        print(f"   男科数据: {len(selected_male_rows)} 条")
        print(f"   肿瘤科数据: {len(selected_oncology_rows)} 条")
        print(f"   总计: {len(all_rows)} 条")
        
        # 8. 生成输出文件路径
        if output_file is None:
            base_name = os.path.splitext(os.path.basename(surgery_file))[0]
            dir_name = os.path.dirname(surgery_file)
            output_file = os.path.join(dir_name, f"{base_name}_merged.csv")
        
        # 9. 写入新的CSV文件
        print(f"\n8. 正在保存结果到: {output_file}")
        with open(output_file, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.writer(f)
            # 写入表头（使用外科文件的表头）
            if surgery_header:
                writer.writerow(surgery_header)
            # 写入所有数据
            writer.writerows(all_rows)
        
        print(f"\n{'=' * 60}")
        print(f"处理完成！")
        print(f"结果已保存到: {output_file}")
        print(f"文件编码: UTF-8 with BOM (Excel可正确打开)")
        print(f"{'=' * 60}")
        
        return output_file
        
    except Exception as e:
        print(f"\n处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == '__main__':
    # 默认文件路径
    surgery_file = r'd:\桌面\data\外科5-14000.csv'
    male_file = r'd:\桌面\data\男科5-13000.csv'
    oncology_file = r'd:\桌面\data\肿瘤科5-10000.csv'
    
    # 从命令行参数获取文件路径
    if len(sys.argv) >= 4:
        surgery_file = sys.argv[1]
        male_file = sys.argv[2]
        oncology_file = sys.argv[3]
        output_file = sys.argv[4] if len(sys.argv) > 4 else None
    elif len(sys.argv) == 2:
        # 如果只提供一个参数，作为输出文件路径
        output_file = sys.argv[1]
    else:
        output_file = None
    
    # 检查文件是否存在
    for file_path, file_name in [(surgery_file, "外科"), (male_file, "男科"), (oncology_file, "肿瘤科")]:
        if not os.path.exists(file_path):
            print(f"错误：{file_name}文件不存在: {file_path}")
            print("\n使用方法:")
            print(f"  python {os.path.basename(__file__)} [外科文件] [男科文件] [肿瘤科文件] [输出文件]")
            sys.exit(1)
    
    merge_and_update_departments(surgery_file, male_file, oncology_file, output_file)

