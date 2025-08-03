-- End-to-end tests for send-to-agent.nvim
local send_to_agent = require("send-to-agent")

describe("send-to-agent E2E tests", function()
  local test_file_path
  local original_system

  before_each(function()
    -- Create a temporary test file
    test_file_path = vim.fn.tempname() .. ".lua"
    local test_content = {
      "-- Test Lua file",
      "local function test_function()",
      "  print('Hello, World!')",
      "  return true",
      "end",
      "",
      "return test_function",
    }
    vim.fn.writefile(test_content, test_file_path)

    -- Reset configuration
    send_to_agent.setup({
      tmux = {
        auto_switch_pane = false, -- Don't switch panes during tests
      },
    })

    -- Mock vim.system to capture tmux commands
    original_system = vim.system
    vim.system = function(cmd, opts)
      opts = opts or {}
      local result = {
        code = 0,
        stdout = "",
        stderr = "",
      }

      -- Mock tmux responses based on command
      if cmd[1] == "which" and cmd[2] == "tmux" then
        -- tmux is available
        result.code = 0
      elseif cmd[1] == "tmux" and cmd[2] == "list-panes" then
        -- Mock agent panes
        result.stdout = "%1|claude|agent-window\n%2|bash|main-window\n%3|opencode|dev-window\n"
      elseif cmd[1] == "tmux" and cmd[2] == "send-keys" then
        -- Capture the sent text for verification
        local sent_text = cmd[5] -- The text being sent
        print("MOCK SEND: " .. sent_text)
        result.code = 0
      elseif cmd[1] == "git" and cmd[2] == "rev-parse" then
        -- Mock git root
        result.stdout = "/mock/git/root"
        result.code = 0
      end

      if opts.capture then
        return {
          wait = function()
            return result
          end,
        }
      else
        return {
          wait = function()
            return result
          end,
        }
      end
    end
  end)

  after_each(function()
    -- Clean up
    if test_file_path and vim.fn.filereadable(test_file_path) == 1 then
      vim.fn.delete(test_file_path)
    end

    -- Restore original vim.system
    vim.system = original_system
  end)

  describe("send_buffer functionality", function()
    it("should send buffer reference to agent", function()
      -- Open the test file
      vim.cmd("edit " .. test_file_path)

      -- Capture print output to verify the sent text
      local captured_output = {}
      local original_print = print
      print = function(msg)
        table.insert(captured_output, msg)
        original_print(msg)
      end

      -- Execute send_buffer
      local success = send_to_agent.send_buffer()

      -- Restore print
      print = original_print

      -- Verify success
      assert.is_true(success)

      -- Check that the correct reference was sent
      local found_send = false
      for _, output in ipairs(captured_output) do
        if output:match("MOCK SEND:") and output:match("@.*%.lua") then
          found_send = true
          break
        end
      end
      assert.is_true(found_send, "Expected to find file reference in tmux send command")
    end)

    it("should handle buffer without file gracefully", function()
      -- Create unnamed buffer
      vim.cmd("enew")

      -- Execute send_buffer
      local success = send_to_agent.send_buffer()

      -- Should fail gracefully
      assert.is_false(success)
    end)
  end)

  describe("send_selection functionality", function()
    it("should send selection with line numbers", function()
      -- Open the test file
      vim.cmd("edit " .. test_file_path)

      -- Mock visual selection (lines 2-4)
      vim.fn.setpos("'<", { 0, 2, 1, 0 })
      vim.fn.setpos("'>", { 0, 4, 1, 0 })

      -- Capture print output
      local captured_output = {}
      local original_print = print
      print = function(msg)
        table.insert(captured_output, msg)
        original_print(msg)
      end

      -- Execute send_selection
      local success = send_to_agent.send_selection()

      -- Restore print
      print = original_print

      -- Verify success
      assert.is_true(success)

      -- Check that the correct reference with line numbers was sent
      local found_selection = false
      for _, output in ipairs(captured_output) do
        if output:match("MOCK SEND:") and output:match("@.*%.lua#L2%-4") then
          found_selection = true
          break
        end
      end
      assert.is_true(found_selection, "Expected to find selection reference with line numbers")
    end)

    it("should handle single line selection", function()
      -- Open the test file
      vim.cmd("edit " .. test_file_path)

      -- Mock single line selection (line 3)
      vim.fn.setpos("'<", { 0, 3, 1, 0 })
      vim.fn.setpos("'>", { 0, 3, 1, 0 })

      -- Capture print output
      local captured_output = {}
      local original_print = print
      print = function(msg)
        table.insert(captured_output, msg)
        original_print(msg)
      end

      -- Execute send_selection
      local success = send_to_agent.send_selection()

      -- Restore print
      print = original_print

      -- Verify success
      assert.is_true(success)

      -- Check for single line reference
      local found_single_line = false
      for _, output in ipairs(captured_output) do
        if output:match("MOCK SEND:") and output:match("@.*%.lua#L3") and not output:match("L3%-") then
          found_single_line = true
          break
        end
      end
      assert.is_true(found_single_line, "Expected to find single line reference")
    end)
  end)

  describe("agent detection", function()
    it("should detect multiple agents and prioritize correctly", function()
      local agents = send_to_agent.detect_agent_panes()

      -- Should detect both claude and opencode
      assert.is_not_nil(agents)
      assert.is_true(#agents >= 2)

      -- Check agent types
      local found_claude = false
      local found_opencode = false
      for _, agent in ipairs(agents) do
        if agent.agent_type == "claude" then
          found_claude = true
        elseif agent.agent_type == "opencode" then
          found_opencode = true
        end
      end

      assert.is_true(found_claude, "Should detect claude agent")
      assert.is_true(found_opencode, "Should detect opencode agent")
    end)
  end)

  describe("utility functions", function()
    local utils = require("send-to-agent.utils")

    it("should create proper file references", function()
      local ref1 = utils.create_file_reference("/path/to/file.lua")
      assert.matches("@.*file%.lua$", ref1)

      local ref2 = utils.create_file_reference("/path/to/file.lua", 10, 20)
      assert.matches("@.*file%.lua#L10%-20$", ref2)

      local ref3 = utils.create_file_reference("/path/to/file.lua", 15, 15)
      assert.matches("@.*file%.lua#L15$", ref3)
    end)

    it("should escape special characters for tmux", function()
      local escaped = utils.escape_for_tmux("file 'with' quotes.lua")
      assert.is_not_nil(escaped)
      -- Should handle single quotes properly
      assert.matches("'\"'\"'", escaped)
    end)

    it("should handle visual selection ranges", function()
      -- Mock positions
      vim.fn.setpos("'<", { 0, 5, 1, 0 })
      vim.fn.setpos("'>", { 0, 10, 1, 0 })

      local start_line, end_line = utils.get_visual_selection_range()
      assert.are.equal(5, start_line)
      assert.are.equal(10, end_line)
    end)
  end)

  describe("configuration", function()
    it("should respect configuration options", function()
      send_to_agent.setup({
        formatting = {
          include_line_numbers = false,
        },
      })

      local utils = require("send-to-agent.utils")
      local ref = utils.create_file_reference("/path/to/file.lua", 10, 20)

      -- Should not include line numbers when disabled
      assert.matches("@.*file%.lua$", ref)
      assert.does_not_match("#L", ref)
    end)

    it("should handle custom agent patterns", function()
      send_to_agent.setup({
        agents = {
          patterns = { "custom-agent" },
        },
      })

      local config = send_to_agent.get_config()
      assert.are.same({ "custom-agent" }, config.agents.patterns)
    end)
  end)
end)