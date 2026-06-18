local M = {}

M.defaults = {
  keys = {
    run = "<leader>ra",
    run_current = "<leader>rA",
    build = "<leader>rm",
    export = "<leader>rE",
    export_last = "<leader>rq",
    debug_start = "<leader>rt",
    debug_stop = "<leader>rT",
    debug_restart = "<leader>rx",
    run_debug = "<leader>rd",
    open = "<leader>ro",
    docs = "<leader>rH",
  },
  pipe = {
    path = "./server.pipe",
    auto_start = true,
  },
  mason = {
    auto_setup = true,
    packages = {
      "gdscript-formatter",
      "gdtoolkit",
    },
  },
  lsp = {
    auto_setup = true,
    gdscript_port = 6005,
    gdscript = {},
    gdshader = {},
  },
  treesitter = {
    auto_setup = true,
  },
  docs = {
    auto_setup = true,
    url_template = "https://docs.godotengine.org/en/stable/classes/class_%s.html",
  },
  snacks = {
    auto_setup = true,
    exclude = { "*.uid", "server.pipe" },
  },
  debug = {
    auto_setup = true,
    adapter = {
      type = "server",
      connect = "tcp://127.0.0.1:6006",
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
    terminal = {
      direction = "float",
      size = 80,
    },
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
}

function M.apply(opts)
  opts = opts or {}
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  if merged.dap then
    vim.notify("[godot.nvim] config.dap is deprecated, use config.debug instead", vim.log.levels.WARN)
    merged.debug = vim.tbl_deep_extend("force", merged.debug or {}, merged.dap)
    merged.dap = nil
  end

  if merged.debugger then
    vim.notify("[godot.nvim] config.debugger is deprecated, use config.debug instead", vim.log.levels.WARN)
    merged.debug = vim.tbl_deep_extend("force", merged.debug or {}, merged.debugger)
    merged.debugger = nil
  end

  M.options = merged
  return M.options
end

function M.get()
  return M.options or M.defaults
end

return M
