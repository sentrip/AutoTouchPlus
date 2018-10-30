#!/usr/bin/env python3
import os, re
test_boilerplate = u"""require("AutoTouchPlus")
assert(is(exe('dpkg-query -W curl')),
  'cURL not installed. Either install it or remove this check from tests.lua (2-3)')
"""

test_files = ['tests/' + i for i in sorted(os.listdir('tests')) if i != 'test_test.lua']

data = ''
for fn in test_files:
  data += '\n\n\n'
  with open(fn) as f:
    for line in f:
      if not line.startswith('require') and not line.startswith('run_tests()'):
        data += line
  data += '\n\n\n'

data += '\nif run_tests() == 0 then (alert or print)("All tests passed!") end \n'

with open('tests/test_test.lua') as f:
  data += '\n\n\n' + '\n'.join(f.read().splitlines()[1:]) + '\n\n\n'

with open('tests.lua', 'w') as f:
  f.write(test_boilerplate)
  f.write(data)

os.system('python3 .scripts/compile.py')
exit(os.system('lua tests.lua'))
