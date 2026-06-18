# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-06-18

### Architecture changes
- **Merged `dap.lua` + `debugger.lua`** → `debug.lua` — single debug module with real DAP keymaps.
- **Added `docs.lua`** — Godot documentation lookup (delegates to gdscript-extended-lsp, fallback opens browser).
- **Added `snacks.lua`** — Auto-hides `.uid` and `server.pipe` from snacks.nvim explorer.
- **Refactored `config.lua`** — Added `debug`, `docs`, `snacks` sections; deprecated `dap` / `debugger` keys with migration.
- **Refactored `runner.lua`** — Added `GodotExport` / `GodotExportLast` commands with preset picker, timestamped & platform subdirectories.
- **Refactored `pipe.lua`** — Added running-server guard (`vim.uv.fs_stat`).
- **Refactored `init.lua`** — Updated module loading to reflect new architecture.
- **Updated `README.md`** — Features table, commands, configuration, project structure.
- **Updated `docs/godot.txt`** — Sync with new module layout.

### New features
- **Export presets** — `:GodotExport` with interactive preset picker (snacks picker | vim.ui.select fallback).
- **Debug module** — `:GodotDebugStart/Stop/Restart`, working DAP keymaps.
- **Documentation lookup** — `:GodotDocs` (browser fallback).
- **Snacks integration** — Auto-hide `.uid` and `server.pipe` from file explorer.
