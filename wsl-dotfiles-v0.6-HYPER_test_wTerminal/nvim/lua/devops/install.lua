-- Install every Mason package (LSP servers from nvim-lspconfig opts + mason ensure_installed
-- from LazyVim, its extras and this config) and every Tree-sitter parser, then WAIT.
-- Headless:  nvim --headless -c "lua require('devops.install').run()"
local M = {}

local function out(msg)
  if #vim.api.nvim_list_uis() == 0 then
    io.stdout:write(msg .. "\n")
  else
    vim.notify(msg)
  end
end

local function lspconfig_to_mason()
  local ok, ml = pcall(require, "mason-lspconfig")
  if ok and ml.get_mappings then                                   -- mason-lspconfig v2
    local m = ml.get_mappings()
    return m.lspconfig_to_package or m.lspconfig_to_mason or {}
  end
  local ok1, server = pcall(require, "mason-lspconfig.mappings.server") -- v1
  return ok1 and server.lspconfig_to_package or {}
end

function M.packages()
  local list, seen = {}, {}
  local function add(name)
    if type(name) == "string" and not seen[name] then
      seen[name] = true
      table.insert(list, name)
    end
  end
  local mason_opts = LazyVim.opts("mason.nvim")
  for _, n in ipairs(mason_opts.ensure_installed or {}) do add(n) end

  local map = lspconfig_to_mason()
  local servers = (LazyVim.opts("nvim-lspconfig").servers or {})
  for name, cfg in pairs(servers) do
    local enabled = cfg == true or (type(cfg) == "table" and cfg.enabled ~= false and cfg.mason ~= false)
    if enabled and map[name] then add(map[name]) end
  end
  table.sort(list)
  return list
end

function M.install_mason(timeout)
  require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim" } })
  local registry = require("mason-registry")
  local refreshed = false
  registry.refresh(function() refreshed = true end)
  vim.wait(120000, function() return refreshed end, 200)

  local pkgs, failed, pending = M.packages(), {}, {}
  out(("mason: %d packages"):format(#pkgs))
  for _, name in ipairs(pkgs) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      table.insert(failed, name .. " (not in mason registry)")
    elseif not pkg:is_installed() then
      pending[name] = pkg
      if not pkg:is_installing() then
        out("  installing " .. name)
        pcall(pkg.install, pkg)
      end
    end
  end

  vim.wait(timeout or 1800000, function()
    for name, pkg in pairs(pending) do
      if pkg:is_installed() then
        out("  ✓ " .. name)
        pending[name] = nil
      elseif not pkg:is_installing() then
        table.insert(failed, name)
        out("  ✗ " .. name)
        pending[name] = nil
      end
    end
    return next(pending) == nil
  end, 1000)
  for name in pairs(pending) do table.insert(failed, name .. " (timeout)") end
  return failed
end

function M.install_treesitter()
  local langs = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local ts = require("nvim-treesitter")
  out(("treesitter: %d parsers"):format(#langs))
  if ts.install then                                   -- main branch: async task
    local ok, task = pcall(ts.install, langs, { summary = true })
    if ok and task and task.wait then task:wait(1800000) end
  else                                                 -- master branch
    pcall(vim.cmd, "TSInstallSync! " .. table.concat(langs, " "))
  end
end

---@param opts? {exit?: boolean}
function M.run(opts)
  opts = opts or {}
  local exit = opts.exit ~= false and #vim.api.nvim_list_uis() == 0
  require("lazy").sync({ wait = true, show = false })
  M.install_treesitter()
  local failed = M.install_mason()
  if #failed > 0 then
    out("FAILED: " .. table.concat(failed, ", "))
  else
    out("all tools installed")
  end
  if exit then vim.cmd(#failed > 0 and "cquit 1" or "qall!") end
end

return M
