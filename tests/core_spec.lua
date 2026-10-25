local h = require("helpers")

return {
  {
    "setup(opts) is applied",
    function()
      h.setup({ notes_dir = "/tmp/somewhere", window_opts = { width_pct = 50 } })
      local config = require("easynote.config")
      h.eq("/tmp/somewhere", config.notes_dir)
      h.eq(50, config.window_opts.width_pct)
      h.eq(75, config.window_opts.height_pct)
    end,
  },
  {
    "config has defaults before setup",
    function()
      h.eq("~/wiki", require("easynote.config").notes_dir)
    end,
  },
  {
    "setup does not map legacy :Notes commands",
    function()
      vim.g.mapleader = "\\"
      require("easynote").setup()
      h.eq("<Cmd>EasyNoteFloating<CR>", vim.fn.maparg("\\n", "n"))
      h.eq("<Cmd>EasyNote<CR>", vim.fn.maparg("\\N", "n"))
      for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
        h.truthy(not (map.rhs or ""):find("<Cmd>Notes"), map.rhs)
      end
    end,
  },
  {
    "finds notes files, skipping ignored dirs and directories with matching names",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md")
      h.write(vault .. "/a/notes.md")
      h.write(vault .. "/.obsidian/notes.md")
      h.write(vault .. "/.trash/notes.md")
      vim.fn.mkdir(vault .. "/b/notes.md", "p")
      h.setup({ notes_dir = vault })
      h.eq(
        { vault .. "/a/notes.md", vault .. "/notes.md" },
        require("easynote.file").get_note_files({ scope = "global" })
      )
    end,
  },
  {
    ":EasyNote picks with vim.ui.select and remembers the default",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md")
      h.write(vault .. "/work/notes.md")
      h.setup({ notes_dir = vault })
      local record = h.stub_select(function(items)
        return items[2]
      end)
      vim.cmd("EasyNote")
      h.eq(vault .. "/work/notes.md", vim.api.nvim_buf_get_name(0))
      h.eq(1, record.calls)

      vim.cmd("enew")
      vim.cmd("EasyNote")
      h.eq(1, record.calls, "default file should be reused")
      h.eq(vault .. "/work/notes.md", vim.api.nvim_buf_get_name(0))
    end,
  },
  {
    "default = false always prompts",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md")
      h.write(vault .. "/b/notes.md")
      h.setup({ notes_dir = vault })
      local record = h.stub_select()
      require("easynote").open()
      require("easynote").open({ default = false })
      h.eq(2, record.calls)
    end,
  },
  {
    "default files persist between sessions",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md")
      h.write(vault .. "/x/notes.md")
      h.setup({ notes_dir = vault })
      h.stub_select(function(items)
        return items[2]
      end)
      vim.cmd("EasyNote")
      local data_home = h.data_home

      h.reset()
      vim.env.XDG_DATA_HOME = data_home
      h.setup({ notes_dir = vault })
      local record = h.stub_select()
      vim.cmd("EasyNote")
      h.eq(0, record.calls)
      h.eq(vault .. "/x/notes.md", vim.api.nvim_buf_get_name(0))

      vim.cmd("EasyNoteInvalidateDefault")
      vim.cmd("EasyNote")
      h.eq(1, record.calls)
    end,
  },
  {
    ":EasyNoteL uses the project root of the current buffer",
    function()
      local repo = h.tmpdir()
      h.git_init(repo)
      h.write(repo .. "/src/main.lua")
      h.write(repo .. "/docs/notes.md")
      h.setup({ notes_dir = h.tmpdir() })
      h.stub_select()
      vim.cmd.edit(repo .. "/src/main.lua")
      vim.cmd("EasyNoteL")
      h.eq(repo .. "/docs/notes.md", vim.api.nvim_buf_get_name(0))
    end,
  },
  {
    ":EasyNoteL outside a project notifies instead of erroring",
    function()
      local dir = h.tmpdir()
      h.setup({ notes_dir = dir })
      vim.cmd.cd(dir)
      local msg
      local notify = vim.notify
      vim.notify = function(m)
        msg = m
      end
      vim.cmd("EasyNoteL")
      vim.notify = notify
      h.truthy(msg and msg:find("no project root"), msg)
    end,
  },
  {
    "creates the first notes file when none exist",
    function()
      local vault = h.tmpdir() .. "/new"
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNote")
      h.eq(vault .. "/notes.md", vim.api.nvim_buf_get_name(0))
    end,
  },
}
