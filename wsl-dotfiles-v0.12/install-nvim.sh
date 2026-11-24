#!/usr/bin/env bash
# ==============================================================================
# install-nvim.sh — replace ONLY the Neovim config with the one from this bundle
#
#   Touches:   ~/.config/nvim  (or ~/.config/$NVIM_APPNAME with --appname)
#              and, with --fresh, nvim's own data/state/cache folders
#   Leaves:    shells, tmux, git, Windows Terminal, AutoHotkey, apt packages, PATH …
#
#   ./install-nvim.sh                 back up ~/.config/nvim, link the bundle's nvim/ there,
#                                     install plugins/parsers/Mason tools headless, run tests
#   ./install-nvim.sh --copy          copy instead of symlink (bundle folder can be deleted after)
#   ./install-nvim.sh --fresh         also back up plugins/state/cache → clean reinstall
#   ./install-nvim.sh --appname nvim-devops
#                                     install side by side; start it with
#                                     NVIM_APPNAME=nvim-devops nvim  (your current config stays)
#   ./install-nvim.sh --no-bootstrap  only put the config in place (plugins install on next start)
#   ./install-nvim.sh --no-test       skip nvim/tests/run.sh
#   ./install-nvim.sh --dry-run       print what would happen, change nothing
#
#   Backups: <path>.bak.<timestamp> — restore with:  mv ~/.config/nvim.bak.2026… ~/.config/nvim
#   Safe to run again: an existing link to this bundle is kept, nothing is backed up twice.
# ==============================================================================
set -Eeuo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/nvim"
mode=link fresh=0 bootstrap=1 test=1 dry=0 appname="${NVIM_APPNAME:-nvim}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --copy) mode=copy ;;
    --fresh) fresh=1 ;;
    --appname) appname="${2:?--appname needs a name}"; shift ;;
    --appname=*) appname="${1#*=}" ;;
    --no-bootstrap) bootstrap=0 test=0 ;;
    --no-test) test=0 ;;
    --dry-run) dry=1 ;;
    -h | --help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '\033[34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m ✗\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [[ $dry == 1 ]]; then echo "   [dry-run] $*"; else "$@"; fi; }

[[ -f $src/init.lua ]] || die "no nvim/init.lua next to this script ($src)"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$appname"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/$appname"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/$appname"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/$appname"
stamp="$(date +%Y%m%d-%H%M%S)"
export NVIM_APPNAME="$appname"

# --- 1. checks (report only — this script installs no system packages) -------------
log "checks"
command -v nvim >/dev/null || die "nvim not found — install it first (./install.sh does, or the release tarball)"
ver="$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
IFS=. read -r major minor patch <<<"$ver"
if (( major == 0 && (minor < 11 || (minor == 11 && ${patch:-0} < 2)) )); then
  die "nvim $ver is too old — LazyVim needs 0.11.2+"
fi
ok "nvim $ver"
missing=()
for tool in git rg gcc make curl unzip node npm tree-sitter java go; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
command -v fd >/dev/null || command -v fdfind >/dev/null || missing+=(fd)
if ((${#missing[@]})); then
  warn "not found: ${missing[*]} — the config still loads; the matching LSPs/tools stay unavailable"
  warn "(./install.sh --no-zsh --no-devops installs them without touching the rest)"
else
  ok "git, rg, fd, gcc, node, tree-sitter, java, go"
fi

# --- 2. back up what is there ---------------------------------------------------------
backups=()
backup() {
  local path=$1
  [[ -e $path || -L $path ]] || return 0
  run mv "$path" "$path.bak.$stamp"
  backups+=("$path")
  ok "backed up $path → $path.bak.$stamp"
}

log "config → $config_dir ($mode)"
if [[ $mode == link && -L $config_dir && "$(readlink -f "$config_dir")" == "$(readlink -f "$src")" ]]; then
  ok "already linked to this bundle"
else
  backup "$config_dir"
  run mkdir -p "$(dirname "$config_dir")"
  if [[ $mode == link ]]; then
    run ln -s "$src" "$config_dir"
    ok "linked $config_dir → $src  (keep this folder; use --copy if you want to delete it)"
  else
    run cp -a "$src" "$config_dir"
    ok "copied to $config_dir"
  fi
fi

if [[ $fresh == 1 ]]; then
  log "fresh start: plugins, Mason tools, parsers, sessions and caches are reinstalled"
  for d in "$data_dir" "$state_dir" "$cache_dir"; do backup "$d"; done
fi

# --- 3. plugins, parsers, Mason tools + tests --------------------------------------------
if [[ $bootstrap == 1 ]]; then
  log "plugins + Tree-sitter parsers + Mason tools (first run: 5–15 min)"
  run nvim --headless -c "lua require('devops.install').run()" || warn "some tools failed to install — see above"
fi
if [[ $test == 1 ]]; then
  log "tests (filetypes, LSPs, formatters, linters, completion)"
  run "$config_dir/tests/run.sh" || warn "tests reported failures — fix, then rerun $config_dir/tests/run.sh"
fi

echo
ok "done — start with: $([[ $appname != nvim ]] && echo "NVIM_APPNAME=$appname ")nvim"
echo "   docs: $config_dir/README.md"
for b in "${backups[@]}"; do echo "   undo: rm -rf $b && mv $b.bak.$stamp $b"; done
