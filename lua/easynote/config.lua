local EasyNoteConfig = {}

---@alias DefaultPickerOptions "fzf"
---@alias NotesScope "local" | "global"

---@class NotesConfiguration
---@field notes_dir string
---@field notes_filenames table[string]
---@field default_global_notes_file string|nil
---@field use_default_file boolean
---@field default_picker DefaultPickerOptions
---@field default_notes_scope NotesScope
---@field dir_markers table[string] list of strings which will be used to mark the project root
EasyNoteConfig.config = {
  notes_dir = "~/wiki",
  notes_filenames = { "notes.md" },
  default_file = nil,
  use_default_file = true,
  default_picker = "fzf",
  default_notes_scope = "global",
  dir_markers = { ".git" },
}

return EasyNoteConfig
