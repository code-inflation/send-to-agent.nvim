-- Minimal Neovim configuration for testing send-to-agent.nvim

local M = {}

function M.setup()
  -- Set up package path
  local script_path = debug.getinfo(1).source:match("@?(.*/)")
  local plugin_path = vim.fn.fnamemodify(script_path, ":h")
  
  -- Add plugin to runtimepath
  vim.opt.runtimepath:prepend(plugin_path)
  
  -- Minimal settings for testing
  vim.opt.swapfile = false
  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.hidden = true
  
  -- Ensure we have a proper window setup
  if vim.api.nvim_get_current_win() == 0 then
    vim.cmd("new")
  end
  
  -- Load the plugin
  require("send-to-agent")
end

-- Auto-setup if running as minimal init or test
if vim.env.PLENARY_TEST_TIMEOUT or vim.v.progname:match("test") then
  M.setup()
end

return M