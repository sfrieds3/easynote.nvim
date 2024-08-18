# EasyNote

A no-frills plugin for quickly and easily taking notes and moving on with your life.

## Installation

lazy.nvim:

```lua
  {
    "sfrieds3/easynote.nvim",
    cmd = { "EasyNote", "EasyNoteL", "EasyNoteFloating", "EasyNoteFloatingL" },
    opts = {
      -- configuration goes here
    },
  },
```

## Usage

The default configuration will create a few user commands:

- `:EasyNote` prompt and open note from configured global notes directory in current buffer
- `:EasyNoteL` prompt and open note from local project notes directory in current buffer
- `:EasyNoteFloating` prompt and open note from configured global notes directory in floating window
- `:EasyNoteFloatingL` prompt and open note from local project notes directory in floating window

EasyNote will cache the default notes file for a given context. This means you will only be prompted to pick a notes file the first time running either `:EasyNote[L]` or `:EasyNoteFloating[L]`. Any subsequent calls will automatically open this default file.

To invalidate this cache, run `:EasyNoteInvalidateDefault`. Alternately, pass `{default = false}` to  `require("easynote").open` and EasyNote will prompt to pick a notes file.
