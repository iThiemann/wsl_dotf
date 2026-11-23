# ==============================================================================
# 50-aliases.zsh — aliases (shared with bash: ~/.config/shell/aliases.sh)
#   git / helm / terraform / ansible / helmfile aliases come from the oh-my-zsh plugins.
# ==============================================================================
[[ -r ~/.config/shell/aliases.sh ]] && source ~/.config/shell/aliases.sh

alias edit-zsh='nvim ~/.zshrc ~/.zshrc.d/'
alias reload-zsh='exec zsh'
