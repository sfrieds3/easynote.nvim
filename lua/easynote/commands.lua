local EasyNoteCommands = {}

function EasyNoteCommands.setup()
  local function complete(arglead)
    return require("easynote").complete(arglead)
  end
  local function name(args)
    return args.args ~= "" and args.args or nil
  end

  vim.api.nvim_create_user_command("EasyNote", function(args)
    require("easynote").open({ name = name(args) })
  end, { desc = "Open notes, today's daily note or a named note in current window", nargs = "?", complete = complete })

  vim.api.nvim_create_user_command("EasyNoteL", function()
    require("easynote").open({ scope = "local" })
  end, { desc = "Open local project notes in current window" })

  vim.api.nvim_create_user_command("EasyNoteFloating", function(args)
    require("easynote").open({ floating = true, name = name(args) })
  end, {
    desc = "Toggle notes, or open today's daily note or a named note, in floating window",
    nargs = "?",
    complete = complete,
  })

  vim.api.nvim_create_user_command("EasyNoteFloatingL", function()
    require("easynote").open({ floating = true, scope = "local" })
  end, { desc = "Toggle local project notes in floating window" })

  vim.api.nvim_create_user_command("EasyNoteAdd", function(args)
    require("easynote").add({
      text = args.args,
      line1 = args.range > 0 and args.line1 or nil,
      line2 = args.range > 0 and args.line2 or nil,
    })
  end, { desc = "Add a quick note to today's daily note", nargs = "*", range = true })

  vim.api.nvim_create_user_command("EasyNoteOpenInObsidian", function()
    require("easynote").open_in_obsidian()
  end, { desc = "Open the current note in Obsidian" })

  vim.api.nvim_create_user_command("EasyNoteInvalidateDefault", function()
    require("easynote").invalidate_default_file()
  end, { desc = "Reset default notes file" })

  vim.api.nvim_create_user_command("EasyNoteInvalidateLocalDefault", function()
    require("easynote").invalidate_local_default_file()
  end, { desc = "Reset default local notes file for the current project" })
end

return EasyNoteCommands
