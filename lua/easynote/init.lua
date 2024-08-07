FORCE_RELOAD = true
if FORCE_RELOAD then
  package.loaded["easynote"] = nil
end

local Notes = {}

local config = require("easynote.config").config

Notes.force_reload = true
Notes.is_configured = false

function Notes.get_float_fullscreen_opts()
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

--- Setup
---@param opts table setup configuration
function Notes.setup(opts)
  vim.tbl_deep_extend("force", config, opts)

  vim.keymap.set("n", "<leader>N", "<cmd>Notes<cr>", { desc = "Open Wiki Notes File" })
  vim.keymap.set("n", "<leader>n", "<cmd>NotesFloating<cr>", { desc = "Open Wiki Notes File" })
  Notes.is_configured = true
end

--- Open a floating window.. reserving the right to have this function do more
---@param file string file path to open in floating window
---@param opts table|nil currently unused, reserved for future use
function Notes.open_floating(file, opts)
  ---@diagnostic disable-next-line: unused-local, redefined-local
  local opts = opts or {}
  ---@diagnostic disable-next-line: unused-local
  local original_winid = vim.api.nvim_get_current_win()
  local win_opts = Notes.get_float_fullscreen_opts()
  local bufnr = vim.api.nvim_create_buf(false, false)
  ---@diagnostic disable-next-line: unused-local
  local winid = vim.api.nvim_open_win(bufnr, true, win_opts)
  vim.bo[bufnr].bufhidden = "wipe"

  vim.cmd.edit({ args = file })
end

---@class FilePromptOpts
---@field handler function
---@field handler_opts table[any]|nil

--- Prompt the user to pick a filename and do something with it
--- pass selected filename (along with opts.handler_opts) to opts.handler
--- currently works with fzf, should extend in the future to suppor telescope or native
---@param files table[string] list of files to provide user for prompt
---@param opts FilePromptOpts handler for filename
function Notes.prompt_and_open_file(files, opts)
  local handler = opts["handler"] or Notes.open_floating
  local handler_opts = opts["handler_opts"] or {}
  require("fzf-lua").fzf_exec(files, {
    actions = {
      ["default"] = function(selected)
        if config["use_default_file"] then
          -- TODO: we need to store this based on if it is a local or global note
          config.default_global_notes_file = selected
        end
        handler(selected, handler_opts)
      end,
    },
  })
end

--- Get the root directory of a filename, using `config.dir_markers`
---@param filename string filename to get root dir of
---@return string? root directory of filename
function Notes.get_root_dir(filename)
  return vim.fs.root(vim.fn.expand(filename), config.dir_markers)
end

---@class GetNotesOpts
---@field scope NotesScope?

--- Get a listing of notes files using config
---@param opts GetNotesOpts? opts passed by caller
---@return table[string] list of potential notes files
---@diagnostic disable-next-line: unused-local
function Notes.get_note_files(opts)
  opts = opts or {}
  local notes_scope = opts.scope or config.default_notes_scope
  local search_dir = notes_scope == "global" and config.notes_dir or Notes.get_root_dir(vim.fn.expand("%s"))
  return vim.fs.find(config.notes_filenames, { limit = math.huge, scope = "file", path = vim.fn.expand(search_dir) })
end

--- Return default file, if applicable, else nil
---@param opts UserCmdOpts
---@return string? file
function Notes.get_default_file(opts)
  local scope = opts.scope or config.default_notes_scope
  local use_default = opts.use_default or config.use_default_file

  local file = nil
  if use_default then
    if scope == "global" then
      file = config.default_global_notes_file or nil
    else
      -- FIXME: placeholder.. this should really pull the default file for local scope
      file = config.default_global_notes_file or nil
    end
  end

  return file
end

---@class UserCmdOpts
---@field scope NotesScope?
---@field floating boolean?
---@field use_default boolean?

--- Open notes
---@param opts UserCmdOpts opts to configure notes
function Notes.open(opts)
  opts = opts or {}
  local floating = opts.floating or false

  ---@type NotesScope
  local notes_scope = opts.scope or "global"

  local file = Notes.get_default_file(opts)

  if floating then
    if not file then
      Notes.prompt_and_open_file(
        Notes.get_note_files({ scope = notes_scope }),
        { handler = Notes.open_floating, handler_opts = {} }
      )
    else
      Notes.open_floating(file)
    end
  else
    -- TODO: use `Notes.prompt_for_file` instead of default fzf stuff
    require("fzf-lua").fzf_exec(
      Notes.get_note_files(),
      { actions = {
        ["default"] = require("fzf-lua").actions.file_edit,
      } }
    )
  end
end

vim.api.nvim_create_user_command("Notes", function()
  require("easynote").open()
end, { desc = "Open notes in current split" })

vim.api.nvim_create_user_command("NotesL", function()
  require("easynote").open({ scope = "local" })
end, { desc = "Open local project notes in current split" })

vim.api.nvim_create_user_command("NotesFloating", function()
  require("easynote").open({ floating = true })
end, { desc = "Open notes in floating window" })

vim.api.nvim_create_user_command("NotesFloatingL", function()
  require("easynote").open({ floating = true, scope = "local" })
end, { desc = "Open local notes in floating window" })

vim.api.nvim_create_user_command("NotesInvalidateDefault", function()
  require("easynote").config.default_file = nil
end, { desc = "Reset default notes file" })

if not Notes.is_configured or Notes.force_reload then
  Notes.setup({})
end

return Notes
