# devim — the new nvim config side by side

`nvim` keeps starting your current config. `devim` starts the latest config from the wsl-dotfiles bundle.
Your current `~/.config/nvim` stays as it is.

## 1. Install the new config under its own name

```bash
cd ~/wsl-dotfiles
./install-nvim.sh --appname devim        # → ~/.config/devim, plugins in ~/.local/share/devim
```

## 2. Add the alias (bash and zsh)

`~/.bashrc.local` and `~/.zshrc.local` are the right place, because this is specific to this machine:

```bash
echo "alias devim='NVIM_APPNAME=devim nvim'" >> ~/.bashrc.local
echo "alias devim='NVIM_APPNAME=devim nvim'" >> ~/.zshrc.local
exec $SHELL -l
```

| Command | Config | Plugins, Mason tools, sessions, undo |
|---|---|---|
| `nvim` | `~/.config/nvim` (current) | `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` |
| `devim` | `~/.config/devim` (latest) | `~/.local/share/devim`, `~/.local/state/devim`, `~/.cache/devim` |

The two don't share anything, so trying `devim` can't break `nvim`.

## Optional: a wrapper script instead of the alias

Git, tmux popups and scripts don't see shell aliases. A small script on the PATH works everywhere, and you don't need the alias with it:

```bash
printf '#!/bin/sh\nNVIM_APPNAME=devim exec nvim "$@"\n' > ~/.local/bin/devim
chmod +x ~/.local/bin/devim
```

To make devim the editor for git and the shell, add this to the same `.local` files:

```bash
export EDITOR=devim VISUAL=devim
```

## Tests and updates

| Task | Command |
|---|---|
| Run the tests | `NVIM_APPNAME=devim ~/.config/devim/tests/run.sh`, or `:DevopsTest` inside devim |
| Update from a newer bundle | `./install-nvim.sh --appname devim` (keeps the link and syncs plugins) |

## Switch over for good

```bash
./install-nvim.sh            # backs up ~/.config/nvim and puts the new config there
```

After that, `devim` can stay or go. To remove it completely:

```bash
rm -rf ~/.config/devim ~/.local/share/devim ~/.local/state/devim ~/.cache/devim ~/.local/bin/devim
# and delete the alias line from ~/.bashrc.local and ~/.zshrc.local
```
