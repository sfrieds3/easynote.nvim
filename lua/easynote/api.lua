local EasyNoteApi = {}

require("easynote.interfaces")

local config = require("easynote.config")
local file = require("easynote.file")
local window = require("easynote.window")
local utils = require("easynote.utils")

--- Open a file in the current window
---@param path string
function EasyNoteApi.edit(path)
  vim.cmd.edit({ args = { path }, magic = { file = false } })
end

--- Open notes
---@param opts UserCmdOpts? opts to configure notes
function EasyNoteApi.open(opts)
  opts = vim.deepcopy(opts or {})
  opts.scope = opts.scope or config.default_notes_scope

  -- the open key closes the float again instead of stacking another one on top
  if opts.floating and window.is_open() then
    window.close({ write = true })
    return
  end

  opts.root_dir = opts.root_dir or utils.get_root_dir(0)
  if opts.scope == "local" and not opts.root_dir then
    vim.notify("easynote: no project root found (looked for " .. table.concat(config.dir_markers, ", ") .. ")")
    return
  end

  local handler = opts.floating and window.open_floating or EasyNoteApi.edit

  local default_file = file.get_default_file(opts)
  if default_file then
    handler(default_file, opts)
    return
  end

  local files = file.get_note_files(opts)
  if #files == 0 then
    local search_dir = file.get_search_dir(opts) --[[@as string]]
    local new_file = vim.fs.joinpath(search_dir, config.notes_filenames[1])
    vim.fn.mkdir(search_dir, "p")
    if file.use_default(opts) then
      require("easynote.state").set_default(opts.scope, opts.root_dir, new_file)
    end
    handler(new_file, opts)
    return
  end

  if #files == 1 then
    if file.use_default(opts) then
      require("easynote.state").set_default(opts.scope, opts.root_dir, files[1])
    end
    handler(files[1], opts)
    return
  end

  file.prompt_and_open_file(files, { handler = handler, handler_opts = opts })
end

--- Invalidate the global default file
function EasyNoteApi.invalidate_default_file()
  file.reset_default_file("global")
end

--- Invalidate the local default file
---@param root_dir? string optional root dir to invalidate
function EasyNoteApi.invalidate_local_default_file(root_dir)
  root_dir = root_dir or utils.get_root_dir(0)
  if root_dir then
    file.reset_default_file("local", root_dir)
  end
end

--- Close the floating notes window, if open
function EasyNoteApi.close()
  window.close({ write = true })
end

return EasyNoteApi
