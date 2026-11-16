# wsl_dotf

Personal dotfiles for my WSL (Ubuntu) environment.

## Contents

| Folder / File        | Purpose                                  |
|----------------------|------------------------------------------|
| `zsh/`               | `.zshrc`, aliases, functions, prompt     |
| `git/`               | `.gitconfig`, global gitignore           |
| `nvim/`              | Neovim config (`~/.config/nvim`)         |
| `tmux/`              | `.tmux.conf`                             |
| `bin/`               | Personal scripts added to `$PATH`        |
| `install.sh`         | Symlinks everything into place           |

> Adjust this table to match the actual folders.

## Requirements

- WSL 2 with Ubuntu (or another Debian-based distro)
- `git`, `zsh`, `curl`
- Optional: `neovim`, `tmux`, `fzf`, `eza`, `atuin`

```bash
sudo apt update && sudo apt install -y git zsh curl
```

## Installation

```bash
git clone <repo-url> ~/dev/bdr/wsl_dotf
cd ~/dev/bdr/wsl_dotf
./install.sh          # or symlink manually, see below
chsh -s "$(which zsh)"
```

### Manual symlinks

```bash
ln -sf ~/dev/bdr/wsl_dotf/zsh/.zshrc      ~/.zshrc
ln -sf ~/dev/bdr/wsl_dotf/git/.gitconfig  ~/.gitconfig
ln -sf ~/dev/bdr/wsl_dotf/tmux/.tmux.conf ~/.tmux.conf
ln -sfn ~/dev/bdr/wsl_dotf/nvim           ~/.config/nvim
```

## Machine-specific settings

Anything secret or machine-specific goes in `*.local` files, which are git-ignored:

- `~/.zshrc.local`: sourced at the end of `.zshrc`
- `~/.gitconfig.local`: included via `[include] path = ~/.gitconfig.local`

## Git defaults

```ini
[init]
    defaultBranch = main
```

## Updating

```bash
cd ~/dev/bdr/wsl_dotf
git pull
```
