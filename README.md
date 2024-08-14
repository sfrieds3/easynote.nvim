# EasyNote

A no-frills plugin for quickly and easily taking notes and moving on with your life.

## Installation

lazy.nvim:

```lua
  {
    "sfrieds3/easynote.nvim",
    cmd = { "Notes", "NotesL", "NotesFloating", "NotesFloatingL" },
    opts = {
      -- configuration goes here
    },
  },
```

## Usage

The default configuration will create a few user commands:

- `:Notes` prompt and open note from configured global notes directory in current buffer
- `:NotesL` prompt and open note from local project notes directory in current buffer
- `:NotesFloating` prompt and open note from configured global notes directory in floating window
- `:NotesFloatingL` prompt and open note from local project notes directory in floating window

EasyNote will cache the default notes file for a given context. This means you will only be prompted to pick a notes file the first time running either `:Notes[L]` or `:NotesFloating[L]`. Any subsequent calls will automatically open this default file.

To invalidate this cache, run `:NotesInvalidateDefault`. Alternately, pass `{default = false}` to  `require("easynote").open` and EasyNote will prompt to pick a notes file.
