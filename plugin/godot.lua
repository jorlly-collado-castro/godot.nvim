if vim.g.godot_nvim_loaded then
  return
end
vim.g.godot_nvim_loaded = true

local ok, err = pcall(require, "godot")
if ok then
  err.setup()
else
  vim.notify("[godot.nvim] Failed to load: " .. tostring(err), vim.log.levels.ERROR)
end
