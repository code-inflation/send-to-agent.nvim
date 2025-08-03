local M = {}

---Check if tmux is available
---@return boolean
function M.is_tmux_available()
  local result = vim.system({ "which", "tmux" }, { capture = true }):wait()
  return result.code == 0
end

---Get relative path from git root, fallback to absolute path
---@param filepath string Absolute file path
---@return string Relative path from git root or absolute path
function M.get_relative_path(filepath)
  if not filepath then
    return ""
  end

  -- Ensure filepath is absolute
  local abs_filepath = vim.fn.fnamemodify(filepath, ":p")
  local dir_path = vim.fn.fnamemodify(abs_filepath, ":h")
  
  -- Check if directory exists before trying git command
  if vim.fn.isdirectory(dir_path) == 0 then
    return vim.fn.fnamemodify(filepath, ":t")
  end

  -- Try to get git root
  local git_result = vim.system({ "git", "rev-parse", "--show-toplevel" }, {
    cwd = dir_path,
    capture = true,
  }):wait()

  if git_result.code == 0 and git_result.stdout then
    local git_root = vim.trim(git_result.stdout)
    local relative = abs_filepath:sub(#git_root + 2) -- +2 to remove leading slash
    if relative and relative ~= "" then
      return relative
    end
  end

  -- Fallback to filename only
  return vim.fn.fnamemodify(filepath, ":t")
end

---Escape special characters in filename for tmux send-keys
---@param text string Text to escape
---@return string Escaped text
function M.escape_for_tmux(text)
  -- Escape single quotes for tmux send-keys
  return text:gsub("'", "'\"'\"'")
end

---Get visual selection line range
---@return number, number Start line, end line (1-indexed)
function M.get_visual_selection_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return start_pos[2], end_pos[2]
end

---Create file reference string
---@param filepath string File path
---@param start_line? number Start line number (1-indexed)
---@param end_line? number End line number (1-indexed)
---@return string File reference in @filename.ext#L1-5 format
function M.create_file_reference(filepath, start_line, end_line)
  local config = require("send-to-agent.config").get()
  local path = config.formatting.relative_paths and M.get_relative_path(filepath) or filepath

  if start_line and end_line and config.formatting.include_line_numbers then
    if start_line == end_line then
      return string.format("@%s#L%d", path, start_line)
    else
      return string.format("@%s#L%d-%d", path, start_line, end_line)
    end
  end

  return string.format("@%s", path)
end

---Show notification to user
---@param message string Message to display
---@param level? number Log level (vim.log.levels)
function M.notify(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(string.format("[send-to-agent] %s", message), level)
end

return M