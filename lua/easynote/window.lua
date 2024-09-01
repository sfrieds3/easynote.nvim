local EasyNoteWindow = {}

EasyNoteWindow.window_cmd_map = {
  WriteQuit = "<cmd>wq<cr>",
  Quit = "<cmd>q<cr>",
}

function EasyNoteWindow.get_float_fullscreen_opts()
  local win_config = require("easynote.config").window_opts

  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local rounded_width = vim.fn.round(win_width * win_config.width_pct / 100)
  local rounded_height = vim.fn.round(win_height * win_config.height_pct / 100)
  local row = (win_height - (win_height * (win_config.height_pct / 100))) / 2
  local col = (win_width - (win_width * (win_config.width_pct / 100))) / 2

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

  EasyNoteWindow.setup_keymap(require("easynote.config").window_mappings, EasyNoteWindow.window_cmd_map)
end

-- TODO: consolidate keymap settings into utils
--- Setup buffer keymaps for EasyNote floating window
---@param mappings table<string, string> configured foating window mappings
---@param cmd_map table<string, string> mapping of floating window commands to keymap commnads
---@param buffer boolean whether to setup buffer keymaps or global keymaps
function EasyNoteWindow.setup_keymap(mappings, cmd_map, buffer)
  mappings = mappings or require("easynote.config").window_mappings
  cmd_map = cmd_map or {}
  buffer = buffer or true

  for window_cmd, mapping in pairs(mappings) do
    local cmd = cmd_map[window_cmd] or window_cmd
    vim.keymap.set("n", mapping, cmd_map[window_cmd], { desc = "EasyNote:" .. mapping, buffer = buffer })
  end
end

return EasyNoteWindow
