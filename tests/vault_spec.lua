local h = require("helpers")

local function project()
  return require("easynote.project")
end

return {
  {
    "parse_remote handles ssh, https and alias hosts",
    function()
      h.setup({ host_aliases = { ["github-work"] = "github.com" } })
      local cases = {
        ["git@github.com:sfrieds3/asteroid.git"] = { "github.com", "sfrieds3/asteroid" },
        ["https://github.com/sfrieds3/asteroid"] = { "github.com", "sfrieds3/asteroid" },
        ["https://github.com/sfrieds3/asteroid.git/"] = { "github.com", "sfrieds3/asteroid" },
        ["https://user:token@GitHub.com/sfrieds3/asteroid.git"] = { "github.com", "sfrieds3/asteroid" },
        ["ssh://git@github.com:22/sfrieds3/asteroid.git"] = { "github.com", "sfrieds3/asteroid" },
        ["github-work:sfrieds3/asteroid.git"] = { "github.com", "sfrieds3/asteroid" },
        ["git@gitlab.com:group/sub/repo.git"] = { "gitlab.com", "group/sub/repo" },
        ["/srv/git/repo.git"] = {},
        ["file:///srv/git/repo.git"] = {},
      }
      for url, expected in pairs(cases) do
        h.eq(expected, { project().parse_remote(url) }, url)
      end
    end,
  },
  {
    "sanitize_path makes Obsidian-safe names",
    function()
      h.eq("a-b/c-d", project().sanitize_path("a:b/c?d"))
      h.eq("x/y", project().sanitize_path("../x//y/"))
      h.eq("hidden", project().sanitize_path(".hidden"))
      h.eq("untitled", project().sanitize_path("/"))
    end,
  },
  {
    ":EasyNoteL opens the project note keyed by remote with frontmatter",
    function()
      local vault = h.tmpdir()
      local repo = h.tmpdir() .. "/checkout"
      h.git_init(repo, "git@github.com:sfrieds3/asteroid.git")
      h.write(repo .. "/main.lua")
      h.setup({ notes_dir = vault, project_notes_dir = "Projects" })
      vim.cmd.edit(repo .. "/main.lua")
      vim.cmd("EasyNoteL")
      local note = vault .. "/Projects/sfrieds3/asteroid.md"
      h.eq(note, vim.api.nvim_buf_get_name(0))
      h.eq(
        { "---", "tags: [project]", "repo: github.com/sfrieds3/asteroid", "---", "", "# asteroid", "" },
        h.read(note)
      )
    end,
  },
  {
    "different clones of the same repo share one note",
    function()
      local vault = h.tmpdir()
      local a = h.tmpdir() .. "/a"
      local b = h.tmpdir() .. "/b"
      h.git_init(a, "git@github.com:sfrieds3/asteroid.git")
      h.git_init(b, "https://github.com/sfrieds3/asteroid")
      h.setup({ notes_dir = vault, project_notes_dir = "Projects" })
      h.eq(project().note_path(a), project().note_path(b))
    end,
  },
  {
    "git config easynote.project and local fallback",
    function()
      local vault = h.tmpdir()
      local a = h.tmpdir() .. "/thing"
      local b = h.tmpdir() .. "/other"
      h.git_init(a)
      h.git_init(b)
      vim.system({ "git", "-C", b, "config", "easynote.project", "me/custom" }):wait()
      h.setup({ notes_dir = vault, project_notes_dir = "Projects" })
      h.eq(vault .. "/Projects/local/thing.md", project().note_path(a))
      h.eq(vault .. "/Projects/me/custom.md", project().note_path(b))
      h.eq({ "---", "tags: [project]", "---", "", "# thing", "" }, h.read(project().ensure_note(a)))
    end,
  },
  {
    "format_date supports moment tokens",
    function()
      local daily = require("easynote.daily")
      local t = os.time({ year = 2026, month = 3, day = 2, hour = 14, min = 5, sec = 9 })
      h.eq("2026-03-02", daily.format_date("YYYY-MM-DD", t))
      h.eq("2026/03/2026-03-02 Monday", daily.format_date("YYYY/MM/YYYY-MM-DD dddd", t))
      h.eq("2nd of March, 14:05:09 day", daily.format_date("Do [of] MMMM, HH:mm:ss [day]", t))
      h.eq("Q1 2:05 pm", daily.format_date("[Q]Q h:mm a", t))
    end,
  },
  {
    ":EasyNote today follows .obsidian/daily-notes.json and its template",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/.obsidian/daily-notes.json", {
        vim.json.encode({ folder = "Daily", format = "YYYY/YYYY-MM-DD", template = "Templates/Daily" }),
      })
      h.write(vault .. "/Templates/Daily.md", { "# {{title}}", "created {{date}} {{time}}", "{{date:dddd}}" })
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNote today")
      local name = os.date("%Y-%m-%d")
      local path = vault .. "/Daily/" .. os.date("%Y") .. "/" .. name .. ".md"
      h.eq(path, vim.api.nvim_buf_get_name(0))
      local lines = h.read(path)
      h.eq("# " .. name, lines[1])
      h.truthy(lines[2]:match("^created " .. vim.pesc(name) .. " %d%d:%d%d$"), lines[2])
      h.eq(os.date("%A"), lines[3])
    end,
  },
  {
    "daily_notes config overrides obsidian settings",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/.obsidian/daily-notes.json", { vim.json.encode({ folder = "Daily" }) })
      h.setup({ notes_dir = vault, daily_notes = { folder = "Journal", format = "YYYYMMDD" } })
      h.eq(vault .. "/Journal/" .. os.date("%Y%m%d") .. ".md", require("easynote.daily").path())
    end,
  },
  {
    ":EasyNoteAdd appends to the daily note with a project link",
    function()
      local vault = h.tmpdir()
      local repo = h.tmpdir() .. "/asteroid"
      h.git_init(repo, "git@github.com:sfrieds3/asteroid.git")
      h.write(repo .. "/main.lua", { "local x = 1", "", "return x" })
      h.setup({ notes_dir = vault, project_notes_dir = "Projects" })
      vim.cmd.edit(repo .. "/main.lua")
      vim.cmd("EasyNoteAdd fix the thing")
      vim.cmd("1,3EasyNoteAdd look")
      local lines = h.read(vault .. "/" .. os.date("%Y-%m-%d") .. ".md")
      h.truthy(lines[1]:match("^%- %d%d:%d%d fix the thing %(%[%[sfrieds3/asteroid%]%]%)$"), lines[1])
      h.truthy(lines[2]:match("^%- %d%d:%d%d look `main.lua:1%-3` %(%[%[sfrieds3/asteroid%]%]%)$"), lines[2])
      h.eq({ "  ```lua", "  local x = 1", "", "  return x", "  ```" }, vim.list_slice(lines, 3))
    end,
  },
  {
    ":EasyNoteAdd goes to capture_file and through a loaded buffer",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/Inbox.md", { "# Inbox" })
      h.setup({ notes_dir = vault, capture_file = "Inbox.md" })
      vim.cmd.edit(vault .. "/Inbox.md")
      vim.cmd("enew")
      vim.cmd("EasyNoteAdd hello")
      local lines = h.read(vault .. "/Inbox.md")
      h.eq("# Inbox", lines[1])
      h.truthy(lines[2]:match("^%- %d%d:%d%d hello$"), lines[2])
      h.eq(2, #lines)
    end,
  },
  {
    ":EasyNote <name> opens a sanitized named note and completes names",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/ideas/Big Plan.md")
      h.write(vault .. "/.obsidian/workspace.md")
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNote meeting: q3/plan?")
      h.eq(vault .. "/meeting- q3/plan-.md", vim.api.nvim_buf_get_name(0))
      h.eq({ "ideas/Big Plan" }, require("easynote").complete("id"))
      h.eq({ "today" }, require("easynote").complete("to"))
    end,
  },
  {
    "float runs checktime so external changes show up",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md", { "old" })
      h.setup({ notes_dir = vault })
      vim.cmd.edit(vault .. "/notes.md")
      vim.cmd("enew")
      vim.uv.sleep(1100)
      h.write(vault .. "/notes.md", { "new" })
      vim.cmd("EasyNoteFloating")
      h.eq({ "new" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end,
  },
  {
    ":EasyNoteOpenInObsidian opens an obsidian:// uri",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/a note.md")
      h.setup({ notes_dir = vault })
      local opened
      local open = vim.ui.open
      vim.ui.open = function(uri)
        opened = uri
      end
      vim.cmd.edit(vault .. "/a note.md")
      vim.cmd("EasyNoteOpenInObsidian")
      vim.ui.open = open
      h.eq("obsidian://open?path=" .. vim.uri_encode(vault .. "/a note.md", "rfc3986"):gsub("/", "%%2F"), opened)
    end,
  },
}
