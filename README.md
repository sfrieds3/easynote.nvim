# EasyNote

A no-frills plugin for quickly and easily taking notes and moving on with your life.

Requires Neovim 0.10+.

## Installation

lazy.nvim:

```lua
  {
    "sfrieds3/easynote.nvim",
    cmd = { "EasyNote", "EasyNoteL", "EasyNoteFloating", "EasyNoteFloatingL" },
    keys = { "<leader>n", "<leader>N" },
    opts = {
      -- configuration goes here
    },
  },
```

## Usage

The default configuration will create a few user commands:

- `:EasyNote` prompt and open note from configured global notes directory in current window
- `:EasyNoteL` prompt and open note from local project notes directory in current window
- `:EasyNoteFloating` prompt and open note from configured global notes directory in floating window
- `:EasyNoteFloatingL` prompt and open note from local project notes directory in floating window

Running a floating command while the float is open closes it again (writing any changes). Inside the float, `q` writes
and closes.

Notes files are picked with `vim.ui.select`, so if fzf-lua, telescope, snacks or similar replace `vim.ui.select`, their
picker is used. When there is only one notes file it is opened directly, and when there are none the first entry of
`notes_filenames` is created.

EasyNote remembers the default notes file for a given context (globally, and per project root) and saves it under
`stdpath("data")/easynote`, so you are only prompted the first time. To forget it, run `:EasyNoteInvalidateDefault` or
`:EasyNoteInvalidateLocalDefault`. Alternately, pass `{ default = false }` to `require("easynote").open` and EasyNote
will prompt to pick a notes file.

## Configuration

```lua
{
  notes_dir = "~/wiki",
  notes_filenames = { "notes.md" },
  use_default_file = true, -- remember the picked file
  persist_defaults = true, -- save remembered files between sessions
  default_notes_scope = "global",
  dir_markers = { ".git" }, -- marks the project root for local notes
  ignore_dirs = { ".git", ".obsidian", ".trash", "node_modules" },
  create_user_commands = true,
  mappings = { -- set a mapping to false to disable it
    EasyNote = "<leader>N",
    EasyNoteFloating = "<leader>n",
  },
  window_mappings = { -- WriteQuit or Quit
    WriteQuit = "q",
  },
  window_opts = {
    width_pct = 75, -- percent of the editor
    height_pct = 75,
    border = "rounded",
  },
}
```

## Development

Run the tests with `nvim --headless --clean -l tests/run.lua`.
