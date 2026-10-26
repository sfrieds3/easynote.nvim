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
    version = "*", -- latest release, drop this to track main
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
- `:EasyNoteAdd <text>` add a quick note to today's daily note (see [Vault mode](#vault-mode))
- `:EasyNoteOpenInObsidian` open the current note in Obsidian

Running a floating command while the float is open closes it again (writing any changes). Inside the float, `q` writes
and closes.

Notes files are picked with `vim.ui.select`, so if fzf-lua, telescope, snacks or similar replace `vim.ui.select`, their
picker is used. When there is only one notes file it is opened directly, and when there are none the first entry of
`notes_filenames` is created.

EasyNote remembers the default notes file for a given context (globally, and per project root) and saves it under
`stdpath("data")/easynote`, so you are only prompted the first time. To forget it, run `:EasyNoteInvalidateDefault` or
`:EasyNoteInvalidateLocalDefault`. Alternately, pass `{ default = false }` to `require("easynote").open` and EasyNote
will prompt to pick a notes file.

## Vault mode

Point `notes_dir` at an Obsidian vault and set `project_notes_dir` to keep one note per project inside it:

```lua
opts = {
  notes_dir = "~/vault",
  project_notes_dir = "Projects",
}
```

### Project notes

With `project_notes_dir` set, `:EasyNoteL` and `:EasyNoteFloatingL` open the project note for the current repository
instead of searching the repository for notes files. Notes are keyed by repository, not by path on disk: the
`origin` remote (see `git_remote`) is reduced to `owner/repo`, so ssh and https clones, every worktree, and checkouts
on different machines all open `~/vault/Projects/sfrieds3/asteroid.md`. New notes start with frontmatter:

```markdown
---
tags: [project]
repo: github.com/sfrieds3/asteroid
---
```

- If you clone through an SSH alias host (`github-work:owner/repo`), map it with
  `host_aliases = { ["github-work"] = "github.com" }`.
- `git config easynote.project some/name` picks the note for a repository explicitly.
- Repositories without a remote (and directories outside one) use `Projects/local/<dirname>.md`.

### Daily notes

`:EasyNote today` (or `:EasyNoteFloating today`) opens today's daily note. The folder, date format and template are
read from `.obsidian/daily-notes.json`, so it opens the same file Obsidian would. They can be overridden with
`daily_notes = { folder = "Daily", format = "YYYY-MM-DD", template = "Templates/Daily" }`. Templates fill in
`{{title}}`, `{{date}}`, `{{time}}`, `{{date:FORMAT}}` and `{{time:FORMAT}}`.

### Quick capture

`:EasyNoteAdd <text>` appends `- 14:32 text ([[sfrieds3/asteroid]])` to today's daily note, or to `capture_file`
(e.g. `"Inbox.md"`) if configured. Run it on a range or visual selection to also capture the `path:line` and the
selected code:

```lua
vim.keymap.set("x", "<leader>na", ":EasyNoteAdd ", { desc = "Capture selection" })
```

### Other commands

- `:EasyNote <name>` opens or creates `<notes_dir>/<name>.md`, with completion of existing notes. Characters
  Obsidian can't use in filenames or links are replaced with `-`.
- `:EasyNoteOpenInObsidian` opens the current note in the Obsidian app.
- The float runs `:checktime` when it opens, so it picks up changes made by a sync client.

Links, `gf`, backlinks and tags are left to [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim), which
works inside the EasyNote float.

## Configuration

```lua
{
  notes_dir = "~/wiki",
  notes_filenames = { "notes.md" },
  use_default_file = true, -- remember the picked file
  persist_defaults = true, -- save remembered files between sessions
  default_notes_scope = "global",
  dir_markers = { ".git" }, -- marks the project root for local notes
  project_notes_dir = nil, -- e.g. "Projects", enables project notes in notes_dir
  git_remote = "origin",
  host_aliases = {}, -- { ["ssh-alias"] = "github.com" }
  daily_notes = {}, -- overrides for .obsidian/daily-notes.json: folder, format, template
  capture_file = nil, -- e.g. "Inbox.md", default is today's daily note
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

Checks run in CI on every pull request:

- tests: `nvim --headless --clean -l tests/run.lua` (Neovim 0.10, stable and nightly)
- formatting: `stylua --check .`
- lint: `luacheck lua tests`
- types: `lua-language-server --check lua --configpath "$PWD/.luarc.json"` with `VIMRUNTIME` set

## Releases

A release is a semver tag on `main`; plugin managers (e.g. lazy.nvim with `version = "*"`) pick it up from git directly:

```sh
git tag -a v0.1.0 -m v0.1.0
git push origin v0.1.0
```

Tag a commit that is already green on `main`. To also publish a release page with notes from the merged pull requests,
run `gh release create v0.1.0 --generate-notes`.

Pull request titles are checked to follow [Conventional Commits](https://www.conventionalcommits.org) (`feat: ...`,
`fix: ...`, `feat!: ...` for breaking changes), which makes it easy to pick the next version: breaking changes bump the
major version (minor before 1.0), `feat` the minor and `fix` the patch.
