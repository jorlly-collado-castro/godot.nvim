local M = {}

function M.setup()
  local config = require("godot.config").get()
  local docs_opts = config.docs
  if not docs_opts.auto_setup then return end

  local ok = pcall(require, "gdscript-extended-lsp")
  if ok then return end

  vim.api.nvim_create_user_command("GodotDocs", function()
    local word = vim.fn.expand("<cword>")
    if word == "" then
      vim.notify("[godot.nvim] No symbol under cursor", vim.log.levels.WARN)
      return
    end
    local url = docs_opts.url_template:format(word:lower())
    vim.ui.open(url)
  end, { desc = "Open Godot docs for symbol under cursor" })
end

return M
