-- Dump every key map that has a description (LazyVim + plugins + this config) for
-- the shell `keys` overview:  nvim --headless -c "lua require('devops.keys').dump(path)" -c qa!
local M = {}

function M.dump(path)
  -- LazyVim sets most key maps on VeryLazy, which a headless start never fires
  pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "VeryLazy" })
  vim.wait(300)
  local leader = vim.g.mapleader or "\\"
  local lines, seen = {}, {}
  local mode_name = { n = "", x = "[visual] ", i = "[insert] ", t = "[terminal] ", o = "[operator] " }
  for _, mode in ipairs({ "n", "x", "i", "t", "o" }) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      local desc = m.desc
      if desc and desc ~= "" and not m.lhs:match("^<Plug>") and not m.lhs:match("^<SNR>") then
        local lhs = m.lhs
        if leader == " " and lhs:sub(1, 1) == " " then
          lhs = "<leader>" .. lhs:sub(2)
        end
        local key = mode .. lhs
        if not seen[key] then
          seen[key] = true
          table.insert(lines, mode_name[mode] .. lhs .. "\t" .. desc:gsub("[\t\n]", " "))
        end
      end
    end
  end
  table.sort(lines)
  -- buffer-local LSP maps (LazyVim sets them on attach, so they aren't global)
  local lsp = {
    { "gd", "Goto definition" }, { "gr", "References" }, { "gI", "Goto implementation" },
    { "gy", "Goto type definition" }, { "gD", "Goto declaration" }, { "K", "Hover docs" },
    { "gK", "Signature help" }, { "<leader>ca", "Code action" }, { "<leader>cr", "Rename symbol" },
    { "<leader>cR", "Rename file" }, { "<leader>cl", "LSP info" }, { "]]", "Next reference" },
    { "[[", "Previous reference" },
  }
  for _, k in ipairs(lsp) do
    table.insert(lines, k[1] .. "\t" .. k[2] .. " (LSP, in buffers with a server)")
  end
  vim.fn.writefile(lines, path)
end

return M
