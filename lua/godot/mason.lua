local M = {}

local function install_missing_packages(packages)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    vim.defer_fn(function()
      install_missing_packages(packages)
    end, 500)
    return
  end

  for _, name in ipairs(packages) do
    if not registry.is_installed(name) then
      local ok, pkg = pcall(registry.get_package, name)
      if ok and pkg then
        vim.notify(string.format("[godot.nvim] Installing %s via Mason...", name), vim.log.levels.INFO)
        pkg:install()
      end
    end
  end
end

function M.setup()
  local config = require("godot.config").get()
  if not config.mason.auto_setup then return end

  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    vim.notify("[godot.nvim] mason.nvim not found – skipping tool installation", vim.log.levels.DEBUG)
    return
  end

  if mason.settings then
    mason.settings.ensure_installed = mason.settings.ensure_installed or {}
    vim.list_extend(mason.settings.ensure_installed, config.mason.packages)
  end

  mason.setup({
    ensure_installed = vim.list_extend({}, config.mason.packages),
  })

  vim.defer_fn(function()
    install_missing_packages(config.mason.packages)
  end, 500)
end

return M
