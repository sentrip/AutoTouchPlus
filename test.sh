python3 << EOF
import os, re
boilerplate = """---- AutoTouchPlus stuff and things.
-- @module AutoTouchPlus
-- @author Djordje Pepic
-- @license Apache 2.0
-- @copyright Djordje Pepic 2018
-- @usage require("AutoTouchPlus")
"""
test_boilerplate = u"""require("AutoTouchPlus")
--check for wget
assert(is(exe('dpkg-query -W wget')), 
  'wget not installed. Either install it or remove this check from test.lua (4-5)')
-------------------------------AutoTouch mocking --------------------------- 
alert = alert or print
tap = tap or function(x, y) print('tapping', x, y) end
usleep = usleep or function(t) sleep(t / 1000000) end
----------------------------------------------------------------------------
"""

# Create library file
lines = []
files = ['src/core.lua'] + ['src/' + i for i in os.listdir('src') if i != 'core.lua']
for fn in files:
  with open(fn) as f:
    lines.extend(f.read().splitlines())
result = []
for ln in lines:
  c = ln.strip('\r\n ')
  if any(ln.startswith(i) for i in ['return', 'require', '--']):
    continue
  else:
    result.append(c)
with open('AutoTouchPlus.lua', 'w') as f:
  f.write(boilerplate)
  for ln in result:
    f.write(ln + '\n')


# Create test file
test_files = ['tests/' + i for i in os.listdir('tests')]

data = "failed = test_all{\n"

for fn in test_files:
  with open(fn) as f:
    data += f.read().strip('\n') + ',\n'

data += '\n}\nif is.Nil(rootDir) then os.exit(num(failed)) end\n'

with open('tests.lua', 'w') as f:
  f.write(test_boilerplate)
  f.write(data)

EOF

lua tests1.lua