local M = {}

local last_export_preset = nil

local function find_godot_project()
  return vim.fn.findfile("project.godot", vim.fn.getcwd() .. ";")
end

local function project_root()
  local project = find_godot_project()
  if project == "" then return vim.fn.getcwd() end
  return vim.fn.fnamemodify(project, ":h")
end

function M.run_project(args)
  local config = require("godot.config").get()
  local cmd = config.runner.command

  local full_cmd = { cmd }
  for _, arg in ipairs(config.runner.args) do
    table.insert(full_cmd, arg)
  end

  if args then
    for _, arg in ipairs(args) do
      table.insert(full_cmd, arg)
    end
  end

  table.insert(full_cmd, "--path")
  table.insert(full_cmd, project_root())

  if config.runner.open_terminal then
    local term_opts = vim.deepcopy(config.runner.terminal)
    local snack_ok, snacks = pcall(require, "snacks")
    if snack_ok then
      snacks.terminal(full_cmd, { position = term_opts.direction or "float" })
    else
      vim.fn.termopen(full_cmd, term_opts)
    end
  else
    vim.fn.jobstart(full_cmd, {
      detach = true,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.notify("[godot.nvim] Godot exited with code " .. code, vim.log.levels.WARN)
        end
      end,
    })
  end
end

function M.run_current_scene()
  local scene = vim.fn.expand("%:p")
  if vim.fn.fnamemodify(scene, ":e") ~= "tscn" then
    vim.notify("[godot.nvim] Current file is not a scene (.tscn)", vim.log.levels.ERROR)
    return
  end
  M.run_project({ scene })
end

local function pick_preset(callback)
  local config = require("godot.config").get()
  local presets = config.runner.export.presets
  local items = vim.tbl_keys(presets)
  table.sort(items)

  local snack_ok, snacks = pcall(require, "snacks")
  if snack_ok and snacks.picker then
    snacks.picker.select(items, { prompt = "Export preset" }, function(item)
      if item then callback(item, presets[item]) end
    end)
  else
    vim.ui.select(items, { prompt = "Export preset" }, function(item)
      if item then callback(item, presets[item]) end
    end)
  end
end

function M.export_project(preset_name)
  local config = require("godot.config").get()
  local export_opts = config.runner.export
  local preset_id = export_opts.presets[preset_name]

  if not preset_id then
    vim.notify("[godot.nvim] Unknown export preset: " .. tostring(preset_name), vim.log.levels.ERROR)
    return
  end

  last_export_preset = preset_name

  local output_dir = export_opts.output_dir

  if export_opts.timestamp then
    output_dir = output_dir .. "/build_" .. os.date("%Y-%m-%d_%H%M%S")
  end

  output_dir = output_dir .. "/" .. preset_name

  vim.fn.mkdir(output_dir, "p")

  local full_cmd = {
    "godot",
    "--path",
    project_root(),
    "--headless",
    "--export-release",
    preset_id,
    output_dir .. "/game",
  }

  vim.fn.jobstart(full_cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("[godot.nvim] Export " .. preset_name .. " completed -> " .. output_dir, vim.log.levels.INFO)
      else
        vim.notify("[godot.nvim] Export " .. preset_name .. " failed with code " .. code, vim.log.levels.ERROR)
      end
    end,
  })
end

function M.open_project()
  local config = require("godot.config").get()
  local cmd = config.runner.command
  local full_cmd = { cmd, "--path", project_root() }

  if config.runner.open_terminal then
    local snack_ok, snacks = pcall(require, "snacks")
    if snack_ok then
      snacks.terminal(full_cmd, { position = "float" })
    else
      vim.fn.termopen(full_cmd, {})
    end
  else
    vim.fn.jobstart(full_cmd, {
      detach = true,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.notify("[godot.nvim] Godot exited with code " .. code, vim.log.levels.WARN)
        end
      end,
    })
  end
end

function M.setup()
  local config = require("godot.config").get()
  if not config.runner.auto_setup then return end

  vim.api.nvim_create_user_command("GodotRun", function()
    M.run_project()
  end, { desc = "Run the Godot project" })

  vim.api.nvim_create_user_command("GodotOpen", function()
    M.open_project()
  end, { desc = "Open project in Godot editor" })

  vim.api.nvim_create_user_command("GodotRunCurrent", function()
    M.run_current_scene()
  end, { desc = "Run the current Godot scene" })

  vim.api.nvim_create_user_command("GodotBuild", function()
    M.run_project({ "--build" })
  end, { desc = "Build the Godot project" })

  vim.api.nvim_create_user_command("GodotExport", function(info)
    local preset = info.args
    if preset and preset ~= "" then
      M.export_project(preset)
    else
      pick_preset(function(name, _)
        M.export_project(name)
      end)
    end
  end, { nargs = "?", desc = "Export project with optional preset name" })

  vim.api.nvim_create_user_command("GodotExportLast", function()
    if last_export_preset then
      M.export_project(last_export_preset)
    else
      vim.notify("[godot.nvim] No previous export to repeat", vim.log.levels.WARN)
    end
  end, { desc = "Re-run the last export" })
end

return M
