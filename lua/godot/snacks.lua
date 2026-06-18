local M = {}

function M.setup()
  local config = require("godot.config").get()
  local snacks_opts = config.snacks
  if not snacks_opts.auto_setup then return end

  local ok, snacks = pcall(require, "snacks")
  if not ok then return end

  vim.schedule(function()
    local picker_ok, picker = pcall(require, "snacks.picker")
    if picker_ok and picker.config then
      picker.config.sources.explorer = vim.tbl_deep_extend(
        "force",
        picker.config.sources.explorer or {},
        { exclude = snacks_opts.exclude }
      )
    end
  end)
end

return M
