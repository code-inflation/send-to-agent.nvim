---send-to-agent.nvim - Send filename references to AI CLI agents in tmux panes
---@author cybuerg
---@license MIT

local config = require("send-to-agent.config")
local tmux = require("send-to-agent.tmux")
local utils = require("send-to-agent.utils")

local M = {}

---Setup the plugin with user configuration
---@param opts? SendToAgentConfig User configuration options
function M.setup(opts)
  config.setup(opts)
end

---Send current buffer as file reference to AI agent
---@return boolean Success status
function M.send_buffer()
  local filepath = vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    utils.notify("Buffer has no associated file", vim.log.levels.WARN)
    return false
  end

  local file_ref = utils.create_file_reference(filepath)
  local success, error_msg = tmux.send_to_agent(file_ref)

  if not success then
    utils.notify(error_msg or "Failed to send buffer", vim.log.levels.ERROR)
  end

  return success
end

---Send visual selection as file reference with line numbers to AI agent
---@return boolean Success status
function M.send_selection()
  local filepath = vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    utils.notify("Buffer has no associated file", vim.log.levels.WARN)
    return false
  end

  local start_line, end_line = utils.get_visual_selection_range()
  local file_ref = utils.create_file_reference(filepath, start_line, end_line)
  local success, error_msg = tmux.send_to_agent(file_ref)

  if not success then
    utils.notify(error_msg or "Failed to send selection", vim.log.levels.ERROR)
  end

  return success
end

---Detect and display available AI agent panes
---@return AgentPane[]? List of detected agent panes
function M.detect_agent_panes()
  local agent_panes = tmux.detect_agent_panes()

  if not agent_panes then
    utils.notify("tmux is not available", vim.log.levels.ERROR)
    return nil
  end

  if #agent_panes == 0 then
    utils.notify("No AI agents detected in tmux panes", vim.log.levels.WARN)
    return {}
  end

  local message = string.format("Detected %d AI agent(s):", #agent_panes)
  for _, pane in ipairs(agent_panes) do
    message = message .. string.format("\n  %s (%s) - %s", pane.agent_type, pane.pane_id, pane.window_name)
  end

  utils.notify(message)
  return agent_panes
end

---Get plugin configuration
---@return SendToAgentConfig Current configuration
function M.get_config()
  return config.get()
end

---Send arbitrary text to AI agent (for advanced usage)
---@param text string Text to send
---@return boolean Success status
function M.send_text(text)
  local success, error_msg = tmux.send_to_agent(text)

  if not success then
    utils.notify(error_msg or "Failed to send text", vim.log.levels.ERROR)
  end

  return success
end

return M