local EasyNoteCommands = {}

function EasyNoteCommands.setup()
  vim.api.nvim_create_user_command("EasyNote", function()
    require("easynote").open()
  end, { desc = "Open notes in current window" })

  vim.api.nvim_create_user_command("EasyNoteL", function()
    require("easynote").open({ scope = "local" })
  end, { desc = "Open local project notes in current window" })

  vim.api.nvim_create_user_command("EasyNoteFloating", function()
    require("easynote").open({ floating = true })
  end, { desc = "Toggle notes in floating window" })

  vim.api.nvim_create_user_command("EasyNoteFloatingL", function()
    require("easynote").open({ floating = true, scope = "local" })
  end, { desc = "Toggle local project notes in floating window" })

  vim.api.nvim_create_user_command("EasyNoteInvalidateDefault", function()
    require("easynote").invalidate_default_file()
  end, { desc = "Reset default notes file" })

  vim.api.nvim_create_user_command("EasyNoteInvalidateLocalDefault", function()
    require("easynote").invalidate_local_default_file()
  end, { desc = "Reset default local notes file for the current project" })
end

return EasyNoteCommands
