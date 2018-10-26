#!/usr/bin/env python3
import json, os, re, subprocess, sys


if __name__ == '__main__':
  green = '\u001b[32;1m'
  red = '\u001b[31;1m'
  reset = '\u001b[0m'
  github = ['curl', '-s', '-H', 'Authorization: token %s' % os.environ['AUTOTOUCHPLUS_GITHUB_TOKEN']]

  # Get current version
  with open('.bumpversion.cfg') as f:
    current_version = f.read().splitlines()[1].split('=')[1].strip()
  
  # Get latest changes
  with open('HISTORY.rst') as f:
    full_history = f.read()

  # Parse latest changes and verify history entry is up to date
  history = full_history.split('-----------')[1].split('|')[0].strip() + '\n'  
  history_version = re.search(r'\* (\d+\.\d+\.\d+).*', history.split('\n')[0]).group(1)
  assert history_version == current_version, 'Did not add entry in HISTORY.rst: current_version: %s, history_version: %s' % (current_version, history_version)

  # Build release description
  changes = '\n'
  for ln in history.split('\n')[1:]:
    if ln.strip().startswith('*'):
      changes += ln.strip() + '\n'
  
  print('Creating release v%s...' % current_version)

  # Create release
  form_args = [
    '--data', 
    ("{" + ','.join(['"%s": "%s"' % (k, v) for k,v in {
      'tag_name': 'v%s' % current_version,
      'target_commitish': 'master',
      'name': 'v%s' % current_version,
      'body': 'Release of version %s' % current_version,
      'draft': 'false',
      'prerelease': 'false'
    }.items()]) + "}").replace('"false"', 'false')
  ]
  data = json.loads(subprocess.check_output(github + ['-X', 'POST'] + form_args + ['https://api.github.com/repos/sentrip/AutoTouchPlus/releases']).decode())
  if not data.get('name', None):
    print(red + 'Error creating release: %s - %s' % (data['message'], data.get('errors', [])))    
    exit(0)
  # data = json.loads(subprocess.check_output(github + ['https://api.github.com/repos/sentrip/AutoTouchPlus/releases/latest']).decode())
  release_id = data['id']

  # Upload AutoTouchPlus.lua and tests.lua to latest release
  for fname in ['tests.lua']:#['AutoTouchPlus.lua', 'tests.lua']:
    data = json.loads(subprocess.check_output(github + ['-X', 'POST', '-F', "file=@%s" % fname, '-H', "Content-Type: application/octet-stream", 'https://uploads.github.com/repos/sentrip/AutoTouchPlus/releases/%s/assets?name=%s' % (release_id, fname)]).decode())
    if not data.get('name', None):
      print(red + 'Error uploading %s: %s - %s' % (fname, data['message'], data['errors']))    
      break
  else:
    print(green + 'Success!' + reset)
