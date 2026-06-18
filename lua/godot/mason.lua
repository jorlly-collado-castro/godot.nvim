local M = {}

function M.setup()
  local config = require("godot.config").get()
  if not config.mason.auto_setup then return end

  local ok, mason = pcall(require, "mason")
  if not ok then
    vim.notify("[godot.nvim] mason.nvim not found – skipping tool installation", vim.log.levels.WARN)
    return
  end

  local current_opts = mason.settings or {}
  current_opts.ensure_installed = current_opts.ensure_installed or {}

  vim.list_extend(current_opts.ensure_installed, config.mason.packages)

  mason.setup(current_opts)
end

return M
