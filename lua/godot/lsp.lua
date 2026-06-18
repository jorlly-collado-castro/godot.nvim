local M = {}

local function setup_server(opts)
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("[godot.nvim] nvim-lspconfig not found – skipping LSP setup", vim.log.levels.DEBUG)
    return
  end

  local util_ok, util = pcall(require, "lspconfig.util")
  if not util_ok then return end

  if vim.fn.executable("gdlsp") == 0 then
    vim.notify(
      "[godot.nvim] `gdlsp` not found on PATH – LSP disabled. Install with `:MasonInstall gdtoolkit`",
      vim.log.levels.INFO
    )
    return
  end

  local configs_ok, configs = pcall(require, "lspconfig.configs")
  if not configs_ok then return end

  if not configs.gdtoolkit then
    configs.gdtoolkit = {
      default_config = {
        cmd = { "gdlsp" },
        filetypes = { "gdscript" },
        root_dir = util.root_pattern("project.godot"),
        settings = {},
      },
      docs = {
        description = [[
https://github.com/godotengine/godot

The GDScript language server provided by the gdtoolkit package.
Install via mason: `:MasonInstall gdtoolkit`
]],
      },
    }
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function()
      lspconfig.gdtoolkit.setup(opts)
    end,
  })
end

function M.setup()
  local config = require("godot.config").get()
  local lsp_opts = config.lsp
  if not lsp_opts.auto_setup then return end

  setup_server(lsp_opts.gdtoolkit)

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
