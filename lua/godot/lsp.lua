local M = {}

local function detect_godot_project()
  return vim.fn.findfile("project.godot", vim.fn.getcwd() .. ";") ~= ""
end

function M.setup()
  local config = require("godot.config").get()
  local lsp_opts = config.lsp
  if not lsp_opts.auto_setup then return end

  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    vim.notify("[godot.nvim] nvim-lspconfig not found – skipping LSP setup", vim.log.levels.DEBUG)
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function()
      lspconfig.gdtoolkit.setup(lsp_opts.gdtoolkit)
    end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*/project.godot",
    callback = function()
      if vim.bo.filetype == "" then
        vim.bo.filetype = "gdscript"
      end
    end,
  })
end

return M
