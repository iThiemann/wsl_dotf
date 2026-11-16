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
export GOPATH="$HOME/go"
path_prepend "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/.atuin/bin" "$HOME/.local/bin"

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

# --- bat / man / eza / grep (Tokyo Night, same as the Mac) -------------------------
# tokyonight_night is not built into bat → install.sh puts the theme into
# ~/.config/bat/themes and rebuilds the cache; fall back if it isn't there yet.
export EZA_CONFIG_DIR="$HOME/.config/eza"           # theme.yml lives here
if command -v bat >/dev/null 2>&1; then
  if bat --list-themes 2>/dev/null | grep -qx 'tokyonight_night'; then
    export BAT_THEME=tokyonight_night
  else
    export BAT_THEME=OneHalfDark
  fi
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'
fi
# AstroNVim / nvim for man pages ->  export MANPAGER='nvim +Man!'

export GREP_COLORS='ms=01;38;2;247;118;142:mc=01;38;2;247;118;142:sl=38;2;169;177;214:cx=38;2;192;202;245:fn=38;2;122;162;247:ln=38;2;224;175;104:bn=38;2;187;154;247:se=38;2;125;207;255'

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
fi

# --- language tool managers (only when installed) -------------------------------------
if [[ -d $HOME/.nvm ]]; then export NVM_DIR="$HOME/.nvm"; fi

export PNPM_HOME="$HOME/.local/share/pnpm"           # Linux location (Mac: ~/Library/pnpm)
[[ -d $PNPM_HOME ]] && path_prepend "$PNPM_HOME"

[[ -d $HOME/.rbenv/shims ]] && path_prepend "$HOME/.rbenv/shims"
export PATH

# --- fzf (same values as on the Mac) -------------------------------------------------
# no --type f → Ctrl-T offers files AND directories, like on the Mac
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --strip-cwd-prefix'

# Fast directory search for huge monorepos
# export FZF_ALT_C_COMMAND='fd --type d --hidden --follow \
#   --exclude .git --exclude node_modules --exclude .terraform \
#   --exclude .venv --exclude venv --exclude __pycache__ \
#   --exclude dist --exclude build --exclude target \
#   --strip-cwd-prefix'

# alternative colour sets:
#   --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7,fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
#   --color=fg:#c0caf5,bg:-1,hl:#bb9af7,fg+:#c0caf5,bg+:-1,hl+:#7dcfff,info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
#   --color=fg:#CBE0F0,bg:#011628,hl:#B388FF,fg+:#CBE0F0,bg+:#143652,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED
export FZF_DEFAULT_OPTS='
  --height=40%
  --layout=reverse
  --border rounded
  --cycle
  --margin 1
  --ansi
  --info=inline
  --prompt="❯ "
  --pointer="▶"
  --marker="✓"
  --bind=ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
  --bind=ctrl-f:preview-page-down,ctrl-b:preview-page-up
  --bind=ctrl-/:toggle-preview
  --color=fg:#CBE0F0,bg:-1,hl:#B388FF,fg+:#CBE0F0,bg+:-1,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED
'

# preview script for files AND directories — also used by ** completion,
# gcof and _fzf_comprun (functions.sh). Defined here because the OPTS below need it.
_fzf_preview_cmd() {
  cat <<'EOF'
p={}

[ -n "$p" ] || {
  echo "(no selection)"
  exit 0
}

if [ -d "$p" ]; then
  if command -v eza >/dev/null 2>&1; then
    eza -la \
      --group-directories-first \
      --icons=always \
      --color=always \
      --git \
      -- "$p" 2>/dev/null | head -200
  else
    ls -lah -- "$p" 2>/dev/null | head -200
  fi
elif [ -r "$p" ]; then
  if command -v bat >/dev/null 2>&1; then
    bat \
      --style=numbers,changes,header \
      --color=always \
      --paging=never \
      --line-range :400 \
      -- "$p" 2>/dev/null
  else
    sed -n "1,400p" "$p" 2>/dev/null
  fi
else
  echo "(no preview) $p"
fi
EOF
}
_fzf_preview() { _fzf_preview_cmd; }

export FZF_CTRL_T_OPTS="
  --preview='$(_fzf_preview_cmd)'
  --preview-window=right,60%,border-left
"
export FZF_ALT_C_OPTS="
  --preview='$(_fzf_preview_cmd)'
  --preview-window=right,60%,border-left
"
