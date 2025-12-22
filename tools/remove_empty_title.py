#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
删除CSV文件中title列为空的行
"""
import csv
import sys
import os

def remove_empty_title_rows(csv_file_path, output_file_path=None):
    """
    删除CSV文件中title列为空的行
    
    Args:
        csv_file_path: 输入CSV文件路径
        output_file_path: 输出CSV文件路径（如果为None，则自动生成）
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
        
        # 尝试不同的编码方式读取文件
        encodings = ['gbk', 'gb18030', 'gb2312', 'utf-8-sig', 'utf-8', 'big5', 'latin-1', 'cp1252', 'iso-8859-1']
        header = None
        all_rows = []
        encoding_used = None
        
        print(f"\n正在读取文件: {csv_file_path}")
        
        for encoding in encodings:
            try:
                with open(csv_file_path, 'r', encoding=encoding, newline='') as f:
                    reader = csv.reader(f)
                    # 读取表头
                    header = next(reader, None)
                    if header is None:
                        print("错误：文件没有表头")
                        return None
                    
                    # 查找title列的索引
                    try:
                        title_index = header.index('title')
                    except ValueError:
                        # 如果找不到'title'，尝试查找中文列名
                        title_index = None
                        for i, col_name in enumerate(header):
                            if 'title' in col_name.lower() or '标题' in col_name or '名称' in col_name:
                                title_index = i
                                break
                        
                        if title_index is None:
                            print("错误：找不到title列")
                            print(f"可用的列: {', '.join(header)}")
                            return None
                    
                    print(f"   找到title列，索引: {title_index}")
                    
                    # 读取所有数据行
                    total_rows = 0
                    empty_title_count = 0
                    valid_rows = []
                    
                    for row in reader:
                        total_rows += 1
                        if row and len(row) > title_index:
                            # 检查title列是否为空（去除空白字符后）
                            title_value = row[title_index].strip() if row[title_index] else ""
                            if title_value:
                                valid_rows.append(row)
                            else:
                                empty_title_count += 1
                        elif row:  # 如果行存在但列数不够，也保留（可能是数据格式问题）
                            valid_rows.append(row)
                    
                    encoding_used = encoding
                    all_rows = valid_rows
                    break
                    
            except UnicodeDecodeError:
                continue
            except Exception as e:
                if encoding == encodings[-1]:
                    print(f"读取文件时出错: {e}")
                    import traceback
                    traceback.print_exc()
                continue
        
        if encoding_used is None:
            print("错误：无法读取CSV文件，所有编码尝试都失败了")
            return None
        
        print(f"   成功读取，编码: {encoding_used}")
        print(f"   总行数: {total_rows}")
        print(f"   title为空的行数: {empty_title_count}")
        print(f"   保留的行数: {len(all_rows)}")
        
        # 生成输出文件路径
        if output_file_path is None:
            base_name = os.path.splitext(os.path.basename(csv_file_path))[0]
            dir_name = os.path.dirname(csv_file_path)
            output_file_path = os.path.join(dir_name, f"{base_name}_cleaned.csv")
        
        # 写入新的CSV文件
        print(f"\n正在保存结果到: {output_file_path}")
        with open(output_file_path, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.writer(f)
            # 写入表头
            if header:
                writer.writerow(header)
            # 写入有效数据
            writer.writerows(all_rows)
        
        print(f"\n{'=' * 60}")
        print(f"处理完成！")
        print(f"删除了 {empty_title_count} 行title为空的数据")
        print(f"保留了 {len(all_rows)} 行有效数据")
        print(f"结果已保存到: {output_file_path}")
        print(f"文件编码: UTF-8 with BOM (Excel可正确打开)")
        print(f"{'=' * 60}")
        
        return output_file_path
        
    except Exception as e:
        print(f"\n处理文件时出错: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == '__main__':
    # 默认文件路径
    csv_file = r'd:\桌面\data\外科5-14000_merged.csv'
    
    # 从命令行参数获取文件路径
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
    else:
        output_file = None
    
    if not os.path.exists(csv_file):
        print(f"文件不存在: {csv_file}")
        print("\n使用方法:")
        print(f"  python {os.path.basename(__file__)} <输入CSV文件路径> [输出CSV文件路径]")
        sys.exit(1)
    
    remove_empty_title_rows(csv_file, output_file)


