
ls tests | xargs -I '{}' lua -lluacov 'tests/{}'
luacov
ls -1 src/ | wc -l | xargs -I '{}' python -c 'print(eval("{}+9"))' | xargs -I '{}' tail -n '{}' luacov.report.out
