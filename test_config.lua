#!/usr/bin/env nvim
-- Configuration test for send-to-agent.nvim
-- Tests that custom agent patterns and priority work correctly
-- Usage: nvim --headless -l test_config.lua

local plugin_path = vim.fn.getcwd()
vim.opt.runtimepath:prepend(plugin_path)

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

local function run_config_tests()
  print("=== Configuration Tests ===\n")

  local tests_passed = 0
  local tests_failed = 0

  local function test(name, fn)
    io.write("Testing: " .. name .. " ... ")
    local success, err = pcall(fn)
    if success then
      print("✅ PASS")
      tests_passed = tests_passed + 1
    else
      print("❌ FAIL")
      print("  Error: " .. tostring(err))
      tests_failed = tests_failed + 1
    end
  end

  -- Test 1: Default configuration
  test("Default configuration", function()
    -- Reset global state
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")
    send_to_agent.setup()

    local config = send_to_agent.get_config()

    assert(config.agents, "Should have agents config")
    assert(config.agents.patterns, "Should have patterns")
    assert(config.agents.priority_order, "Should have priority_order")

    -- Check default patterns
    assert(vim.tbl_contains(config.agents.patterns, "claude"), "Should include 'claude'")
    assert(vim.tbl_contains(config.agents.patterns, "codex"), "Should include 'codex'")
    assert(vim.tbl_contains(config.agents.patterns, "cursor-agent"), "Should include 'cursor-agent'")
    assert(vim.tbl_contains(config.agents.patterns, "opencode"), "Should include 'opencode'")
    assert(vim.tbl_contains(config.agents.patterns, "gemini"), "Should include 'gemini'")

    print("  Default patterns: " .. table.concat(config.agents.patterns, ", "))
  end)

  -- Test 2: Custom agent patterns
  test("Custom agent patterns", function()
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")
    send_to_agent.setup({
      agents = {
        patterns = { "my-custom-agent", "another-agent" }
      }
    })

    local config = send_to_agent.get_config()

    assert(#config.agents.patterns == 2, "Should have 2 custom patterns")
    assert(vim.tbl_contains(config.agents.patterns, "my-custom-agent"), "Should include 'my-custom-agent'")
    assert(vim.tbl_contains(config.agents.patterns, "another-agent"), "Should include 'another-agent'")
    assert(not vim.tbl_contains(config.agents.patterns, "claude"), "Should NOT include default 'claude'")

    print("  Custom patterns: " .. table.concat(config.agents.patterns, ", "))
  end)

  -- Test 3: Custom priority order
  test("Custom priority order", function()
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")
    send_to_agent.setup({
      agents = {
        patterns = { "gemini", "claude", "codex" },
        priority_order = { "gemini", "claude", "codex" } -- gemini has highest priority
      }
    })

    local config = send_to_agent.get_config()

    assert(config.agents.priority_order[1] == "gemini", "Gemini should be first priority")
    assert(config.agents.priority_order[2] == "claude", "Claude should be second priority")
    assert(config.agents.priority_order[3] == "codex", "Codex should be third priority")

    print("  Priority order: " .. table.concat(config.agents.priority_order, " > "))
  end)

  -- Test 4: Partial configuration (merge with defaults)
  test("Partial configuration merges with defaults", function()
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")
    send_to_agent.setup({
      agents = {
        patterns = { "custom-agent" }
        -- priority_order not specified, should use default
      },
      tmux = {
        auto_switch_pane = false
      }
      -- formatting not specified, should use defaults
    })

    local config = send_to_agent.get_config()

    -- Custom agent patterns
    assert(vim.tbl_contains(config.agents.patterns, "custom-agent"), "Should have custom pattern")

    -- Should have priority_order (from defaults, since patterns were overridden)
    assert(config.agents.priority_order, "Should have priority_order")

    -- Custom tmux config
    assert(config.tmux.auto_switch_pane == false, "Should have custom tmux config")
    assert(config.tmux.return_focus_delay == 0, "Should have default return_focus_delay")

    -- Default formatting config
    assert(config.formatting.relative_paths == true, "Should have default relative_paths")
    assert(config.formatting.include_line_numbers == true, "Should have default include_line_numbers")
  end)

  -- Test 5: Empty configuration uses defaults
  test("Empty configuration uses all defaults", function()
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")
    send_to_agent.setup({}) -- Empty config

    local config = send_to_agent.get_config()

    assert(#config.agents.patterns == 5, "Should have 5 default patterns")
    assert(#config.agents.priority_order == 5, "Should have 5 default priority entries")
    assert(config.tmux.auto_switch_pane == true, "Should have default auto_switch_pane")
    assert(config.formatting.relative_paths == true, "Should have default relative_paths")
  end)

  -- Test 6: Adding new agents while keeping defaults
  test("Extending default agents", function()
    vim.g.loaded_send_to_agent = nil
    package.loaded["send-to-agent"] = nil

    local send_to_agent = require("send-to-agent")

    -- Get defaults first
    local defaults = { "claude", "codex", "cursor-agent", "opencode", "gemini" }
    local extended_patterns = vim.list_extend(vim.deepcopy(defaults), { "my-agent", "another-agent" })
    local extended_priority = vim.list_extend(vim.deepcopy(defaults), { "my-agent", "another-agent" })

    send_to_agent.setup({
      agents = {
        patterns = extended_patterns,
        priority_order = extended_priority
      }
    })

    local config = send_to_agent.get_config()

    assert(#config.agents.patterns == 7, "Should have 7 patterns (5 defaults + 2 custom)")
    assert(vim.tbl_contains(config.agents.patterns, "claude"), "Should still have 'claude'")
    assert(vim.tbl_contains(config.agents.patterns, "my-agent"), "Should have 'my-agent'")
    assert(vim.tbl_contains(config.agents.patterns, "another-agent"), "Should have 'another-agent'")

    print("  Extended patterns: " .. table.concat(config.agents.patterns, ", "))
  end)

  -- Summary
  print(string.format("\n=== Test Results ==="))
  print(string.format("✅ Passed: %d", tests_passed))
  print(string.format("❌ Failed: %d", tests_failed))
  print(string.format("📊 Total:  %d", tests_passed + tests_failed))

  if tests_failed == 0 then
    print("\n🎉 All configuration tests passed!")
    print("✨ Agent configuration system is working correctly!")
    vim.cmd("qall!")
  else
    print("\n💥 Some tests failed!")
    os.exit(1)
  end
end

run_config_tests()
