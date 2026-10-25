-- Minimal test runner: nvim --headless --clean -l tests/run.lua [filter]
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
package.path = root .. "/tests/?.lua;" .. package.path

local helpers = require("helpers")
local filter = _G.arg[1]

local passed, failed = 0, 0
local specs = vim.fn.glob(root .. "/tests/*_spec.lua", false, true)
table.sort(specs)
for _, spec in ipairs(specs) do
  local cases = dofile(spec)
  for _, case in ipairs(cases) do
    local name = vim.fs.basename(spec):gsub("_spec%.lua$", "") .. ": " .. case[1]
    if not filter or name:find(filter, 1, true) then
      helpers.reset()
      local ok, err = xpcall(case[2], debug.traceback)
      if ok then
        passed = passed + 1
        io.stdout:write("ok   " .. name .. "\n")
      else
        failed = failed + 1
        io.stdout:write("FAIL " .. name .. "\n" .. err .. "\n")
      end
    end
  end
end

io.stdout:write(string.format("\n%d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
