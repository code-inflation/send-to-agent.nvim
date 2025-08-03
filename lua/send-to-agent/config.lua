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

local M = {}

---Default configuration
---@type SendToAgentConfig
M.defaults = {
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

---Current configuration
---@type SendToAgentConfig
M.options = {}

---Setup configuration with user options
---@param opts? SendToAgentConfig User configuration options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

---Get current configuration
---@return SendToAgentConfig
function M.get()
  if vim.tbl_isempty(M.options) then
    M.setup()
  end
  return M.options
end

return M