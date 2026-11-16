# wsl-dotfiles — bash *and* zsh for WSL Ubuntu 24.04

A single command sets up two shells that work the same way:

- **bash + ble.sh**: autosuggestions, syntax highlighting and a completion menu
- **zsh + oh-my-zsh** with plugins for:
  - VCS & cloud: git, docker, docker-compose, kubectl, oc, helm, zsh-helmfile, terraform, aws, gcloud, azure, ansible, jfrog
  - languages: python, pip, node, npm, yarn, golang, rust, drush
  - productivity: sudo, extract, z, history, command-not-found, vscode, ssh, starship, tldr, web-search
  - community: fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting

Both share one set of **aliases, functions and environment** (`~/.config/shell/`), so a change shows up in both.
Both also use the same tools: **fzf · zoxide · starship · atuin · eza · tmux**, plus bat, fd, ripgrep, lazygit, neovim and fzf-git.sh.
DevOps CLIs: **kubectl · helm (+helm-diff) · helmfile · terraform · ansible**. Also delta (git pager) and tldr (tlrc).
The aws, gcloud, az, oc, jf and drush plugins only add completion and aliases. They switch on once you install the matching CLI.

## Quick start

```bash
# inside WSL (unpack in WSL rather than in Windows Explorer so files keep LF line endings)
cd ~ && tar -xzf /mnt/c/Users/<you>/Downloads/wsl-dotfiles.tar.gz
cd ~/wsl-dotfiles && ./install.sh                 # add --default-shell=zsh to switch right away
exec zsh -l        # or: exec bash
```

On Windows: `winget install DEVCOM.JetBrainsMonoNerdFont`, then restart Windows Terminal.
The new profiles **"Ubuntu-24.04 · bash"**, **"· zsh"** and **"· tmux"** already use that font and the Tokyo Night scheme.

| Flag | Effect |
|---|---|
| `--update` | re-download every tool / pull every plugin |
| `--default-shell=zsh` / `=bash` | also set the login shell (runs `chsh`, asks for your password) |
| `--no-zsh` · `--no-devops` · `--no-nvim` · `--no-wt` | skip zsh+oh-my-zsh · DevOps CLIs · neovim · Windows Terminal profiles |
| `--links-only` | only (re)link the dotfiles |
| `--wsl-conf` | set `appendWindowsPath=false` (much faster completion; VS Code stays reachable) |

You can run the script again at any time. Existing files are moved to `*.bak.<timestamp>` before they are linked.

## Switching shells

| How | What it does |
|---|---|
| `tozsh` / `tobash` | replaces the current shell right now (`exec zsh -l` / `exec bash -l`); nothing else changes |
| Windows Terminal profile | **· bash** or **· zsh** tab; both can stay open side by side |
| `shell-switch` | shows the default and the running shell |
| `shell-switch zsh` / `bash` / `toggle` | changes the default login shell (`chsh`) |

## tmux

Start it with the **"Ubuntu-24.04 · tmux"** profile or with `tmux new -A -s main`. Prefix = `Ctrl-b`.

| Key | Action |
|---|---|
| `prefix Space` / `Alt-Space` | **which-key menu**: groups for sessions, windows, panes, tools and plugins; press the letter to run an entry |
| `prefix ?` | **fuzzy search of every key binding**, with descriptions, in a popup |
| `prefix o` | session manager (tmux-sessionx: fzf + zoxide dirs + preview) |
| `prefix C-s` / `C-r` | save / restore sessions now (they are also saved every 10 min and restored when tmux starts) |
| `C-h/j/k/l` | move between nvim splits and tmux panes (vim-tmux-navigator; also add the plugin to nvim) |
| `prefix t` / `g` | popup shell / lazygit |
| `prefix u` · `prefix F` | open a URL from the pane · tmux-fzf |
| `prefix I` · `U` | TPM install / update plugins |

Plugins: tpm, tmux-sensible, tmux-resurrect, tmux-continuum, tmux-sessionx, vim-tmux-navigator,
tmux-yank, tmux-prefix-highlight, tmux-fzf-url, tmux-fzf, tmux-open.
Edit the menu in `config/tmux/which-key.tmux`. Each custom binding has a description (`bind -N`), so it appears in `prefix ?`.
For nvim to come back with its open files after a restore, save sessions in nvim (persistence.nvim / `:mksession`).

## git

`config/git/gitconfig` → `~/.gitconfig`. Every setting has a comment saying what it does, plus alternatives with their effect.
Main choices:
- `pull.rebase`, `push.autoSetupRemote`
- `fetch.prune`, `merge.conflictStyle = zdiff3`, `diff.algorithm = histogram`, `rerere`
- delta as the pager
- `core.autocrlf = input`, and `fileMode = false` only for repos under `/mnt/`

Name, e-mail and the credential helper go into `~/.gitconfig.local`. install.sh takes them from an existing `~/.gitconfig` or asks you, and uses the Windows Git Credential Manager if Git for Windows is installed.
Git aliases: `git lg / st / undo / amend / wip / unwip / gone / who / aliases`.

## Layout

```
shell/env.sh          → ~/.config/shell/   shared by BOTH shells: PATH, EDITOR, fzf opts
shell/functions.sh                         shared: ls/lt/u/gcob/glog/gstash/ide_tmux/…
shell/aliases.sh                           shared: navigation, eza, general, apt, WSL
shell/omz-compat.sh                        bash only: oh-my-zsh git/helm/helmfile/terraform/ansible aliases

bash/bashrc, bashrc.d/{10-env,20-tools,40-functions,50-aliases,60-bindkeys}.bash, blerc, inputrc
zsh/zshrc,   zshrc.d/{10-env,30-source,40-functions,50-aliases,60-bindkeys}.zsh

config/starship.toml · config/atuin/config.toml
config/tmux/tmux.conf · which-key.tmux    → ~/.config/tmux/  (plugins in ~/.config/tmux/plugins)
config/git/gitconfig · ignore · wsl-mnt   → ~/.gitconfig, ~/.config/git/
bin/open · pbcopy · pbpaste · shell-switch · tmux-keys → ~/.local/bin
windows-terminal/  fragment with bash / zsh / tmux profiles and the Tokyo Night scheme
~/.bashrc.local · ~/.zshrc.local           machine-specific, not in the repo
```

## Keys (same in both shells)

| Key | Action |
|---|---|
| `↑` / `↓` | prefix history search |
| `→` / `End` | accept autosuggestion (zsh: also `Ctrl-Space`) |
| `Tab` | completion menu (zsh: fzf-tab with previews) |
| `Ctrl-R` | atuin |
| `Ctrl-T` / `Alt-C` / `**<Tab>` | fzf file / cd / completion |
| `Ctrl-G f` · `b` · `l` | your pickers: file path · switch branch · commit hash |
| `Ctrl-G Ctrl-F/B/T/R/H/S/L` | fzf-git.sh |

DevOps aliases: `k` · `h hin hup hun hse` · `hf hfa hfd hfs hft` · `tf tfi tfp tfa tfv tff …` · `a aplaybook ainv agal aval …`.
In bash, tab completion works for the aliases as well. Completion scripts are cached in `~/.cache/bash-completion` so startup stays fast.

## Differences from the macOS setup

- `h` is `history` (from the history plugin) and not `helm`; the helm shortcuts `hin`, `hup`, `hun` and `hse` still work.
- The `z` plugin keeps its own database alongside zoxide. Remove it from the list if you only use `cd`/`cdi`.
- `cd` is zoxide's own `cd` (`zoxide init --cmd cd`), and `cdi` opens the picker.
- zsh-syntax-highlighting is loaded once, at the very end of `~/.zshrc`. On the Mac it was loaded twice: as a plugin and again from Homebrew.
- Up/Down bindings now cover both `^[[A` and `^[OA`. oh-my-zsh switches the arrow keys into a mode where they send `^[OA`, so the old `^[[A` binding alone never fired.
- Left out because they only work on macOS: `brew` plugin, `res1-3` (displayplacer), `networkQuality`. Replacements: `apti/apts/aptu`, `speedtest-cli`.
- Bugs fixed while porting:
  - `glog` returned `*` and not the commit hash.
  - The `gcob` preview showed nothing.
  - The `gstash` preview passed the stash name with a trailing colon, and its "Apply" also dropped the stash. Apply now keeps it, and there's a separate Drop option.
  - `gcmb` could pick up `*` from the current branch.
  - `dux` used `sort -n` on human-readable sizes.
  - `keep_delete` with an empty name would have deleted everything.
  - `^p hist-widget` was dropped, because that widget isn't defined anywhere.

## Troubleshooting

- bash without ble.sh: `NO_BLE=1 bash`
- Slow completion: `./install.sh --wsl-conf`, then run `wsl --shutdown`.
- helm 4: helmfile and helm-diff are installed against helm 3 (`get-helm-3`).
- Share history with the Mac: `atuin login`, then `atuin sync`.
