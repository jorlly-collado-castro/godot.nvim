local M = {}

function M.setup()
  local config = require("godot.config").get()
  if not config.treesitter.auto_setup then return end

  vim.defer_fn(function()
    local has_parser = pcall(vim.treesitter.query.parse, "gdscript", "(node) @capture")
    if has_parser then return end

    if vim.fn.exists(":TSInstallSync") == 2 then
      vim.cmd("TSInstallSync gdscript")
    end
  end, 200)
end

return M
