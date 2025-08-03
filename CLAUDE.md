# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Neovim plugin project** called `send-to-agent.nvim` that integrates Neovim with AI CLI agents running in tmux panes. The plugin sends filename references (e.g., `@filename.ext`) to AI agents using their native syntax, enabling seamless workflow between editing and AI assistance.

## Architecture

This is a **Lua-based Neovim plugin** with the following planned structure:

- **Single-file implementation**: Core functionality in `lua/send-to-agent.lua`
- **Pure Lua approach**: No external dependencies beyond Neovim built-ins
- **Reference-only strategy**: Sends `@filename.ext` patterns, not file content
- **Tmux integration**: Primary target for pane detection and switching
- **Agent-agnostic**: Uniform syntax across Claude, OpenCode, and Gemini CLI agents

### Key Technical Decisions

1. **Uniform syntax**: All supported agents use identical `@filename.ext#L1-5` format
2. **Agent detection**: Uses `tmux list-panes` with pattern matching
3. **Async operations**: Leverages `vim.system()` for command execution
4. **Zero-config**: Works out of the box with sensible defaults

## Core Components (Planned)

- `M.setup(opts)` - Plugin initialization
- `M.send_buffer()` - Send entire buffer as `@filename.ext`
- `M.send_selection()` - Send selection as `@filename.ext#L1-5`
- `M.detect_agent_panes()` - Find running AI agents
- `M.switch_to_agent()` - Switch to agent pane

## Development Commands

**Note**: This is a new project with no build system yet. Based on the PLAN.md, testing will use:

- **Testing framework**: busted or plenary (to be determined)
- **Manual testing**: Requires tmux and AI agents (claude, opencode, gemini)
- **No build process**: Pure Lua plugin, no compilation needed

## Supported AI Agents

The plugin targets these CLI agents with `@filename` syntax support:
- Claude Code CLI (`claude` command)
- OpenCode (`opencode` command) 
- Gemini CLI (`gemini` command)

All agents use the same reference format: `@filename.ext#L1-5`

## Development Status

**Current state**: Planning phase - only PLAN.md exists
**Next steps**: Implement core Lua module according to specification in PLAN.md