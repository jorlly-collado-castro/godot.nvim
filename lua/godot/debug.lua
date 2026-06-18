local M = {}

local function port_open(host, port)
  local ok, chan = pcall(vim.fn.sockconnect, "tcp", host .. ":" .. port, { mode = "raw" })
  if ok and chan > -1 then
    vim.fn.chanclose(chan)
    return true
  end
  return false
end

local function parse_url(url)
  local host, port = url:match("([^:/]+):(%d+)$")
  host = host or "127.0.0.1"
  port = tonumber(port) or 6006
  return host, port
end

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

local function require_dap()
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("[godot.nvim] nvim-dap not found", vim.log.levels.ERROR)
  end
  return ok, dap
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
    vim.notify("[godot.nvim] nvim-dap not found – skipping debug keymaps", vim.log.levels.DEBUG)
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
    local _, port = parse_url(debug_opts.adapter.connect)
    if not port_open("127.0.0.1", port) then
      vim.notify(
        "[godot.nvim] Godot not reachable on port " .. port
          .. ". Start Godot with --remote-debug or press rd to auto-launch.",
        vim.log.levels.ERROR
      )
      return
    end
    dap.continue()
  end, { desc = "Start DAP debugging session" })

  vim.api.nvim_create_user_command("GodotDebugStop", function()
    dap.terminate()
  end, { desc = "Stop debugging" })

  vim.api.nvim_create_user_command("GodotDebugRestart", function()
    dap.restart()
  end, { desc = "Restart debugging" })

  vim.api.nvim_create_user_command("GodotRunDebug", function()
    M.run_debug()
  end, { desc = "Run project with DAP debugging" })
end

--- Starts Godot with remote-debug enabled and connects DAP
function M.run_debug()
  local config = require("godot.config").get()
  local host, port = parse_url(config.debug.adapter.connect)

  -- Launch Godot in debug mode
  require("godot.runner").run_project({ "--remote-debug", host .. ":" .. port })

  -- Poll for the debug port to become available (up to 15s)
  local elapsed = 0
  local timer = vim.uv.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    if port_open(host, port) then
      timer:stop()
      timer:close()
      local ok, dap = require_dap()
      if ok then dap.continue() end
      return
    end
    elapsed = elapsed + 500
    if elapsed >= 15000 then
      timer:stop()
      timer:close()
      vim.notify("[godot.nvim] Timed out waiting for Godot debugger on " .. host .. ":" .. port, vim.log.levels.ERROR)
    end
  end))
end

return M
