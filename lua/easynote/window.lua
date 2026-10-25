local EasyNoteWindow = {}

---@type integer? the currently open EasyNote floating window
local float_winid = nil

EasyNoteWindow.window_cmd_map = {
  WriteQuit = function()
    EasyNoteWindow.close({ write = true })
  end,
  Quit = function()
    EasyNoteWindow.close()
  end,
}

--- Floating window config sized relative to the whole editor
---@return vim.api.keyset.win_config
function EasyNoteWindow.get_float_fullscreen_opts()
  local win_config = require("easynote.config").window_opts

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight
  local width = math.max(1, math.floor(editor_width * win_config.width_pct / 100))
  local height = math.max(1, math.floor(editor_height * win_config.height_pct / 100))

  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((editor_height - height) / 2),
    col = math.floor((editor_width - width) / 2),
    border = win_config.border or "rounded",
  }
end

--- Whether the EasyNote floating window is currently open
---@return boolean
function EasyNoteWindow.is_open()
  return float_winid ~= nil and vim.api.nvim_win_is_valid(float_winid)
end

--- Window id of the open floating window, if any
---@return integer?
function EasyNoteWindow.winid()
  return EasyNoteWindow.is_open() and float_winid or nil
end

--- Close the floating window
---@param opts { write: boolean? }?
function EasyNoteWindow.close(opts)
  opts = opts or {}
  if not EasyNoteWindow.is_open() then
    return
  end
  local winid = float_winid --[[@as integer]]
  if opts.write then
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.bo[bufnr].modified and vim.bo[bufnr].buftype == "" then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("silent update")
      end)
    end
  end
  vim.api.nvim_win_close(winid, false)
end

--- Open a floating window.. reserving the right to have this function do more
---@param file string file path to open in floating window
---@param opts table? currently unused, reserved for future use
---@diagnostic disable-next-line: unused-local
function EasyNoteWindow.open_floating(file, opts)
  if EasyNoteWindow.is_open() then
    vim.api.nvim_set_current_win(float_winid --[[@as integer]])
  else
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.bo[scratch].bufhidden = "wipe"
    float_winid = vim.api.nvim_open_win(scratch, true, EasyNoteWindow.get_float_fullscreen_opts())
    EasyNoteWindow.setup_autocmds(float_winid)
  end

  vim.cmd.edit({ args = { file }, magic = { file = false } })
  EasyNoteWindow.setup_keymap(vim.api.nvim_get_current_buf())
end

---@type table<integer, string[]> buffers that received window mappings, and the lhs set on each
local mapped_buffers = {}

local augroup = vim.api.nvim_create_augroup("EasyNoteWindow", { clear = true })

--- Keep window mappings on whatever buffer the float shows, and clean up when it closes
---@param winid integer
function EasyNoteWindow.setup_autocmds(winid)
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    callback = function(args)
      if vim.api.nvim_get_current_win() == winid then
        EasyNoteWindow.setup_keymap(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(winid),
    once = true,
    callback = function()
      EasyNoteWindow.clear_keymaps()
      vim.api.nvim_clear_autocmds({ group = augroup })
      float_winid = nil
    end,
  })
end

--- Setup buffer keymaps for EasyNote floating window
---@param bufnr integer buffer to set mappings on
---@param mappings table<string, string|false>? configured floating window mappings
---@param cmd_map table<string, string|function>? mapping of floating window commands to keymap rhs
function EasyNoteWindow.setup_keymap(bufnr, mappings, cmd_map)
  mappings = mappings or require("easynote.config").window_mappings or {}
  cmd_map = cmd_map or EasyNoteWindow.window_cmd_map

  if mapped_buffers[bufnr] then
    return
  end
  mapped_buffers[bufnr] = {}
  for window_cmd, lhs in pairs(mappings) do
    local rhs = cmd_map[window_cmd]
    if lhs and rhs then
      vim.keymap.set("n", lhs, function()
        -- the buffer may also be visible outside the float; behave like the plain key there
        if vim.api.nvim_get_current_win() ~= float_winid then
          vim.api.nvim_feedkeys(vim.keycode(lhs), "n", false)
        elseif type(rhs) == "function" then
          rhs()
        else
          vim.cmd(rhs)
        end
      end, { desc = "EasyNote: " .. window_cmd, buffer = bufnr })
      table.insert(mapped_buffers[bufnr], lhs)
    end
  end
end

--- Remove window mappings from every buffer that was shown in the float
function EasyNoteWindow.clear_keymaps()
  for bufnr, lhs_list in pairs(mapped_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      for _, lhs in ipairs(lhs_list) do
        pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
      end
    end
  end
  mapped_buffers = {}
end

return EasyNoteWindow
