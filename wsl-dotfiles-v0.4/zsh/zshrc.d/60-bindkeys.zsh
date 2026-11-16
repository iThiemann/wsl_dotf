# ==============================================================================
# 60-bindkeys.zsh — bindkey / zle (same keys as the bash setup)
#
#   Up / Down       prefix history search        Ctrl-R   atuin
#   Ctrl-T / Alt-C  fzf file / cd                Tab      fzf-tab menu
#   Ctrl-G f/b/l    file path / switch branch / commit hash
#   Ctrl-G Ctrl-F/B/T/R/H/S/L   fzf-git.sh
#   → / End         accept suggestion            Ctrl-Space accept suggestion
# ==============================================================================

# Up/Down: both escape sequences — oh-my-zsh switches the terminal to
# application mode, where the arrows send ^[OA / ^[OB instead of ^[[A / ^[[B
bindkey '^[[A' history-search-backward
bindkey '^[OA' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[OB' history-search-forward

bindkey '^ ' autosuggest-accept

# Ctrl-g f  -> file picker (inserts path)
fzf-g-file-widget() {
  local out
  out="$(gcof)" || { zle redisplay; return; }
  LBUFFER+="$out"
  zle redisplay
}
zle -N fzf-g-file-widget
bindkey '^gf' fzf-g-file-widget

# Ctrl-g b -> branch switch
fzf-g-branch-widget() {
  gcob
  zle reset-prompt
}
zle -N fzf-g-branch-widget
bindkey '^gb' fzf-g-branch-widget

# Ctrl-g l -> commit picker (inserts hash)
fzf-g-commit-widget() {
  local h
  h="$(glog)" || { zle redisplay; return; }
  LBUFFER+="$h"
  zle redisplay
}
zle -N fzf-g-commit-widget
bindkey '^gl' fzf-g-commit-widget

# atuin owns Ctrl-R in every keymap (fzf --zsh binds it too)
if (( $+widgets[atuin-search] )); then
  bindkey -M emacs '^R' atuin-search
  bindkey -M viins '^R' atuin-search
fi
