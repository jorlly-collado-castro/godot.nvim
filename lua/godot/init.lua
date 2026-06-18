local M = {}

function M.setup(opts)
  local config = require("godot.config")
  config.apply(opts)

  require("godot.pipe").setup()
  require("godot.mason").setup()
  require("godot.snacks").setup()
  require("godot.runner").setup()
  require("godot.lsp").setup()
  require("godot.treesitter").setup()
  require("godot.debug").setup()
  require("godot.docs").setup()
end

return M
