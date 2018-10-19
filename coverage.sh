# TODO: Make it so CI builds can print test results to stout and check for failures
if ls tests | xargs -I {} lua -lluacov tests/{} | grep 'failed'; then echo 'Some tests have failed'; exit 1; fi
luacov
ls -1 src/ | wc -l | xargs -I '{}' python -c 'print(eval("{}+9"))' | xargs -I '{}' tail -n '{}' luacov.report.out
echo '-----------------------------------------'
echo "All tests passed!"