local M = {}

function M.setup()
  local config = require("godot.config").get()
  local ts_opts = config.treesitter
  if not ts_opts.auto_setup then return end

  local ok, treesitter = pcall(require, "nvim-treesitter.configs")
  if not ok then
    vim.notify("[godot.nvim] nvim-treesitter not found – skipping treesitter setup", vim.log.levels.DEBUG)
    return
  end

  treesitter.setup({
    ensure_installed = ts_opts.ensure_installed,
    highlight = { enable = true },
  })
end

return M
