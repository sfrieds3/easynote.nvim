local h = require("helpers")

local function floats()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
  end, vim.api.nvim_list_wins())
end

return {
  {
    "float is sized relative to the editor",
    function()
      h.setup({ window_opts = { width_pct = 50, height_pct = 50 } })
      vim.cmd("vsplit")
      local opts = require("easynote.window").get_float_fullscreen_opts()
      h.eq("editor", opts.relative)
      h.eq(math.floor(vim.o.columns / 2), opts.width)
    end,
  },
  {
    "open key toggles the float instead of stacking",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md", { "hello" })
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNoteFloating")
      h.eq(1, #floats())
      h.eq(vault .. "/notes.md", vim.api.nvim_buf_get_name(0))
      vim.cmd("EasyNoteFloating")
      h.eq(0, #floats())
    end,
  },
  {
    "closing writes changes",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md", { "hello" })
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNoteFloating")
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { "world" })
      vim.cmd("EasyNoteFloating")
      h.eq({ "hello", "world" }, h.read(vault .. "/notes.md"))
    end,
  },
  {
    "q mapping is removed when the float closes",
    function()
      local vault = h.tmpdir()
      h.write(vault .. "/notes.md")
      h.setup({ notes_dir = vault })
      vim.cmd("EasyNoteFloating")
      local bufnr = vim.api.nvim_get_current_buf()
      local function q_maps()
        return vim.tbl_filter(function(map)
          return map.lhs == "q"
        end, vim.api.nvim_buf_get_keymap(bufnr, "n"))
      end
      h.eq(1, #q_maps())
      vim.api.nvim_feedkeys("q", "x", false)
      h.eq(0, #floats())
      h.truthy(vim.api.nvim_buf_is_valid(bufnr))
      h.eq(0, #q_maps())
    end,
  },
}
