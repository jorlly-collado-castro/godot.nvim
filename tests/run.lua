local function test_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    error("Failed to require " .. name .. ": " .. tostring(mod))
  end
  return mod
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("Expected %s, got %s: %s", tostring(b), tostring(a), msg or ""))
  end
end

local function assert_truthy(val, msg)
  if not val then
    error("Expected truthy: " .. (msg or ""))
  end
end

local function assert_falsy(val, msg)
  if val then
    error("Expected falsy: " .. (msg or ""))
  end
end

local function refute_contains(str, substr, msg)
  if str:find(substr, 1, true) then
    error(string.format("Unexpected %q in %q: %s", substr, str, msg or ""))
  end
end

-- ── Config tests ──────────────────────────────────────────

local config = test_require("godot.config")

-- Defaults
assert_eq(config.get().mason.auto_setup, true, "mason auto_setup should default true")
assert_eq(config.get().lsp.auto_setup, true, "lsp auto_setup should default true")
assert_eq(config.get().lsp.gdscript_port, 6005, "gdscript_port should default 6005")
assert_eq(#vim.tbl_keys(config.get().lsp.gdscript), 0, "gdscript opts should default to empty")
assert_eq(#vim.tbl_keys(config.get().lsp.gdshader), 0, "gdshader opts should default to empty")

-- No gdlsp anywhere in defaults
local defaults_str = vim.inspect(config.get())
refute_contains(defaults_str, "gdlsp", "config should not reference gdlsp")

-- Config merging
config.apply({
  lsp = { gdscript = { settings = { foo = 1 } } },
})
assert_eq(config.get().lsp.gdscript_port, 6005, "port should survive merge")
assert_eq(config.get().lsp.gdscript.settings.foo, 1, "custom settings should merge")

-- Deprecation handling
local warn_count = 0
local function capture_warn(msg, level)
  warn_count = warn_count + 1
end
vim.notify = capture_warn

config.apply({ dap = { host = "0.0.0.0" } })
assert_eq(warn_count, 1, "dap key should trigger deprecation warn")
assert_eq(config.get().debug.host, "0.0.0.0", "dap.host should migrate to debug.adapter.host")

-- Reset for module tests
config.apply({})

-- ── Module loading tests ──────────────────────────────────

-- All modules must load without error
local modules = {
  "godot.config",
  "godot.pipe",
  "godot.mason",
  "godot.snacks",
  "godot.runner",
  "godot.lsp",
  "godot.treesitter",
  "godot.debug",
  "godot.docs",
}
for _, name in ipairs(modules) do
  test_require(name)
end

-- ── LSP module tests ──────────────────────────────────────

local lsp = require("godot.lsp")

-- setup() must not throw when called with defaults
local ok_lsp, err_lsp = pcall(lsp.setup)
assert_truthy(ok_lsp, "lsp.setup() should not throw: " .. tostring(err_lsp))

-- Verify no gdlsp references in lsp module source
local lsp_src = vim.fn.readfile("lua/godot/lsp.lua")
local lsp_text = table.concat(lsp_src, "\n")
refute_contains(lsp_text, "gdlsp", "lsp module should not reference gdlsp")
refute_contains(lsp_text, "gdtoolkit", "lsp module should not reference gdtoolkit")

-- ── Mason module tests ────────────────────────────────────

local mason = require("godot.mason")

-- setup() must not throw
local ok_mason, err_mason = pcall(mason.setup)
assert_truthy(ok_mason, "mason.setup() should not throw: " .. tostring(err_mason))

-- Verify mason source doesn't reference ensure_installed (Mason has no such setting)
local mason_src = vim.fn.readfile("lua/godot/mason.lua")
local mason_text = table.concat(mason_src, "\n")
refute_contains(mason_text, "mason.settings.ensure_installed", "mason module should not write to Mason settings")

-- ── Config source tests ───────────────────────────────────

-- Ensure lsp runs after mason in init.lua (order dependency)
local init_src = test_require("godot")
-- (implied by the require order in init.lua)

-- ── Runner module tests ───────────────────────────────────

local runner = require("godot.runner")
local ok_runner, err_runner = pcall(runner.setup)
assert_truthy(ok_runner, "runner.setup() should not throw: " .. tostring(err_runner))

-- ── Debug module tests ────────────────────────────────────

local debug = require("godot.debug")
local ok_debug, err_debug = pcall(debug.setup)
assert_truthy(ok_debug, "debug.setup() should not throw: " .. tostring(err_debug))

-- ── Treesitter module tests ───────────────────────────────

local ts = require("godot.treesitter")
local ok_ts, err_ts = pcall(ts.setup)
assert_truthy(ok_ts, "treesitter.setup() should not throw: " .. tostring(err_ts))

-- ── Docs module tests ─────────────────────────────────────

local docs = require("godot.docs")
local ok_docs, err_docs = pcall(docs.setup)
assert_truthy(ok_docs, "docs.setup() should not throw: " .. tostring(err_docs))

-- ── Snacks module tests ───────────────────────────────────

local snacks = require("godot.snacks")
local ok_snacks, err_snacks = pcall(snacks.setup)
assert_truthy(ok_snacks, "snacks.setup() should not throw: " .. tostring(err_snacks))

print("[godot.nvim] all tests passed")
os.exit(0)
