# godot.nvim

A comprehensive Neovim plugin for Godot engine development.

## Features

| Feature                      | Module       | Status       | Description                                                                                             |
| ---------------------------- | ------------ | ------------ | ------------------------------------------------------------------------------------------------------- |
| Synchronized external editor | `pipe`       | **complete** | Pipe server connects Godot to running Neovim with running‑server guard.                                 |
| LSP integration              | `lsp`        | **complete** | GDScript language server (`gdlsp`) via nvim-lspconfig.                                                  |
| Treesitter support           | `treesitter` | **complete** | GDScript syntax highlighting via nvim-treesitter.                                                       |
| Mason tooling                | `mason`      | **complete** | Auto-installs `gdscript-formatter` and `gdtoolkit`.                                                     |
| Launch project               | `runner`     | **complete** | `GodotRun`, `GodotRunCurrent` commands.                                                                 |
| Package / export             | `runner`     | **complete** | `GodotExport` with preset picker, timestamped directories, and platform subdirs.                        |
| DAP debugger                 | `debug`      | **complete** | nvim-dap adapter for Godot remote debugger with working keymaps (`<leader>db`, `dc`, `do`, `di`, `du`). |
| Debugger commands            | `debug`      | **complete** | `GodotDebugStart/Stop/Restart`, merged into `debug` module.                                             |
| Snacks integration           | `snacks`     | **complete** | Auto‑hides `.uid` and `server.pipe` from file explorer.                                                 |
| Godot documentation          | `docs`       | **partial**  | Delegates to `gdscript-extended-lsp` if installed; fallback opens browser.                              |
| Profiler integration         | —            | **none**     | Not implemented.                                                                                        |

## Installation

### setup godot external editor

```
Text Editor > External > Exec Path = /opt/homebrew/bin/nvim (or your nvim install)
Text Editor > External > Exec Flags = --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"
Text Editor > External > Use External Edit = True
```

### lazy.nvim

```lua
{
  "<YOUR_GITHUB_USER>/godot.nvim",
  lazy = false,
  opts = {
    pipe = { path = "./server.pipe" },
    mason = { auto_setup = true },
    lsp = { auto_setup = true },
    treesitter = { auto_setup = true },
    debug = { auto_setup = true },
    runner = { auto_setup = true },
    docs = { auto_setup = true },
    snacks = { auto_setup = true },
  },
}
```

### packer.nvim

```lua
use {
  "<YOUR_GITHUB_USER>/godot.nvim",
  config = function()
    require('godot').setup({})
  end,
}
```

## Configuration

All options and their defaults:

```lua
require('godot').setup({
  pipe = {
    path = "./server.pipe",
    auto_start = true,
  },
  mason = {
    auto_setup = true,
    packages = { "gdscript-formatter", "gdtoolkit" },
  },
  lsp = {
    auto_setup = true,
    gdtoolkit = { cmd = { "gdlsp" } },
  },
  treesitter = {
    auto_setup = true,
    ensure_installed = { "gdscript" },
  },
  debug = {
    auto_setup = true,
    adapter = {
      type = "server",
      host = "127.0.0.1",
      port = 6006,
    },
    keymaps = {
      toggle_breakpoint = "<leader>db",
      continue = "<leader>dc",
      step_over = "<leader>do",
      step_into = "<leader>di",
      step_out = "<leader>du",
    },
  },
  runner = {
    auto_setup = true,
    command = "godot",
    args = {},
    open_terminal = true,
    terminal = { direction = "float", size = 80 },
    export = {
      presets = {
        linux = "Linux/X11",
        windows = "Windows Desktop",
        mac = "macOS",
        web = "Web",
      },
      output_dir = "build",
      timestamp = true,
    },
  },
  docs = {
    auto_setup = true,
    url_template = "https://docs.godotengine.org/en/stable/classes/class_%s.html",
  },
  snacks = {
    auto_setup = true,
    exclude = { "*.uid", "server.pipe" },
  },
})
```

## Commands

| Command             | Description                                     |
| ------------------- | ----------------------------------------------- |
| `GodotRun`          | Run the Godot project in the current directory. |
| `GodotRunCurrent`   | Run the current `.tscn` scene.                  |
| `GodotBuild`        | Build the project (`godot --build`).            |
| `GodotExport`       | Export project with preset picker or by name.   |
| `GodotExportLast`   | Re-run the last export.                         |
| `GodotDebugStart`   | Start a DAP debugging session.                  |
| `GodotDebugStop`    | Stop debugging.                                 |
| `GodotDebugRestart` | Restart debugging.                              |
| `GodotDocs`         | Open Godot docs for symbol under cursor.        |

## Project Structure

```
lua/godot/
├── init.lua         # Entry point, configures and loads all modules
├── config.lua       # Default configuration and merging
├── pipe.lua         # Godot external editor pipe server
├── mason.lua        # Mason.nvim integration
├── runner.lua       # Project runner + export presets
├── debug.lua        # Merged DAP adapter + debugger commands
├── lsp.lua          # GDScript LSP (gdtoolkit via nvim-lspconfig)
├── treesitter.lua   # nvim-treesitter GDScript parser
├── docs.lua         # Godot documentation integration
└── snacks.lua       # Snacks explorer config
```

## Requirements

- Neovim >= 0.9
- Optional: [mason.nvim](https://github.com/williamboman/mason.nvim)
- Optional: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- Optional: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Optional: [nvim-dap](https://github.com/mfussenegger/nvim-dap)

## Development

```bash
make fmt     # Format code with stylua
make lint    # Lint with luacheck
make test    # Run headless tests
```

## License

GPLv3 © 2026
