local EasyNoteState = {}

local config = require("easynote.config")

---@class EasyNoteDefaults
---@field global string?
---@field local_files table<string, string>

---@type EasyNoteDefaults?
local defaults = nil

--- Path of the file default notes files are persisted to
---@return string
function EasyNoteState.path()
  return vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "easynote", "defaults.json")
end

---@return EasyNoteDefaults
local function load()
  if defaults then
    return defaults
  end
  defaults = { global = nil, local_files = {} }
  if not config.persist_defaults then
    return defaults
  end

  local ok, lines = pcall(vim.fn.readfile, EasyNoteState.path())
  if ok and #lines > 0 then
    local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if decoded_ok and type(decoded) == "table" then
      defaults.global = type(decoded.global) == "string" and decoded.global or nil
      defaults.local_files = type(decoded.local_files) == "table" and decoded.local_files or {}
    end
  end
  return defaults
end

local function save()
  if not config.persist_defaults then
    return
  end
  local path = EasyNoteState.path()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local data = load()
  local encoded = vim.json.encode({
    global = data.global,
    -- keep an empty map an object rather than an array
    local_files = next(data.local_files) and data.local_files or vim.empty_dict(),
  })
  local ok, err = pcall(vim.fn.writefile, { encoded }, path)
  if not ok then
    vim.notify("easynote: failed to save default notes files: " .. tostring(err), vim.log.levels.WARN)
  end
end

--- Get the default notes file for a scope
---@param scope NotesScope
---@param root_dir string? project root, required for local scope
---@return string?
function EasyNoteState.get_default(scope, root_dir)
  local data = load()
  if scope == "global" then
    return data.global
  end
  return root_dir and data.local_files[root_dir] or nil
end

--- Set (or clear, when `file` is nil) the default notes file for a scope
---@param scope NotesScope
---@param root_dir string? project root, required for local scope
---@param file string?
function EasyNoteState.set_default(scope, root_dir, file)
  local data = load()
  if scope == "global" then
    data.global = file
  elseif root_dir then
    data.local_files[root_dir] = file
  else
    return
  end
  save()
end

--- Forget in-memory state so the next access reloads from disk
function EasyNoteState.reset_cache()
  defaults = nil
end

return EasyNoteState
