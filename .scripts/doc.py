#!/usr/bin/env python3
import os, sys, webbrowser


if __name__ == '__main__':
  os.system('cp AutoTouchPlus.lua src/AutoTouchPlus.lua')
  os.system('ldoc src -d docs -c docs/config.ld')
  os.system('rm  src/AutoTouchPlus.lua')
  os.system('cp docs/modules/AutoTouchPlus.html docs/README')
  os.system('rm  docs/modules/AutoTouchPlus.html')
  os.system('ldoc src -d docs -c docs/config.ld')
  with open('docs/topics/README.html') as f:
    data = f.read().splitlines()
  b, e, ct, ht = [], [], [], []
  for i, ln in enumerate(data):
    if '<!DOCTYPE html PUBLIC' in ln:
      b.append(i)
    if '<p><h1>Module <code>' in ln:
      e.append(i)
    if '</div> <!-- id="content" -->' in ln:
      ct.append(i)
    if '</html>' in ln:
      ht.append(i), 
  with open('docs/topics/README.html', 'w') as f:
    for ln in data[:b[1]] + data[e[0]:ct[0]] + data[ht[0]:]:
      f.write(ln + '\n')

  if int(os.environ.get('NO_RENDER', 0)) == 0:
    webbrowser.open('docs/index.html')
  