local utils = require("send-to-agent.utils")

local M = {}

---@class AgentPane
---@field pane_id string Tmux pane ID
---@field command string Command running in pane
---@field window_name string Window name
---@field agent_type string Detected agent type

---Get all tmux panes with their details
---@return AgentPane[]? List of panes or nil if tmux unavailable
function M.get_all_panes()
  if not utils.is_tmux_available() then
    return nil
  end

  local result = vim.system({
    "tmux",
    "list-panes",
    "-a",
    "-F",
    "#{pane_id}|#{pane_current_command}|#{window_name}",
  }, { capture = true }):wait()

  if result.code ~= 0 then
    return nil
  end

  local panes = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local pane_id, command, window_name = line:match("([^|]+)|([^|]+)|([^|]*)")
    if pane_id and command then
      table.insert(panes, {
        pane_id = pane_id,
        command = command,
        window_name = window_name or "",
        agent_type = "",
      })
    end
  end

  return panes
end

---Detect AI agent panes from tmux panes
---@return AgentPane[]? List of detected agent panes
function M.detect_agent_panes()
  local panes = M.get_all_panes()
  if not panes then
    return nil
  end

  local config = require("send-to-agent.config").get()
  local agent_panes = {}

  for _, pane in ipairs(panes) do
    for _, pattern in ipairs(config.agents.patterns) do
      if pane.command:match(pattern) then
        pane.agent_type = pattern
        table.insert(agent_panes, pane)
        break
      end
    end
  end

  return agent_panes
end

---Select the best agent pane based on priority
---@param agent_panes AgentPane[] List of agent panes
---@return AgentPane? Selected agent pane
function M.select_best_agent(agent_panes)
  if not agent_panes or #agent_panes == 0 then
    return nil
  end

  if #agent_panes == 1 then
    return agent_panes[1]
  end

  local config = require("send-to-agent.config").get()

  -- Select based on priority order
  for _, priority_agent in ipairs(config.agents.priority_order) do
    for _, pane in ipairs(agent_panes) do
      if pane.agent_type == priority_agent then
        return pane
      end
    end
  end

  -- Fallback to first available
  return agent_panes[1]
end

---Send text to a tmux pane
---@param pane_id string Tmux pane ID
---@param text string Text to send
---@return boolean Success status
function M.send_to_pane(pane_id, text)
  if not utils.is_tmux_available() then
    utils.notify("tmux is not available", vim.log.levels.ERROR)
    return false
  end

  local escaped_text = utils.escape_for_tmux(text)
  local result = vim.system({
    "tmux",
    "send-keys",
    "-t",
    pane_id,
    escaped_text,
    "Enter",
  }):wait()

  if result.code ~= 0 then
    utils.notify(string.format("Failed to send to pane %s", pane_id), vim.log.levels.ERROR)
    return false
  end

  return true
end

---Switch to a tmux pane
---@param pane_id string Tmux pane ID
---@return boolean Success status
function M.switch_to_pane(pane_id)
  if not utils.is_tmux_available() then
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
function M.send_to_agent(text)
  local agent_panes = M.detect_agent_panes()

  if not agent_panes then
    return false, "tmux is not available"
  end

  if #agent_panes == 0 then
    return false, "No AI agents detected in tmux panes"
  end

  local selected_pane = M.select_best_agent(agent_panes)
  if not selected_pane then
    return false, "Failed to select agent pane"
  end

  local success = M.send_to_pane(selected_pane.pane_id, text)
  if not success then
    return false, string.format("Failed to send to %s agent", selected_pane.agent_type)
  end

  local config = require("send-to-agent.config").get()
  if config.tmux.auto_switch_pane then
    M.switch_to_pane(selected_pane.pane_id)
  end

  utils.notify(string.format("Sent to %s agent in pane %s", selected_pane.agent_type, selected_pane.pane_id))
  return true
end

return M