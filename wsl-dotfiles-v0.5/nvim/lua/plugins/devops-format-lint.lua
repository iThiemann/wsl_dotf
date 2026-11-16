-- Formatters (conform.nvim) and linters (nvim-lint) for the DevOps matrix.
-- LazyVim extras already provide: terraform_fmt, prettier, ruff, gofumpt/goimports,
-- markdownlint-cli2, hadolint, sqlfluff, php-cs-fixer … — this file adds/overrides the rest.

-- SQL dialect per buffer: b:sql_dialect > file name hint > g:sql_dialect (options.lua)
local function sql_dialect(buf)
  buf = buf or 0
  if vim.b[buf].sql_dialect then
    return vim.b[buf].sql_dialect
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name:match("%.mariadb%.sql$") then return "mariadb" end
  if name:match("%.mysql%.sql$") then return "mysql" end
  if name:match("%.pg%.sql$") or name:match("%.psql$") then return "postgres" end
  return vim.g.sql_dialect or "ansi"
end

-- Does the current buffer look like a Kubernetes/OpenShift manifest?
local function is_k8s_manifest()
  local lines = vim.api.nvim_buf_get_lines(0, 0, 200, false)
  local api, kind = false, false
  for _, l in ipairs(lines) do
    if l:match("^apiVersion:") then api = true end
    if l:match("^kind:") then kind = true end
    if api and kind then return true end
  end
  return false
end

return {
  -- formatters ---------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        -- OpenTofu / Terragrunt / plain HCL: `tofu fmt`, fall back to `terraform fmt`
        opentofu = { "tofu_fmt", "terraform_fmt", stop_after_first = true },
        ["opentofu-vars"] = { "tofu_fmt", "terraform_fmt", stop_after_first = true },
        hcl = { "tofu_fmt", "terraform_fmt", stop_after_first = true },
        jinja = { "djlint" },
        htmldjango = { "djlint" },
        sql = { "sqlfluff" },
        mysql = { "sqlfluff" },
        ["yaml.docker-compose"] = { "prettier" },
        ["yaml.gitlab"] = { "prettier" },
        -- deliberately NOT formatted: helm (Go templates break), yaml.ansible (keeps
        -- jinja quoting), nginx/jq/sshconfig (no reliable formatter)
      },
      formatters = {
        tofu_fmt = {
          command = "tofu",
          args = { "fmt", "-no-color", "-" },
          stdin = true,
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci", "-bn" },  -- 2 spaces, indent case, binary ops at line start
        },
        sqlfluff = {
          args = function(_, ctx)
            return { "format", "--dialect=" .. sql_dialect(ctx.buf), "-" }
          end,
          require_cwd = false,
          stdin = true,
        },
        djlint = {
          prepend_args = { "--indent", "2" },
        },
      },
    },
  },

  -- linters ------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      local by_ft = {
        yaml = { "yamllint", "kubeconform" },
        ["yaml.gitlab"] = { "yamllint" },
        ["yaml.docker-compose"] = { "yamllint" },
        terraform = { "terraform_validate", "tflint", "trivy" },
        tf = { "terraform_validate", "tflint" },
        opentofu = { "tflint" },
        dockerfile = { "hadolint", "trivy" },
        jinja = { "djlint" },
        vim = { "vint" },
        go = { "golangcilint" },
        sql = { "sqlfluff" },
        mysql = { "sqlfluff" },
      }
      for ft, linters in pairs(by_ft) do
        opts.linters_by_ft[ft] = linters
      end

      opts.linters = opts.linters or {}

      -- yamllint reads ~/.config/yamllint/config (relaxed, 160 chars) unless the project has one
      -- sqlfluff: dialect per buffer, no project config required
      opts.linters.sqlfluff = {
        stdin = false,            -- lints the saved file (nvim-lint appends the file name)
        args = {
          "lint", "--format=json",
          function() return "--dialect=" .. sql_dialect(0) end,
        },
      }

      -- kubeconform: validate Kubernetes / OpenShift manifests (+ CRDs) on save
      opts.linters.kubeconform = {
        cmd = "kubeconform",
        stdin = true,
        stream = "stdout",
        ignore_exitcode = true,
        args = {
          "-output", "json",
          "-strict",
          "-ignore-missing-schemas",
          "-schema-location", "default",
          "-schema-location",
          "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
        },
        condition = function()
          return vim.fn.executable("kubeconform") == 1 and is_k8s_manifest()
        end,
        parser = function(output, bufnr)
          local diags = {}
          local ok, data = pcall(vim.json.decode, output)
          if not ok or type(data) ~= "table" or type(data.resources) ~= "table" then
            return diags
          end
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          for _, r in ipairs(data.resources) do
            if r.status == "statusInvalid" or r.status == "statusError" then
              local lnum = 0
              if r.name and r.name ~= "" then
                for i, l in ipairs(lines) do
                  if l:match("^%s+name:%s*[\"']?" .. vim.pesc(r.name)) then
                    lnum = i - 1
                    break
                  end
                end
              end
              table.insert(diags, {
                lnum = lnum,
                col = 0,
                severity = vim.diagnostic.severity.ERROR,
                source = "kubeconform",
                message = string.format("%s %s: %s", r.kind or "?", r.name or "", r.msg or "invalid"),
              })
            end
          end
          return diags
        end,
      }

      -- trivy is thorough but slow: only when the project opts in with trivy.yaml/.trivyignore
      opts.linters.trivy = {
        condition = function(ctx)
          return vim.fs.find({ "trivy.yaml", ".trivyignore", ".trivyignore.yaml" },
            { path = ctx.dirname, upward = true })[1] ~= nil
        end,
      }
      return opts
    end,
  },
}
