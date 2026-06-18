local M = {}

local function setup_project_godot_autocmd()
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*/project.godot",
    callback = function()
      if vim.bo.filetype == "" then
        vim.bo.filetype = "gdscript"
      end
    end,
  })
end

local function register_server(opts)
  if vim.fn.executable("gdlsp") == 0 then
    return false
  end

  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then return true end

  local util_ok, util = pcall(require, "lspconfig.util")
  if not util_ok then return true end

  local configs_ok, configs = pcall(require, "lspconfig.configs")
  if not configs_ok then return true end

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

  setup_project_godot_autocmd()

  return true
end

function M.setup()
  local config = require("godot.config").get()
  local lsp_opts = config.lsp
  if not lsp_opts.auto_setup then return end

  if register_server(lsp_opts.gdtoolkit) then return end

  if config.mason.auto_setup then
    vim.defer_fn(function()
      if not register_server(lsp_opts.gdtoolkit) then
        vim.notify(
          "[godot.nvim] `gdlsp` not found – LSP unavailable this session. Install via `:MasonInstall gdtoolkit`, then restart Neovim.",
          vim.log.levels.INFO
        )
      end
    end, 8000)
  else
    vim.notify(
      "[godot.nvim] `gdlsp` not found – GDScript LSP disabled. Install via `:MasonInstall gdtoolkit`",
      vim.log.levels.INFO
    )
  end
end

return M
