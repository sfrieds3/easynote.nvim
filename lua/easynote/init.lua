local EasyNote = {}

---@param opts EasyNoteConfiguration? user configuration
function EasyNote.setup(opts)
  require("easynote.config").setup(opts)
end

return setmetatable(EasyNote, {
  __index = function(_, key)
    return require("easynote.api")[key]
  end,
})
