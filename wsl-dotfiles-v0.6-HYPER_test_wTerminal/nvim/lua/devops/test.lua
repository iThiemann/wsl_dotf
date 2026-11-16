-- Checks every DevOps language end to end: filetype, Tree-sitter parser, LSP client(s)
-- attached, formatter available (conform), linter configured + executable (nvim-lint).
-- Headless: tests/run.sh   ·   inside nvim: :DevopsTest
-- "a|b" = either name is fine. requires = external CLI → missing CLI gives WARN, not FAIL.
local M = {}

M.cases = {
  { file = "ansible/playbooks/site.yml", ft = "yaml.ansible", lsp = { "ansiblels" }, ts = "yaml" },
  { file = "terraform/main.tf", ft = "terraform", lsp = { "terraformls" }, fmt = { "terraform_fmt" },
    lint = { "tflint" }, ts = "terraform", requires = "terraform" },
  { file = "tofu/main.tofu", ft = "opentofu", lsp = { "tofu_ls" }, fmt = { "tofu_fmt" }, ts = "hcl",
    requires = "tofu-ls" },
  { file = "terragrunt/terragrunt.hcl", ft = "hcl", fmt = { "tofu_fmt|terraform_fmt" }, ts = "hcl", requires = "tofu" },
  { file = "helm/demo/templates/deployment.yaml", ft = "helm", lsp = { "helm_ls" }, ts = "helm" },
  { file = "helm/demo/values.yaml", ft = "yaml|yaml.helm-values", lsp = { "yamlls|helm_ls" } },
  { file = "helmfile/helmfile.yaml.gotmpl", ft = "helm", ts = "helm" },
  { file = "k8s/deployment.yaml", ft = "yaml", lsp = { "yamlls" }, fmt = { "prettier" },
    lint = { "yamllint", "kubeconform" }, ts = "yaml" },
  { file = "k8s/route.yaml", ft = "yaml", lsp = { "yamlls" }, lint = { "kubeconform" } },
  { file = "docker/Dockerfile", ft = "dockerfile", lsp = { "dockerls|docker_language_server" },
    lint = { "hadolint" }, ts = "dockerfile" },
  { file = "docker/Containerfile", ft = "dockerfile", lsp = { "dockerls|docker_language_server" },
    lint = { "hadolint" } },
  { file = "docker/compose.yaml", ft = "yaml.docker-compose",
    lsp = { "docker_compose_language_service|docker_language_server", "yamlls" }, lint = { "yamllint" } },
  { file = "podman/web.container", ft = "systemd" },
  { file = "gitlab/.gitlab-ci.yml", ft = "yaml.gitlab", lsp = { "gitlab_ci_ls", "yamlls" },
    fmt = { "prettier" }, lint = { "yamllint" } },
  { file = "bash/deploy.sh", ft = "sh|bash", lsp = { "bashls" }, fmt = { "shfmt" }, ts = "bash" },
  { file = "python/app.py", ft = "python", lsp = { "basedpyright|pyright", "ruff" },
    fmt = { "ruff_format|ruff_fix" }, ts = "python" },
  { file = "go/main.go", ft = "go", lsp = { "gopls" }, fmt = { "goimports|gofumpt" },
    lint = { "golangcilint" }, ts = "go", requires = "go" },
  { file = "web/index.html", ft = "html", lsp = { "html" }, fmt = { "prettier" }, ts = "html" },
  { file = "web/style.css", ft = "css", lsp = { "cssls" }, fmt = { "prettier" }, ts = "css" },
  { file = "jinja/nginx.conf.j2", ft = "jinja", lsp = { "jinja_lsp" }, fmt = { "djlint" }, lint = { "djlint" } },
  { file = "java/src/main/java/demo/App.java", ft = "java", lsp = { "jdtls" }, ts = "java",
    wait = 120000, requires = "java" },
  { file = "jq/filter.jq", ft = "jq", lsp = { "jqls" }, ts = "jq" },
  { file = "markdown/README.md", ft = "markdown", lsp = { "marksman" }, fmt = { "prettier" },
    lint = { "markdownlint-cli2" }, ts = "markdown" },
  { file = "nginx/site.conf", ft = "nginx", lsp = { "nginx_language_server" }, ts = "nginx" },
  { file = "php/index.php", ft = "php", lsp = { "intelephense|phpactor" }, ts = "php" },
  { file = "sql/schema.pg.sql", ft = "sql", fmt = { "sqlfluff" }, lint = { "sqlfluff" }, ts = "sql" },
  { file = "sql/schema.mariadb.sql", ft = "sql", fmt = { "sqlfluff" }, lint = { "sqlfluff" } },
  { file = ".ssh/config", ft = "sshconfig", ts = "ssh_config" },
  { file = "vim/test.vim", ft = "vim", lsp = { "vimls" }, lint = { "vint" }, ts = "vim" },
  { file = "yaml/app-config.yaml", ft = "yaml", lsp = { "yamlls" }, fmt = { "prettier" }, lint = { "yamllint" } },
  { file = "json/data.json", ft = "json", lsp = { "jsonls" }, fmt = { "prettier" }, ts = "json" },
  { file = "http/health.http", ft = "http", ts = "http" },
}

local function any_of(spec, set)
  for alt in spec:gmatch("[^|]+") do
    if set[alt] then return alt end
  end
end

local function linters_for(ft)
  local lint = require("lint")
  local names = {}
  for part in (ft .. "."):gmatch("([^.]+)%.") do
    for _, n in ipairs(lint.linters_by_ft[part] or {}) do names[n] = true end
  end
  for _, n in ipairs(lint.linters_by_ft[ft] or {}) do names[n] = true end
  return names
end

local function linter_executable(name)
  local l = require("lint").linters[name]
  if type(l) == "function" then l = l() end
  if type(l) ~= "table" then return false end
  local cmd = type(l.cmd) == "function" and l.cmd() or l.cmd
  return type(cmd) == "string" and vim.fn.executable(cmd) == 1
end

local function check_case(root, case)
  local res = {}
  local function add(kind, status, detail) table.insert(res, { kind = kind, status = status, detail = detail }) end
  local path = root .. "/" .. case.file
  if vim.fn.filereadable(path) == 0 then
    add("file", "FAIL", "fixture missing: " .. path)
    return res
  end
  local soft = case.requires and vim.fn.executable(case.requires) == 0
  local FAIL = soft and "WARN" or "FAIL"
  if soft then add("cli", "WARN", case.requires .. " not installed") end

  vim.cmd("silent! %bwipeout!")
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  -- filetype
  if any_of(case.ft, { [ft] = true }) then add("filetype", "PASS", ft)
  else add("filetype", "FAIL", ("got %q, want %s"):format(ft, case.ft)) end

  -- tree-sitter parser
  if case.ts then
    local ok, parser = pcall(vim.treesitter.get_parser, buf, case.ts, { error = false })
    if ok and parser then add("treesitter", "PASS", case.ts)
    else add("treesitter", "FAIL", "parser missing: " .. case.ts) end
  end

  -- LSP clients
  if case.lsp and #case.lsp > 0 then
    local function attached()
      local set = {}
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do set[c.name] = true end
      return set
    end
    vim.wait(case.wait or 30000, function()
      local set = attached()
      for _, spec in ipairs(case.lsp) do
        if not any_of(spec, set) then return false end
      end
      return true
    end, 250)
    local set = attached()
    for _, spec in ipairs(case.lsp) do
      local hit = any_of(spec, set)
      if hit then add("lsp", "PASS", hit)
      else add("lsp", FAIL, spec .. " not attached (got: " .. table.concat(vim.tbl_keys(set), ",") .. ")") end
    end
  end

  -- formatters
  if case.fmt then
    local ok, conform = pcall(require, "conform")
    local avail = {}
    if ok then
      for _, f in ipairs(conform.list_formatters(buf)) do avail[f.name] = true end
    end
    for _, spec in ipairs(case.fmt) do
      local hit = any_of(spec, avail)
      if hit then add("formatter", "PASS", hit) else add("formatter", FAIL, spec .. " not available") end
    end
  end

  -- linters
  if case.lint then
    local ok = pcall(require, "lint")
    local configured = ok and linters_for(ft) or {}
    for _, name in ipairs(case.lint) do
      if not configured[name] then add("linter", "FAIL", name .. " not configured for " .. ft)
      elseif not linter_executable(name) then add("linter", FAIL, name .. " not executable")
      else add("linter", "PASS", name) end
    end
  end
  return res
end

---@param opts? {root?: string, exit?: boolean, only?: string}
function M.run(opts)
  opts = opts or {}
  local headless = #vim.api.nvim_list_uis() == 0
  local root = opts.root or vim.env.DEVOPS_TEST_FIXTURES
    or (vim.fn.stdpath("config") .. "/tests/fixtures")
  local lines, counts = {}, { PASS = 0, WARN = 0, FAIL = 0 }

  for _, case in ipairs(M.cases) do
    if not opts.only or case.file:find(opts.only, 1, true) then
      for _, r in ipairs(check_case(root, case)) do
        counts[r.status] = counts[r.status] + 1
        table.insert(lines, ("%-4s  %-40s %-10s %s"):format(r.status, case.file, r.kind, r.detail or ""))
      end
    end
  end
  table.insert(lines, ("\n%d passed · %d warnings · %d failed"):format(counts.PASS, counts.WARN, counts.FAIL))

  local report = vim.fn.stdpath("state") .. "/devops-test-report.txt"
  vim.fn.writefile(lines, report)
  if headless then
    io.stdout:write(table.concat(lines, "\n") .. "\nreport: " .. report .. "\n")
    if opts.exit ~= false then vim.cmd(counts.FAIL > 0 and "cquit 1" or "qall!") end
  else
    vim.cmd("silent! %bwipeout!")
    vim.cmd("edit " .. vim.fn.fnameescape(report))
  end
  return counts
end

return M
