local EasyNote = {}

local config = require("easynote.config")
local utils = require("easynote.utils")

---@class FilePromptOpts
---@field handler function
---@field handler_opts table[any]|nil

--- Prompt the user to pick a filename and do something with it
--- pass selected filename (along with opts.handler_opts) to opts.handler
--- currently works with fzf, should extend in the future to suppor telescope or native
---@param files table[string] list of files to provide user for prompt
---@param opts FilePromptOpts handler for filename
function EasyNote.prompt_and_open_file(files, opts)
  local handler = opts["handler"] or EasyNote.open_floating
  local handler_opts = opts["handler_opts"] or {}
  require("fzf-lua").fzf_exec(files, {
    actions = {
      ["default"] = function(selected)
        -- TODO: extract this logic into separate function
        if config["use_default_file"] then
          if handler_opts.scope == "local" then
            if handler_opts.root_dir then
              config.default_local_notes_files[handler_opts.root_dir] = selected
            end
          else
            config.default_global_notes_file = selected
          end
        end
        handler(selected, handler_opts)
      end,
    },
  })
end

--- Get a listing of notes files using config
---@param opts UserCmdOpts? opts passed by caller
---@return table[string] list of potential notes files
---@diagnostic disable-next-line: unused-local
function EasyNote.get_note_files(opts)
  opts = opts or {}
  local notes_scope = opts.scope or config.default_notes_scope
  local search_dir = notes_scope == "global" and config.notes_dir or utils.get_root_dir(vim.fn.expand("%s"))
  return vim.fs.find(config.notes_filenames, { limit = math.huge, scope = "file", path = vim.fn.expand(search_dir) })
end

--- Return default file, if applicable, else nil
---@param opts UserCmdOpts
---@return string? file
function EasyNote.get_default_file(opts)
  local scope = opts.scope or config.default_notes_scope
  local use_default = opts.default or config.use_default_file

  local file = nil
  if use_default then
    if scope == "global" then
      file = config.default_global_notes_file or nil
    else
      file = opts.root_dir and config.default_local_notes_files[opts.root_dir]
    end
  end

  return file
end

return EasyNote
