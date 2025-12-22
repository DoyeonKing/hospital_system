#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
从CSV文件中筛选出departments数量排前10的，并生成新的CSV文件
"""
import csv
import sys
import os
from collections import Counter

def filter_top10_departments(csv_file_path, output_file_path=None):
    """
    从CSV文件中筛选出departments数量排前10的，并生成新的CSV文件
    
    Args:
        csv_file_path: 输入CSV文件路径
        output_file_path: 输出CSV文件路径（如果为None，则自动生成）
    """
    try:
        # 尝试不同的编码方式（优先尝试中文常用编码）
        encodings = ['gbk', 'gb18030', 'gb2312', 'utf-8-sig', 'utf-8', 'big5', 'latin-1', 'cp1252', 'iso-8859-1']
        all_rows = []
        header = None
        encoding_used = None
        last_error = None
        
        print(f"正在尝试读取文件: {csv_file_path}")
        print("尝试的编码顺序:", ', '.join(encodings))
        
        for encoding in encodings:
            try:
                print(f"  尝试编码: {encoding}...", end=' ')
                # 不使用 errors='replace'，确保能正确解码，避免乱码
                with open(csv_file_path, 'r', encoding=encoding, newline='') as f:
                    reader = csv.reader(f)
                    # 读取表头
                    header = next(reader, None)
                    if header is None:
                        print("失败（文件为空）")
                        continue
                    
                    # 读取所有数据行
                    all_rows = []
                    row_count = 0
                    for row in reader:
                        if row and len(row) > 0:
                            all_rows.append(row)
                            row_count += 1
                    
                    # 如果成功读取到数据，保存使用的编码并跳出循环
                    if row_count > 0 or header:
                        encoding_used = encoding
                        print(f"成功！读取到 {len(all_rows)} 行数据")
                        break
                    else:
                        print("失败（没有数据行）")
                        continue
                        
            except UnicodeDecodeError as e:
                print(f"失败（编码错误）")
                last_error = f"UnicodeDecodeError: {str(e)}"
                continue
            except Exception as e:
                print(f"失败（{type(e).__name__}: {str(e)}）")
                last_error = f"{type(e).__name__}: {str(e)}"
                continue
        
        if encoding_used is None:
            print(f"\n错误：无法读取CSV文件，所有编码尝试都失败了")
            if last_error:
                print(f"最后一次错误: {last_error}")
            print("\n建议:")
            print("1. 检查文件路径是否正确")
            print("2. 检查文件是否损坏")
            print("3. 尝试用Excel打开文件，然后另存为UTF-8编码的CSV文件")
            return None
        
        print(f"成功读取文件，使用编码: {encoding_used}")
        print(f"总共有 {len(all_rows)} 行数据")
        
        # 统计每个department的数量（假设第一列是department）
        department_counter = Counter()
        for row in all_rows:
            if row and len(row) > 0:
                department = row[0].strip()
                if department:  # 忽略空值
                    department_counter[department] += 1
        
        # 获取数量排前10的departments
        top10_departments = [dept for dept, count in department_counter.most_common(10)]
        
        print(f"\n找到 {len(department_counter)} 个不同的科室")
        print("\n数量排前10的科室：")
        for i, (dept, count) in enumerate(department_counter.most_common(10), 1):
            print(f"{i}. {dept}: {count} 条记录")
        
        # 筛选出属于前10个departments的行
        top10_rows = []
        for row in all_rows:
            if row and len(row) > 0:
                department = row[0].strip()
                if department in top10_departments:
                    top10_rows.append(row)
        
        print(f"\n筛选后保留 {len(top10_rows)} 行数据")
        
        # 生成输出文件路径
        if output_file_path is None:
            base_name = os.path.splitext(os.path.basename(csv_file_path))[0]
            dir_name = os.path.dirname(csv_file_path)
            output_file_path = os.path.join(dir_name, f"{base_name}_top10.csv")
        
        # 写入新的CSV文件（使用UTF-8-sig编码，Excel可以正确打开）
        print(f"\n正在保存结果到: {output_file_path}")
        with open(output_file_path, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.writer(f)
            # 写入表头
            if header:
                writer.writerow(header)
            # 写入筛选后的数据
            writer.writerows(top10_rows)
        
        print(f"结果已保存到: {output_file_path}")
        print(f"文件编码: UTF-8 with BOM (Excel可正确打开)")
        return output_file_path
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == '__main__':
    # 设置输出编码为UTF-8
    if sys.platform == 'win32':
        import io
        # 设置控制台代码页为UTF-8
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleOutputCP(65001)  # UTF-8
            kernel32.SetConsoleCP(65001)  # UTF-8
        except:
            pass
        
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    
    # 从命令行参数获取文件路径
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
    else:
        # 默认文件路径（可以根据需要修改）
        csv_file = r'内科5000-33000.csv'
        output_file = None
    
    if not os.path.exists(csv_file):
        print(f"文件不存在: {csv_file}")
        print("\n使用方法:")
        print(f"  python {os.path.basename(__file__)} <输入CSV文件路径> [输出CSV文件路径]")
        sys.exit(1)
    
    filter_top10_departments(csv_file, output_file)

