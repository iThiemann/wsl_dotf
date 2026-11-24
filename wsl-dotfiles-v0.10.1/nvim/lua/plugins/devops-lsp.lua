-- Language servers that LazyVim extras don't cover (or need DevOps settings).
-- Servers listed here are installed by Mason automatically (mason-lspconfig mapping).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- shell ---------------------------------------------------------------
        bashls = {
          filetypes = { "sh", "bash" },
          settings = {
            bashIde = {
              globPattern = "*@(.sh|.inc|.bash|.command)",
              shellcheckArguments = "--external-sources",
            },
          },
        },

        -- CI ------------------------------------------------------------------
        gitlab_ci_ls = {},                      -- filetype yaml.gitlab (see config/filetypes.lua)

        -- web -----------------------------------------------------------------
        html = { filetypes = { "html" } },
        cssls = {},
        emmet_language_server = {
          filetypes = { "html", "css", "scss", "jinja", "htmldjango", "php" },
        },

        -- templates / misc ------------------------------------------------------
        jinja_lsp = { filetypes = { "jinja", "htmldjango" } },
        jqls = {},
        nginx_language_server = {},
        vimls = {},

        -- helm: helm_ls for chart templates AND helmfiles; it drives yamlls itself
        -- (helm-ls docs: filetypes { "helm", "helmfile" }, root Chart.yaml / helmfile.yaml)
        helm_ls = {
          filetypes = { "helm", "helmfile" },
          root_markers = { "Chart.yaml", "helmfile.yaml", "helmfile.yaml.gotmpl", ".git" },
          settings = {
            ["helm-ls"] = {
              yamlls = { enabled = true, path = "yaml-language-server" },
            },
          },
        },

        -- terraform-ls handles *.tf; tofu-ls handles *.tofu (installed by install.sh
        -- with `go install`, not by Mason, so only enabled when present)
        terraformls = {},
        tofu_ls = {
          mason = false,
          enabled = vim.fn.executable("tofu-ls") == 1,
          cmd = { "tofu-ls", "serve" },
          filetypes = { "opentofu", "opentofu-vars" },
          root_markers = { ".terraform", ".terraform.lock.hcl", ".git" },
        },
      },
    },
  },

  -- Mason: CLI tools that aren't LSP servers (formatters, linters) -------------------
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "shellcheck",
        "shfmt",
        "yamllint",
        "tflint",
        "trivy",
        "djlint",
        "sqlfluff",
        "vint",
        "golangci-lint",
        "actionlint",
        "stylua",
      },
    },
  },

  -- Tree-sitter parsers for every language in the matrix ---------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "css", "diff", "dockerfile", "git_config", "gitcommit", "gitignore",
        "go", "gomod", "gosum", "gotmpl", "hcl", "helm", "html", "http", "ini",
        "java", "jinja", "jinja_inline", "jq", "json", "json5", "lua", "make",
        "markdown", "markdown_inline", "nginx", "php", "python", "query", "regex",
        "sql", "ssh_config", "terraform", "toml", "vim", "vimdoc", "xml", "yaml",
      },
    },
  },
}
