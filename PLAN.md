# PLAN.md - Send-to-Agent.nvim MVP Implementation

## Project Overview

**Plugin Name:** `send-to-agent.nvim`  
**Goal:** A minimal, efficient Neovim plugin that seamlessly sends filename references to AI CLI agents running in tmux panes, with automatic pane switching for streamlined workflow.

**Value Proposition:** Bridge the gap between Neovim editing and AI CLI agents using their native `@filename` syntax without leaving the editor or managing terminals manually.

## MVP Feature Specification

> **🔍 Key Research Insight**: Analysis of the existing code-bridge.nvim reveals it sends **filename references only** (`@filename.ext`), not actual file content. This approach leverages AI agents' built-in file reading capabilities for better performance and is supported by all major AI CLI agents.

> **🎯 MVP Focus**: This plan focuses on the **reference-only approach** with the three major AI agents (Claude, OpenCode, Gemini) that all support `@filename` syntax. This creates a simple, fast, and reliable foundation that covers 95% of use cases.

### Core Features

1. **Filename Reference Sending**
   - Send entire current buffer as `@filename.ext` to AI agent
   - Send visual selection as `@filename.ext#L1-5` to AI agent
   - Agent-specific syntax handling for different line number formats
   - Preserve cursor position and editor state

2. **AI Agent Detection**
   - Dynamically detect running AI agents in tmux panes
   - Support for major agents: Claude Code CLI, OpenCode, Gemini CLI
   - Priority-based selection when multiple agents detected

3. **Automatic Pane Switching**
   - Switch to detected agent pane after sending reference
   - Return focus option for seamless workflow
   - Handle multiple agent instances gracefully

4. **Zero-Config Operation**
   - Works out of the box with sensible defaults
   - Smart agent-specific syntax selection
   - Automatic relative path resolution

### Supported AI Agents

| Agent | Process Pattern | Reference Syntax | Status |
|-------|----------------|------------------|---------|
| Claude Code CLI | `claude` | `@file.ext#L1-5` | ✅ **Primary** |
| OpenCode | `opencode` | `@file.ext#L1-5` | ✅ **Supported** |
| Gemini CLI | `gemini` | `@file.ext#L1-5` | ✅ **Supported** |

> **🎯 Uniform Syntax**: All three major AI agents support the **exact same syntax** `@filename.ext#L1-5`! This dramatically simplifies our implementation - we can use identical formatting across all agents.

## Technical Design

### Architecture Decisions

1. **Single File Implementation** (`lua/send-to-agent.lua`)
   - Keep MVP simple and maintainable
   - Easier to debug and contribute to
   - Clear separation of concerns within one file

2. **Pure Lua Implementation**
   - No external dependencies beyond Neovim's built-in capabilities
   - Use `vim.system()` for async command execution
   - Leverage Neovim's tmux integration patterns

3. **Reference-Only Strategy**
   - Send `@filename.ext` patterns exclusively (matches code-bridge.nvim behavior)
   - Agent-specific syntax handling for line numbers
   - Simplified and performant approach

4. **Agent Detection**
   - Use `tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{window_name}'`
   - Pattern match against known AI agent commands
   - Prioritize most recently active pane if multiple matches

5. **Smart Reference Formatting**
   - **Whole files**: `@filename.ext` 
   - **Selections**: `@filename.ext#L1-5` (uniform across all agents!)
   - **Simplified syntax**: No agent-specific variations needed
   - Include relative path from project root when available

### Core Components

```lua
-- Main module structure
local M = {}

-- Simplified configuration (uniform syntax!)
M.config = {
  agents = {
    patterns = { "claude", "opencode", "gemini" },
    auto_switch_pane = true,
  }
}

-- Core functions
M.setup(opts)                    -- Plugin initialization
M.send_buffer()                  -- Send entire buffer as @filename.ext
M.send_selection()               -- Send selection as @filename.ext#L1-5
M.detect_agent_panes()           -- Find running agents
M.switch_to_agent()              -- Switch to agent pane
M.format_file_reference()        -- Format @filename patterns (uniform syntax)
```

### Tmux Integration Pattern

```bash
# Detection command
tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{window_name} #{pane_title}'

# Send command to pane
tmux send-keys -t [pane_id] [formatted_content] Enter

# Switch to pane
tmux select-pane -t [pane_id]
```

## Implementation Requirements

### Dependencies

- **Neovim 0.9+** (for modern Lua APIs)
- **tmux** (primary integration target)
- **System clipboard** (fallback mechanism)

### File Structure

```
send-to-agent.nvim/
├── lua/
│   └── send-to-agent.lua          # Main implementation
├── README.md                      # Setup and usage guide
├── tests/
│   ├── spec/
│   │   └── send_to_agent_spec.lua # E2E test suite
│   └── helpers/
│       └── tmux_mock.lua          # Testing utilities
├── doc/
│   └── send-to-agent.txt          # Vim help documentation
└── plugin/
    └── send-to-agent.vim          # Vim commands registration
```

### User Interface

**Commands:**
- `:SendToAgent` - Send current buffer
- `:SendToAgentSelection` - Send visual selection (visual mode only)
- `:SendToAgentDetect` - Show detected agent panes

**Default Keybindings (suggested in README):**
```lua
vim.keymap.set('n', '<leader>sa', require('send-to-agent').send_buffer)
vim.keymap.set('v', '<leader>sa', require('send-to-agent').send_selection)
vim.keymap.set('n', '<leader>sd', require('send-to-agent').detect_agent_panes)
```

### Configuration API

```lua
require('send-to-agent').setup({
  agents = {
    patterns = { "claude", "opencode", "gemini" },
    priority_order = { "claude", "opencode", "gemini" },
  },
  tmux = {
    auto_switch_pane = true,
    return_focus_delay = 0, -- ms to wait before returning focus
  },
  formatting = {
    relative_paths = true,
    include_line_numbers = true, -- Always use @file.ext#L1-5 for selections
  },
})
```

> **🎉 Massive Simplification**: With uniform `@filename.ext#L1-5` syntax across all agents, configuration becomes trivial! No agent-specific syntax overrides needed.

## Testing Strategy

### E2E Testing Approach

1. **Tmux Mock Environment**
   - Mock tmux commands for testing
   - Simulate various pane configurations
   - Test agent detection algorithms

2. **Integration Tests**
   - Test full workflow: detect → format → send → switch
   - Verify content formatting accuracy
   - Test fallback mechanisms

3. **Edge Case Testing**
   - No tmux environment
   - Multiple agent instances
   - Network/permission issues
   - Large file handling

### Test Structure

```lua
-- tests/spec/send_to_agent_spec.lua
describe("send-to-agent.nvim", function()
  describe("agent detection", function()
    it("should detect claude in tmux pane")
    it("should detect opencode in tmux pane")
    it("should detect gemini in tmux pane") 
    it("should detect multiple agents and prioritize correctly")
    it("should handle no agents gracefully")
  end)
  
  describe("reference formatting", function()
    it("should format file references (@filename.ext)")
    it("should format selection references with line numbers (@filename.ext#L1-5)")
    it("should use uniform syntax for all agents")
    it("should use relative paths correctly")
    it("should handle special characters in filenames")
  end)
  
  describe("pane switching", function()
    it("should switch to detected agent pane")
    it("should handle missing panes gracefully")
  end)
end)
```

## Documentation Requirements

### README.md Structure

1. **Installation Instructions**
   - Lazy.nvim setup
   - Manual installation
   - Dependencies check

2. **Quick Start Guide**
   - Basic keybinding setup
   - Example workflow
   - Troubleshooting common issues

3. **Configuration Reference**
   - All options documented
   - Examples for different use cases
   - Advanced configurations

4. **Workflow Examples**
   - Code review workflow
   - Debugging assistance
   - Documentation generation

### Example Workflow Section

```markdown
## Example Workflow

1. **Setup tmux with AI agent:**
   ```bash
   tmux new-session -d -s coding
   tmux new-window -t coding -n agent
   tmux send-keys -t coding:agent "claude" Enter
   ```

2. **In Neovim, send current file:**
   ```
   <leader>sa  " Send entire buffer to agent
   ```

3. **Review response in agent pane** (automatically switched)

4. **Send specific selection:**
   ```
   v           " Visual mode
   [select code]
   <leader>sa  " Send selection to agent
   ```
```

## Development TODO List

### Phase 1: Core Implementation (Week 1-2)

- [ ] **Setup project structure**
  - [ ] Initialize git repository
  - [ ] Create directory structure
  - [ ] Setup basic Lua module

- [ ] **Implement agent detection**
  - [ ] Write tmux pane listing function
  - [ ] Implement pattern matching for known agents (claude, opencode, gemini)
  - [ ] Add priority-based selection logic
  - [ ] Handle edge cases (no agents, multiple agents)

- [ ] **Implement reference formatting**
  - [ ] **File reference**: `@filename.ext` formatting with relative paths
  - [ ] **Selection reference**: `@filename.ext#L1-5` with uniform syntax (all agents!)
  - [ ] Special character escaping in filenames
  - [ ] Line number calculation for visual selections

- [ ] **Implement sending mechanism**
  - [ ] Tmux send-keys integration for filename references
  - [ ] Error handling and user feedback
  - [ ] Consistent formatting across all agents (uniform syntax!)

- [ ] **Implement pane switching**
  - [ ] Switch to agent pane after sending
  - [ ] Optional return focus mechanism
  - [ ] Handle missing/invalid panes

### Phase 2: User Interface (Week 2-3)

- [ ] **Create Vim commands**
  - [ ] `:SendToAgent` command
  - [ ] `:SendToAgentSelection` command
  - [ ] `:SendToAgentDetect` command

- [ ] **Add configuration system**
  - [ ] Default configuration table
  - [ ] Setup function with user options
  - [ ] Configuration validation

- [ ] **Implement user feedback**
  - [ ] Success/error notifications
  - [ ] Agent detection status
  - [ ] Debug information display

### Phase 3: Testing (Week 3-4)

- [ ] **Setup testing framework**
  - [ ] Configure busted/plenary testing
  - [ ] Create tmux mocking utilities
  - [ ] Setup CI/CD pipeline

- [ ] **Write core tests**
  - [ ] Agent detection tests for claude, opencode, gemini
  - [ ] Reference formatting tests (@filename.ext patterns)
  - [ ] Uniform syntax formatting tests (same format for all agents!)
  - [ ] Pane switching tests
  - [ ] Configuration validation tests

- [ ] **Write integration tests**
  - [ ] End-to-end workflow tests
  - [ ] Fallback mechanism tests
  - [ ] Error handling tests

- [ ] **Manual testing**
  - [ ] Test with real AI agents
  - [ ] Test on different platforms
  - [ ] Performance testing with large files

### Phase 4: Documentation (Week 4)

- [ ] **Write README.md**
  - [ ] Installation instructions
  - [ ] Quick start guide
  - [ ] Configuration reference
  - [ ] Example workflows

- [ ] **Create Vim help documentation**
  - [ ] Function reference
  - [ ] Configuration options
  - [ ] Troubleshooting guide

- [ ] **Add code documentation**
  - [ ] Function docstrings
  - [ ] Type annotations
  - [ ] Usage examples

### Phase 5: Polish & Release (Week 5)

- [ ] **Code quality improvements**
  - [ ] Code review and refactoring
  - [ ] Performance optimizations
  - [ ] Error handling improvements

- [ ] **Release preparation**
  - [ ] Version tagging
  - [ ] Changelog creation
  - [ ] Package for distribution

- [ ] **Community preparation**
  - [ ] Contribution guidelines
  - [ ] Issue templates
  - [ ] License selection

## Success Criteria

### MVP Success Metrics

1. **Functionality**: All core features work reliably
   - Agent detection accuracy > 95% for claude, opencode, gemini
   - Reference formatting accuracy > 98% with uniform syntax
   - Pane switching works in 100% of detected cases
   - Consistent behavior across all supported agents

2. **Usability**: Simple setup and usage  
   - Zero-config installation works out of the box for all supported agents
   - Clear error messages for common issues
   - Documentation covers uniform syntax behavior

3. **Reliability**: Handles edge cases gracefully
   - Graceful degradation when tmux unavailable
   - Proper error handling for missing files or invalid panes
   - No crashes or data loss under normal usage

4. **Performance**: Responsive user experience
   - Agent detection completes in < 100ms
   - Reference sending completes in < 50ms
   - No noticeable impact on Neovim startup time

### Post-MVP Enhancement Opportunities

**Phase 2 Extensions (Future Versions):**
- **Clipboard fallback**: Support workflows without tmux
- **Content mode**: Send actual file content for agents without `@filename` support
- **Additional agents**: Charm Crush, custom agent support
- **Multi-file context**: Send multiple file references at once
- **Session management**: Integration with agent session history
- **Provider-specific optimizations**: Leverage unique features per agent
- **Advanced UI**: Floating windows for agent selection
- **Custom prompt templates**: Pre-defined context patterns
- **Workspace-aware configurations**: Project-specific agent preferences
- **LSP integration**: Intelligent context based on language servers

## Risk Mitigation

### Technical Risks

1. **Tmux dependency**: MVP requires tmux - mitigated by clear documentation and error messages
2. **Agent detection reliability**: Extensive testing with various tmux setups and agent configurations
3. **Cross-platform compatibility**: Test on macOS, Linux, Windows (WSL)
4. **Filename escaping**: Handle special characters and spaces in file paths

### User Experience Risks

1. **Limited agent support**: Focus on major agents with proven `@filename` support
2. **Unclear error messages**: Implement helpful diagnostics for common issues
3. **Setup complexity**: Minimize with zero-config defaults and clear documentation
4. **Breaking changes**: Semantic versioning and backward compatibility

This plan provides a clear roadmap for implementing a focused, reliable MVP that addresses the core user need while maintaining simplicity and extensibility for future enhancements.

## 🚀 Major Simplification Achieved

**The discovery that all three major AI agents (Claude, OpenCode, Gemini) use the identical `@filename.ext#L1-5` syntax has dramatically simplified our MVP:**

- ❌ **No agent-specific syntax handling** needed
- ❌ **No complex configuration** for different formats  
- ❌ **No syntax detection logic** required
- ✅ **Single, uniform formatting function** for all agents
- ✅ **Simplified configuration** with minimal options
- ✅ **Consistent user experience** across all agents
- ✅ **Much cleaner codebase** and easier testing

This means our MVP can be **significantly simpler** while still providing universal compatibility with all major AI CLI agents. The implementation becomes straightforward: detect agent → format reference → send → switch pane.
