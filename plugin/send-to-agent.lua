-- send-to-agent.nvim plugin initialization and commands
-- This file runs once when Neovim starts

if vim.g.loaded_send_to_agent then
  return
end
vim.g.loaded_send_to_agent = 1

-- Only load in Neovim 0.9+
if vim.fn.has("nvim-0.9") == 0 then
  vim.notify("[send-to-agent] Requires Neovim 0.9+", vim.log.levels.ERROR)
  return
end

local send_to_agent = require("send-to-agent")

-- User commands
vim.api.nvim_create_user_command("SendToAgent", function()
  send_to_agent.send_buffer()
end, {
  desc = "Send current buffer as file reference to AI agent",
})

vim.api.nvim_create_user_command("SendToAgentSelection", function()
  send_to_agent.send_selection()
end, {
  desc = "Send visual selection as file reference to AI agent",
  range = true,
})

vim.api.nvim_create_user_command("SendToAgentDetect", function()
  send_to_agent.detect_agent_panes()
end, {
  desc = "Detect and display available AI agent panes",
})

-- Plug mappings for user customization
vim.keymap.set("n", "<Plug>(SendToAgentBuffer)", send_to_agent.send_buffer, {
  desc = "Send buffer to AI agent",
})

vim.keymap.set("v", "<Plug>(SendToAgentSelection)", send_to_agent.send_selection, {
  desc = "Send selection to AI agent",
})

vim.keymap.set("n", "<Plug>(SendToAgentDetect)", send_to_agent.detect_agent_panes, {
  desc = "Detect AI agents",
})