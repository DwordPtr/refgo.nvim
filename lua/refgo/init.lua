local M = {}

local notify_fn = vim.notify_once or vim.notify

-- Copies the current line reference to the selection registers (* and +)
M.copy = function()
  local fp = vim.fn.expand("%")
  local cwd = vim.fn.getcwd()
  local relpath = string.gsub(fp, cwd .. "/", "")

  local winid = vim.api.nvim_get_current_win()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(winid))
  local ref = string.format("%s:%d", relpath, row)
  vim.fn.setreg("*", ref)
  vim.fn.setreg("+", ref)
  notify_fn(string.format("Copied '%s' to clipboard", ref), vim.log.levels.INFO)
end

-- Copies the current line reference and the lines of codes surrounding the cursor,
-- to the selection registers (* and +)
M.copy_with_context = function(n)
  if n == nil or n == "" then
    n = 1
  end

  local fp = vim.fn.expand("%")
  local cwd = vim.fn.getcwd()
  local relpath = string.gsub(fp, cwd .. "/", "")

  local winid = vim.api.nvim_get_current_win()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(winid))
  local ref = string.format("%s:%d", relpath, row)

  local from = row - n - 1
  local to = row + n
  local lines = vim.api.nvim_buf_get_lines(0, from, to, false)
  local fullContext = ref .. "\n---\n" .. table.concat(lines, "\n")
  vim.fn.setreg("*", fullContext)
  vim.fn.setreg("+", fullContext)
  notify_fn(string.format("Copied '%s' to clipboard, along with %d lines", ref, #lines), vim.log.levels.INFO)
end

-- Opens the provided reference. If no reference is passed down, the selection
-- register will be used as the default reference value.
M.open = function(reference)
  if reference == nil or reference == "" then
    reference = vim.fn.getreg("*", 1)
  end

  local match = string.gmatch(reference, "(.+):(%d+)")
  local path, line = match()
  if path == nil then
    notify_fn(string.format("Could not parse '%s' as '<file path>:<line no>'", reference), vim.log.levels.WARN)
    return
  end
  vim.cmd(":e " .. path)
  vim.cmd(":" .. line)
end

M.open_below_cursor = function()
  local token_below_cursor = get_current_token()
  M.open(token_below_cursor)
end

local function get_current_token()
  -- 1. Get the current cursor position (row, col)
  local row, col = unpack(vim.fn.getpos('.')[1:2])  -- Note: getpos() returns a list

  -- 2. Get the current line
  local line = vim.fn.getline(row)

  -- 3. Find the token under the cursor
  local start_col, end_col = find_token_boundaries(line, col)

  if start_col and end_col then
    return string.sub(line, start_col, end_col)
  else
    return nil -- No token found under the cursor
  end
end

local function find_token_boundaries(line, col)
  -- This function defines what a "token" is.  You'll likely need to customize this.
  -- Here's a simple example that considers tokens to be separated by whitespace.

  -- Find the start of the token
  local start_col = col
  while start_col > 1 and string.sub(line, start_col - 1, start_col - 1):match("%s") == "" do
    start_col = start_col - 1
  end

  -- Find the end of the token
  local end_col = col
  while end_col <= string.len(line) and string.sub(line, end_col, end_col):match("%s") == "" do
    end_col = end_col + 1
  end

  -- Adjust end_col to be inclusive
  end_col = end_col -1

  -- Check if the cursor is actually within the token boundaries
  if col >= start_col and col <= end_col then
    return start_col, end_col
  else
    return nil, nil
  end
end

return M
