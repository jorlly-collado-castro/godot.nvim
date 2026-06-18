local M = {}

local function start_server()
  local config = require("godot.config").get()
  if not config.pipe.auto_start then return end

  local pipe_path = config.pipe.path
  local project = vim.fn.findfile("project.godot", vim.fn.getcwd() .. ";")
  if project == "" then return end

  local project_dir = vim.fn.fnamemodify(project, ":h")
  local full_path = project_dir .. "/" .. pipe_path

  if vim.uv.fs_stat(full_path) then return end

  pcall(vim.fn.serverstart, full_path)
end

function M.setup()
  start_server()

  local group = vim.api.nvim_create_augroup("GodotPipeServer", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    callback = start_server,
  })
end

return M
