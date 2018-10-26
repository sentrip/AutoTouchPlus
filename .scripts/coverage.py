#!/usr/bin/env python3
import io, os, sys, subprocess

for fn in ['luacov.stats.out', 'luacov.report.out']:
  if os.path.exists(fn):
    os.remove(fn)

exit_code = 0
output = ''
for fn in sorted(os.listdir('tests/')):
  result = subprocess.check_output(['lua', '-lluacov', 'tests/%s' % fn]).decode()
  print(result, end='')
  output += result

os.system('luacov')
print(subprocess.check_output(['tail', '-n', str(len(os.listdir('src')) + 9), 'luacov.report.out']).decode())
exit(1 if 'failed' in output else 0)
