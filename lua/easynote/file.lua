local EasyNoteFile = {}

local config = require("easynote.config")
local state = require("easynote.state")
local utils = require("easynote.utils")

---@class FilePromptOpts
---@field handler fun(file: string, opts: table?)
---@field handler_opts UserCmdOpts?

--- Directory a scope searches for notes files
---@param opts UserCmdOpts
---@return string? dir
function EasyNoteFile.get_search_dir(opts)
  local scope = opts.scope or config.default_notes_scope
  if scope == "global" then
    return config.notes_root()
  end
  return opts.root_dir
end

--- Whether a directory should be skipped while searching
---@param dir string path relative to the search root
---@return boolean
local function is_ignored(dir)
  return vim.tbl_contains(config.ignore_dirs or {}, vim.fs.basename(dir))
end

--- Get a listing of notes files using config
---@param opts UserCmdOpts? opts passed by caller
---@return string[] list of potential notes files
function EasyNoteFile.get_note_files(opts)
  opts = opts or {}
  local search_dir = EasyNoteFile.get_search_dir(opts)
  if not search_dir or vim.fn.isdirectory(search_dir) == 0 then
    return {}
  end

  local files = {}
  for name, type in
    vim.fs.dir(search_dir, {
      depth = math.huge,
      skip = function(dir)
        return not is_ignored(dir)
      end,
    })
  do
    if type == "file" and vim.tbl_contains(config.notes_filenames, vim.fs.basename(name)) then
      table.insert(files, vim.fs.joinpath(search_dir, name))
    end
  end
  table.sort(files)
  return files
end

--- Prompt the user to pick a filename and pass it (along with opts.handler_opts) to opts.handler
--- Uses `vim.ui.select`, so whatever picker overrides it (fzf-lua, telescope, snacks, ...) is used.
---@param files string[] list of files to provide user for prompt
---@param opts FilePromptOpts handler for filename
function EasyNoteFile.prompt_and_open_file(files, opts)
  local handler_opts = opts.handler_opts or {}
  local search_dir = EasyNoteFile.get_search_dir(handler_opts)

  vim.ui.select(files, {
    prompt = "Notes file",
    format_item = function(item)
      if search_dir and vim.startswith(item, search_dir .. "/") then
        return item:sub(#search_dir + 2)
      end
      return item
    end,
  }, function(selected)
    if not selected then
      return
    end
    if EasyNoteFile.use_default(handler_opts) then
      state.set_default(handler_opts.scope or config.default_notes_scope, handler_opts.root_dir, selected)
    end
    opts.handler(selected, handler_opts)
  end)
end

--- Whether the remembered default file should be used and stored
---@param opts UserCmdOpts
---@return boolean
function EasyNoteFile.use_default(opts)
  if opts.default ~= nil then
    return opts.default
  end
  return config.use_default_file
end

--- Return default file, if applicable, else nil
---@param opts UserCmdOpts
---@return string? file
function EasyNoteFile.get_default_file(opts)
  if not EasyNoteFile.use_default(opts) then
    return nil
  end
  local file = state.get_default(opts.scope or config.default_notes_scope, opts.root_dir)
  if file and utils.is_file(file) then
    return file
  end
  return nil
end

--- Reset default notes file for a given scope
---@param scope NotesScope
---@param root_dir string? root dir to reset the local default file for
function EasyNoteFile.reset_default_file(scope, root_dir)
  state.set_default(scope, root_dir, nil)
end

return EasyNoteFile
