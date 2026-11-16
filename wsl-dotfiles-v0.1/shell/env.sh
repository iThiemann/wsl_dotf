# ==============================================================================
# ~/.config/shell/env.sh — environment shared by bash AND zsh
# ==============================================================================

path_prepend() {
  local d
  for d in "$@"; do
    [[ -d $d && ":$PATH:" != *":$d:"* ]] && PATH="$d:$PATH"
  done
}
# last one listed ends up first
path_prepend "$HOME/.cargo/bin" "$HOME/.atuin/bin" "$HOME/.local/bin"

# VS Code from Windows, also when appendWindowsPath=false
__dot_add_vscode() {
  [[ -n ${ZSH_VERSION-} ]] && setopt local_options null_glob
  command -v code >/dev/null 2>&1 && return
  local d
  for d in /mnt/c/Users/*/AppData/Local/Programs/"Microsoft VS Code"/bin; do
    [[ -d $d ]] && { PATH="$PATH:$d"; return; }
  done
}
__dot_add_vscode
unset -f __dot_add_vscode
export PATH

export IS_WSL=0
[[ -n ${WSL_DISTRO_NAME-} ]] && IS_WSL=1

export EDITOR=nvim VISUAL=nvim
export PAGER=less
export LESS='-R -F -i -M -j.3'
export LANG="${LANG:-C.UTF-8}"

if command -v bat >/dev/null 2>&1; then
  export BAT_THEME='OneHalfDark'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'
fi

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
fi

# --- fzf ---------------------------------------------------------------------
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Tokyo Night colours (match rg / tmux / starship / Windows Terminal scheme)
export FZF_DEFAULT_OPTS="\
--height=60% --layout=reverse --border --info=inline \
--bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-/:toggle-preview' \
--color=fg:#c0caf5,bg:-1,hl:#ff9e64,fg+:#c0caf5,bg+:#283457,hl+:#ff9e64 \
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a \
--color=header:#9ece6a,border:#27a1b9"

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :300 {} 2>/dev/null || eza --tree --level=2 --color=always --icons=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=always {} | head -200'"

# --- node (only if nvm is installed) ------------------------------------------
if [[ -d $HOME/.nvm ]]; then export NVM_DIR="$HOME/.nvm"; fi
