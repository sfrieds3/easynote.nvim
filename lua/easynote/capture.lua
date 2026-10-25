local EasyNoteCapture = {}

local config = require("easynote.config")
local utils = require("easynote.utils")

---@class EasyNoteCaptureOpts
---@field text string? text of the entry
---@field line1 integer? first line of a range of the current buffer to include
---@field line2 integer? last line of the range
---@field time integer? defaults to now

--- File captures are appended to: `capture_file` if configured, else today's daily note
---@param time integer?
---@return string
function EasyNoteCapture.target(time)
  if config.capture_file then
    local path = vim.fs.joinpath(config.notes_root(), config.capture_file)
    if not utils.is_file(path) then
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      vim.fn.writefile({}, path)
    end
    return path
  end
  return require("easynote.daily").ensure(time)
end

--- Find a loaded buffer for a file
---@param path string
---@return integer?
local function loaded_buffer(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr)) == path then
      return bufnr
    end
  end
end

--- Append lines to a file, going through its buffer when it is loaded
---@param path string
---@param lines string[]
function EasyNoteCapture.append(path, lines)
  path = vim.fs.normalize(path)
  local bufnr = loaded_buffer(path)
  if bufnr then
    local was_modified = vim.bo[bufnr].modified
    local existing = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #existing == 1 and existing[1] == "" then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    else
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
    end
    if not was_modified then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("silent write")
      end)
    end
    return
  end

  local existing = utils.is_file(path) and vim.fn.readfile(path) or {}
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(vim.list_extend(existing, lines), path)
end

--- Build the lines of a capture entry
---@param opts EasyNoteCaptureOpts
---@return string[]
function EasyNoteCapture.entry(opts)
  local root = utils.get_root_dir(0)
  local parts = {
    "-",
    os.date("%H:%M", opts.time) --[[@as string]],
  }

  local text = vim.trim(opts.text or "")
  if text ~= "" then
    table.insert(parts, text)
  end

  local code = nil
  local bufname = vim.api.nvim_buf_get_name(0)
  if opts.line1 and bufname ~= "" then
    local path = vim.fs.normalize(bufname)
    if root and vim.startswith(path, root .. "/") then
      path = path:sub(#root + 2)
    else
      path = vim.fn.fnamemodify(path, ":~")
    end
    local line1 = opts.line1 --[[@as integer]]
    local line2 = opts.line2 or line1
    local location = path .. ":" .. line1 .. (line2 ~= line1 and ("-" .. line2) or "")
    table.insert(parts, "`" .. location .. "`")
    code = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  end

  if root and config.project_notes_dir then
    table.insert(parts, "([[" .. require("easynote.project").info(root).id .. "]])")
  end

  local lines = { table.concat(parts, " ") }
  if code then
    table.insert(lines, "  ```" .. vim.bo.filetype)
    for _, line in ipairs(code) do
      table.insert(lines, line == "" and "" or ("  " .. line))
    end
    table.insert(lines, "  ```")
  end
  return lines
end

--- Capture a quick note
---@param opts EasyNoteCaptureOpts
---@return string path the file the entry was added to
function EasyNoteCapture.add(opts)
  local lines = EasyNoteCapture.entry(opts)
  local path = EasyNoteCapture.target(opts.time)
  EasyNoteCapture.append(path, lines)
  vim.notify("easynote: added to " .. vim.fn.fnamemodify(path, ":t:r"))
  return path
end

return EasyNoteCapture
