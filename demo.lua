#!/usr/bin/env nvim
-- Demonstration script for send-to-agent.nvim
-- This shows how the plugin works with real AI agents
-- Usage: nvim --headless -l demo.lua

-- Set up the test environment
local plugin_path = vim.fn.getcwd()
vim.opt.runtimepath:prepend(plugin_path)

-- Load minimal test config
require("tests.minimal_init").setup()

local function run_demo()
  print("=== send-to-agent.nvim Demo ===\n")
  
  local send_to_agent = require("send-to-agent")
  local utils = require("send-to-agent.utils")
  
  -- Setup with configuration
  send_to_agent.setup({
    tmux = {
      auto_switch_pane = false -- Don't switch during demo
    }
  })
  
  print("1. Plugin Configuration:")
  local config = send_to_agent.get_config()
  print("   - Supported agents: " .. table.concat(config.agents.patterns, ", "))
  print("   - Auto-switch panes: " .. tostring(config.tmux.auto_switch_pane))
  print("   - Relative paths: " .. tostring(config.formatting.relative_paths))
  print("")
  
  print("2. Checking tmux availability:")
  local tmux_available = utils.is_tmux_available()
  print("   - tmux available: " .. tostring(tmux_available))
  
  if not tmux_available then
    print("   ❌ tmux is not available. Please install tmux to use this plugin.")
    return
  end
  print("")
  
  print("3. Detecting AI agents in tmux:")
  local agents = send_to_agent.detect_agent_panes()
  
  if not agents or #agents == 0 then
    print("   ⚠️  No AI agents detected in tmux panes.")
    print("   💡 To test with a real agent, run:")
    print("      tmux new-session -d -s demo")
    print("      tmux send-keys -t demo 'claude' Enter")
    print("      # (or 'opencode' or 'gemini')")
  else
    print("   ✅ Found " .. #agents .. " AI agent(s):")
    for i, agent in ipairs(agents) do
      print("      " .. i .. ". " .. agent.agent_type .. " in pane " .. agent.pane_id .. " (" .. agent.window_name .. ")")
    end
  end
  print("")
  
  print("4. Testing file reference creation:")
  -- Create a demo file
  local demo_file = vim.fn.tempname() .. ".lua"
  vim.fn.writefile({
    "-- Demo file for send-to-agent.nvim",
    "local M = {}",
    "",
    "function M.greet(name)",
    "  print('Hello, ' .. name .. '!')",
    "  return 'Greeting sent'",
    "end",
    "",
    "function M.calculate(a, b)",
    "  return a + b",
    "end",
    "",
    "return M"
  }, demo_file)
  
  -- Test different reference formats
  local ref1 = utils.create_file_reference(demo_file)
  print("   - Full file: " .. ref1)
  
  local ref2 = utils.create_file_reference(demo_file, 4, 7)
  print("   - Selection (lines 4-7): " .. ref2)
  
  local ref3 = utils.create_file_reference(demo_file, 9, 9) 
  print("   - Single line (line 9): " .. ref3)
  print("")
  
  print("5. Testing send functionality:")
  -- Open the demo file
  vim.cmd("edit " .. demo_file)
  
  if agents and #agents > 0 then
    print("   - Attempting to send file to agent...")
    local success = send_to_agent.send_buffer()
    if success then
      print("   ✅ Successfully sent: " .. ref1)
      print("   🔄 Check your AI agent pane to see the file reference!")
    else
      print("   ❌ Failed to send to agent")
    end
    
    -- Test selection sending
    print("   - Testing selection sending (lines 4-7)...")
    vim.fn.setpos("'<", { 0, 4, 1, 0 })
    vim.fn.setpos("'>", { 0, 7, 1, 0 })
    
    local success2 = send_to_agent.send_selection()
    if success2 then
      print("   ✅ Successfully sent selection: " .. ref2)
    else
      print("   ❌ Failed to send selection")
    end
  else
    print("   ⏭️  Skipping send test (no agents available)")
  end
  print("")
  
  print("6. Available commands:")
  print("   - :SendToAgent          - Send current buffer")
  print("   - :SendToAgentSelection - Send visual selection") 
  print("   - :SendToAgentDetect    - Show detected agents")
  print("")
  
  print("7. Suggested keymaps (add to your config):")
  print("   vim.keymap.set('n', '<leader>sa', '<Plug>(SendToAgentBuffer)')")
  print("   vim.keymap.set('v', '<leader>sa', '<Plug>(SendToAgentSelection)')")  
  print("   vim.keymap.set('n', '<leader>sd', '<Plug>(SendToAgentDetect)')")
  print("")
  
  -- Cleanup
  vim.fn.delete(demo_file)
  
  print("🎉 Demo completed!")
  print("📚 Check the README.md for full documentation and usage examples.")
  
  vim.cmd("qall!")
end

-- Run the demo
run_demo()