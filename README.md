# send-to-agent.nvim

Send filename references (`@filename.ext`) to AI CLI agents running in tmux panes. Single-file Neovim plugin.

## Requirements

- **Neovim 0.9+**
- **tmux**
- **AI CLI agent** (claude, opencode, or gemini)

## Installation

### Manual
```bash
git clone https://github.com/cybuerg/send-to-agent.nvim ~/.local/share/nvim/site/pack/plugins/start/send-to-agent.nvim

# Add to your init.lua:
require('send-to-agent').setup()
```

### vim-plug
```vim
Plug 'cybuerg/send-to-agent.nvim'

" In your init.lua:
lua require('send-to-agent').setup()
```

## Usage

### Commands
- `:SendToAgent` - Send current buffer as `@filename.ext`
- `:SendToAgentSelection` - Send visual selection as `@filename.ext#L1-5`
- `:SendToAgentDetect` - Show detected agents

### Keymaps
```lua
-- Suggested keymaps (add to your config)
vim.keymap.set('n', '<leader>sa', '<Plug>(SendToAgentBuffer)', { desc = 'Send buffer to AI agent' })
vim.keymap.set('v', '<leader>sa', '<Plug>(SendToAgentSelection)', { desc = 'Send selection to AI agent' })
vim.keymap.set('n', '<leader>sd', '<Plug>(SendToAgentDetect)', { desc = 'Detect AI agents' })
```

## Configuration

```lua
require("send-to-agent").setup({
  agents = {
    patterns = { "claude", "opencode", "gemini" },
    priority_order = { "claude", "opencode", "gemini" },
  },
  tmux = {
    auto_switch_pane = true,
  },
  formatting = {
    relative_paths = true,
    include_line_numbers = true,
  },
})
```