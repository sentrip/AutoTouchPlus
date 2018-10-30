#!/usr/bin/env python3
import re, sys, subprocess

if __name__ == '__main__':
  green = '\u001b[32;1m'
  red = '\u001b[31;1m'
  reset = '\u001b[0m'
  lines = subprocess.check_output(['git', 'grep', 'TODO', 'src/*', 'tests/*']).decode().split('\n')
  current_module = ''
  counts = {'src': 0, 'tests': 0}
  for line in lines:
    match = re.match(r'(.*\.lua): [ -]*TODO: (.*)', line)
    if match:
      module, item = match.groups()
      if module != current_module:
        print('%s\n%s:%s' % (red, module, reset))
        current_module = module
      print('\t - %s' % item)

      if module.startswith('src'):
        counts['src'] += 1
      if module.startswith('tests'):
        counts['tests'] += 1
        
  if counts['src'] + counts['tests']:
    print('\nTODO items left: %d (src: %d, tests: %d)' % (counts['src'] + counts['tests'], counts['src'], counts['tests']))
  else:
    print(green + 'No TODO items left')
