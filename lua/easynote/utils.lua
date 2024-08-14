local EasyNoteUtils = {}

local config = require("easynote.config")

--- Get the root directory of a filename, using `config.dir_markers`
---@param filename string filename to get root dir of
---@return string? root directory of filename
function EasyNoteUtils.get_root_dir(filename)
  return vim.fs.root(vim.fn.expand(filename), config.dir_markers)
end

return EasyNoteUtils
