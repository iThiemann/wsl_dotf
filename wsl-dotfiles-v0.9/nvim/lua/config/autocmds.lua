-- Autocommands (LazyVim defaults: https://www.lazyvim.org/configuration/general)
local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("devops", { clear = true })

-- YAML/HCL/JSON: show whitespace problems, 2 spaces, no spell noise
au("FileType", {
  group = group,
  pattern = { "yaml", "yaml.*", "helm", "hcl", "terraform", "opentofu", "json", "jsonc" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.spell = false
  end,
})

-- Makefiles, Go, nginx keep real tabs
au("FileType", {
  group = group,
  pattern = { "make", "go", "gomod" },
  callback = function() vim.opt_local.expandtab = false end,
})

-- Never autoformat secrets / vault files / huge manifests
au("BufReadPre", {
  group = group,
  pattern = { "*vault*.yml", "*vault*.yaml", "*.enc.yaml", "*secret*.yaml" },
  callback = function(ev) vim.b[ev.buf].autoformat = false end,
})
