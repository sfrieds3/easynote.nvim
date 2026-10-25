local EasyNoteDaily = {}

local config = require("easynote.config")
local utils = require("easynote.utils")

---@class EasyNoteDailySettings
---@field folder string folder relative to `notes_dir`
---@field format string moment.js style date format, may contain `/` for subfolders
---@field template string? template path relative to `notes_dir`

local function ordinal(n)
  local last_two = n % 100
  if last_two >= 11 and last_two <= 13 then
    return n .. "th"
  end
  return n .. (({ "st", "nd", "rd" })[n % 10] or "th")
end

local function strip_zero(value)
  return tostring(tonumber(value))
end

--- moment.js tokens mapped to strftime, longest first so e.g. `MMMM` wins over `MM`
---@type { [1]: string, [2]: string, [3]: (fun(value: string): string)? }[]
local tokens = {
  { "YYYY", "%Y" },
  { "YY", "%y" },
  { "MMMM", "%B" },
  { "MMM", "%b" },
  { "MM", "%m" },
  { "M", "%m", strip_zero },
  { "DDDD", "%j" },
  { "DDD", "%j", strip_zero },
  {
    "Do",
    "%d",
    function(value)
      return ordinal(tonumber(value))
    end,
  },
  { "DD", "%d" },
  { "D", "%d", strip_zero },
  { "dddd", "%A" },
  { "ddd", "%a" },
  {
    "dd",
    "%a",
    function(value)
      return value:sub(1, 2)
    end,
  },
  { "d", "%w" },
  { "GGGG", "%G" },
  { "gggg", "%G" },
  { "WW", "%V" },
  { "ww", "%V" },
  { "W", "%V", strip_zero },
  { "w", "%V", strip_zero },
  {
    "Q",
    "%m",
    function(value)
      return tostring(math.floor((tonumber(value) - 1) / 3) + 1)
    end,
  },
  { "HH", "%H" },
  { "H", "%H", strip_zero },
  { "hh", "%I" },
  { "h", "%I", strip_zero },
  { "mm", "%M" },
  { "m", "%M", strip_zero },
  { "ss", "%S" },
  { "s", "%S", strip_zero },
  { "A", "%p" },
  { "a", "%p", string.lower },
}

--- Format a time using a moment.js format string, the format Obsidian uses
---@param format string
---@param time integer? defaults to now
---@return string
function EasyNoteDaily.format_date(format, time)
  time = time or os.time()
  local out = {}
  local i = 1
  while i <= #format do
    local close = format:sub(i, i) == "[" and format:find("]", i + 1, true)
    local token = not close
      and vim.iter(tokens):find(function(candidate)
        return format:sub(i, i + #candidate[1] - 1) == candidate[1]
      end)
    if close then
      table.insert(out, format:sub(i + 1, close - 1))
      i = close + 1
    elseif token then
      local value = os.date(token[2], time) --[[@as string]]
      table.insert(out, token[3] and token[3](value) or value)
      i = i + #token[1]
    else
      table.insert(out, format:sub(i, i))
      i = i + 1
    end
  end
  return table.concat(out)
end

--- Read a JSON file from the vault's `.obsidian` directory
---@param name string
---@return table
local function read_obsidian_json(name)
  local path = vim.fs.joinpath(config.notes_root(), ".obsidian", name)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(decoded) == "table" and decoded or {}
end

--- Non-empty string or nil
local function nonempty(value)
  return type(value) == "string" and value ~= "" and value or nil
end

--- Daily note settings: defaults, overridden by `.obsidian/daily-notes.json`, overridden by `config.daily_notes`
---@return EasyNoteDailySettings
function EasyNoteDaily.settings()
  local obsidian = read_obsidian_json("daily-notes.json")
  local user = config.daily_notes or {}
  return {
    folder = user.folder or nonempty(obsidian.folder) or "",
    format = user.format or nonempty(obsidian.format) or "YYYY-MM-DD",
    template = user.template or nonempty(obsidian.template),
  }
end

--- Path of the daily note for a given time
---@param time integer? defaults to now
---@return string
function EasyNoteDaily.path(time)
  local settings = EasyNoteDaily.settings()
  local name = EasyNoteDaily.format_date(settings.format, time) .. ".md"
  return vim.fs.normalize(vim.fs.joinpath(config.notes_root(), settings.folder, name))
end

--- Fill in `{{title}}`, `{{date}}`, `{{time}}` and `{{date:FORMAT}}` / `{{time:FORMAT}}` template variables
---@param content string
---@param title string
---@param time integer? defaults to now
---@return string
function EasyNoteDaily.render_template(content, title, time)
  local templates = read_obsidian_json("templates.json")
  local date_format = nonempty(templates.dateFormat) or "YYYY-MM-DD"
  local time_format = nonempty(templates.timeFormat) or "HH:mm"

  return (
    content:gsub("{{%s*(%w+)%s*:?(.-)%s*}}", function(name, format)
      name = name:lower()
      if name == "title" then
        return title
      elseif name == "date" then
        return EasyNoteDaily.format_date(format ~= "" and format or date_format, time)
      elseif name == "time" then
        return EasyNoteDaily.format_date(format ~= "" and format or time_format, time)
      end
    end)
  )
end

--- Initial lines of a new daily note, from the configured template
---@param title string
---@param time integer?
---@return string[]
local function initial_lines(title, time)
  local template = EasyNoteDaily.settings().template
  if not template then
    return {}
  end
  local path = vim.fs.joinpath(config.notes_root(), template)
  if not path:match("%.md$") then
    path = path .. ".md"
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    vim.notify("easynote: daily note template not found: " .. path, vim.log.levels.WARN)
    return {}
  end
  return vim.split(EasyNoteDaily.render_template(table.concat(lines, "\n"), title, time), "\n", { plain = true })
end

--- Path of the daily note for a given time, creating it from the template if missing
---@param time integer? defaults to now
---@return string
function EasyNoteDaily.ensure(time)
  local path = EasyNoteDaily.path(time)
  if not utils.is_file(path) then
    local title = vim.fn.fnamemodify(path, ":t:r")
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(initial_lines(title, time), path)
  end
  return path
end

return EasyNoteDaily
