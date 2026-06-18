local M = {}

local function open_url()
  local config = require("godot.config").get()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("[godot.nvim] No symbol under cursor", vim.log.levels.WARN)
    return
  end
  vim.ui.open(config.docs.url_template:format(word:lower()))
end

function M.setup()
  local config = require("godot.config").get()
  if not config.docs.auto_setup then return end

  vim.api.nvim_create_user_command("GodotDocs", function()
    local ok = pcall(require, "gdscript-extended-lsp")
    if ok then
      vim.cmd("GDScriptDocs")
    else
      open_url()
    end
  end, { desc = "Open Godot docs for symbol under cursor" })
end

return M
