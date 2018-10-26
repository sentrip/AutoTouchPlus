#!/usr/bin/env python3
import os, re
test_boilerplate = u"""-------------------------------AutoTouch mocking ---------------------------
alert = alert or print
tap = tap or function(x, y) print('tapping', x, y) end
usleep = usleep or function(t) sleep(t / 1000000) end
function intToRgb(i) return 0, 0, 0 end
function rgbToInt(r,g,b) return 0 end
----------------------------------------------------------------------------
require("AutoTouchPlus")
--check for wget
assert(is(exe('dpkg-query -W wget')),
  'wget not installed. Either install it or remove this check from test.lua (4-5)')
----------------------------------------------------------------------------
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

data += '\nif run_tests() == 0 then alert("All tests passed!") end \n'

with open('tests/test_test.lua') as f:
  data += '\n\n\n' + '\n'.join(f.read().splitlines()[1:]) + '\n\n\n'

with open('tests.lua', 'w') as f:
  f.write(test_boilerplate)
  f.write(data)

os.system('python3 .scripts/compile.py')
exit(os.system('lua tests.lua'))
