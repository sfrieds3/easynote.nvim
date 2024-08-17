local EasyNoteConfig = {}

require("easynote.interfaces")

---@alias DefaultPickerOptions "fzf"
---@alias NotesScope "local" | "global"

---@type EasyNoteDefaultLocalFile
local default_local_files = setmetatable({}, {
  __index = function(_, _)
    return nil -- TODO: do we want to do something more interesting here?
  end,
})

---@type EasyNoteConfiguration
local defaults = {
  notes_dir = "~/wiki",
  notes_filenames = { "notes.md" },
  default_global_notes_file = nil,
  default_local_notes_files = default_local_files,
  use_default_file = true,
  default_picker = "fzf",
  default_notes_scope = "global",
  dir_markers = { ".git" },
  create_user_commands = true,
  mappings = {
    Notes = "<leader>N",
    NotesFloating = "<leader>n",
  },
}

local config = {}

---Setup
---@param opts table? setup configuration
function EasyNoteConfig.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", defaults, opts)

  vim.keymap.set("n", "<leader>N", "<cmd>Notes<cr>", { desc = "Open Wiki Notes File" })
  vim.keymap.set("n", "<leader>n", "<cmd>NotesFloating<cr>", { desc = "Open Wiki Notes File" })

  if config.create_user_commands then
    require("easynote.commands").setup()
  end

  require("easynote.keymap").setup(config)
end

return setmetatable(EasyNoteConfig, {
  __index = function(_, key)
    config = config or EasyNoteConfig.setup()
    return config[key]
  end,
})
