# Neovim — LazyVim for DevOps / SRE on WSL

This folder is a complete Neovim config: [LazyVim](https://www.lazyvim.org/) plus LSP, formatter, linter, Tree-sitter and completion for DevOps work, tuned for **Ubuntu 24.04 in WSL** with **Windows Terminal** on Windows 11.
It lives in `~/.config/nvim` (a link to this folder). Everything outside that folder (shells, tmux, git, Windows) belongs to the rest of the bundle and is not needed here.

## Install or replace only the nvim config

```bash
cd ~/wsl-dotfiles
./install-nvim.sh                         # back up ~/.config/nvim, link this config, install plugins + tools, run tests
./install-nvim.sh --appname nvim-devops   # side by side: NVIM_APPNAME=nvim-devops nvim  (old config untouched)
./install-nvim.sh --copy                  # copy instead of link (you can delete the bundle afterwards)
./install-nvim.sh --fresh                 # also back up plugins/state/cache for a clean reinstall
./install-nvim.sh --no-bootstrap          # only put the config in place
./install-nvim.sh --dry-run               # show what would happen
```

`install-nvim.sh` changes **only** the nvim config folder (and, with `--fresh`, nvim's data/state/cache folders). Everything it replaces is moved to `<path>.bak.<timestamp>`, and the script prints the command to undo. Running it again is safe: an existing link to the bundle is kept.
It installs no system packages. It reports missing tools and keeps going. If you need them, `./install.sh` installs them (Node, Go, JDK 21, tree-sitter CLI, tofu, terragrunt, oc, kubeconform, k9s).

Requirements: **Neovim ≥ 0.11.2**, git, ripgrep, fd, a C compiler, curl/unzip, Node (most LSPs), a Nerd Font in Windows Terminal (JetBrainsMono Nerd Font).

## Layout

```
init.lua                        entry point
lua/config/lazy.lua             lazy.nvim bootstrap + every LazyVim extra (version-controlled, not :LazyExtras)
lua/config/options.lua          options, LSP choices (basedpyright, intelephense), WSL clipboard
lua/config/keymaps.lua          extra maps (base64, jq, SQL dialect, :JdtlsReset)
lua/config/filetypes.lua        helm / helmfile / gitlab-ci / ansible / compose / jinja detection
lua/plugins/devops-lsp.lua      LSP servers, Mason tools, Tree-sitter parsers
lua/plugins/devops-yaml.lua     yamlls schemas (k8s, OpenShift, GitLab, compose, …)
lua/plugins/devops-format-lint.lua  conform + nvim-lint (kubeconform, sqlfluff, trivy, …)
lua/plugins/devops-tools.lua    k9s, kubectl/oc, infra-as-code runners, tmux navigation, diffview
lua/plugins/completion.lua      blink.cmp — keys, ranking, sources
snippets/                       own DevOps snippets (VS Code format)
lua/devops/                     headless install + tests (:DevopsInstall, :DevopsTest)
tests/                          run.sh, fixtures, Dockerfile for a clean-machine run
lua/plugins/local.lua           your own machine-only additions (git-ignored)
```

## Languages

| Area | LSP | Format | Lint |
|---|---|---|---|
| Kubernetes / OpenShift YAML | yamlls + schemas | prettier | yamllint, kubeconform |
| Helm charts, helmfile | helm_ls | — | — |
| Ansible | ansiblels | — | ansible-lint (through ansiblels) |
| Terraform / OpenTofu / Terragrunt | terraformls / tofu_ls | terraform_fmt / tofu_fmt | tflint |
| Docker, Podman, Compose | dockerls, compose LS | — | hadolint, yamllint |
| GitLab CI | gitlab_ci_ls, yamlls | prettier | yamllint |
| bash / sh | bashls | shfmt | shellcheck |
| Python | basedpyright, ruff | ruff | ruff |
| Go | gopls | goimports, gofumpt | golangci-lint |
| Java | jdtls (JDK 21+) | — | — |
| PHP | intelephense | — | — |
| HTML / CSS / Jinja | html, cssls, emmet, jinja_lsp | prettier, djlint | djlint |
| JSON / jq | jsonls, jqls | prettier | — |
| Markdown | marksman | prettier | markdownlint |
| SQL (MariaDB / PostgreSQL) | — (dadbod completion) | sqlfluff | sqlfluff |
| nginx, Vim script, SSH config | nginx LS, vimls | — | vint |

`<leader>uf` toggles format-on-save. `:LspInfo`, `:ConformInfo`, `:Mason` show what is active.

## Completion (blink.cmp)

[blink.cmp](https://cmp.saghen.dev/) is LazyVim's completion engine. `lua/plugins/completion.lua` tunes it for heavy use.

### Keys

| Key (insert mode) | Action |
|---|---|
| `Enter` | accept the selected item |
| `Ctrl-y` | select the first item and accept it |
| `Ctrl-Space` | open the menu · then toggle the docs window |
| `Ctrl-e` | close the menu and undo the preview |
| `Ctrl-n` / `Ctrl-p`, `Ctrl-j` / `Ctrl-k` | next / previous item |
| `Ctrl-k` (no menu open) | signature help on / off |
| `Ctrl-b` / `Ctrl-f` | scroll the docs window |
| `Tab` / `Shift-Tab` | next / previous item · else jump between snippet fields · else Tab |
| `Esc` (or a CapsLock tap) | close the menu and leave insert mode |

| Key (command line) | Action |
|---|---|
| `Tab` / `Shift-Tab` | open the menu, next / previous item |
| `Ctrl-y` / `Ctrl-e` | accept / cancel |
| `←` / `→` | move the cursor (not the menu) |

The menu opens by itself for `:` commands. For `/` and `?` searches it only completes words from the buffer when you press Tab.

### Why these keys work on Windows 11

Keys travel Windows → AutoHotkey → Windows Terminal → (tmux) → nvim. Each layer can swallow some, so completion only uses keys that pass all of them:

- **No `Ctrl+Shift+…`:** Windows Terminal uses those for copy, paste, tabs and search.
- **No `Alt+Shift+…`:** the bundle's Windows Terminal pane and layout keys.
- **No `Alt+Space`:** tmux which-key menu (Windows Terminal passes it through on purpose).
- **No `Ctrl+S`:** LazyVim's save.
- **No Win / Hyper (CapsLock) combos:** AutoHotkey handles them. A CapsLock tap is `Esc`, which closes the menu like a normal Esc.
- **`Ctrl+Space`:** Windows Terminal sends a NUL byte. nvim reads it as `<C-Space>`; `<C-@>` is mapped too, for terminals that report it that way.
- **`Ctrl+J` / `Ctrl+K`:** completion uses them only in insert mode. In normal mode they keep moving between nvim splits and tmux panes (vim-tmux-navigator).

If a key does nothing, check what arrives: in insert mode press `Ctrl-v` and then the key. `^@` means Ctrl+Space arrived. Nothing at all means Windows or Windows Terminal took it. A common cause for Ctrl+Space is an input-language switch hotkey (Settings → Time & language → Typing → Advanced keyboard settings → Input language hot keys).

### Ranking and sources

- Exact matches come first, then the Rust fuzzy score: typo-tolerant, boosted for items you pick often (frecency) and words near the cursor (proximity).
- Source weights: LSP +5, path +3, snippets −1, buffer words −3.
- LSP "Text" filler items are dropped.
- Snippets need 2 characters and stay hidden right after `.`, `:` or `(`.
- Buffer words need 3 characters, show at most 8, come from every visible buffer and skip files over 20,000 lines.
- Paths include hidden files (`.gitlab-ci.yml`, `.github/`).
- Lua gets lazydev, SQL buffers get dadbod (table and column names), both from LazyVim.

### Display

- Moving through the list doesn't rewrite the line; ghost text previews the selected item.
- While a snippet is active nothing is preselected, so `Enter` still makes a newline.
- Rounded menu with a source column (`[LSP]`, `[Buffer]`, `[Snippets]`, `[Path]`, `[dadbod]`) and labels highlighted like code.
- The docs window opens after 150 ms.
- Signature help comes from blink. noice's own signature popup is turned off, so only one appears.

### Snippets

Own snippets live in `snippets/` next to friendly-snippets:

| Filetype | Prefixes |
|---|---|
| YAML / Helm / helmfile | `k8s-deploy`, `k8s-svc`, `k8s-cm`, `k8s-ing`, `hf-release` |
| bash / sh / zsh | `bash-strict`, `trapcleanup`, `loghelpers` |
| Terraform / OpenTofu | `tfvar`, `tfout`, `tfbackend` |
| Dockerfile | `dmulti` |
| Ansible | `atask`, `aplay` |
| GitLab CI | `gljob` |

Add a snippet to the matching JSON file, or add a new file and list it in `snippets/package.json`.

## DevOps keys

`<leader>` is `Space`. Press it and wait for which-key to list everything.

| Keys | Action |
|---|---|
| `<leader>kk` · `kx` · `kn` | k9s · switch kube context · namespaces |
| `<leader>ka` / `kA` · `kd` · `kv` · `ke` | dry-run apply / apply · diff vs cluster · kubeconform · explain kind |
| `<leader>ko` / `kO` · `kp` | OpenShift dry-run apply / apply · current project |
| `<leader>ii` / `ip` / `iv` | tofu init / plan / validate + tflint |
| `<leader>iI` / `iP` · `ig` / `iG` | terraform init / plan · terragrunt plan / format check |
| `<leader>ih` · `if` / `iF` | helm lint + template · helmfile lint / diff |
| `<leader>ia` / `iA` | ansible syntax + lint / check mode |
| `<leader>id` · `ic` · `in` · `is` | hadolint · compose validate · nginx -t · trivy |
| `<leader>cb` / `cB` (visual) | base64 decode / encode the selection |
| `<leader>cj` · `cq` | jq pretty-print · SQL dialect for sqlfluff |
| `<leader>gv` / `gV` / `gq` | Diffview open / file history / close |
| `<leader>fY` · `fK` | clipboard history · all shell/tmux/Windows shortcuts |
| `<leader>W` | write without formatting |
| `Ctrl-h/j/k/l` (normal) | move between nvim splits and tmux panes |

## WSL specifics

- **Clipboard:** yank and paste use the Windows clipboard (`clipboard=unnamedplus`): `win32yank.exe` if it is on the PATH, otherwise the bundle's UTF-8-safe `pbcopy` / `pbpaste`. The bundle's clipboard history sees those copies too.
- **Files under `/mnt/c`** work, but LSPs and file watchers are much slower there. Keep repos in the Linux home (`~/work/…`).
- **Fuzzy matcher:** blink.cmp downloads a prebuilt Rust library once (on first start). Without network it falls back to the Lua matcher and shows a warning.

## Tests

```bash
tests/run.sh                    # every language + completion: filetype, parser, LSP, formatter, linter
tests/run.sh --install          # install plugins, parsers and Mason tools first
DEVOPS_TEST_ONLY=k8s tests/run.sh   # only cases whose path contains "k8s" ("completion" for blink)
```

`tests/Dockerfile` runs the same tests on a clean Ubuntu 24.04 (build instructions in its header), and `.gitlab-ci.yml` at the bundle root runs it in CI.

Inside nvim: `:DevopsTest`, `:DevopsInstall`. The result is also written to `~/.local/state/nvim/devops-test-report.txt`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `client jdtls quit with exit code 13` | `:JdtlsReset`, reopen the `.java` file. `java -version` must be 21+; `JAVA_HOME` is set by the bundle's `env.sh` |
| Completion warns about the Lua fuzzy matcher | network was down at first start: `:Lazy build blink.cmp` |
| A key does nothing | see *Why these keys work on Windows 11* above (`Ctrl-v` test) |
| LSP missing for a filetype | `:LspInfo`, then `:Mason` to (re)install; `:set ft?` to check the filetype |
| Format on save does something unwanted | `<leader>uf` toggles it, `<leader>W` writes once without it |
| Plugin update broke something | `git checkout` the old `lazy-lock.json`, then `:Lazy restore` |
| Start over | `./install-nvim.sh --fresh` |
