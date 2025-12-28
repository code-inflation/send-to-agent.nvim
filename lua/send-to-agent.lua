---send-to-agent.nvim - Send filename references to AI CLI agents in tmux panes
---@author cybuerg  
---@license MIT

-- =============================================================================
-- TYPE DEFINITIONS
-- =============================================================================

---@class SendToAgentConfig
---@field agents SendToAgentAgentsConfig
---@field tmux SendToAgentTmuxConfig
---@field formatting SendToAgentFormattingConfig

---@class SendToAgentAgentsConfig
---@field patterns string[] Agent command patterns to detect
---@field priority_order string[] Priority order for agent selection

---@class SendToAgentTmuxConfig
---@field auto_switch_pane boolean Whether to automatically switch to agent pane
---@field return_focus_delay number Delay in ms before returning focus (0 = no return)

---@class SendToAgentFormattingConfig
---@field relative_paths boolean Use relative paths from git root when available
---@field include_line_numbers boolean Always use @file.ext#L1-5 for selections

---@class AgentPane
---@field pane_id string Tmux pane ID
---@field command string Command running in pane
---@field window_name string Window name
---@field agent_type string Detected agent type
---@field session_name string Tmux session name
---@field window_index number Tmux window index

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

local M = {}

---Default configuration
---@type SendToAgentConfig
local defaults = {
  agents = {
    patterns = { "claude", "codex", "cursor-agent", "opencode", "gemini" },
    priority_order = { "claude", "codex", "cursor-agent", "opencode", "gemini" },
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

---Current configuration
---@type SendToAgentConfig
local config = {}

---Get current configuration
---@return SendToAgentConfig
local function get_config()
  if vim.tbl_isempty(config) then
    config = vim.deepcopy(defaults)
  end
  return config
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

---Check if tmux is available
---@return boolean
local function is_tmux_available()
  local result = vim.system({ "which", "tmux" }, { capture = true }):wait()
  return result.code == 0
end

---Get relative path from git root, fallback to absolute path
---@param filepath string Absolute file path
---@return string Relative path from git root or absolute path
local function get_relative_path(filepath)
  if not filepath then
    return ""
  end

  -- Ensure filepath is absolute
  local abs_filepath = vim.fn.fnamemodify(filepath, ":p")
  local dir_path = vim.fn.fnamemodify(abs_filepath, ":h")
  
  -- Check if directory exists before trying git command
  if vim.fn.isdirectory(dir_path) == 0 then
    return vim.fn.fnamemodify(filepath, ":t")
  end

  -- Try to get git root
  local git_result = vim.system({ "git", "rev-parse", "--show-toplevel" }, {
    cwd = dir_path,
    capture = true,
  }):wait()

  if git_result.code == 0 and git_result.stdout then
    local git_root = vim.trim(git_result.stdout)
    local relative = abs_filepath:sub(#git_root + 2) -- +2 to remove leading slash
    if relative and relative ~= "" then
      return relative
    end
  end

  -- Fallback to filename only
  return vim.fn.fnamemodify(filepath, ":t")
end

---Escape special characters in filename for tmux send-keys
---@param text string Text to escape
---@return string Escaped text
local function escape_for_tmux(text)
  -- Escape single quotes for tmux send-keys
  return text:gsub("'", "'\"'\"'")
end

---Get visual selection line range
---@return number, number Start line, end line (1-indexed)
local function get_visual_selection_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return start_pos[2], end_pos[2]
end

---Create file reference string
---@param filepath string File path
---@param start_line? number Start line number (1-indexed)
---@param end_line? number End line number (1-indexed)
---@return string File reference in @filename.ext#L1-5 format
local function create_file_reference(filepath, start_line, end_line)
  local current_config = get_config()
  local path = current_config.formatting.relative_paths and get_relative_path(filepath) or filepath

  if start_line and end_line and current_config.formatting.include_line_numbers then
    if start_line == end_line then
      return string.format("@%s#L%d", path, start_line)
    else
      return string.format("@%s#L%d-%d", path, start_line, end_line)
    end
  end

  return string.format("@%s", path)
end

---Show notification to user
---@param message string Message to display
---@param level? number Log level (vim.log.levels)
local function notify(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(string.format("[send-to-agent] %s", message), level)
end

-- =============================================================================
-- TMUX INTEGRATION
-- =============================================================================

---Get current tmux context (session and window)
---@return string?, number? Current session name and window index, or nil if not in tmux
local function get_current_context()
  if not is_tmux_available() then
    return nil, nil
  end

  local result = vim.system({
    "tmux",
    "display-message",
    "-p",
    "#{session_name}|#{window_index}",
  }, { capture = true }):wait()

  if result.code ~= 0 or not result.stdout then
    return nil, nil
  end

  local session_name, window_index = result.stdout:match("([^|]+)|([^|]*)")
  return session_name, tonumber(window_index)
end

---Get all tmux panes with their details
---@return AgentPane[]? List of panes or nil if tmux unavailable
local function get_all_panes()
  if not is_tmux_available() then
    return nil
  end

  local result = vim.system({
    "tmux",
    "list-panes",
    "-a",
    "-F",
    "#{pane_id}|#{pane_current_command}|#{window_name}|#{session_name}|#{window_index}",
  }, { capture = true }):wait()

  if result.code ~= 0 then
    return nil
  end

  local panes = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local pane_id, command, window_name, session_name, window_index = line:match("([^|]+)|([^|]+)|([^|]*)|([^|]*)|([^|]*)")
    if pane_id and command then
      table.insert(panes, {
        pane_id = pane_id,
        command = command,
        window_name = window_name or "",
        agent_type = "",
        session_name = session_name or "",
        window_index = tonumber(window_index) or 0,
      })
    end
  end

  return panes
end

---Detect AI agent panes from tmux panes (session-scoped)
---@return AgentPane[]? List of detected agent panes
local function detect_agent_panes()
  local panes = get_all_panes()
  if not panes then
    return nil
  end

  -- Get current session context
  local current_session, _ = get_current_context()
  if not current_session then
    return nil -- Not in tmux
  end

  local current_config = get_config()
  local agent_panes = {}

  -- Filter panes to current session only and detect agents
  for _, pane in ipairs(panes) do
    if pane.session_name == current_session then -- Only consider panes in current session
      for _, pattern in ipairs(current_config.agents.patterns) do
        if pane.command:match(pattern) then
          pane.agent_type = pattern
          table.insert(agent_panes, pane)
          break
        end
      end
    end
  end

  return agent_panes
end

---Select the best agent pane based on context-aware priority
---@param agent_panes AgentPane[] List of agent panes
---@return AgentPane? Selected agent pane
local function select_best_agent(agent_panes)
  if not agent_panes or #agent_panes == 0 then
    return nil
  end

  if #agent_panes == 1 then
    return agent_panes[1]
  end

  -- Get current context
  local current_session, current_window = get_current_context()
  if not current_session or not current_window then
    -- Fallback to old behavior if context unavailable
    return agent_panes[1]
  end

  local current_config = get_config()

  -- Priority 1: Same window agents (highest priority)
  for _, priority_agent in ipairs(current_config.agents.priority_order) do
    for _, pane in ipairs(agent_panes) do
      if pane.agent_type == priority_agent 
         and pane.session_name == current_session 
         and pane.window_index == current_window then
        return pane
      end
    end
  end

  -- Priority 2: Same session, different window agents (fallback)
  for _, priority_agent in ipairs(current_config.agents.priority_order) do
    for _, pane in ipairs(agent_panes) do
      if pane.agent_type == priority_agent 
         and pane.session_name == current_session then
        return pane
      end
    end
  end

  -- This should not happen since we already filter by session in detect_agent_panes
  -- But as a final fallback
  return agent_panes[1]
end

---Send text to a tmux pane
---@param pane_id string Tmux pane ID
---@param text string Text to send
---@return boolean Success status
local function send_to_pane(pane_id, text)
  if not is_tmux_available() then
    notify("tmux is not available", vim.log.levels.ERROR)
    return false
  end

  local escaped_text = escape_for_tmux(text)
  local result = vim.system({
    "tmux",
    "send-keys",
    "-t",
    pane_id,
    escaped_text,
    "Enter",
  }):wait()

  if result.code ~= 0 then
    notify(string.format("Failed to send to pane %s", pane_id), vim.log.levels.ERROR)
    return false
  end

  return true
end

---Switch to a tmux pane
---@param pane_id string Tmux pane ID
---@return boolean Success status
local function switch_to_pane(pane_id)
  if not is_tmux_available() then
    return false
  end

  local result = vim.system({
    "tmux",
    "select-pane",
    "-t",
    pane_id,
  }):wait()

  return result.code == 0
end

---Find and send to best available agent
---@param text string Text to send
---@return boolean, string? Success status and error message
local function send_to_agent(text)
  local agent_panes = detect_agent_panes()

  if not agent_panes then
    return false, "tmux is not available"
  end

  if #agent_panes == 0 then
    local current_session, _ = get_current_context()
    if current_session then
      return false, string.format("No AI agents detected in current tmux session '%s'", current_session)
    else
      return false, "No AI agents detected in tmux panes"
    end
  end

  local selected_pane = select_best_agent(agent_panes)
  if not selected_pane then
    return false, "Failed to select agent pane"
  end

  local success = send_to_pane(selected_pane.pane_id, text)
  if not success then
    return false, string.format("Failed to send to %s agent", selected_pane.agent_type)
  end

  local current_config = get_config()
  if current_config.tmux.auto_switch_pane then
    switch_to_pane(selected_pane.pane_id)
  end

  -- Show context-aware notification
  local context_info = ""
  local current_session, current_window = get_current_context()
  if current_session and current_window and selected_pane.window_index == current_window then
    context_info = " (same window)"
  elseif current_session and selected_pane.window_index ~= current_window then
    context_info = string.format(" (window %d)", selected_pane.window_index)
  end
  
  notify(string.format("Sent to %s agent in pane %s%s", selected_pane.agent_type, selected_pane.pane_id, context_info))
  return true
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

---Setup the plugin with user configuration
---@param opts? SendToAgentConfig User configuration options
function M.setup(opts)
  -- Guard against multiple setup calls
  if vim.g.loaded_send_to_agent then
    return
  end
  vim.g.loaded_send_to_agent = 1

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 0 then
    vim.notify("[send-to-agent] Requires Neovim 0.9+", vim.log.levels.ERROR)
    return
  end

  -- Setup configuration
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Register user commands
  vim.api.nvim_create_user_command("SendToAgent", function()
    M.send_buffer()
  end, {
    desc = "Send current buffer as file reference to AI agent",
  })

  vim.api.nvim_create_user_command("SendToAgentSelection", function()
    M.send_selection()
  end, {
    desc = "Send visual selection as file reference to AI agent",
    range = true,
  })

  vim.api.nvim_create_user_command("SendToAgentDetect", function()
    M.detect_agent_panes()
  end, {
    desc = "Detect and display available AI agent panes",
  })

  -- Register Plug mappings for user customization
  vim.keymap.set("n", "<Plug>(SendToAgentBuffer)", M.send_buffer, {
    desc = "Send buffer to AI agent",
  })

  vim.keymap.set("v", "<Plug>(SendToAgentSelection)", M.send_selection, {
    desc = "Send selection to AI agent",
  })

  vim.keymap.set("n", "<Plug>(SendToAgentDetect)", M.detect_agent_panes, {
    desc = "Detect AI agents",
  })
end

---Send current buffer as file reference to AI agent
---@return boolean Success status
function M.send_buffer()
  local filepath = vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    notify("Buffer has no associated file", vim.log.levels.WARN)
    return false
  end

  local file_ref = create_file_reference(filepath)
  local success, error_msg = send_to_agent(file_ref)

  if not success then
    notify(error_msg or "Failed to send buffer", vim.log.levels.ERROR)
  end

  return success
end

---Send visual selection as file reference with line numbers to AI agent
---@return boolean Success status
function M.send_selection()
  local filepath = vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    notify("Buffer has no associated file", vim.log.levels.WARN)
    return false
  end

  local start_line, end_line = get_visual_selection_range()
  local file_ref = create_file_reference(filepath, start_line, end_line)
  local success, error_msg = send_to_agent(file_ref)

  if not success then
    notify(error_msg or "Failed to send selection", vim.log.levels.ERROR)
  end

  return success
end

---Detect and display available AI agent panes
---@return AgentPane[]? List of detected agent panes
function M.detect_agent_panes()
  local agent_panes = detect_agent_panes()

  if not agent_panes then
    notify("tmux is not available", vim.log.levels.ERROR)
    return nil
  end

  if #agent_panes == 0 then
    notify("No AI agents detected in tmux panes", vim.log.levels.WARN)
    return {}
  end

  local message = string.format("Detected %d AI agent(s):", #agent_panes)
  for _, pane in ipairs(agent_panes) do
    message = message .. string.format("\n  %s (%s) - %s", pane.agent_type, pane.pane_id, pane.window_name)
  end

  notify(message)
  return agent_panes
end

---Get plugin configuration
---@return SendToAgentConfig Current configuration
function M.get_config()
  return get_config()
end

---Send arbitrary text to AI agent (for advanced usage)
---@param text string Text to send
---@return boolean Success status
function M.send_text(text)
  local success, error_msg = send_to_agent(text)

  if not success then
    notify(error_msg or "Failed to send text", vim.log.levels.ERROR)
  end

  return success
end

return M