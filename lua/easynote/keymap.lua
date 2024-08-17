local EasyNoteKeymap = {}

require("easynote.interfaces")

--- Setup keymaps as defined in `config.mappings`
---@param opts EasyNoteConfiguration easynote configuration
function EasyNoteKeymap.setup(opts)
  local mappings = opts.mappings or {}

  for cmd, mapping in pairs(mappings) do
    vim.keymap.set("n", mapping, "<cmd>" .. cmd .. "<cr>", { desc = cmd })
  end
end

return EasyNoteKeymap
