#!/usr/bin/env python3
import os, re
boilerplate = """---- AutoTouchPlus stuff and things.
-- @module AutoTouchPlus
-- @author Djordje Pepic
-- @license Apache 2.0
-- @copyright Djordje Pepic 2018
-- @usage require("AutoTouchPlus")
"""

files = ['src/core.lua', 'src/logic.lua'] + ['src/' + i for i in os.listdir('src') if i != 'core.lua' and i != 'logic.lua']

lines = []
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