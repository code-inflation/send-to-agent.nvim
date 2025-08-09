.PHONY: test dev

# Run tmux integration test
test:
	nvim --headless -l test_with_tmux.lua

# Open Neovim with plugin loaded for manual testing
dev:
	nvim -c "set runtimepath+=." -c "lua require('send-to-agent').setup()" README.md