local M = {}

local registered = {}
local group_registered = false

local function find_godot_root(dir)
  for _ = 1, 10 do
    if vim.fn.filereadable(dir .. "/project.godot") == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then return nil end
    dir = parent
  end
end

local defaults = {
  run = "<leader>ga",
  run_current = "<leader>gA",
  build = "<leader>gm",
  export = "<leader>gE",
  export_last = "<leader>gq",
  debug_start = "<leader>gt",
  debug_stop = "<leader>gT",
  debug_restart = "<leader>gx",
  docs = "<leader>gH",
}

local keymap_defs = {
  run = { ":GodotRun<CR>", "Run Project" },
  run_current = { ":GodotRunCurrent<CR>", "Run Current Scene" },
  build = { ":GodotBuild<CR>", "Build Project" },
  export = { ":GodotExport<CR>", "Export Project" },
  export_last = { ":GodotExportLast<CR>", "Re-run Last Export" },
  debug_start = { ":GodotDebugStart<CR>", "Debug Start" },
  debug_stop = { ":GodotDebugStop<CR>", "Debug Stop" },
  debug_restart = { ":GodotDebugRestart<CR>", "Debug Restart" },
  docs = { ":GodotDocs<CR>", "Docs for Symbol" },
}

local function clear_keymaps()
  for _, lhs in ipairs(registered) do
    pcall(vim.keymap.del, "n", lhs)
  end
  registered = {}

  if group_registered then
    local wk_ok, wk = pcall(require, "which-key")
    if wk_ok then
      pcall(wk.del, "<leader>g", "group")
    end
    group_registered = false
  end
end

local function register_keymaps(keys)
  clear_keymaps()

  local wk_ok, wk = pcall(require, "which-key")
  if wk_ok then
    wk.add({ { "<leader>g", group = "Godot" } })
    group_registered = true
  end

  for name, def in pairs(keymap_defs) do
    local lhs = keys[name]
    if lhs then
      local cmd, desc = unpack(def)
      vim.keymap.set("n", lhs, cmd, { desc = "Godot: " .. desc })
      table.insert(registered, lhs)
    end
  end
end

function M.setup()
  local config = require("godot.config").get()
  local keys = vim.tbl_deep_extend("force", vim.deepcopy(defaults), config.keys or {})

  local function refresh()
    if find_godot_root(vim.fn.getcwd()) then
      register_keymaps(keys)
    else
      clear_keymaps()
    end
  end

  refresh()

  vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = refresh,
  })
end

return M
