# ==============================================================================
# ~/.config/shell/functions.sh — functions shared by bash AND zsh
#   Written in the common subset of both shells. `function name {` is used so
#   an existing alias (oh-my-zsh defines many) can't break the definition.
# ==============================================================================

unalias ls la ll l lt u glog gfc gup gsmb gcmb gcmbf gcof gcob gstash \
  keep_delete keep_print pathfzf ide_tmux 2>/dev/null

# --- git: quick commit / push ---------------------------------------------------
function gfc {
  git commit -m "$*" && git push
}

function gup {
  local msg="$*"
  if [[ -z $msg ]]; then
    echo 'Usage: gup "commit message"' >&2
    return 1
  fi
  git add -A || return
  git commit -m "$msg" || return
  git push || return
}

# --- keep only one entry in a folder (keep_print first to preview) ----------------
function keep_delete {
  local folder="$1" keepfile="$2"
  # guard: an empty keepfile would make find match (and delete) everything
  if [[ ! -d $folder || -z $keepfile ]]; then
    echo "Usage: keep_delete <folder> <name-to-keep>" >&2
    return 1
  fi
  find "$folder" -mindepth 1 -maxdepth 1 ! -name "$keepfile" -exec rm -rf {} +
}

function keep_print {
  local folder="$1" keepfile="$2"
  if [[ ! -d $folder || -z $keepfile ]]; then
    echo "Usage: keep_print <folder> <name-to-keep>" >&2
    return 1
  fi
  find "$folder" -mindepth 1 -maxdepth 1 ! -name "$keepfile" -print
}

# --- browse $PATH entries with a directory preview -----------------------------------
function pathfzf {
  tr ':' '\n' <<<"$PATH" |
    nl -w2 -s'  ' |
    fzf \
      --prompt='PATH> ' \
      --height=60% \
      --layout=reverse \
      --border \
      --preview='eza -la --icons=always --color=always {2..} 2>/dev/null | head -80' \
      --preview-window=right:60%
}

# --- ls → eza (long, all, human, dirs first; git column inside repos) -------------------
#   -t modified  -S size  -X extension  -r reverse  -l toggles OFF the long view
function ls {
  command -v eza >/dev/null 2>&1 || { command ls --color=auto "$@"; return; }

  local sort="" reverse=false long_format=true
  local -a args
  args=()
  local arg flags i ch

  for arg in "$@"; do
    if [[ $arg == -* && $arg != --* ]]; then
      flags="${arg#-}"
      for ((i = 0; i < ${#flags}; i++)); do
        ch="${flags:$i:1}"
        case "$ch" in
          t) sort="modified" ;;
          S) sort="size" ;;
          X) sort="extension" ;;
          r) reverse=true ;;
          l) long_format=false ;;
          *) args+=("-$ch") ;;
        esac
      done
    else
      args+=("$arg")
    fi
  done

  local -a cmd
  cmd=(eza --icons=always --group-directories-first -a -h)

  if [[ $long_format == true ]]; then
    cmd+=(-l)
    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      cmd+=(--git)
    fi
  fi

  [[ -n $sort ]] && cmd+=(--sort="$sort")
  [[ $reverse == true ]] && cmd+=(--reverse)

  cmd+=("${args[@]}")
  command "${cmd[@]}"
}

# --- tree view: lt [depth 1-5] [path...]   (lt src also works → depth 1) -----------------
function lt {
  local level=1
  if [[ ${1-} =~ ^[0-9]+$ ]]; then
    level=$1
    shift
  fi

  if ((level > 5)); then
    echo "Maximum tree depth is 5" >&2
    return 1
  fi

  eza \
    --icons=always \
    --group-directories-first \
    -a -h -l \
    --tree \
    --level="$level" \
    "$@"
}

# --- fzf hooks (** completion; same names in bash and zsh) --------------------------------
function _fzf_compgen_path {
  fd --type f --hidden --follow --exclude .git --strip-cwd-prefix . "${1:-.}"
}

function _fzf_compgen_dir {
  fd --type d --hidden --follow --exclude .git --strip-cwd-prefix . "${1:-.}"
}

# _fzf_preview_cmd / _fzf_preview are defined in env.sh (FZF_*_OPTS need them early)

function _fzf_comprun {
  local command=$1
  shift

  case "$command" in
    export | unset)
      fzf --preview 'eval "echo \${{}}"' --preview-window=right,60%,border-left "$@"
      ;;
    ssh)
      fzf --preview 'dig {}' --preview-window=right,60%,border-left "$@"
      ;;
    *) # cd, cat, bat, nvim, vim, v, …
      fzf --preview "$(_fzf_preview_cmd)" --preview-window=right,60%,border-left "$@"
      ;;
  esac
}

# --- tmux: ide_tmux <session> [dir] → editor pane + 25% terminal below -----------------
function ide_tmux {
  local session_name="${1-}"
  local project_dir="${2:-$PWD}"
  [[ -n $session_name ]] || { echo "Usage: ide_tmux <session> [dir]" >&2; return 1; }

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$project_dir"
    tmux rename-window -t "$session_name" 'IDE'
    tmux split-window -v -l 25% -t "$session_name" -c "$project_dir"
  fi

  if [[ -n ${TMUX-} ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

# --- u [n] → go up n directories -------------------------------------------------------
function u {
  local n="${1:-1}" p="" i
  [[ $n =~ ^[0-9]+$ ]] || { echo "Usage: u [levels]" >&2; return 1; }
  for ((i = 0; i < n; i++)); do p+="../"; done
  cd "${p:-.}" || return
}

# --- git helpers ---------------------------------------------------------------------
function __dot_in_git_repo {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "not in a git repo" >&2
    return 2
  }
}

# local branches whose upstream was deleted
function __dot_git_gone {
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads |
    awk '$2 == "[gone]" { print $1 }'
}

function gsmb { __dot_git_gone; }                                               # show
function gcmb { git fetch --prune && __dot_git_gone | xargs -r git branch -d; }  # clean
function gcmbf { git fetch --prune && __dot_git_gone | xargs -r git branch -D; } # force

# oh-my-zsh already defines these in zsh; bash gets them here
if ! type git_current_branch >/dev/null 2>&1; then
  function git_current_branch { git branch --show-current 2>/dev/null; }
fi
if ! type git_main_branch >/dev/null 2>&1; then
  function git_main_branch {
    local b
    for b in main master trunk develop; do
      git show-ref -q --verify "refs/heads/$b" && { echo "$b"; return; }
    done
    echo main
  }
fi

# --- gcof: pick a tracked file, print its path ------------------------------------------
function gcof {
  __dot_in_git_repo || return
  local f
  f="$(git ls-files | fzf --preview "$(_fzf_preview)" --prompt='files> ')" || return
  printf '%s\n' "$f"
}

# --- gcob: pick a local/remote branch and switch to it ----------------------------------
function gcob {
  __dot_in_git_repo || return
  local b
  b="$(
    {
      git for-each-ref --format='%(refname:short)' refs/heads
      git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin
    } | grep -vx 'HEAD' | awk 'NF' | sort -u |
      fzf --prompt='branches> ' \
        --preview 'git log --oneline --decorate --graph --color=always -n 40 {} -- 2>/dev/null ||
                   git log --oneline --decorate --graph --color=always -n 40 origin/{} --'
  )" || return

  if git show-ref --verify --quiet "refs/heads/$b"; then
    git switch "$b"
  else
    git switch -c "$b" --track "origin/$b"
  fi
}

# --- glog: browse commits, print the selected hash --------------------------------------
function glog {
  __dot_in_git_repo || return
  local c
  c="$(
    git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr%Creset %an' |
      fzf --ansi --no-sort --reverse --prompt='commits> ' \
        --preview 'echo {} | grep -oE "[0-9a-f]{7,40}" | head -n1 | xargs -r git show --color=always --stat'
  )" || return

  # strip colours + graph characters, keep the first hash
  c="$(sed 's/\x1b\[[0-9;]*m//g' <<<"$c" | grep -oE '[0-9a-f]{7,40}' | head -n1)"
  [[ -n $c ]] && printf '%s\n' "$c"
}

# --- gstash: pick a stash, then apply / pop / show / drop -------------------------------
function gstash {
  __dot_in_git_repo || return
  local s ref action

  s="$(
    git stash list | fzf \
      --prompt='stash> ' \
      --delimiter=':' \
      --preview 'git stash show -p --color=always {1}' \
      --preview-window=right:70%
  )" || return

  ref="${s%%:*}"
  echo "selected: $ref"
  printf '%s' "Apply (a) / Pop (p) / Show (s) / Drop (d) / Cancel (c): "
  read -r action

  case "$action" in
    a) git stash apply "$ref" ;;
    p) git stash pop "$ref" ;;
    s) git stash show -p "$ref" ;;
    d) git stash drop "$ref" ;;
    *) echo "cancelled" ;;
  esac
}

# --- AWS profile helpers (oh-my-zsh's aws plugin provides these in zsh) -------------
if ! type asp >/dev/null 2>&1; then
  # asp [profile]  → set (or with no argument: clear) the active AWS profile
  function asp {
    if [[ -z ${1-} ]]; then
      unset AWS_PROFILE AWS_DEFAULT_PROFILE
      echo "AWS profile cleared"
      return
    fi
    export AWS_PROFILE="$1" AWS_DEFAULT_PROFILE="$1"
    echo "AWS_PROFILE=$1"
  }
  function agp { echo "${AWS_PROFILE:-<none>}"; }
  function aws_profiles { aws configure list-profiles 2>/dev/null; }
fi

# aspf → pick an AWS profile with fzf (works in both shells)
function aspf {
  local p
  p="$(aws configure list-profiles 2>/dev/null | fzf --prompt='aws profile> ' --height=40%)" || return
  asp "$p"
}
