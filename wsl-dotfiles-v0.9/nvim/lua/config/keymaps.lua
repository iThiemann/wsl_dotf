-- Extra key maps (LazyVim defaults: https://www.lazyvim.org/keymaps)
local map = vim.keymap.set

-- base64 decode/encode the visual selection in place (k8s secrets)
map("v", "<leader>cb", [[c<c-r>=system('base64 -d', @")<cr><esc>]], { desc = "Base64 decode selection" })
map("v", "<leader>cB", [[c<c-r>=trim(system('base64 -w0', @"))<cr><esc>]], { desc = "Base64 encode selection" })

-- pretty-print JSON buffer/selection with jq
map("n", "<leader>cj", "<cmd>%!jq .<cr>", { desc = "jq pretty buffer" })
map("v", "<leader>cj", ":!jq .<cr>", { desc = "jq pretty selection" })

-- SQL dialect for sqlfluff in this buffer
map("n", "<leader>cq", function()
  vim.ui.select({ "postgres", "mariadb", "mysql", "ansi", "sqlite", "tsql" }, { prompt = "SQL dialect" }, function(d)
    if d then
      vim.b.sql_dialect = d
      vim.notify("sqlfluff dialect: " .. d)
    end
  end)
end, { desc = "SQL dialect (sqlfluff)" })

-- jdtls broken ("exit code 13")? wipe its caches; it rebuilds on the next start
vim.api.nvim_create_user_command("JdtlsReset", function()
  for _, d in ipairs({ vim.fn.stdpath("cache") .. "/jdtls", vim.fn.expand("~/.cache/jdtls"), vim.fn.stdpath("data") .. "/jdtls" }) do
    vim.fn.delete(d, "rf")
  end
  vim.notify("jdtls caches removed — reopen a .java file (first start indexes for a while)")
end, { desc = "Delete jdtls caches" })

-- quick save without format (e.g. a big generated manifest)
map("n", "<leader>W", "<cmd>noautocmd write<cr>", { desc = "Write without formatting" })
