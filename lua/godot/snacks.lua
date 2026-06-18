local M = {}

function M.setup()
  local config = require("godot.config").get()
  local snacks_opts = config.snacks
  if not snacks_opts.auto_setup then return end

  local ok = pcall(require, "snacks")
  if not ok then return end

  vim.defer_fn(function()
    local picker_ok, picker = pcall(require, "snacks.picker")
    if picker_ok and picker.config then
      picker.config.sources = vim.tbl_deep_extend("force", picker.config.sources or {}, {
        explorer = { exclude = snacks_opts.exclude },
      })
    end
  end, 100)
end

return M
