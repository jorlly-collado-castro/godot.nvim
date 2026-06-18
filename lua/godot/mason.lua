local M = {}

local function install_missing(packages)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    vim.defer_fn(function()
      install_missing(packages)
    end, 500)
    return
  end

  for _, name in ipairs(packages) do
    if not registry.is_installed(name) then
      if registry.has_package(name) then
        registry.get_package(name):install()
      end
    end
  end
end

function M.setup()
  local config = require("godot.config").get()
  if not config.mason.auto_setup then return end

  local ok, mason = pcall(require, "mason")
  if not ok then
    vim.notify("[godot.nvim] mason.nvim not found – skipping tool installation", vim.log.levels.DEBUG)
    return
  end

  if not mason.has_setup then
    mason.setup {}
  end

  vim.defer_fn(function()
    install_missing(config.mason.packages)
  end, 500)
end

return M
