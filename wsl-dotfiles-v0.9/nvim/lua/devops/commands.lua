-- :DevopsInstall / :DevopsTest — also usable headless (see tests/run.sh)
vim.api.nvim_create_user_command("DevopsInstall", function()
  require("devops.install").run({ exit = false })
end, { desc = "Install all Mason tools + Tree-sitter parsers and wait" })

vim.api.nvim_create_user_command("DevopsTest", function()
  require("devops.test").run({ exit = false })
end, { desc = "Check LSP/formatter/linter/parser for every DevOps language" })
