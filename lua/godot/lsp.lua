local M = {}

local function port_open(host, port, callback)
  local tcp = vim.uv.new_tcp()
  if not tcp then
    callback(false)
    return
  end
  tcp:connect(host, port, function(err)
    tcp:close()
    callback(err == nil)
  end)
end

local function setup_gdscript(opts)
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then return end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function()
      lspconfig.gdscript.setup(opts)
    end,
  })
end

local function setup_gdshader(opts)
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then return end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "gdshader", "gdshaderinc" },
    callback = function()
      lspconfig.gdshader_lsp.setup(opts)
    end,
  })
end

function M.setup()
  local config = require("godot.config").get()
  local lsp_opts = config.lsp
  if not lsp_opts.auto_setup then return end

  local lspconfig_ok = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("[godot.nvim] nvim-lspconfig not found – skipping LSP setup", vim.log.levels.DEBUG)
    return
  end

  if lsp_opts.gdscript ~= false then
    port_open("127.0.0.1", lsp_opts.gdscript_port or 6005, function(ok)
      if ok then
        setup_gdscript(lsp_opts.gdscript or {})
      end
    end)
  end

  if lsp_opts.gdshader ~= false then
    setup_gdshader(lsp_opts.gdshader or {})
  end

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
