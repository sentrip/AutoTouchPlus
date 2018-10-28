#!/usr/bin/env python3
import os, sys, webbrowser

if __name__ == '__main__':
  os.system('ldoc src -d docs -c docs/config.ld')
  if int(os.environ.get('NO_RENDER', 0)) == 0:
    webbrowser.open('docs/index.html')