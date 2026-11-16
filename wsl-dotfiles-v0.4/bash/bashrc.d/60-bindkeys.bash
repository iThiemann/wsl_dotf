# ==============================================================================
# 60-bindkeys.bash — key bindings (port of 60-bindkeys.zsh)
#
#   Up / Down    prefix history search (type "git", press Up)
#   Ctrl-R       atuin
#   Ctrl-T       fzf: insert file      Alt-C   fzf: cd into dir
#   Ctrl-G f     pick tracked file → insert path      (gcof)
#   Ctrl-G b     pick branch → switch                 (gcob)
#   Ctrl-G l     pick commit → insert hash            (glog)
#   Ctrl-G Ctrl-F/B/T/R/H/S/L   fzf-git.sh widgets
#   → / End      accept autosuggestion (ble.sh),  Alt-F accept one word
#
#   With ble.sh the bindings themselves live in ~/.blerc; below is the
#   plain-readline fallback (NO_BLE=1 bash).
# ==============================================================================

# insert text at the cursor (works for both `bind -x` and `ble-bind -x`)
__rl_insert() {
  READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$1${READLINE_LINE:READLINE_POINT}"
  READLINE_POINT=$((READLINE_POINT + ${#1}))
}

_w_git_file() {
  local out
  out="$(gcof)" || return
  __rl_insert "$out"
}

_w_git_branch() {
  gcob
}

_w_git_commit() {
  local h
  h="$(glog)" || return
  __rl_insert "$h"
}

if [[ -z ${BLE_VERSION-} ]]; then
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
  bind -x '"\C-gf": _w_git_file'
  bind -x '"\C-gb": _w_git_branch'
  bind -x '"\C-gl": _w_git_commit'
fi
