-- Options (loaded before lazy.nvim starts LazyVim's defaults are already sane)
local opt = vim.opt

-- LazyVim language choices
vim.g.lazyvim_python_lsp = "basedpyright"     -- alt: "pyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_php_lsp = "intelephense"         -- alt: "phpactor"
vim.g.lazyvim_picker = "snacks"
vim.g.autoformat = true                        -- format on save (toggle: <leader>uf / uF)

-- DevOps files are mostly 2-space YAML/HCL/JSON
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.relativenumber = true
opt.scrolloff = 8
opt.colorcolumn = "120"
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.spelllang = { "en", "de" }
opt.clipboard = "unnamedplus"                  -- uses pbcopy/pbpaste-style providers on WSL
opt.undofile = true
opt.swapfile = false

-- WSL clipboard: win32yank if present, else our UTF-8-safe pbcopy/pbpaste
if vim.fn.has("wsl") == 1 then
  if vim.fn.executable("win32yank.exe") == 1 then
    vim.g.clipboard = {
      name = "win32yank",
      copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
      paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
      cache_enabled = 0,
    }
  elseif vim.fn.executable("pbcopy") == 1 then
    vim.g.clipboard = {
      name = "wsl-pbcopy",
      copy = { ["+"] = "pbcopy", ["*"] = "pbcopy" },
      paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
      cache_enabled = 0,
    }
  end
end

-- SQL dialect for sqlfluff (format + lint). Change per buffer: :SqlDialect mariadb
vim.g.sql_dialect = "postgres"

-- filetype rules for DevOps files nvim doesn't know (see lua/config/filetypes.lua)
require("config.filetypes")
require("devops.commands")
