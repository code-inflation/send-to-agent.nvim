# send-to-agent.nvim

A minimal, efficient Neovim plugin that seamlessly sends filename references to AI CLI agents running in tmux panes, with automatic pane switching for streamlined workflow.

## 🚀 Features

- **Universal Compatibility**: Works with Claude Code CLI, OpenCode, and Gemini CLI using identical `@filename.ext#L1-5` syntax
- **Zero Configuration**: Works out of the box with sensible defaults
- **Smart Detection**: Automatically finds AI agents running in tmux panes
- **Reference-Only**: Sends lightweight filename references, not file content
- **Relative Paths**: Intelligent path resolution from git root
- **Auto Pane Switching**: Seamlessly switch to agent pane after sending
- **Pure Lua**: Modern Neovim plugin with no dependencies

## 📦 Installation

### lazy.nvim

```lua
{
  "cybuerg/send-to-agent.nvim",
  config = function()
    require("send-to-agent").setup({
      -- Optional configuration
    })
  end
}
```

### packer.nvim

```lua
use {
  "cybuerg/send-to-agent.nvim",
  config = function()
    require("send-to-agent").setup()
  end
}
```

### Manual Installation

```bash
git clone https://github.com/cybuerg/send-to-agent.nvim ~/.local/share/nvim/site/pack/plugins/start/send-to-agent.nvim
```

## 📋 Requirements

- **Neovim 0.9+**
- **tmux** (for pane detection and switching)
- **AI CLI agent** running in tmux (Claude Code CLI, OpenCode, or Gemini CLI)

## 🎯 Quick Start

1. **Start your AI agent in tmux:**
   ```bash
   tmux new-session -d -s coding
   tmux new-window -t coding -n agent
   tmux send-keys -t coding:agent "claude" Enter
   ```

2. **In Neovim, send current file:**
   ```vim
   :SendToAgent
   ```

3. **Send visual selection:**
   ```vim
   " Select code in visual mode, then:
   :SendToAgentSelection
   ```

4. **Check detected agents:**
   ```vim
   :SendToAgentDetect
   ```

## ⚡ Usage

### Commands

| Command | Description |
|---------|-------------|
| `:SendToAgent` | Send current buffer as `@filename.ext` to AI agent |
| `:SendToAgentSelection` | Send visual selection as `@filename.ext#L1-5` to AI agent |
| `:SendToAgentDetect` | Show detected AI agent panes in tmux |

### Keymaps

The plugin provides `<Plug>` mappings for user customization:

```lua
-- Suggested keymaps (add to your config)
vim.keymap.set('n', '<leader>sa', '<Plug>(SendToAgentBuffer)', { desc = 'Send buffer to AI agent' })
vim.keymap.set('v', '<leader>sa', '<Plug>(SendToAgentSelection)', { desc = 'Send selection to AI agent' })
vim.keymap.set('n', '<leader>sd', '<Plug>(SendToAgentDetect)', { desc = 'Detect AI agents' })
```

## ⚙️ Configuration

The plugin works without configuration, but you can customize it:

```lua
require("send-to-agent").setup({
  agents = {
    patterns = { "claude", "opencode", "gemini" },    -- Agent command patterns to detect
    priority_order = { "claude", "opencode", "gemini" }, -- Priority for multiple agents
  },
  tmux = {
    auto_switch_pane = true,  -- Switch to agent pane after sending
    return_focus_delay = 0,   -- Delay before returning focus (0 = no return)
  },
  formatting = {
    relative_paths = true,         -- Use relative paths from git root
    include_line_numbers = true,   -- Include line numbers for selections
  },
})
```

### Default Configuration

```lua
{
  agents = {
    patterns = { "claude", "opencode", "gemini" },
    priority_order = { "claude", "opencode", "gemini" },
  },
  tmux = {
    auto_switch_pane = true,
    return_focus_delay = 0,
  },
  formatting = {
    relative_paths = true,
    include_line_numbers = true,
  },
}
```

## 🔄 Workflow Examples

### Code Review Workflow

```bash
# Terminal: Start AI agent
tmux new-session -d -s review
tmux send-keys -t review "claude" Enter
```

```lua
-- Neovim: Send problematic function
-- 1. Navigate to function
-- 2. Select function in visual mode
-- 3. <leader>sa (sends: @src/utils.lua#L45-67)
-- 4. Automatically switches to claude pane
-- 5. Ask: "Can you review this function for potential bugs?"
```

### Documentation Generation

```lua
-- Send entire file for documentation
-- :SendToAgent (sends: @src/api.lua)
-- Ask: "Generate comprehensive documentation for this API module"
```

### Debugging Assistance

```lua
-- Send specific error-prone section
-- Visual select problematic code
-- :SendToAgentSelection (sends: @src/parser.lua#L123-145)
-- Ask: "This function is throwing errors, can you help debug it?"
```

## 🤝 Supported AI Agents

| Agent | Command | Status | Reference Format |
|-------|---------|--------|------------------|
| **Claude Code CLI** | `claude` | ✅ Primary | `@filename.ext#L1-5` |
| **OpenCode** | `opencode` | ✅ Supported | `@filename.ext#L1-5` |
| **Gemini CLI** | `gemini` | ✅ Supported | `@filename.ext#L1-5` |

> **Note**: All supported agents use identical reference syntax, making the plugin universally compatible!

## 🔧 How It Works

1. **Detection**: Scans tmux panes for known AI agent commands
2. **Selection**: Chooses best agent based on priority order
3. **Formatting**: Creates `@filename.ext#L1-5` reference with relative paths
4. **Sending**: Uses `tmux send-keys` to send reference to agent pane
5. **Switching**: Automatically switches to agent pane (configurable)

## 🚨 Troubleshooting

### No agents detected

```bash
# Check tmux is running
tmux list-sessions

# Check agent is running
tmux list-panes -a -F '#{pane_id} #{pane_current_command}'

# Manually start agent
tmux send-keys -t [pane_id] "claude" Enter
```

### Agent not responding

- Ensure the AI agent supports `@filename` syntax
- Check file paths are accessible from agent's working directory
- Verify tmux pane is active and responsive

### Permission issues

```bash
# Check tmux permissions
tmux info

# Verify file accessibility
ls -la [filepath]
```

## 🧪 Testing

```bash
# Run tests
make test

# Lint code
make lint

# Format code
make format

# Run all checks
make ci
```

## 📝 API Reference

### Core Functions

```lua
local send_to_agent = require("send-to-agent")

-- Send current buffer
send_to_agent.send_buffer()

-- Send visual selection
send_to_agent.send_selection()

-- Detect available agents
local agents = send_to_agent.detect_agent_panes()

-- Send arbitrary text
send_to_agent.send_text("@custom/file.lua#L10-20")

-- Get current configuration
local config = send_to_agent.get_config()
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make ci`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the workflow needs of modern AI-assisted development
- Built for the Neovim community with love ❤️
- Special thanks to the tmux and AI CLI tool developers

---

**Happy coding with AI assistance!** 🚀