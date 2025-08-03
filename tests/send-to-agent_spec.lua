local send_to_agent = require("send-to-agent")

describe("send-to-agent.nvim", function()
  before_each(function()
    -- Reset configuration before each test
    send_to_agent.setup()
  end)

  describe("configuration", function()
    it("should have default configuration", function()
      local config = send_to_agent.get_config()
      
      assert.are.same({ "claude", "opencode", "gemini" }, config.agents.patterns)
      assert.are.same({ "claude", "opencode", "gemini" }, config.agents.priority_order)
      assert.is_true(config.tmux.auto_switch_pane)
      assert.is_true(config.formatting.relative_paths)
      assert.is_true(config.formatting.include_line_numbers)
    end)

    it("should merge user configuration", function()
      send_to_agent.setup({
        agents = {
          patterns = { "custom-agent" },
        },
        tmux = {
          auto_switch_pane = false,
        },
      })

      local config = send_to_agent.get_config()
      assert.are.same({ "custom-agent" }, config.agents.patterns)
      assert.is_false(config.tmux.auto_switch_pane)
      -- Should keep defaults for non-specified options
      assert.is_true(config.formatting.relative_paths)
    end)
  end)

  describe("utility functions", function()
    local utils = require("send-to-agent.utils")

    it("should create file reference without line numbers", function()
      local ref = utils.create_file_reference("/path/to/file.lua")
      assert.matches("@.*file%.lua$", ref)
    end)

    it("should create file reference with line numbers", function()
      local ref = utils.create_file_reference("/path/to/file.lua", 10, 20)
      assert.matches("@.*file%.lua#L10%-20$", ref)
    end)

    it("should create file reference with single line", function()
      local ref = utils.create_file_reference("/path/to/file.lua", 15, 15)
      assert.matches("@.*file%.lua#L15$", ref)
    end)

    it("should escape text for tmux", function()
      local escaped = utils.escape_for_tmux("file with 'quotes'.lua")
      assert.matches("file with '\"'\"'quotes'\"'\"'%.lua", escaped)
    end)
  end)

  describe("tmux integration", function()
    local tmux = require("send-to-agent.tmux")

    -- Mock tests would go here - for now just check module loads
    it("should load tmux module", function()
      assert.is_not_nil(tmux.detect_agent_panes)
      assert.is_not_nil(tmux.send_to_agent)
    end)
  end)
end)