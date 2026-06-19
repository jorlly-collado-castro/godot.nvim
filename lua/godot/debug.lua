local M = {}

local function port_open(host, port)
  local ok, chan = pcall(vim.fn.sockconnect, "tcp", host .. ":" .. port, { mode = "raw" })
  if ok and chan > -1 then
    vim.fn.chanclose(chan)
    return true
  end
  return false
end

local function project_root()
  local proj = vim.fn.findfile("project.godot", vim.fn.getcwd() .. ";")
  if proj == "" then return vim.fn.getcwd() end
  return vim.uv.fs_realpath(vim.fn.fnamemodify(proj, ":h")) or vim.fn.fnamemodify(proj, ":h")
end

local function start_editor_debug_server()
  local config = require("godot.config").get()
  local dap_port = tostring(config.debug.adapter.port)
  local debug_server_port = tostring(config.debug.debug_server_port)

  local cmd = { config.runner.command }
  for _, arg in ipairs(config.runner.args) do
    table.insert(cmd, arg)
  end
  table.insert(cmd, "-e")
  table.insert(cmd, "--headless")
  table.insert(cmd, "--dap-port")
  table.insert(cmd, dap_port)
  table.insert(cmd, "--debug-server")
  table.insert(cmd, "tcp://127.0.0.1:" .. debug_server_port)
  table.insert(cmd, "--path")
  table.insert(cmd, project_root())
  vim.fn.jobstart(cmd, { detach = true })
end

local function start_game_debug()
  local config = require("godot.config").get()
  local debug_server_port = tostring(config.debug.debug_server_port)
  local cmd = { config.runner.command }
  for _, arg in ipairs(config.runner.args) do
    table.insert(cmd, arg)
  end
  table.insert(cmd, "--remote-debug")
  table.insert(cmd, "tcp://127.0.0.1:" .. debug_server_port)
  table.insert(cmd, "--path")
  table.insert(cmd, project_root())
  vim.fn.jobstart(cmd, { detach = true })
end

local function configure_dap(adapter_opts)
  local ok, dap = pcall(require, "dap")
  if not ok then return end

  dap.adapters.godot = adapter_opts

  dap.configurations.gdscript = {
    {
      type = "godot",
      request = "attach",
      name = "Attach to Running Godot",
      project = project_root(),
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
    M.start_debug_session()
  end, { desc = "Start editor debug server" })

  vim.api.nvim_create_user_command("GodotDebugStop", function()
    dap.terminate()
  end, { desc = "Stop debugging" })

  vim.api.nvim_create_user_command("GodotDebugRestart", function()
    dap.restart()
  end, { desc = "Restart debugging" })

  vim.api.nvim_create_user_command("GodotRunDebug", function()
    M.run_debug()
  end, { desc = "Run game with DAP (starts editor if needed)" })
end

--- Start the editor debug server. Does NOT attach DAP (the game must be
--- running first). Use `GodotRunDebug` to launch the game and attach DAP.
function M.start_debug_session()
  local config = require("godot.config").get()
  local host = config.debug.adapter.host or "127.0.0.1"
  local port = config.debug.adapter.port

  if port_open(host, port) then
    vim.notify("[godot.nvim] Editor already running on " .. host .. ":" .. port, vim.log.levels.INFO)
    return
  end

  start_editor_debug_server()

  local elapsed = 0
  local timer = vim.uv.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    if port_open(host, port) then
      timer:stop()
      timer:close()
      vim.notify("[godot.nvim] Editor ready on " .. host .. ":" .. port
        .. ". Run GodotRunDebug to start debugging.", vim.log.levels.INFO)
      return
    end
    elapsed = elapsed + 500
    if elapsed >= 30000 then
      timer:stop()
      timer:close()
      vim.notify("[godot.nvim] Timed out waiting for editor on " .. host .. ":" .. port, vim.log.levels.ERROR)
    end
  end))
end

--- Launch the game and attach DAP. Starts the editor first if not already running.
function M.run_debug()
  local config = require("godot.config").get()
  local host = config.debug.adapter.host or "127.0.0.1"
  local port = config.debug.adapter.port

  local function launch_and_attach()
    vim.notify("[godot.nvim] Launching game...", vim.log.levels.INFO)
    start_game_debug()

    -- Wait for game to connect to the editor's remote-debug port,
    -- then call dap.continue() to attach. The game typically connects
    -- within ~1s; 2s is a safe buffer.
    vim.defer_fn(function()
      local ok, dap = require_dap()
      if not ok then return end

      if dap.session() then
        vim.notify("[godot.nvim] Already debugging", vim.log.levels.INFO)
        return
      end

      local saved_ft = vim.bo.filetype
      vim.bo.filetype = "gdscript"
      pcall(dap.continue, dap)
      vim.bo.filetype = saved_ft
    end, 2500)
  end

  if port_open(host, port) then
    launch_and_attach()
    return
  end

  vim.notify("[godot.nvim] Starting editor...", vim.log.levels.INFO)
  start_editor_debug_server()

  local elapsed = 0
  local timer = vim.uv.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    if port_open(host, port) then
      timer:stop()
      timer:close()
      launch_and_attach()
      return
    end
    elapsed = elapsed + 500
    if elapsed >= 20000 then
      timer:stop()
      timer:close()
      vim.notify("[godot.nvim] Timed out waiting for editor", vim.log.levels.ERROR)
    end
  end))
end

return M
