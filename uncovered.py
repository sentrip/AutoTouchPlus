#!/usr/bin/env python3
import os
import re
import sys

processed = {}

def show_uncovered(path):
    green = '\u001b[32;1m'
    red = '\u001b[31;1m'
    reset = '\u001b[0m'
    for name, code in processed.items():
        if re.search(path, name):
            if re.search(r'\*{8}', code):
                output = []
                for i, line in enumerate(code.split('\n')):
                    if '*' * 8 in line:
                        output.append(('%d\t' % (i + 1)) + red + line[10:].strip() + reset)
                return '\n'.join(output)
            else:
                return green + 'All lines covered in ' + path + reset

    else:
        return red + 'No modules exist with the path ' + path + reset


if __name__ == '__main__':
    with open('luacov.report.out') as f:
        data = f.read()
    
    regex = '=' * 78 + r'\n'
    regex += r'(.*)\n'
    regex += '=' * 78 + r'\n'
    split_data = re.split(regex, data)[1:]
    for i in range(0, len(split_data), 2):
        path, code = split_data[i], split_data[i + 1]
        processed[path] = code
    
    if len(sys.argv) < 2:
        os.system('tail -n %d luacov.report.out' % (len(os.listdir('src')) + 9))
    else:
        print(show_uncovered(sys.argv[1]))

