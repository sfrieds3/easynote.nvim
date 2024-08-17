local EasyNoteApi = {}

require("easynote.interfaces")

local file = require("easynote.file")
local window = require("easynote.window")
local utils = require("easynote.utils")

--- Open notes
---@param opts UserCmdOpts opts to configure notes
function EasyNoteApi.open(opts)
  opts = opts or {}
  local floating = opts.floating or false
  ---@type NotesScope
  local notes_scope = opts.scope or "global"
  opts["root_dir"] = utils.get_root_dir(vim.fn.expand("%"))

  -- TODO: is this too tightly coupled to the user command?
  local default_file = file.get_default_file(opts)

  if floating then
    if not default_file then
      file.prompt_and_open_file(file.get_note_files(opts), { handler = window.open_floating, handler_opts = opts })
    else
      window.open_floating(default_file)
    end
  else
    -- FIXME: use `Notes.prompt_for_file` instead of default fzf stuff
    -- this (obviously) is not storing the default file
    require("fzf-lua").fzf_exec(
      file.get_note_files(),
      { actions = {
        ["default"] = require("fzf-lua").actions.file_edit,
      } }
    )
  end
end

return EasyNoteApi
