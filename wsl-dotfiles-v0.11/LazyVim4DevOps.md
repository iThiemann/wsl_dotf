# LazyVim for DevOps, Ops & SRE — step-by-step setup guide

Nov 16, 2026 · @Niels Thiemann

## Overview

One command turns a fresh WSL Ubuntu 24.04 into a LazyVim IDE with LSP, formatting, linting and Tree-sitter for 30 DevOps/SRE file types. One test command then proves every language works. The config lives in `wsl-dotfiles/nvim` and is linked to `~/.config/nvim`, so the `v` alias and plain `nvim` both use it.

What you get:

- **LazyVim** as the base: sensible defaults, `<Space>` which-key menus, snacks picker, blink completion, gitsigns, lazygit, trouble, todo-comments.
- **Language extras** from LazyVim where they exist (ansible, terraform, helm, docker, yaml, json, python, go, java, php, sql, markdown, git, toml), plus custom specs for everything LazyVim doesn't cover: OpenTofu, Terragrunt, helmfile, GitLab CI, nginx, Jinja, jq, Vim script, bash, HTML/CSS, Podman Quadlets, SSH config.
- **Kubernetes/OpenShift awareness**: YAML schemas for manifests, an OpenShift Route schema, `kubeconform` validation on save, `oc`/`kubectl` dry-run and diff from the editor, and `kubectl.nvim` as a cluster browser.
- **SRE tooling inside nvim**: SQL client for MariaDB/PostgreSQL (dadbod), tmux pane navigation, session saving that tmux-resurrect restores.
- **Automation**: `install.sh` installs prerequisites, plugins and \~70 Mason tools without opening nvim. `nvim/tests/run.sh` opens a sample file per language headless and checks LSP attach, formatter, linter and parser, and fails with exit code 1 if anything is missing.

How the config is structured:

| File | Purpose |
| --- | --- |
| `lua/config/lazy.lua` | lazy.nvim bootstrap + the LazyVim extras (version-controlled, no `lazyvim.json` clicking) |
| `lua/config/options.lua`, `keymaps.lua`, `autocmds.lua` | editor options, DevOps key maps, filetype rules |
| `lua/plugins/devops-lsp.lua` | language servers and their settings |
| `lua/plugins/devops-format-lint.lua` | conform formatters + nvim-lint linters (incl. kubeconform) |
| `lua/plugins/devops-yaml.lua` | YAML schemas (Kubernetes, OpenShift, GitLab CI, compose, helmfile, Ansible) |
| `lua/plugins/devops-tools.lua` | kubectl.nvim, dadbod, REST, tmux navigator, sessions, diffview |
| `lua/devops/install.lua` | `:DevopsInstall` — installs every Mason tool and waits (used headless) |
| `tests/` | fixtures per language, headless test runner, Dockerfile, CI job |

## Step 1 — Prerequisites on WSL Ubuntu 24.04

LazyVim needs a current Neovim plus a C compiler and the tree-sitter CLI. Ubuntu's own packages are too old for several of these, so `install.sh` downloads them. LazyVim lists [tree-sitter-cli and a C compiler for nvim-treesitter](https://lazyvim.org/), plus curl, fzf, ripgrep and fd for the pickers. On nvim-treesitter's main branch the CLI is a hard requirement: without it, parser installation silently hangs on "Compiling parser" ([kickstart.nvim issue](https://github.com/nvim-lua/kickstart.nvim/issues/1894)).

| Need | Why | Installed by `install.sh` as |
| --- | --- | --- |
| Neovim ≥ 0.11 | LazyVim + native LSP config | release tarball → `~/.local/opt/nvim` (apt has 0.9) |
| tree-sitter CLI, `build-essential` | compile Tree-sitter parsers | GitHub release binary + apt |
| git, curl, fzf, ripgrep, fd, lazygit | plugin manager, pickers, git UI | apt / GitHub releases (earlier steps) |
| Node.js LTS + npm | \~40 % of Mason tools are npm packages (yamlls, bashls, ansiblels, prettier, markdownlint, intelephense, html/css LS) | nodejs.org tarball → `~/.local/opt/node` |
| Go (latest) | gopls, golangci-lint, `go install` of tofu-ls | go.dev tarball → `~/.local/opt/go` |
| `python3-venv`, `python3-pip` | Mason pip tools: ansible-lint, sqlfluff, yamllint, djlint, nginx-language-server | apt |
| OpenJDK 21 | jdtls (Java LSP) | apt `openjdk-21-jdk-headless` |
| `php-cli` | php-cs-fixer, phpcs | apt |
| terraform, tofu, tofu-ls, terragrunt | `terraform fmt`/`tofu fmt` formatting, validate, plan key maps | HashiCorp apt repo, OpenTofu installer, `go install`, GitHub release |
| kubectl, helm, helmfile, oc, kubeconform, k9s | k8s/OpenShift key maps and on-save validation | GitHub releases / OpenShift mirror |
| ansible, podman, mariadb/postgresql clients, aws | playbook checks, Quadlets, dadbod SQL client | apt / AWS installer |
| Nerd Font in Windows Terminal | icons | `setup-windows.ps1` (JetBrainsMono Nerd Font) |

If you install by hand instead, these are the essential commands:

```bash
sudo apt install -y build-essential python3-venv python3-pip openjdk-21-jdk-headless php-cli unzip
# Neovim, tree-sitter, Node LTS, Go: use the release tarballs (apt versions are too old)
```

## Step 2 — Install LazyVim and the DevOps config

Running `./install.sh` from the `wsl-dotfiles` bundle does all of Step 1, links the config and installs everything headless. The first run takes 5–15 minutes, mostly Mason and jdtls.

1. Unpack the bundle inside WSL and run the installer:

   ```bash
   cd ~ && tar -xzf /mnt/c/Users/<you>/Downloads/wsl-dotfiles.tar.gz
   cd ~/wsl-dotfiles && ./install.sh
   ```
2. It moves any existing `~/.config/nvim` to `~/.config/nvim.bak.<timestamp>` and links `wsl-dotfiles/nvim` there. Your old `~/.local/share/nvim` (plugins, Mason) is left alone; delete it for a truly clean start.
3. It bootstraps without opening the UI: `nvim --headless -c "lua require('devops.install').run()"`. That syncs plugins, compiles all Tree-sitter parsers, and installs every Mason package it collects from the LazyVim extras, the LSP servers and this config. It waits until each one finishes and lists failures.
4. It runs `nvim/tests/run.sh` (Step 8) and prints a PASS/WARN/FAIL table.
5. Open nvim (`v` or `nvim`). The dashboard appears; `<Space>` shows the which-key menu, `:Lazy` the plugins, `:Mason` the tools, `:LspInfo` / `:ConformInfo` what is active in the current buffer.

Re-running is safe: `./install.sh --update` upgrades the binaries, and `:Lazy update` / `:MasonUpdate` update plugins and tools. Commit `nvim/lazy-lock.json` after an update you're happy with — it pins every plugin to a commit, so the same versions come back on a new machine.

Options:

- `./install.sh --no-nvim-bootstrap` links the config only; plugins install on first start.
- `./install.sh --links-only` re-links after you moved the repo.
- `lua/plugins/local.lua` (git-ignored) holds machine-specific settings such as database URLs.

## Step 3 — LazyVim extras

The extras are imported in `lua/config/lazy.lua` rather than toggled with `:LazyExtras`. That way the set is in git and identical on every machine. Each extra brings its LSP, formatter, linter, Tree-sitter parser and Mason install list, so you only write config for what LazyVim lacks. Imports must sit between `lazyvim.plugins` and your own `plugins` ([LazyVim extras docs](https://lazyvim.org/extras/lang/terraform)).

| Extra | What it adds for DevOps/SRE |
| --- | --- |
| `lang.ansible` | ansiblels, ansible-lint, nvim-ansible (`<leader>ta` runs the playbook/role) ([docs](https://www.lazyvim.org/extras/lang/ansible)) |
| `lang.terraform` | terraform-ls, `terraform fmt`, `terraform validate` lint, Terraform doc/state pickers |
| `lang.helm` | helm-ls, gotmpl highlighting; stops yamlls inside chart templates ([docs](https://lazyvim.org/extras/lang/helm)) |
| `lang.docker` | dockerls, docker-compose LS, hadolint |
| `lang.yaml` / `lang.json` | yamlls / jsonls with SchemaStore (compose, GitLab CI, helmfile, Ansible, kustomize, GitHub Actions …) |
| `lang.python` | basedpyright (set in `options.lua`) + ruff lint/format, debugpy |
| `lang.go` | gopls, gofumpt, goimports, delve |
| `lang.java` | jdtls via nvim-jdtls, java-debug |
| `lang.php` | intelephense (set in `options.lua`), php-cs-fixer, phpcs |
| `lang.sql` | vim-dadbod + UI + completion, sqlfluff |
| `lang.markdown` | marksman, markdownlint-cli2, render-markdown, preview |
| `lang.git`, `lang.toml` | git commit/rebase/config files, taplo |
| `formatting.prettier` | prettier for YAML, JSON, Markdown, HTML, CSS |
| `dap.core`, `test.core` | debugger and test runner UI (Go, Python, Java hook in) |
| `util.dot` | dotfiles: bash, git config, tmux and other config files |
| `editor.inc-rename`, `coding.yanky`, `util.mini-hipatterns` | live rename preview, yank history, colour/TODO highlighting |

Two choices are set in `lua/config/options.lua`: `vim.g.lazyvim_python_lsp = "basedpyright"` and `vim.g.lazyvim_php_lsp = "intelephense"`. Change them there if you prefer pyright or phpactor.

## Step 4 — Language matrix

Every language in your list has a language server or a validator, and most have a formatter and a linter. Format runs on save (`<leader>uf` toggles it per buffer). Linters run on open, save and leaving insert mode. Server names follow [mason-lspconfig's mapping](https://github.com/williamboman/mason-lspconfig); linter names follow [nvim-lint](https://github.com/mfussenegger/nvim-lint).

| Language / tool | Filetype | LSP | Formatter | Linter / check | Source |
| --- | --- | --- | --- | --- | --- |
| Ansible | `yaml.ansible` | ansiblels | — (keeps Jinja quoting) | ansible-lint (via ansiblels) | extra |
| Terraform | `terraform` | terraformls | terraform fmt | terraform validate, tflint, trivy\* | extra + custom |
| OpenTofu | `opentofu` (`*.tofu`) | tofu-ls ([opentofu/tofu-ls](https://github.com/opentofu/tofu-ls)) | tofu fmt | tflint | custom |
| Terragrunt | `hcl` | — | tofu fmt → terraform fmt | `<leader>iG` format check, `<leader>ig` plan | custom |
| Helm charts | `helm` | helm\_ls (+ yamlls inside) | — (templates) | `<leader>ih` helm lint + template | extra |
| helmfile | `helmfile` (`helmfile*.yaml`, `helmfile.d/*.yaml`, `*.yaml.gotmpl`) | helm\_ls (filetypes `helm` + `helmfile`, runs yamlls inside) | — | `<leader>if` lint, `<leader>iF` diff | custom |
| Kubernetes | `yaml` | yamlls + k8s schema | prettier | yamllint, **kubeconform** (+ CRDs catalog) | custom |
| OpenShift (oc) | `yaml` | yamlls | prettier | kubeconform, `<leader>ko` `oc apply --dry-run=server` | custom |
| Docker / Podman | `dockerfile` (`Dockerfile*`, `Containerfile*`) | dockerls | — | hadolint, trivy\* | extra |
| Docker Compose | `yaml.docker-compose` | docker compose LS + yamlls | prettier | yamllint, `<leader>ic` compose config | extra + custom |
| Podman Quadlets | `systemd` (`*.container`, `*.pod`, …) | — | — | — (highlighting) | custom |
| GitLab CI | `yaml.gitlab` | gitlab\_ci\_ls + yamlls (GitLab schema) | prettier | yamllint | custom |
| bash / sh | `sh`, `bash` | bashls (runs shellcheck) | shfmt `-i 2 -ci -bn` | shellcheck | custom |
| Python | `python` | basedpyright + ruff | ruff format | ruff | extra |
| Go | `go` | gopls | goimports, gofumpt | golangci-lint | extra + custom |
| HTML | `html` | html, emmet | prettier | — | custom |
| CSS | `css` | cssls, emmet | prettier | (cssls diagnostics) | custom |
| Jinja | `jinja` (`*.j2`, `*.jinja`) | jinja\_lsp, emmet | djlint | djlint | custom |
| Java | `java` | jdtls | jdtls | jdtls diagnostics | extra |
| jq | `jq` | jqls | — | (jqls diagnostics) | custom |
| Markdown | `markdown` | marksman | prettier | markdownlint-cli2 | extra |
| MariaDB | `sql` (`*.mariadb.sql`) | — | sqlfluff `--dialect=mariadb` | sqlfluff | extra + custom |
| PostgreSQL | `sql` (`*.pg.sql`, default) | — | sqlfluff `--dialect=postgres` | sqlfluff | extra + custom |
| nginx | `nginx` | nginx\_language\_server | — | `<leader>in` nginx -t | custom |
| PHP | `php` | intelephense | php-cs-fixer | phpcs | extra |
| SSH config | `sshconfig` | — | — | — (highlighting) | built-in |
| Vim script | `vim` | vimls | — | vint | custom |
| YAML (generic) | `yaml` | yamlls + SchemaStore | prettier | yamllint (relaxed, 160 chars) | extra + custom |
| JSON | `json` | jsonls + SchemaStore | prettier | (jsonls) | extra |
| HTTP requests | `http` | — | — | — (kulala removed) | — |

\* trivy only runs when the project has a `trivy.yaml` or `.trivyignore`. It is thorough but slow on every save; `<leader>is` runs it on demand.

Three choices need explaining:

- **No formatter for Helm, helmfile or Ansible.** Formatters reflow Go templates and Jinja expressions and break them. Validation via helm lint, helmfile lint and ansible-lint is safer.
- **SQL dialect** comes from the file name (`*.mariadb.sql`, `*.mysql.sql`, `*.pg.sql`), else `vim.g.sql_dialect = "postgres"`. `<leader>cq` switches it for the current buffer.
- **kubeconform** runs only on YAML that has `apiVersion:` and `kind:` at top level. It validates core resources and CRDs from the [datreeio CRDs-catalog](https://github.com/datreeio/CRDs-catalog), and skips kinds it has no schema for. Typical OpenShift-only kinds may have none — `<leader>ko` asks the cluster instead.

**helmfile in helm\_ls.** helm-ls documents helmfile support with `lspconfig.helm_ls.setup { filetypes = { "helm", "helmfile" }, … }`. In this config the same settings sit in `lua/plugins/devops-lsp.lua` as LazyVim `opts.servers.helm_ls`: `filetypes = { "helm", "helmfile" }`, `root_markers = { "Chart.yaml", "helmfile.yaml", … }` and `settings["helm-ls"].yamlls.path = "yaml-language-server"`. The `lspconfig.<server>.setup` form is the pre-0.11 API, and `root_patterns` is not an lspconfig option; the Neovim 0.11 key is `root_markers`. `lua/config/filetypes.lua` gives helmfiles their own `helmfile` filetype so helm\_ls starts there, and the tests check it on `helmfile.yaml.gotmpl` and `helmfile.d/10-apps.yaml`.

## Step 5 — Filetype detection

The right tools only start if nvim gets the filetype right, and half the DevOps files are "just YAML" or "just HCL". `lua/config/filetypes.lua` fixes this with `vim.filetype.add`. It uses compound filetypes like `yaml.gitlab`: YAML highlighting and yamlls still apply, and the specialised server starts too. Check any buffer with `:set ft?`.

| Files | Filetype | So that |
| --- | --- | --- |
| `.gitlab-ci.yml`, `*.gitlab-ci.yml`, `.gitlab/ci/**`, `ci-templates/**` | `yaml.gitlab` | gitlab\_ci\_ls starts (it only attaches to this filetype) |
| `compose.yaml`, `docker-compose*.yml`, `compose.*.yaml` | `yaml.docker-compose` | compose LS starts |
| `Containerfile*`, `Dockerfile.*`, `*.Dockerfile` | `dockerfile` | dockerls + hadolint for Podman too |
| `*.container`, `*.pod`, `*.network`, `*.volume`, `*.kube`, `*.build` | `systemd` | Podman Quadlet units highlighted |
| `playbooks/**`, \`roles/\*/tasks | handlers | meta/**` ,  `group\_vars/**` ,  `host\_vars/\*\*` ,  `site.yml\` |
| `roles/*/templates/*.j2`, `*.j2`, `*.jinja` | `jinja` | jinja\_lsp + djlint |
| `helmfile.yaml`, `helmfile*.yaml(.gotmpl)`, `helmfile.d/*.yaml(.gotmpl)` | `helmfile` (other `*.yaml.gotmpl`: `helm`) | helm\_ls attaches (helm-ls lists `helmfile` as a filetype); Go-template highlighting via the helm parser |
| chart `templates/*.yaml` | `helm` | set by the helm extra |
| `*.tofu` / `*.tofuvars` | `opentofu` / `opentofu-vars` | tofu-ls; HCL parser reused |
| `terragrunt.hcl`, `root.hcl` | `hcl` | tofu fmt formatting |
| `nginx.conf`, `nginx/**/*.conf`, `conf.d/*.conf`, `sites-*/*`, `*.nginx` | `nginx` | nginx\_language\_server |
| `~/.ssh/config.d/*` | `sshconfig` | highlighting for split SSH configs |
| `*.mariadb.sql`, `*.mysql.sql`, `*.pg.sql`, `*.psql` | `sql` | the right sqlfluff dialect |
| `*.jq` | `jq` | jqls |
| `*.http` | `http` | filetype + Tree-sitter only (no REST client) |

To add a rule, add a line to the `pattern` table in that file. Patterns are Lua patterns matched against the full path; escape `.` and `-` with `%`.

## Step 6 — YAML schemas

Schemas give YAML completion, hover docs and errors before you apply anything. The yaml extra loads SchemaStore, which matches most DevOps files by name. `lua/plugins/devops-yaml.lua` adds the cases SchemaStore can't guess.

| Files | Schema | How it's applied |
| --- | --- | --- |
| compose, GitLab CI root file, helmfile, kustomization, Ansible playbooks/tasks, GitHub Actions, `.pre-commit-config.yaml`, Chart.yaml | SchemaStore catalog | automatic by file name |
| `**/k8s/**`, `**/kubernetes/**`, `**/manifests/**`, `**/deploy/**`, `*.k8s.yaml` | Kubernetes (yannh `master-standalone-strict/all.json`) | glob in `yaml.schemas` |
| `*.gitlab-ci.yml`, `.gitlab/ci/**`, `ci-templates/**` | GitLab CI schema from gitlab.com | glob in `yaml.schemas` |
| any other single file | whatever you name | modeline on line 1 |
| CRDs (cert-manager, ArgoCD, Istio, OpenShift …) | CRDs-catalog | kubeconform on save, not yamlls |

For a manifest outside those folders, put a modeline on its first line:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/master-standalone-strict/deployment-apps-v1.json
```

yamlls also knows custom YAML tags used in DevOps files, so they no longer show as errors: GitLab's `!reference`, CloudFormation's `!Ref`/`!Sub`/`!GetAtt` and friends, and Ansible's `!vault`/`!unsafe`. Key ordering warnings are off and Red Hat telemetry is disabled.

To check which schema a buffer uses, run `:LspInfo` and look at yamlls, or hover a key with `K`.

## Step 7 — DevOps plugins and key maps

The Ops commands sit under two which-key groups, `<leader>k` (Kubernetes/OpenShift) and `<leader>i` (infra as code). Each runs on the current file in a floating terminal that stays open, so you can read the output. The file is saved first. `<leader>` is `Space`.

| Keys | Action |
| --- | --- |
| `<leader>kk` | k9s full-screen in a float (cluster browser, logs, exec) |
| `<leader>kx` | pick kube context |
| `<leader>ka` / `kA` | `kubectl apply --dry-run=server -f` / real apply |
| `<leader>kd` | `kubectl diff -f` against the cluster |
| `<leader>kv` | kubeconform the file (strict) |
| `<leader>ko` / `kO` / `kp` | `oc apply --dry-run=server` / `oc apply` / current project |
| `<leader>ke` | `kubectl explain <kind> --recursive` for the file's kind |
| `<leader>ii` / `ip` / `iv` | tofu init / plan / validate + tflint |
| `<leader>iI` / `iP` | terraform init / plan |
| `<leader>ig` / `iG` | terragrunt plan / format check |
| `<leader>ih` | helm lint + template of the chart |
| `<leader>if` / `iF` | helmfile lint / diff |
| `<leader>ia` / `iA` | ansible syntax-check + ansible-lint / `--check --diff` dry run |
| `<leader>ta` | run the Ansible playbook/role (from the ansible extra) |
| `<leader>id` / `ic` / `in` / `is` | hadolint / compose config / nginx -t / trivy config scan |
| `<leader>cb` / `cB` (visual) | base64 decode / encode the selection (k8s Secrets) |
| `<leader>cj` | pretty-print JSON with jq (buffer or selection) |
| `<leader>cq` | set the sqlfluff dialect for this buffer |
| `<leader>W` | save without formatting |
| `Ctrl-h/j/k/l` | move between nvim splits **and** tmux panes (vim-tmux-navigator) |
| `<leader>qo` | toggle `Session.vim`, which tmux-resurrect uses to reopen nvim with its files |
| `<leader>gv` / `gV` / `gq` | Diffview: working tree / file history / close |
| `<leader>gg` | lazygit (LazyVim) |
| `<leader>D` | database UI (dadbod) for MariaDB/PostgreSQL connections |

The plugins behind these:

- **snacks.nvim** terminal (part of LazyVim) runs k9s and the commands, so nothing new to learn.
- **vim-tmux-navigator** pairs with the tmux config from earlier. Clear the screen inside tmux with `prefix C-l`.
- **vim-obsession** writes `Session.vim`. The global git ignore already excludes it.
- **diffview.nvim** for reviewing branches and MRs side by side.
- **vim-dadbod-ui** (sql extra) for databases. Put connections in `lua/plugins/local.lua`:

  ```lua
  vim.g.dbs = {
    { name = "pg-local", url = "postgres://postgres@localhost:5432/postgres" },
    { name = "maria-local", url = "mysql://root@127.0.0.1:3306/mysql" },
  }
  return {}
  ```
- **gitlab.nvim** is included but disabled. Set `enabled = true` in `devops-tools.lua` and export a `GITLAB_TOKEN` to review merge requests inside nvim.

## Completion — blink.cmp

Completion runs on [blink.cmp](https://cmp.saghen.dev/), LazyVim's default engine, made explicit with the `coding.blink` extra and `vim.g.lazyvim_cmp = "blink.cmp"`. `lua/plugins/completion.lua` holds only the changes to LazyVim's defaults.

| Key (insert mode) | Action |
| --- | --- |
| `Enter` | accept the selected item |
| `Ctrl-y` | select the first item and accept it |
| `Ctrl-Space` | open the menu, then toggle the docs window |
| `Ctrl-e` | close the menu and undo the preview |
| `Ctrl-n` / `Ctrl-p`, `Ctrl-j` / `Ctrl-k` | next / previous item (`Ctrl-k` with no menu: signature help) |
| `Ctrl-b` / `Ctrl-f` | scroll the docs window |
| `Tab` / `Shift-Tab` | jump between snippet fields |
| `:` then `Tab` / `Shift-Tab` | command-line completion; the menu opens by itself for `:` commands, not for `/` searches |

How it behaves:

- **Ranking:** exact matches first, then the Rust fuzzy score with typo tolerance, frecency (items you pick often) and proximity (words near the cursor). LSP items get +5, paths +3, snippets −1, buffer words −3.
- **Less noise:** LSP "Text" items are dropped. Snippets need 2 characters and don't show right after `.`, `:` or `(`. Buffer words need 3 characters, are capped at 8 and come from every visible buffer.
- **Preview:** nothing is written into the line while you move through the list; ghost text shows the selected item instead. With a snippet active nothing is preselected, so `Enter` stays a newline.
- **Windows:** rounded borders, a source column (`[LSP]`, `[Buffer]`, `[Snippets]`, `[dadbod]`), Tree-sitter-highlighted labels, docs after 150 ms. Signature help comes from blink; noice's popup for it is turned off so you only get one.
- **Paths:** hidden files are listed too (`.gitlab-ci.yml`, `.github/`).

**DevOps snippets** live in `nvim/snippets/` (VS Code format, loaded next to friendly-snippets): `k8s-deploy`, `k8s-svc`, `k8s-cm`, `k8s-ing`, `hf-release`, `bash-strict`, `trapcleanup`, `loghelpers`, `tfvar`, `tfout`, `tfbackend`, `dmulti`, `atask`, `aplay`, `gljob`. Add your own to the JSON files, or a new file listed in `package.json`.

## Step 8 — Automated tests

`nvim/tests/run.sh` checks all 32 cases end to end without opening the UI and exits with 1 on any failure. That makes it usable after every change, after `:Lazy update`, and in CI. Inside nvim, `:DevopsTest` runs the same checks and opens the report.

What one run does:

1. Copies `tests/fixtures/` (one small realistic file per language: playbook, `main.tf`, `main.tofu`, `terragrunt.hcl`, chart, helmfile, Deployment, OpenShift Route, Dockerfile, Containerfile, compose, Quadlet, `.gitlab-ci.yml`, script, Python, Go module, HTML, CSS, Jinja, Maven project, jq, Markdown, nginx, PHP, two SQL dialects, SSH config, Vim script, YAML, JSON, `.http`) to a temp dir, so your repo's configs don't influence the result.
2. Runs `:checkhealth` headless and prints any ERROR lines (informational).
3. For each fixture, opens it in headless nvim and checks four things:
   - **filetype** is the expected one (e.g. `yaml.gitlab`);
   - **Tree-sitter parser** loads for it;
   - **LSP** — waits up to 30 s (120 s for jdtls) until every expected server has attached;
   - **formatter** is available to conform and **linter** is configured for that filetype in nvim-lint, with its binary executable.
4. Prints a table and writes `~/.local/state/nvim/devops-test-report.txt`:

   ```text
   PASS  gitlab/.gitlab-ci.yml                    lsp        gitlab_ci_ls
   PASS  k8s/route.yaml                           linter     kubeconform
   WARN  tofu/main.tofu                           cli        tofu-ls not installed
   FAIL  nginx/site.conf                          lsp        nginx_language_server not attached (got: )
   
   118 passed · 1 warnings · 1 failed
   ```

A case that needs an external CLI (`terraform`, `tofu`, `tofu-ls`, `go`, `java`) turns into WARN, not FAIL, when that CLI is missing. Accepted alternatives are written `a|b` (for example `basedpyright|pyright`), so switching a default in `options.lua` doesn't break the test.

Commands:

```bash
nvim/tests/run.sh                       # test
nvim/tests/run.sh --install             # install/update everything first, then test
DEVOPS_TEST_ONLY=k8s nvim/tests/run.sh  # only cases whose path contains "k8s"
```

**Clean-machine test and CI.** `nvim/tests/Dockerfile` builds Ubuntu 24.04, creates a normal user, runs the full `install.sh`, then the tests. The image only builds if everything passes. `.gitlab-ci.yml` at the repo root runs that build in GitLab (Docker-in-Docker) whenever `nvim/`, `install.sh` or `shell/` change.

```bash
docker build -f nvim/tests/Dockerfile -t nvim-devops-test .   # or: podman build …
```

To add a language: add a fixture under `tests/fixtures/<lang>/` and one line to `M.cases` in `lua/devops/test.lua`.

## Step 9 — Daily use, updating, troubleshooting

Most of the time you only need the LazyVim basics plus the `<leader>k`/`<leader>i` groups. When something doesn't attach or format, `:LspInfo`, `:ConformInfo` and `:DevopsTest` tell you which piece is missing.

| Keys / command | Action |
| --- | --- |
| `<Space>` (wait) | which-key: every key map, grouped |
| `<leader><space>` / `<leader>/` | find file / live grep (snacks picker) |
| `gd`, `gr`, `K`, `<leader>ca`, `<leader>cr` | definition, references, hover, code action, rename |
| `]d` / `[d`, `<leader>xx` | next/previous diagnostic, Trouble list |
| `<leader>cf`, `<leader>uf` | format now, toggle format-on-save |
| `<leader>e` | file explorer |
| `<leader>gg` | lazygit |
| `<leader>ft` | terminal |
| `:Mason`, `:Lazy`, `:LazyExtras` | tools, plugins, extras browser |

**Updating.** Run `:Lazy update` and `:MasonUpdate`, or headless `nvim/tests/run.sh --install`. Then run `nvim/tests/run.sh`, and commit `lazy-lock.json` if it passes. To roll back plugins, `git checkout` the old `lazy-lock.json` and run `:Lazy restore`.

**Troubleshooting.**

- *Parser install hangs on "Compiling".* The tree-sitter CLI or C compiler is missing: `tree-sitter --version`, `cc --version`.
- *A server is not attached.* Run `:LspInfo`, then `:Mason` to check it is installed. `:LspLog` shows why it exited. Python-based tools (ansible-lint, sqlfluff, nginx-language-server) need `python3-venv`.
- *Wrong server or none on a YAML file.* Check `:set ft?` against Step 5, and add a pattern if needed.
- *Formatter mangled a template.* Exclude that filetype in `devops-format-lint.lua`, or save once with `<leader>W`.
- *kubeconform never reports.* The file needs top-level `apiVersion:` and `kind:`, and `kubeconform` must be on PATH.
- *Slow startup.* `:Lazy profile`. The heavy parts (jdtls, trivy) only load for their filetypes or projects.
- *Clipboard.* The config uses `win32yank.exe` if present, else the UTF-8-safe `pbcopy`/`pbpaste` scripts from the dotfiles.

**First run.** This config was written and reviewed but not yet executed on a machine. The first `./install.sh` with its built-in test run is the real verification; the FAIL lines tell you exactly what to fix.

## Sources

- [LazyVim — requirements and getting started](https://lazyvim.org/)
- [LazyVim extra: lang.terraform](https://lazyvim.org/extras/lang/terraform) · [lang.helm](https://lazyvim.org/extras/lang/helm) · [lang.ansible](https://www.lazyvim.org/extras/lang/ansible)
- [nvim-treesitter (main branch requirements)](https://github.com/nvim-treesitter/nvim-treesitter)
- [kickstart.nvim issue #1894 — tree-sitter-cli requirement](https://github.com/nvim-lua/kickstart.nvim/issues/1894)
- [mason-lspconfig server mapping](https://github.com/williamboman/mason-lspconfig)
- [nvim-lint linters](https://github.com/mfussenegger/nvim-lint)
- [conform.nvim formatters](https://github.com/stevearc/conform.nvim)
- [gitlab-ci-ls](https://docs.rs/crate/gitlab-ci-ls/1.2.1)
- [OpenTofu language server (tofu-ls)](https://github.com/opentofu/tofu-ls)
- [Formatting OpenTofu files with LazyVim (tofu fmt in conform)](https://dev.to/miry/effortless-formatting-for-opentofu-files-with-lazyvim-4d10)
