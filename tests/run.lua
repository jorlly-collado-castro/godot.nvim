local function test_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    error("Failed to require " .. name .. ": " .. tostring(mod))
  end
  return mod
end

test_require("godot.config")

local godot = test_require("godot")

godot.setup()

test_require("godot.pipe")
test_require("godot.mason")
test_require("godot.snacks")
test_require("godot.runner")
test_require("godot.lsp")
test_require("godot.treesitter")
test_require("godot.debug")
test_require("godot.docs")

print("[godot.nvim] all modules loaded successfully")
os.exit(0)
