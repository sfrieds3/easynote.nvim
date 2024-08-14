local EasyNoteWindow = {}

function EasyNoteWindow.get_float_fullscreen_opts()
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local rounded_width = vim.fn.round(win_width * 0.75)
  local rounded_height = vim.fn.round(win_height * 0.75)
  local row = (win_height - (win_height * 0.75)) / 2
  local col = (win_width - (win_width * 0.75)) / 2

  return {
    relative = "win",
    width = rounded_width,
    height = rounded_height,
    row = row,
    col = col,
    border = "rounded",
  }
end

--- Open a floating window.. reserving the right to have this function do more
---@param file string file path to open in floating window
---@param opts table|nil currently unused, reserved for future use
function EasyNoteWindow.open_floating(file, opts)
  ---@diagnostic disable-next-line: unused-local, redefined-local
  local opts = opts or {}
  ---@diagnostic disable-next-line: unused-local
  local original_winid = vim.api.nvim_get_current_win()
  local win_opts = EasyNoteWindow.get_float_fullscreen_opts()
  local bufnr = vim.api.nvim_create_buf(false, false)
  ---@diagnostic disable-next-line: unused-local
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)
  vim.bo[bufnr].bufhidden = "wipe"

  vim.cmd.edit({ args = file })
end

return EasyNoteWindow
