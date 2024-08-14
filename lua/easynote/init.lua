FORCE_RELOAD = true
if FORCE_RELOAD then
  package.loaded["easynote"] = nil
end

local EasyNote = {}

local config = require("easynote.config")
local utils = require("easynote.utils")

EasyNote.force_reload = true

function EasyNote.setup()
  require("easynote.config").setup()
end

return setmetatable(EasyNote, {
  __index = function(_, key)
    return require("easynote.api")[key]
  end,
})
