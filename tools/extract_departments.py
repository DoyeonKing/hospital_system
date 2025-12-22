#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
从CSV文件中提取第一列（department）的所有唯一值
"""
import csv
import sys
import os

def extract_departments(csv_file_path):
    """
    从CSV文件中提取第一列的所有唯一值
    
    Args:
        csv_file_path: CSV文件路径
    """
    departments = set()
    
    try:
        # 尝试不同的编码方式
        encodings = ['utf-8', 'gbk', 'gb2312', 'utf-8-sig']
        
        for encoding in encodings:
            try:
                with open(csv_file_path, 'r', encoding=encoding, newline='') as f:
                    reader = csv.reader(f)
                    # 跳过表头
                    next(reader, None)
                    
                    for row in reader:
                        if row and len(row) > 0:
                            department = row[0].strip()
                            if department:  # 忽略空值
                                departments.add(department)
                
                # 如果成功读取，跳出循环
                break
            except UnicodeDecodeError:
                continue
            except Exception as e:
                if encoding == encodings[-1]:  # 最后一个编码也失败
                    print(f"使用编码 {encoding} 读取文件时出错: {e}")
                continue
        
        # 将结果排序并输出
        sorted_departments = sorted(departments)
        
        print(f"找到 {len(sorted_departments)} 个唯一的科室名称：\n")
        for dept in sorted_departments:
            print(dept)
        
        # 同时保存到文件
        output_file = os.path.join(os.path.dirname(csv_file_path), 'departments_list.txt')
        with open(output_file, 'w', encoding='utf-8') as f:
            for dept in sorted_departments:
                f.write(dept + '\n')
        
        print(f"\n结果已保存到: {output_file}")
        
        return sorted_departments
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == '__main__':
    # 设置输出编码为UTF-8
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    
    # 默认文件路径
    default_file = r'd:\桌面\data\外科5-14000.csv'
    
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    else:
        csv_file = default_file
    
    if not os.path.exists(csv_file):
        print(f"文件不存在: {csv_file}")
        sys.exit(1)
    
    extract_departments(csv_file)

