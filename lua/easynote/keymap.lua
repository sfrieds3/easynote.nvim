local EasyNoteKeymap = {}

require("easynote.interfaces")

--- Setup keymaps as defined in `config.mappings`, a mapping set to `false` is skipped
---@param opts EasyNoteConfiguration easynote configuration
function EasyNoteKeymap.setup(opts)
  local mappings = opts.mappings or {}

  for cmd, mapping in pairs(mappings) do
    if mapping then
      vim.keymap.set("n", mapping, "<cmd>" .. cmd .. "<cr>", { desc = cmd })
    end
  end
end

return EasyNoteKeymap
