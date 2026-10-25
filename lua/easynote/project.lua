local EasyNoteProject = {}

local config = require("easynote.config")
local utils = require("easynote.utils")

---@class EasyNoteProjectInfo
---@field id string note id, e.g. "owner/repo" or "local/dirname"
---@field repo string? host qualified repo, e.g. "github.com/owner/repo"

---@type table<string, EasyNoteProjectInfo>
local cache = {}

--- Run git in a directory, returning trimmed stdout on success
---@param dir string
---@param args string[]
---@return string?
local function git(dir, args)
  local ok, result = pcall(function()
    return vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
  end)
  if not ok or result.code ~= 0 then
    return nil
  end
  local out = vim.trim(result.stdout or "")
  return out ~= "" and out or nil
end

--- Split a git remote url into host and repository path
--- Handles https, ssh:// and scp-like (`git@host:owner/repo`) urls, including ssh alias hosts.
---@param url string
---@return string? host
---@return string? path e.g. "owner/repo"
function EasyNoteProject.parse_remote(url)
  url = vim.trim(url)
  local host, path
  local rest = url:match("^%a[%w+.-]*://(.*)$")
  if rest then
    rest = rest:gsub("^[^@/]*@", "")
    host, path = rest:match("^([^/:]+):?%d*/(.+)$")
  else
    host, path = url:gsub("^[^@/:]*@", ""):match("^([^/:]+):(.+)$")
  end
  if not host or not path then
    return nil, nil
  end
  path = path:gsub("^/+", ""):gsub("/+$", ""):gsub("%.git$", "")
  if path == "" then
    return nil, nil
  end
  host = host:lower()
  host = (config.host_aliases or {})[host] or host
  return host, path
end

--- Make a single path segment safe to use as an Obsidian filename
---@param segment string
---@return string
function EasyNoteProject.sanitize_segment(segment)
  segment = segment:gsub('[%*"\\/<>:|%?#%^%[%]]', "-")
  segment = vim.trim(segment):gsub("^%.+", ""):gsub("%.+$", "")
  return segment ~= "" and segment or "untitled"
end

--- Make a `/` separated note name safe to use as an Obsidian path
---@param name string
---@return string
function EasyNoteProject.sanitize_path(name)
  local segments = {}
  for segment in vim.gsplit(name, "/", { plain = true, trimempty = true }) do
    if segment ~= "" and segment ~= "." and segment ~= ".." then
      table.insert(segments, EasyNoteProject.sanitize_segment(segment))
    end
  end
  return #segments > 0 and table.concat(segments, "/") or "untitled"
end

--- Identify the project rooted at `root_dir`
--- `git config easynote.project` wins, then the configured remote, then `local/<dirname>`.
---@param root_dir string
---@return EasyNoteProjectInfo
function EasyNoteProject.info(root_dir)
  if cache[root_dir] then
    return cache[root_dir]
  end

  local info
  local override = git(root_dir, { "config", "--get", "easynote.project" })
  local remote = git(root_dir, { "remote", "get-url", config.git_remote or "origin" })
  local host, path
  if remote then
    host, path = EasyNoteProject.parse_remote(remote)
  end

  if override then
    info = { id = override, repo = host and (host .. "/" .. path) or nil }
  elseif host then
    info = { id = path, repo = host .. "/" .. path }
  else
    info = { id = "local/" .. vim.fs.basename(root_dir) }
  end
  info.id = EasyNoteProject.sanitize_path(info.id)

  cache[root_dir] = info
  return info
end

--- Project root for the current buffer, falling back to the working directory
---@return string
function EasyNoteProject.current_root()
  return utils.get_root_dir(0) or vim.fs.normalize(vim.fn.getcwd())
end

--- Path of the project note for a project root
---@param root_dir string
---@return string path
---@return EasyNoteProjectInfo info
function EasyNoteProject.note_path(root_dir)
  local info = EasyNoteProject.info(root_dir)
  local dir = vim.fs.joinpath(config.notes_root(), config.project_notes_dir)
  return vim.fs.joinpath(dir, info.id .. ".md"), info
end

--- Path of the project note for a project root, creating it with frontmatter if missing
---@param root_dir string
---@return string path
function EasyNoteProject.ensure_note(root_dir)
  local path, info = EasyNoteProject.note_path(root_dir)
  if not utils.is_file(path) then
    local lines = { "---", "tags: [project]" }
    if info.repo then
      table.insert(lines, "repo: " .. info.repo)
    end
    vim.list_extend(lines, { "---", "", "# " .. vim.fs.basename(info.id), "" })
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines, path)
  end
  return path
end

function EasyNoteProject.clear_cache()
  cache = {}
end

return EasyNoteProject
