local Helpers = {}

local original_select = vim.ui.select

--- Reset editor and module state between tests
function Helpers.reset()
  vim.cmd("silent! %bwipeout!")
  vim.cmd("silent! only")
  for name in pairs(package.loaded) do
    if name == "easynote" or vim.startswith(name, "easynote.") then
      package.loaded[name] = nil
    end
  end
  vim.ui.select = original_select
  Helpers.messages = {}
  vim.notify = function(msg)
    table.insert(Helpers.messages, msg)
  end
  Helpers.data_home = Helpers.tmpdir()
  vim.env.XDG_DATA_HOME = Helpers.data_home
end

--- Create a fresh temporary directory
---@return string
function Helpers.tmpdir()
  local dir = vim.fs.normalize(vim.fn.tempname())
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir)
end

--- Write a file, creating parent directories
---@param path string
---@param lines string[]?
function Helpers.write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines or {}, path)
end

---@param path string
---@return string[]
function Helpers.read(path)
  return vim.fn.readfile(path)
end

--- Setup easynote with test friendly defaults
---@param opts table?
function Helpers.setup(opts)
  require("easynote").setup(
    vim.tbl_deep_extend("force", { mappings = { EasyNote = false, EasyNoteFloating = false } }, opts or {})
  )
end

--- Make vim.ui.select pick the item matching `pick` (or the first one) and record the items
---@param pick (fun(items: string[]): string?)?
---@return { items: string[]?, calls: integer }
function Helpers.stub_select(pick)
  local record = { items = nil, calls = 0 }
  vim.ui.select = function(items, _, on_choice)
    record.items = items
    record.calls = record.calls + 1
    on_choice(pick and pick(items) or items[1])
  end
  return record
end

--- Create a git repository
---@param dir string
---@param remote string?
function Helpers.git_init(dir, remote)
  vim.fn.mkdir(dir, "p")
  vim.system({ "git", "init", "-q", dir }):wait()
  if remote then
    vim.system({ "git", "-C", dir, "remote", "add", "origin", remote }):wait()
  end
end

function Helpers.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then
    error(
      string.format("%sexpected %s, got %s", msg and (msg .. ": ") or "", vim.inspect(expected), vim.inspect(actual)),
      2
    )
  end
end

function Helpers.truthy(value, msg)
  if not value then
    error(msg or "expected truthy value", 2)
  end
end

return Helpers
