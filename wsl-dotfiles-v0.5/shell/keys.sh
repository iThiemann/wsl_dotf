# ==============================================================================
# ~/.config/shell/keys.sh — `keys`: which-key style overview (bash AND zsh)
#
#   keys              menu of programs → their shortcuts / aliases / functions (fzf)
#   keys git          jump straight to everything matching "git"
#   keys -p tmux      print instead of fzf (for grep/less)
#   keys --export     write all sheets for the Windows AutoHotkey viewer (Caps+F2)
#   F1 / Ctrl-g ?     open it from the prompt; Enter on an alias/function inserts it
#
# The live shell state (aliases, functions, key bindings) is dumped here because a
# separate script can't see the interactive shell; bin/keys-ui renders everything.
# ==============================================================================

function __keys_dump {
  local d=$1
  if [[ -n ${ZSH_VERSION-} ]]; then
    echo zsh >"$d/shell"
    alias -L >"$d/aliases" 2>/dev/null
    print -rl -- ${(k)functions} >"$d/functions"
    bindkey >"$d/bindkeys" 2>/dev/null
  else
    echo bash >"$d/shell"
    alias >"$d/aliases" 2>/dev/null
    declare -F | awk '{print $3}' >"$d/functions"
    if [[ -z ${BLE_VERSION-} ]]; then
      bind -p 2>/dev/null | grep -v '^#' | grep -v 'not bound' >"$d/bind"
      bind -X 2>/dev/null >"$d/bindx"
    else
      echo "${BLE_VERSION}" >"$d/ble"
    fi
  fi
}

function keys {
  local d rc
  d="$(mktemp -d)"
  __keys_dump "$d"
  command keys-ui --dump "$d" "$@"
  rc=$?
  rm -rf "$d"
  return $rc
}
