local EasyNoteUtils = {}

local config = require("easynote.config")

--- Get the root directory of a buffer or filename, using `config.dir_markers`
--- Unnamed and special buffers are resolved from the current working directory.
---@param source (string|integer)? filename or buffer number, defaults to the current buffer
---@return string? root directory
function EasyNoteUtils.get_root_dir(source)
  source = source or 0
  if type(source) == "string" then
    source = source == "" and vim.fn.getcwd() or vim.fn.fnamemodify(source, ":p")
  end
  local root = vim.fs.root(source, config.dir_markers)
  return root and vim.fs.normalize(root) or nil
end

--- Whether a path exists and is a regular file
---@param path string
---@return boolean
function EasyNoteUtils.is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

return EasyNoteUtils
