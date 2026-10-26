local EasyNoteConfig = {}

require("easynote.interfaces")

---@alias NotesScope "local" | "global"

---@type EasyNoteConfiguration
local defaults = {
  notes_dir = "~/wiki",
  notes_filenames = { "notes.md" },
  use_default_file = true,
  persist_defaults = true,
  default_notes_scope = "global",
  dir_markers = { ".git" },
  project_notes_dir = nil,
  git_remote = "origin",
  host_aliases = {},
  daily_notes = {},
  capture_file = nil,
  ignore_dirs = { ".git", ".obsidian", ".trash", "node_modules" },
  create_user_commands = true,
  mappings = {
    EasyNote = "<leader>N",
    EasyNoteFloating = "<leader>n",
  },
  window_mappings = {
    WriteQuit = "q",
  },
  window_opts = {
    width_pct = 75,
    height_pct = 75,
    border = "rounded",
  },
}

local config = vim.deepcopy(defaults)

---Setup
---@param opts EasyNoteConfiguration? setup configuration
function EasyNoteConfig.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if config.create_user_commands then
    require("easynote.commands").setup()
  end

  require("easynote.keymap").setup(config)
end

--- Default configuration, mostly useful for tests
---@return EasyNoteConfiguration
function EasyNoteConfig.defaults()
  return vim.deepcopy(defaults)
end

--- Expanded, absolute path of `notes_dir`
---@return string
function EasyNoteConfig.notes_root()
  return vim.fs.normalize(vim.fn.fnamemodify(vim.fs.normalize(config.notes_dir), ":p"))
end

return setmetatable(EasyNoteConfig, {
  __index = function(_, key)
    return config[key]
  end,
})
