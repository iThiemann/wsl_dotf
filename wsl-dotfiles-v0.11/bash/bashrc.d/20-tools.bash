# ==============================================================================
# 20-tools.bash — tool init (bash counterpart of 30-source.zsh)
#   order matters: starship → fzf → fzf-git → nvm → zoxide → atuin
# ==============================================================================

# --- starship prompt -----------------------------------------------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# --- fzf: Ctrl-T (files), Alt-C (cd), ** <Tab> completion -----------------------
if command -v fzf >/dev/null 2>&1; then
  if [[ ${BLE_VERSION-} ]]; then
    # ble.sh needs its own adapters for fzf (plain 'fzf --bash' fights with it)
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
  else
    eval "$(fzf --bash)"
  fi
fi

# --- fzf-git.sh: Ctrl-G Ctrl-F/B/T/R/H/S/L/E/W ---------------------------------
if [[ -r $HOME/fzf-git.sh/fzf-git.sh ]] && command -v fzf >/dev/null 2>&1; then
  if [[ ${BLE_VERSION-} ]]; then
    ble-import -d integration/fzf-git
  else
    source "$HOME/fzf-git.sh/fzf-git.sh"
  fi
fi

# --- DevOps CLI completions (cached; regenerated when the binary changes) --------
__dot_cached_completion() {  # <tool> <command that prints bash completion…>
  local tool=$1 bin cache
  shift
  bin="$(command -v "$tool" 2>/dev/null)" || return 0
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/bash-completion/$tool.bash"
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    mkdir -p "${cache%/*}"
    "$@" >"$cache" 2>/dev/null || { rm -f "$cache"; return 0; }
  fi
  . "$cache"
}
__dot_cached_completion kubectl  kubectl completion bash
__dot_cached_completion helm     helm completion bash
__dot_cached_completion helmfile helmfile completion bash
__dot_cached_completion rbw      rbw gen-completions bash
unset -f __dot_cached_completion
command -v terraform >/dev/null 2>&1 && complete -C "$(command -v terraform)" terraform
command -v aws_completer >/dev/null 2>&1 && complete -C "$(command -v aws_completer)" aws

# --- nvm (lazy: only if installed) ----------------------------------------------
if [[ -n ${NVM_DIR-} && -s $NVM_DIR/nvm.sh ]]; then
  . "$NVM_DIR/nvm.sh"
  [[ -s $NVM_DIR/bash_completion ]] && . "$NVM_DIR/bash_completion"
fi

# --- zoxide: replaces cd (cd foo → best match, cdi → interactive picker) --------
# This is the proper version of `alias cd="z"`.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash --cmd cd)"

# --- atuin: Ctrl-R history search (Up arrow stays prefix search, like zsh) ---------
if command -v atuin >/dev/null 2>&1; then
  if [[ ${BLE_VERSION-} ]] && command -v fzf >/dev/null 2>&1; then
    # load after fzf's key bindings so atuin owns Ctrl-R
    ble-import -C 'eval "$(atuin init bash --disable-up-arrow)"' integration/fzf-key-bindings
  elif [[ ${BLE_VERSION-} ]]; then
    eval "$(atuin init bash --disable-up-arrow)"
  else
    # without ble.sh atuin needs bash-preexec (sourced last)
    export _ZO_DOCTOR=0
    [[ -r $HOME/.local/share/bash-preexec.sh ]] && source "$HOME/.local/share/bash-preexec.sh"
    eval "$(atuin init bash --disable-up-arrow)"
  fi
fi
