# send-to-agent.nvim

Send filename references (`@filename.ext`) to AI CLI agents running in tmux panes. Single-file Neovim plugin.

## Requirements

- **Neovim 0.9+**
- **tmux**
- **AI CLI agent** (claude, codex, cursor-agent, opencode, or gemini)

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

### Default Configuration

```lua
require("send-to-agent").setup({
  agents = {
    patterns = { "claude", "codex", "cursor-agent", "opencode", "gemini" },
    priority_order = { "claude", "codex", "cursor-agent", "opencode", "gemini" },
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

### Configuration Options

#### `agents.patterns` (table)
List of agent command patterns to detect in tmux panes.
- **Default**: `{ "claude", "codex", "cursor-agent", "opencode", "gemini" }`
- **Example**: Add custom agents
  ```lua
  agents = {
    patterns = { "claude", "codex", "my-custom-agent" }
  }
  ```

#### `agents.priority_order` (table)
Priority order for selecting which agent to send to when multiple agents are detected.
- **Default**: `{ "claude", "codex", "cursor-agent", "opencode", "gemini" }`
- **Priority Rules**:
  1. Agents in the same tmux window (highest priority)
  2. Agents in the same session, different window
  3. Follows the order specified in `priority_order`

- **Example**: Prefer gemini over claude
  ```lua
  agents = {
    patterns = { "claude", "gemini", "codex" },
    priority_order = { "gemini", "claude", "codex" }  -- gemini has highest priority
  }
  ```

#### `tmux.auto_switch_pane` (boolean)
Automatically switch focus to the agent pane after sending.
- **Default**: `true`
- **Example**: Keep focus in current pane
  ```lua
  tmux = {
    auto_switch_pane = false
  }
  ```

#### `formatting.relative_paths` (boolean)
Use relative paths from git root when available.
- **Default**: `true`
- **Example**: Always use absolute paths
  ```lua
  formatting = {
    relative_paths = false
  }
  ```

#### `formatting.include_line_numbers` (boolean)
Include line numbers in selection references (`@file.ext#L1-5`).
- **Default**: `true`

### Configuration Examples

#### Minimal (use all defaults)
```lua
require("send-to-agent").setup()
```

#### Custom agents only
```lua
require("send-to-agent").setup({
  agents = {
    patterns = { "my-agent", "another-agent" },
    priority_order = { "my-agent", "another-agent" }
  }
})
```

#### Extend default agents
```lua
local defaults = { "claude", "codex", "cursor-agent", "opencode", "gemini" }
local custom_agents = { "my-agent", "aider" }

require("send-to-agent").setup({
  agents = {
    patterns = vim.list_extend(vim.deepcopy(defaults), custom_agents),
    priority_order = vim.list_extend(vim.deepcopy(defaults), custom_agents)
  }
})
```

#### Change agent priority
```lua
require("send-to-agent").setup({
  agents = {
    -- Keep all default agents, but prioritize cursor-agent first
    priority_order = { "cursor-agent", "claude", "codex", "opencode", "gemini" }
  }
})
```