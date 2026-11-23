# ==============================================================================
# 50-aliases.bash — aliases
#   shared with zsh:      ~/.config/shell/aliases.sh
#   oh-my-zsh plugin aliases for bash (git, helm, helmfile, terraform, ansible):
#                         ~/.config/shell/omz-compat.sh
# ==============================================================================
[[ -r ~/.config/shell/aliases.sh ]] && . ~/.config/shell/aliases.sh
[[ -r ~/.config/shell/omz-compat.sh ]] && . ~/.config/shell/omz-compat.sh

alias edit-bash='nvim ~/.bashrc ~/.bashrc.d/'
alias reload-bash='exec bash'

# --- tab completion for the git aliases ------------------------------------------
if ! declare -F __git_complete >/dev/null && [[ -r /usr/share/bash-completion/completions/git ]]; then
  . /usr/share/bash-completion/completions/git
fi
if declare -F __git_complete >/dev/null; then
  __git_complete g __git_main
  __git_complete ga _git_add;       __git_complete gaa _git_add;    __git_complete gapa _git_add
  __git_complete gb _git_branch;    __git_complete gba _git_branch; __git_complete gbd _git_branch
  __git_complete gc _git_commit;    __git_complete gca _git_commit
  __git_complete gco _git_checkout; __git_complete gcb _git_checkout
  __git_complete gcp _git_cherry_pick
  __git_complete gd _git_diff;      __git_complete gds _git_diff
  __git_complete gf _git_fetch;     __git_complete gl _git_pull
  __git_complete glo _git_log;      __git_complete glol _git_log
  __git_complete gm _git_merge
  __git_complete gp _git_push;      __git_complete gpf _git_push
  __git_complete grb _git_rebase;   __git_complete grbi _git_rebase
  __git_complete grs _git_restore
  __git_complete gsta _git_stash;   __git_complete gstp _git_stash
  __git_complete gsw _git_switch;   __git_complete gswc _git_switch
fi

# --- tab completion for the helm / helmfile / kubectl / terraform aliases ----------
declare -F __start_helm >/dev/null && complete -o default -F __start_helm h
declare -F __start_helmfile >/dev/null && complete -o default -F __start_helmfile hf
declare -F __start_kubectl >/dev/null && complete -o default -F __start_kubectl k
command -v terraform >/dev/null 2>&1 && complete -C "$(command -v terraform)" tf
