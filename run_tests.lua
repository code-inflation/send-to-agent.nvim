#!/usr/bin/env nvim
-- Simple test runner for send-to-agent.nvim
-- Usage: nvim --headless -l run_tests.lua

-- Set up the test environment
local plugin_path = vim.fn.getcwd()
vim.opt.runtimepath:prepend(plugin_path)

-- Load minimal test config
require("tests.minimal_init").setup()

-- Simple test runner without plenary dependency
local function run_simple_test()
  print("=== Running send-to-agent.nvim E2E Tests ===\n")
  
  local send_to_agent = require("send-to-agent")
  local utils = require("send-to-agent.utils")
  
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
  
  -- Test 1: Plugin loads correctly
  test("Plugin loads without errors", function()
    assert(send_to_agent ~= nil, "Plugin should load")
    assert(type(send_to_agent.setup) == "function", "Should have setup function")
    assert(type(send_to_agent.send_buffer) == "function", "Should have send_buffer function")
    assert(type(send_to_agent.send_selection) == "function", "Should have send_selection function")
  end)
  
  -- Test 2: Configuration works
  test("Configuration system", function()
    send_to_agent.setup({
      agents = {
        patterns = { "test-agent" }
      }
    })
    local config = send_to_agent.get_config()
    assert(config.agents.patterns[1] == "test-agent", "Should apply custom config")
  end)
  
  -- Test 3: Utility functions
  test("File reference creation", function()
    -- Use a real temp file for testing
    local test_file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({"-- test"}, test_file)
    
    local ref1 = utils.create_file_reference(test_file)
    assert(ref1:match("@.*%.lua"), "Should create basic file reference")
    
    local ref2 = utils.create_file_reference(test_file, 10, 20)
    assert(ref2:match("@.*%.lua#L10%-20"), "Should create range reference")
    
    local ref3 = utils.create_file_reference(test_file, 15, 15)
    assert(ref3:match("@.*%.lua#L15") and not ref3:match("L15%-"), "Should create single line reference")
    
    -- Cleanup
    vim.fn.delete(test_file)
  end)
  
  -- Test 4: Tmux escaping
  test("Tmux text escaping", function()
    local escaped = utils.escape_for_tmux("file 'with' quotes.lua")
    assert(type(escaped) == "string", "Should return escaped string")
    assert(escaped:find("'\"'\"'"), "Should properly escape single quotes")
  end)
  
  -- Test 5: Error handling for missing files
  test("Error handling for unnamed buffers", function()
    -- Create unnamed buffer
    vim.cmd("enew")
    local success = send_to_agent.send_buffer()
    assert(success == false, "Should fail gracefully for unnamed buffers")
  end)
  
  
  -- Summary
  print(string.format("\n=== Test Results ==="))
  print(string.format("✅ Passed: %d", tests_passed))
  print(string.format("❌ Failed: %d", tests_failed))
  print(string.format("📊 Total:  %d", tests_passed + tests_failed))
  
  if tests_failed == 0 then
    print("\n🎉 All tests passed!")
    vim.cmd("qall!")
  else
    print("\n💥 Some tests failed!")
    os.exit(1)
  end
end

-- Run the tests
run_simple_test()