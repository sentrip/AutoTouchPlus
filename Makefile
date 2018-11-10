.PHONY: compile coverage docs release test test-single todo uncovered help
.DEFAULT_GOAL := help

define PRINT_HELP
import re, sys
for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP


help:
	@python3 -c "$$PRINT_HELP" < $(MAKEFILE_LIST)

compile:  ## Compile AutoTouchPlus.lua from src folder
	@python3 .scripts/compile.py

coverage:  ## Run tests with coverage
	@python3 .scripts/coverage.py 

docs:  ## Create and render docs
	@python3 .scripts/doc.py 

release:  ## Release new version to GitHub
	@python3 .scripts/release.py 

test:  ## Run all tests
	@python3 .scripts/test.py 

test-single:  ## Run tests for only one module - `make test-single f=core`
	@python3 .scripts/compile.py
	@lua tests/test_$f.lua

todo:  ## Show all todo items in the repository
	@python3 .scripts/todo.py

uncovered:  ## Show coverage - `make uncovered` - or uncovered code - `make uncovered f=core`
	@python3 .scripts/uncovered.py $f
