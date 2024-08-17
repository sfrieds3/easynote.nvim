---@class EasyNoteDefaultLocalFile
---@field dir string
---@field notes_file string

---@class EasyNoteKeymapOpts
---@field command string
---@field mapping string

---@class EasyNoteConfiguration
---@field notes_dir string
---@field notes_filenames table[string]
---@field default_global_notes_file string?
---@field default_local_notes_files table[EasyNoteDefaultLocalFile?]
---@field use_default_file boolean
---@field default_picker DefaultPickerOptions
---@field default_notes_scope NotesScope
---@field dir_markers table[string] list of strings which will be used to mark the project root
---@field create_user_commands boolean
---@field mappings table[EasyNoteKeymapOpts?]

---@class UserCmdOpts
---@field scope NotesScope?
---@field root_dir string?
---@field floating boolean?
---@field default boolean?
