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
  if opts.floating and window.is_open() and not opts.name then
    window.close({ write = true })
    return
  end

  local handler = opts.floating and window.open_floating or EasyNoteApi.edit

  if opts.name == "today" then
    handler(require("easynote.daily").ensure(), opts)
    return
  elseif opts.name then
    handler(EasyNoteApi.named_note_path(opts.name), opts)
    return
  end

  if opts.scope == "local" and config.project_notes_dir then
    local project = require("easynote.project")
    handler(project.ensure_note(opts.root_dir or project.current_root()), opts)
    return
  end

  opts.root_dir = opts.root_dir or utils.get_root_dir(0)
  if opts.scope == "local" and not opts.root_dir then
    vim.notify("easynote: no project root found (looked for " .. table.concat(config.dir_markers, ", ") .. ")")
    return
  end

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

--- Path of a named note under `notes_dir`, with Obsidian-safe file names
---@param name string note name, may contain `/` for subfolders
---@return string
function EasyNoteApi.named_note_path(name)
  name = vim.trim(name):gsub("%.md$", "")
  local path = vim.fs.joinpath(config.notes_root(), require("easynote.project").sanitize_path(name) .. ".md")
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  return path
end

--- Complete note names for `:EasyNote`
---@param arglead string
---@return string[]
function EasyNoteApi.complete(arglead)
  local root = config.notes_root()
  local names = { "today" }
  if vim.fn.isdirectory(root) == 1 then
    for name, type in
      vim.fs.dir(root, {
        depth = math.huge,
        skip = function(dir)
          return not vim.tbl_contains(config.ignore_dirs or {}, vim.fs.basename(dir))
        end,
      })
    do
      if type == "file" and name:match("%.md$") then
        table.insert(names, (name:gsub("%.md$", "")))
      end
    end
  end
  table.sort(names)
  return vim.tbl_filter(function(name)
    return vim.startswith(name:lower(), arglead:lower())
  end, names)
end

--- Capture a quick note into today's daily note (or `capture_file`)
---@param opts EasyNoteCaptureOpts
function EasyNoteApi.add(opts)
  return require("easynote.capture").add(opts or {})
end

--- Open the current note in the Obsidian app
function EasyNoteApi.open_in_obsidian()
  local name = vim.api.nvim_buf_get_name(0)
  local path = name ~= "" and (vim.uv.fs_realpath(name) or name) or nil
  local root = vim.uv.fs_realpath(config.notes_root()) or config.notes_root()
  if not path or not vim.startswith(path, root .. "/") then
    vim.notify("easynote: current buffer is not a note in " .. config.notes_dir, vim.log.levels.WARN)
    return
  end
  local encoded = path:gsub("[^%w%-%._~]", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
  vim.ui.open("obsidian://open?path=" .. encoded)
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
