# ==============================================================================
# 30-source.zsh — oh-my-zsh, plugins, tool init
#   order: oh-my-zsh (incl. starship plugin) → fzf → fzf-git → nvm → zoxide → atuin
#   zsh-syntax-highlighting is sourced at the very end of ~/.zshrc
# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

ZSH_THEME=""                      # starship draws the prompt
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 14
HIST_STAMPS="yyyy-mm-dd"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"   # faster git status in big repos

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'

plugins=(
  # Version Control
  git

  # Cloud & Infrastructure
  docker
  docker-compose
  kubectl
  oc                # OpenShift CLI: completion + aliases
  helm
  zsh-helmfile      # community: helmfile completion + aliases
  terraform
  aws
  gcloud
  azure
  ansible
  jfrog             # JFrog CLI (jf) completion

  # Programming Languages & Tools
  python
  pip
  node
  npm
  yarn
  golang
  rust
  drush             # Drupal shell

  # Productivity Boosters
  sudo              # Esc Esc → prefix previous/current command with sudo
  extract           # x <archive> — universal extractor (.tar, .zip, .gz, .7z, …)
  z                 # jump to frecent dirs (zoxide already powers cd/cdi — z is the classic variant)
  history           # h / hs / hsi history helpers (note: overrides helm's `h`, use `helm` or hin/hup/…)
  command-not-found # suggests the apt package for unknown commands
  vscode            # vsc / vsca / vscd … (uses `code` from Windows)
  ssh               # host completion from ~/.ssh/config + ssh helpers
  starship          # prompt (replaces a manual `starship init zsh`)
  tldr              # Esc-tldr: show tldr page for the command being typed
  web-search        # google / ddg / github … from the shell

  # Community Plugins (must be last)
  fzf-tab           # fzf as the Tab menu — after compinit, before autosuggestions
  zsh-autosuggestions
  # zsh-syntax-highlighting → sourced at the very end of ~/.zshrc (must load after
  #                           every widget, incl. atuin/fzf, which come after oh-my-zsh)
)
  zsh-autosuggestions
  # colorize
  # extract
  # encode64
  # mise
  # uv
  # vscode
  # docker
  # docker-compose
  # tmux
  # kind
  # kubectl
  # kubectx
  # argocd
)

# only load plugins that are actually installed (no errors on a half-done setup)
() {
  local p keep=()
  for p in $plugins; do
    [[ -d $ZSH/plugins/$p || -d $ZSH_CUSTOM/plugins/$p ]] && keep+=($p)
  done
  plugins=($keep)
}

[[ -r $ZSH/oh-my-zsh.sh ]] && source "$ZSH/oh-my-zsh.sh"

# --- fzf: Ctrl-T (files), Alt-C (cd), ** <Tab> -------------------------------------
command -v fzf >/dev/null && source <(fzf --zsh)

# --- fzf-git.sh: Ctrl-G Ctrl-F/B/T/R/H/S/L/E/W ---------------------------------------
[[ -r $HOME/fzf-git.sh/fzf-git.sh ]] && source "$HOME/fzf-git.sh/fzf-git.sh"

# --- nvm ------------------------------------------------------------------------------
if [[ -n ${NVM_DIR-} && -s $NVM_DIR/nvm.sh ]]; then
  source "$NVM_DIR/nvm.sh"
  [[ -s $NVM_DIR/bash_completion ]] && source "$NVM_DIR/bash_completion"
fi

# --- zoxide: replaces cd (cd foo → best match, cdi → picker) ---------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# --- starship (fallback if the oh-my-zsh starship plugin isn't loaded) ---------------
if (( ! ${plugins[(Ie)starship]} )) && command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# --- atuin: Ctrl-R (Up arrow stays prefix search, see 60-bindkeys.zsh) ------------------
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# --- completion look & fzf-tab ----------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
if (( $+functions[enable-fzf-tab] )); then
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:complete:(cd|__zoxide_z|__zoxide_zi):*' fzf-preview \
    'eza -1 --color=always --icons=always $realpath'
  zstyle ':fzf-tab:complete:(nvim|vim|v|bat|cat|less):*' fzf-preview \
    '[[ -d $realpath ]] && eza -1 --color=always --icons=always $realpath || bat -n --color=always --line-range :200 $realpath'
  zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
fi
