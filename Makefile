.PHONY: test test-simple test-tmux demo lint format check

# Run plenary tests (if available)
test:
	nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run simple built-in tests
test-simple:
	nvim --headless -l run_tests.lua

# Run tmux integration tests
test-tmux:
	nvim --headless -l test_with_tmux.lua

# Run demo
demo:
	nvim --headless -l demo.lua

# Lint with luacheck
lint:
	luacheck lua/ plugin/

# Format with stylua
format:
	stylua lua/ plugin/ tests/ *.lua

# Check formatting
check:
	stylua --check lua/ plugin/ tests/ *.lua

# Run all checks
ci: lint check test-simple test-tmux