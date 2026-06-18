local M = {}

local function get_lspconfig()
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return nil end
  return lspconfig
end

local function register_custom_server(lspconfig)
  if lspconfig.configs.gdtoolkit then return end

  lspconfig.configs.gdtoolkit = {
    default_config = {
      cmd = { "gdlsp" },
      filetypes = { "gdscript" },
      root_dir = lspconfig.util.root_pattern("project.godot"),
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

function M.setup()
  local config = require("godot.config").get()
  local lsp_opts = config.lsp
  if not lsp_opts.auto_setup then return end

  local lspconfig = get_lspconfig()
  if not lspconfig then
    vim.notify("[godot.nvim] nvim-lspconfig not found – skipping LSP setup", vim.log.levels.DEBUG)
    return
  end

  register_custom_server(lspconfig)

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
