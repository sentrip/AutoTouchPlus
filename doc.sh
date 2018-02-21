cp AutoTouchPlus.lua src/AutoTouchPlus.lua
ldoc src -c doc/config.ld
rm  src/AutoTouchPlus.lua
cp doc/modules/AutoTouchPlus.html doc/README
rm  doc/modules/AutoTouchPlus.html
ldoc src -c doc/config.ld
python3 << EOF 
with open('doc/topics/README.html') as f:
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
with open('doc/topics/README.html', 'w') as f:
  for ln in data[:b[1]] + data[e[0]:ct[0]] + data[ht[0]:]:
    f.write(ln + '\n')
EOF