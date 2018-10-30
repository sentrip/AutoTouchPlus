#!/usr/bin/env python3
import re, sys, subprocess

if __name__ == '__main__':
  green = '\u001b[32;1m'
  red = '\u001b[31;1m'
  reset = '\u001b[0m'
  lines = subprocess.check_output(['git', 'grep', 'TODO', 'src/', 'tests/', '.scripts/', 'dev.py', 'install.lua', 'Makefile']).decode().split('\n')
  current_module = ''
  counts = {'src': 0, 'tests': 0, 'other': 0}
  for line in lines:
    match = re.match(r'(.*\.\w+):[# -]*TODO:? (.*)', line)
    # print(line, match)
    if match:
      module, item = match.groups()
      if module != current_module:
        print('%s\n%s:%s' % (red, module, reset))
        current_module = module
      print('\t - %s' % item)

      if module.startswith('src'):
        counts['src'] += 1
      elif module.startswith('tests'):
        counts['tests'] += 1
      else:
        counts['other'] += 1
        
  if sum(list(counts.values())):
    print('\nTODO items left: %d (src: %d, tests: %d, other: %d)' % (sum(list(counts.values())), counts['src'], counts['tests'], counts['other']))
  else:
    print(green + 'No TODO items left')
