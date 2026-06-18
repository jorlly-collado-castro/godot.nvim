.PHONY: fmt lint test

fmt:
	stylua .

lint:
	luacheck .

# Run tests (requires plenary.nvim and a 'tests/' directory)
# Adjust the command if you use a different test framework.
# This simply sources a 'tests/run.lua' file which should invoke
# plenary's test runner.

test:
	nvim --headless -c "luafile tests/run.lua" -c "qa"
