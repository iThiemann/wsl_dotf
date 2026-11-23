# ==============================================================================
# 10-env.zsh — environment (shared with bash: ~/.config/shell/env.sh) + zsh options
# ==============================================================================

[[ -r ~/.config/shell/env.sh ]] && source ~/.config/shell/env.sh

# --- history (atuin is the main search; zsh keeps its own as a fallback) ----------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt HIST_VERIFY SHARE_HISTORY

# --- behaviour ---------------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
