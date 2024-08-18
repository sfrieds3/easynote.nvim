local EasyNoteCommands = {}

function EasyNoteCommands.setup()
  vim.api.nvim_create_user_command("Notes", function()
    require("easynote").open()
  end, { desc = "Open notes in current split" })

  vim.api.nvim_create_user_command("NotesL", function()
    require("easynote").open({ scope = "local" })
  end, { desc = "Open local project notes in current split" })

  vim.api.nvim_create_user_command("NotesFloating", function()
    require("easynote").open({ floating = true })
  end, { desc = "Open notes in floating window" })

  vim.api.nvim_create_user_command("NotesFloatingL", function()
    require("easynote").open({ floating = true, scope = "local" })
  end, { desc = "Open local notes in floating window" })

  vim.api.nvim_create_user_command("NotesInvalidateDefault", function()
    require("easynote.config").default_file = nil
  end, { desc = "Reset default notes file" })
end

return EasyNoteCommands
