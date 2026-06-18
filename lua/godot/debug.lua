local M = {}

local function configure_dap(adapter_opts)
  local ok, dap = pcall(require, "dap")
  if not ok then return end

  dap.adapters.godot = adapter_opts

  dap.configurations.gdscript = {
    {
      type = "godot",
      request = "launch",
      name = "Launch Godot Scene",
      project = "${workspaceFolder}",
      launch_scene = true,
    },
    {
      type = "godot",
      request = "attach",
      name = "Attach to Running Godot",
      project = "${workspaceFolder}",
    },
  }
end

function M.setup()
  local config = require("godot.config").get()
  local debug_opts = config.debug
  if not debug_opts.auto_setup then return end

  if debug_opts.adapter then
    configure_dap(debug_opts.adapter)
  end

  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("[godot.nvim] nvim-dap not found – skipping debug keymaps", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gdscript",
    callback = function()
      local km = debug_opts.keymaps
      vim.keymap.set("n", km.toggle_breakpoint, dap.toggle_breakpoint, { buffer = true, desc = "Toggle breakpoint" })
      vim.keymap.set("n", km.continue, dap.continue, { buffer = true, desc = "Continue" })
      vim.keymap.set("n", km.step_over, dap.step_over, { buffer = true, desc = "Step over" })
      vim.keymap.set("n", km.step_into, dap.step_into, { buffer = true, desc = "Step into" })
      vim.keymap.set("n", km.step_out, dap.step_out, { buffer = true, desc = "Step out" })
    end,
  })

  vim.api.nvim_create_user_command("GodotDebugStart", function()
    dap.continue()
  end, { desc = "Start DAP debugging session" })

  vim.api.nvim_create_user_command("GodotDebugStop", function()
    dap.terminate()
  end, { desc = "Stop debugging" })

  vim.api.nvim_create_user_command("GodotDebugRestart", function()
    dap.restart()
  end, { desc = "Restart debugging" })
end

return M
