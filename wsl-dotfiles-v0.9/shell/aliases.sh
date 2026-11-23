# ==============================================================================
# ~/.config/shell/aliases.sh — aliases shared by bash AND zsh
#   (git/helm/terraform/ansible aliases come from oh-my-zsh in zsh and from
#    omz-compat.sh in bash)
# ==============================================================================

# --- navigation (cd itself is zoxide: cd foo → best match, cdi → picker) --------
alias -- -='cd -'
alias cd..='cd ..'
alias ..='cd ..'
alias .1='cd ..'
alias ...='cd ../..'
alias .2='cd ../..'
alias ....='cd ../../..'
alias .3='cd ../../..'
alias .....='cd ../../../..'
alias .4='cd ../../../..'
alias ......='cd ../../../../..'
alias .5='cd ../../../../..'

# --- listing (ls / lt are functions in functions.sh) ------------------------------
alias l='ls'
alias ll='ls'
alias la='ls'
alias lt1='lt 1'
alias lt2='lt 2'
alias lt3='lt 3'
alias lt4='lt 4'
alias lt5='lt 5'

_eza_up='eza -al --color-scale=all --color-scale-mode=gradient --icons=always --group-directories-first'
alias l.="$_eza_up ../"
alias l..="$_eza_up ../../"
alias l.1="$_eza_up ../../"
alias l...="$_eza_up ../../../"
alias l.2="$_eza_up ../../../"
alias l....="$_eza_up ../../../../"
alias l.3="$_eza_up ../../../../"
alias l.....="$_eza_up ../../../../../"
alias l.4="$_eza_up ../../../../../"
alias l......="$_eza_up ../../../../../../"
alias l.5="$_eza_up ../../../../../../"
unset _eza_up

# --- general -------------------------------------------------------------------------
alias c='clear'
alias q='exit'
alias r='reset'
alias df='df -h'
alias dux='sudo du -x -d 1 -h | sort -h'
alias dusage='du -sh * 2>/dev/null | sort -h'
alias genv='printenv | grep -i'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias path='tr ":" "\n" <<<"$PATH" | less'
alias pathls='pathfzf'
alias v='NVIM_APPNAME=nvim nvim'
alias lg='lazygit'
command -v kubectl >/dev/null 2>&1 && alias k='kubectl'
alias IDE='tmux split-window -v -l 30% && tmux split-window -h -l 66% && tmux split-window -h -l 50%'
alias rg='rg --colors=match:fg:ff757f --colors=path:fg:7aa2f7 --colors=line:fg:e0af68 --colors=column:fg:bb9af7'

[[ -r ~/.config/tlrc/config.toml ]] && alias tldr='tldr --config ~/.config/tlrc/config.toml'
command -v speedtest-cli >/dev/null 2>&1 && alias speedtest='speedtest-cli --secure'

# --- apt (instead of brew) -------------------------------------------------------------
alias apti='apt show'
alias apts='apt search'
alias aptu='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'

# --- switching shells (see also: shell-switch) -------------------------------------------
alias tozsh='exec zsh -l'
alias tobash='exec bash -l'
alias edit-shell='nvim ~/.config/shell/'

# --- WSL ↔ Windows (open / pbcopy / pbpaste are scripts in ~/.local/bin) -----------------
if [[ $IS_WSL == 1 ]]; then
  alias explorer='open .'
  alias wslrestart='/mnt/c/Windows/System32/wsl.exe --shutdown'
fi
