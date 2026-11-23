#!/usr/bin/env bash
# ==============================================================================
# install.sh — bootstrap a modern bash shell on WSL Ubuntu 24.04
#   bash (ble.sh) AND zsh (oh-my-zsh) sharing one set of aliases/functions/env
#   fzf · zoxide · starship · atuin · eza · tmux · bat · fd · ripgrep · lazygit · nvim
#   DevOps: kubectl · helm (+helm-diff) · helmfile · terraform · ansible · aws cli v2
#   git config (+delta) · tmux + TPM plugins (resurrect/continuum/sessionx/which-key)
#
#   ./install.sh                    install missing tools + link dotfiles
#   ./install.sh --update           re-download every tool (latest release)
#   ./install.sh --default-shell=zsh   also make zsh (or bash) the login shell
#   ./install.sh --no-zsh           skip zsh / oh-my-zsh
#   ./install.sh --no-devops        skip kubectl/helm/helmfile/terraform/ansible
#   ./install.sh --no-nvim          skip neovim (and the LazyVim DevOps config)
#   ./install.sh --no-nvim-bootstrap  link the nvim config but don't pre-install plugins/tools
#   ./install.sh --no-wt            don't add Windows Terminal profiles
#   ./install.sh --links-only       only (re)link the dotfiles
#   ./install.sh --wsl-conf         set appendWindowsPath=false in /etc/wsl.conf
#
#   Optional: export GITHUB_TOKEN=... to avoid GitHub API rate limits.
# ==============================================================================
set -Eeuo pipefail

DOTDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
SHARE="$HOME/.local/share"
UPDATE=0 WITH_NVIM=1 WITH_NVIM_DEVOPS=1 NVIM_BOOTSTRAP=1 LINKS_ONLY=0 WSL_CONF=0 WITH_ZSH=1 WITH_DEVOPS=1 WITH_WT=1 DEFAULT_SHELL=""

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    --no-nvim) WITH_NVIM=0 WITH_NVIM_DEVOPS=0 ;;
    --no-nvim-bootstrap) NVIM_BOOTSTRAP=0 ;;
    --links-only) LINKS_ONLY=1 ;;
    --wsl-conf) WSL_CONF=1 ;;
    --no-zsh) WITH_ZSH=0 ;;
    --no-devops) WITH_DEVOPS=0 ;;
    --no-wt) WITH_WT=0 ;;
    --default-shell=zsh | --default-shell=bash) DEFAULT_SHELL="${arg#*=}" ;;
    -h | --help) usage ;;
    *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

c_b=$'\e[1;34m' c_y=$'\e[1;33m' c_g=$'\e[1;32m' c_r=$'\e[1;31m' c_0=$'\e[0m'
log()  { printf '\n%s==>%s %s\n' "$c_b" "$c_0" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%s  !%s %s\n' "$c_y" "$c_0" "$*" >&2; }
die()  { printf '%s  ✗%s %s\n' "$c_r" "$c_0" "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run as your normal user — sudo is used where needed"
[[ -n ${WSL_DISTRO_NAME-} ]] || warn "WSL not detected — continuing anyway"

mkdir -p "$BIN" "$OPT" "$SHARE"
export PATH="$BIN:$HOME/.fzf/bin:$PATH"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

case "$(uname -m)" in
  x86_64)        ARCH=x86_64  LGARCH=x86_64 NVARCH=x86_64 GOARCH=amd64 ;;
  aarch64|arm64) ARCH=aarch64 LGARCH=arm64  NVARCH=arm64  GOARCH=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

# true when $1 should be (re)installed
want() { [[ $UPDATE == 1 ]] || ! command -v "$1" >/dev/null 2>&1; }

# gh_asset_url <owner/repo> <ERE for the asset file name>
gh_asset_url() {
  local auth=()
  [[ -n ${GITHUB_TOKEN-} ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  curl -fsSL "${auth[@]}" "https://api.github.com/repos/$1/releases/latest" |
    jq -r '.assets[].browser_download_url' | grep -Ei -- "$2" | head -n1
}

# install_tarball_bin <owner/repo> <asset-regex> <binary-name>
install_tarball_bin() {
  local repo=$1 re=$2 name=$3 url dir f
  url="$(gh_asset_url "$repo" "$re" || true)"
  [[ -n $url ]] || { warn "$name: no release asset matching /$re/ in $repo"; return 1; }
  dir="$(mktemp -d "$TMP/$name.XXXX")"
  curl -fsSL "$url" | tar -xz -C "$dir"
  f="$(find "$dir" -type f -name "$name" | head -n1)"
  [[ -n $f ]] || { warn "$name: binary not found in $url"; return 1; }
  install -m 0755 "$f" "$BIN/$name"
  ok "$name  $("$BIN/$name" --version 2>/dev/null | head -n1)"
}

# ------------------------------------------------------------------------------
step_apt() {
  log "apt packages"
  local pkgs=(git curl wget ca-certificates gnupg lsb-release unzip tar gzip xz-utils
    gawk jq bash-completion tmux ripgrep fd-find bat tree less file man-db dnsutils
    htop btop command-not-found python3 python3-yaml)
  [[ $WITH_ZSH == 1 ]] && pkgs+=(zsh)
  sudo apt-get update -y -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pkgs[@]}"
  for p in wslu speedtest-cli; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$p" >/dev/null 2>&1 ||
      warn "optional package '$p' not installed"
  done
  # Ubuntu ships these under different names
  ln -sf /usr/bin/batcat "$BIN/bat"
  ln -sf /usr/bin/fdfind "$BIN/fd"
  ok "apt done (tmux $(tmux -V | cut -d' ' -f2), bat→batcat, fd→fdfind)"
}

step_fzf() {
  log "fzf (git checkout in ~/.fzf — apt's 0.44 is too old for 'fzf --bash')"
  if [[ -d $HOME/.fzf/.git ]]; then
    [[ $UPDATE == 1 ]] && git -C "$HOME/.fzf" pull -q --ff-only
  else
    git clone -q --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  if [[ $UPDATE == 1 || ! -x $HOME/.fzf/bin/fzf ]]; then
    "$HOME/.fzf/install" --bin >/dev/null
  fi
  ln -sf "$HOME/.fzf/bin/fzf" "$BIN/fzf"
  ln -sf "$HOME/.fzf/bin/fzf-tmux" "$BIN/fzf-tmux"   # used by tmux-sessionx
  ok "fzf $("$BIN/fzf" --version)"
}

step_eza() {
  log "eza"
  want eza || { ok "eza already installed"; return 0; }
  install_tarball_bin eza-community/eza "eza_${ARCH}-unknown-linux-gnu\.tar\.gz$" eza
}

step_zoxide() {
  log "zoxide"
  want zoxide || { ok "zoxide already installed"; return 0; }
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
    sh -s -- --bin-dir "$BIN" >/dev/null
  ok "$(zoxide --version)"
}

step_starship() {
  log "starship"
  want starship || { ok "starship already installed"; return 0; }
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$BIN" >/dev/null
  ok "$(starship --version | head -n1)"
}

step_atuin() {
  log "atuin"
  if want atuin; then
    install_tarball_bin atuinsh/atuin "atuin-${ARCH}-unknown-linux-gnu\.tar\.gz$" atuin
  else
    ok "atuin already installed"
  fi
  # bash-preexec: only used when ble.sh is not available
  curl -fsSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh \
    -o "$SHARE/bash-preexec.sh" --create-dirs || warn "bash-preexec download failed"
  # first run: import the existing bash history
  if [[ ! -f $SHARE/atuin/history.db && -s $HOME/.bash_history ]]; then
    atuin import bash >/dev/null 2>&1 && ok "imported ~/.bash_history into atuin" || true
  fi
}

step_blesh() {
  log "ble.sh (syntax highlighting · autosuggestions · menu completion)"
  if [[ $UPDATE == 0 && -f $SHARE/blesh/ble.sh ]]; then ok "ble.sh already installed"; return 0; fi
  curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz |
    tar -xJ -C "$TMP"
  local src
  src="$(find "$TMP" -maxdepth 2 -name ble.sh -path '*ble-nightly*' | head -n1)"
  [[ -n $src ]] || { warn "ble.sh archive layout unexpected"; return 1; }
  bash "$src" --install "$SHARE" >/dev/null
  ok "ble.sh installed to $SHARE/blesh"
}

step_lazygit() {
  log "lazygit"
  want lazygit || { ok "lazygit already installed"; return 0; }
  install_tarball_bin jesseduffield/lazygit "_linux_${LGARCH}\.tar\.gz$" lazygit
}

step_nvim() {
  [[ $WITH_NVIM == 1 ]] || return 0
  log "neovim (release tarball — apt's 0.9 is too old for current LazyVim/LSP setups)"
  if [[ $UPDATE == 0 && -x $OPT/nvim/bin/nvim ]]; then ok "neovim already installed"; return 0; fi
  local url
  url="$(gh_asset_url neovim/neovim "nvim-linux-${NVARCH}\.tar\.gz$" || true)"
  [[ -n $url || $NVARCH != x86_64 ]] || url="$(gh_asset_url neovim/neovim 'nvim-linux64\.tar\.gz$' || true)"
  [[ -n $url ]] || { warn "neovim asset not found"; return 1; }
  rm -rf "$OPT/nvim" && mkdir -p "$OPT/nvim"
  curl -fsSL "$url" | tar -xz -C "$OPT/nvim" --strip-components=1
  ln -sf "$OPT/nvim/bin/nvim" "$BIN/nvim"
  ok "$("$BIN/nvim" --version | head -n1)"
}

step_fzf_git() {
  log "fzf-git.sh"
  if [[ -d $HOME/fzf-git.sh/.git ]]; then
    [[ $UPDATE == 1 ]] && git -C "$HOME/fzf-git.sh" pull -q --ff-only
  else
    git clone -q --depth 1 https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh"
  fi
  ok "fzf-git.sh in ~/fzf-git.sh"
}

# clone_or_pull <url> <dir>
clone_or_pull() {
  if [[ -d $2/.git ]]; then
    [[ $UPDATE == 1 ]] && git -C "$2" pull -q --ff-only
  else
    git clone -q --depth 1 "$1" "$2"
  fi
}

step_ohmyzsh() {
  [[ $WITH_ZSH == 1 ]] || return 0
  log "oh-my-zsh + plugins"
  local omz="$HOME/.oh-my-zsh" custom
  custom="${ZSH_CUSTOM:-$omz/custom}"
  clone_or_pull https://github.com/ohmyzsh/ohmyzsh.git "$omz"
  clone_or_pull https://github.com/zsh-users/zsh-autosuggestions     "$custom/plugins/zsh-autosuggestions"
  clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
  clone_or_pull https://github.com/Downager/zsh-helmfile             "$custom/plugins/zsh-helmfile"
  clone_or_pull https://github.com/Aloxaf/fzf-tab                    "$custom/plugins/fzf-tab"
  ok "oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, zsh-helmfile, fzf-tab"
}

step_devops() {
  [[ $WITH_DEVOPS == 1 ]] || return 0
  local rc=0

  log "kubectl"
  if want kubectl; then
    local kver
    kver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" &&
      curl -fsSL "https://dl.k8s.io/release/$kver/bin/linux/$GOARCH/kubectl" -o "$TMP/kubectl" &&
      install -m 0755 "$TMP/kubectl" "$BIN/kubectl" &&
      ok "kubectl $kver" || { warn "kubectl failed"; rc=1; }
  else ok "kubectl already installed"; fi

  log "helm (+ helm-diff, needed by helmfile diff/apply)"
  if want helm; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 |
      HELM_INSTALL_DIR="$BIN" USE_SUDO=false bash >/dev/null &&
      ok "$(helm version --short)" || { warn "helm failed"; rc=1; }
  else ok "helm already installed"; fi
  if command -v helm >/dev/null && ! helm plugin list 2>/dev/null | grep -q '^diff'; then
    helm plugin install https://github.com/databus23/helm-diff >/dev/null 2>&1 &&
      ok "helm-diff plugin" || warn "helm-diff plugin failed"
  fi

  log "helmfile"
  if want helmfile; then
    install_tarball_bin helmfile/helmfile "helmfile_[0-9.]+_linux_${GOARCH}\.tar\.gz$" helmfile || rc=1
  else ok "helmfile already installed"; fi

  log "terraform (HashiCorp apt repo)"
  if want terraform; then
    local kr=/usr/share/keyrings/hashicorp-archive-keyring.gpg
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o "$kr"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$kr] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
      sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq terraform &&
      ok "$(terraform version | head -n1)" || { warn "terraform failed"; rc=1; }
  else ok "terraform already installed"; fi

  log "AWS CLI v2 (user install, no sudo)"
  if want aws; then
    local awsarch=$ARCH
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${awsarch}.zip" -o "$TMP/awscli.zip" &&
      unzip -q -o "$TMP/awscli.zip" -d "$TMP" &&
      "$TMP/aws/install" -i "$HOME/.local/aws-cli" -b "$BIN" --update >/dev/null &&
      ok "$(aws --version)" || { warn "aws cli failed"; rc=1; }
  else ok "aws already installed"; fi

  log "rbw (Bitwarden CLI) + pinentry for the terminal"
  if want rbw; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq rbw pinentry-curses >/dev/null &&
      ok "$(rbw --version)" || { warn "rbw not available via apt — see https://github.com/doy/rbw"; rc=1; }
  else ok "rbw already installed"; fi
  if command -v rbw >/dev/null; then
    rbw config show 2>/dev/null | grep -q '"pinentry": *"pinentry"' &&
      rbw config set pinentry pinentry-curses >/dev/null 2>&1 && ok "rbw pinentry → pinentry-curses (works in WSL terminals)"
    rbw config show 2>/dev/null | grep -q '"email": *"[^"]' ||
      warn "rbw: set your account →  rbw config set email you@example.com  (EU vault: rbw config set base_url https://vault.bitwarden.eu)"
  fi

  log "ansible (apt)"
  if want ansible; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible &&
      ok "$(ansible --version | head -n1)" || { warn "ansible failed"; rc=1; }
  else ok "ansible already installed"; fi
  return $rc
}

step_wt() {
  [[ $WITH_WT == 1 && -n ${WSL_DISTRO_NAME-} ]] || return 0
  log "Windows Terminal profiles (bash + zsh, Tokyo Night)"
  local lad dir
  lad="$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')"
  [[ -n $lad && $lad != *%* ]] || { warn "could not find %LOCALAPPDATA% — skipped"; return 1; }
  dir="$(wslpath -u "$lad")/Microsoft/Windows Terminal/Fragments/wsl-dotfiles"
  mkdir -p "$dir"
  sed "s/__DISTRO__/$WSL_DISTRO_NAME/g" "$DOTDIR/windows-terminal/wsl-dotfiles.json.template" \
    >"$dir/wsl-dotfiles.json"
  ok "added '$WSL_DISTRO_NAME · bash' / '· zsh' / '· tmux' — restart Windows Terminal"
}

step_default_shell() {
  [[ -n $DEFAULT_SHELL ]] || return 0
  log "default shell → $DEFAULT_SHELL"
  "$DOTDIR/bin/shell-switch" "$DEFAULT_SHELL"
}

step_delta_tldr() {
  log "delta (git pager) + tldr (tlrc)"
  if want delta; then
    install_tarball_bin dandavison/delta "delta-[0-9.]+-${ARCH}-unknown-linux-gnu\.tar\.gz$" delta || true
  else ok "delta already installed"; fi
  if want tldr; then
    install_tarball_bin tldr-pages/tlrc "tlrc-.*-${ARCH}-unknown-linux-musl\.tar\.gz$" tldr &&
      { "$BIN/tldr" --update >/dev/null 2>&1 || true; }
  else ok "tldr already installed"; fi
}

step_themes() {
  log "Tokyo Night themes for bat (→ delta, man) and eza"
  local bt="$HOME/.config/bat/themes" ez="$HOME/.config/eza"
  mkdir -p "$bt" "$ez"
  if [[ $UPDATE == 1 || ! -f $bt/tokyonight_night.tmTheme ]]; then
    curl -fsSL https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme \
      -o "$bt/tokyonight_night.tmTheme" || warn "bat theme download failed"
  fi
  bat cache --build >/dev/null 2>&1 && ok "bat theme tokyonight_night" || warn "bat cache --build failed"
  if [[ ! -e $ez/theme.yml ]]; then
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza-themes/main/themes/tokyonight.yml \
      -o "$ez/theme.yml" && ok "eza theme tokyonight (or copy your Mac's ~/.config/eza/theme.yml)" ||
      warn "eza theme download failed"
  else
    ok "eza theme.yml exists — left unchanged"
  fi
}

# runs after step_links (needs ~/.config/tmux/tmux.conf in place)
step_tmux_plugins() {
  log "tmux plugins (TPM: resurrect, continuum, sessionx, navigator, yank, …)"
  local p="$HOME/.config/tmux/plugins"
  clone_or_pull https://github.com/tmux-plugins/tpm "$p/tpm"
  # TPM reads the @plugin lines from tmux.conf and clones them — no tmux client needed
  if [[ $UPDATE == 1 ]]; then
    "$p/tpm/bin/update_plugins" all >/dev/null 2>&1 || warn "tmux plugin update reported errors"
  fi
  "$p/tpm/bin/install_plugins" >/dev/null 2>&1 || warn "tmux plugin install reported errors (inside tmux: prefix I)"
  mkdir -p "$SHARE/tmux/resurrect"
  ok "$(find "$p" -mindepth 1 -maxdepth 1 -type d | wc -l) tmux plugins in ${p/#$HOME/\~}"
}

# ~/.gitconfig.local: identity + credential helper (kept out of the repo)
step_git_local() {
  local cfg="$HOME/.gitconfig.local" old="$HOME/.gitconfig" name="" email="" gcm
  [[ -e $cfg ]] && { ok "~/.gitconfig.local exists — left unchanged"; return 0; }
  log "git identity → ~/.gitconfig.local"
  # take over the identity from an existing (not yet linked) ~/.gitconfig
  if [[ -f $old && ! -L $old ]]; then
    name="$(git config --file "$old" user.name || true)"
    email="$(git config --file "$old" user.email || true)"
  fi
  if [[ -t 0 ]]; then
    [[ -n $name ]]  || read -r -p "  git user.name  (e.g. Max Mustermann): " name
    [[ -n $email ]] || read -r -p "  git user.email: " email
  fi
  printf '%s\n' '# ~/.gitconfig.local — personal / machine-specific git settings (not in the repo)' >"$cfg"
  [[ -n $name ]]  && git config --file "$cfg" user.name "$name"
  [[ -n $email ]] && git config --file "$cfg" user.email "$email"
  for gcm in "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" \
             "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"; do
    if [[ -x $gcm ]]; then
      git config --file "$cfg" credential.helper "${gcm// /\\ }"
      ok "credential helper: Windows Git Credential Manager"
      break
    fi
  done
  git config --file "$cfg" --get credential.helper >/dev/null ||
    { git config --file "$cfg" credential.helper 'cache --timeout=3600'
      warn "Git for Windows not found → credential cache (1 h). Install it for GCM."; }
  [[ -n $name && -n $email ]] && ok "user $name <$email>" ||
    warn "set your identity: git config --file ~/.gitconfig.local user.name/user.email"
}

# --- prerequisites for the LazyVim DevOps config (nvim/) ------------------------------
step_nvim_prereqs() {
  [[ $WITH_NVIM_DEVOPS == 1 ]] || return 0
  log "nvim DevOps prerequisites (compiler, tree-sitter CLI, Node, Go, JDK, PHP, CLIs)"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential python3-venv python3-pip \
    openjdk-21-jdk-headless php-cli php-xml php-mbstring unzip podman mariadb-client postgresql-client >/dev/null &&
    ok "apt: build-essential, python3-venv, JDK 21, php-cli, podman, mariadb/postgres clients"

  if want tree-sitter; then
    local tsarch=x64; [[ $ARCH == aarch64 ]] && tsarch=arm64
    local url; url="$(gh_asset_url tree-sitter/tree-sitter "tree-sitter-linux-${tsarch}\.gz$" || true)"
    [[ -n $url ]] && curl -fsSL "$url" | gunzip >"$BIN/tree-sitter" && chmod +x "$BIN/tree-sitter" &&
      ok "$(tree-sitter --version)" || warn "tree-sitter CLI failed"
  else ok "tree-sitter CLI already installed"; fi

  if [[ $UPDATE == 1 || ! -x $OPT/node/bin/node ]]; then
    local nver narch=x64; [[ $ARCH == aarch64 ]] && narch=arm64
    nver="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version')"
    rm -rf "$OPT/node" && mkdir -p "$OPT/node"
    curl -fsSL "https://nodejs.org/dist/$nver/node-$nver-linux-$narch.tar.xz" | tar -xJ -C "$OPT/node" --strip-components=1 &&
      ok "node $nver (LTS)" || warn "node failed"
  else ok "node $("$OPT/node/bin/node" --version) already installed"; fi
  for b in node npm npx; do ln -sf "$OPT/node/bin/$b" "$BIN/$b"; done

  if [[ $UPDATE == 1 || ! -x $OPT/go/bin/go ]]; then
    local gver; gver="$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')"
    rm -rf "$OPT/go" && mkdir -p "$OPT/go"
    curl -fsSL "https://go.dev/dl/$gver.linux-$GOARCH.tar.gz" | tar -xz -C "$OPT/go" --strip-components=1 &&
      ok "$gver" || warn "go failed"
  else ok "$("$OPT/go/bin/go" version | awk '{print $3}') already installed"; fi
  for b in go gofmt; do ln -sf "$OPT/go/bin/$b" "$BIN/$b"; done

  log "IaC / k8s CLIs used by the editor (tofu, tofu-ls, terragrunt, oc, kubeconform, k9s)"
  if want tofu; then
    curl -fsSL https://get.opentofu.org/install-opentofu.sh -o "$TMP/install-opentofu.sh" &&
      sh "$TMP/install-opentofu.sh" --install-method deb >/dev/null && ok "$(tofu version | head -n1)" ||
      warn "opentofu failed"
  else ok "tofu already installed"; fi
  if want tofu-ls; then
    GOBIN="$BIN" "$BIN/go" install github.com/opentofu/tofu-ls@latest >/dev/null 2>&1 &&
      ok "tofu-ls" || warn "tofu-ls (go install) failed — *.tofu files fall back to no LSP"
  fi
  if want terragrunt; then
    local url; url="$(gh_asset_url gruntwork-io/terragrunt "terragrunt_linux_${GOARCH}$" || true)"
    [[ -n $url ]] && curl -fsSL "$url" -o "$BIN/terragrunt" && chmod +x "$BIN/terragrunt" &&
      ok "$(terragrunt --version | head -n1)" || warn "terragrunt failed"
  else ok "terragrunt already installed"; fi
  if want oc; then
    local ocf=openshift-client-linux.tar.gz; [[ $ARCH == aarch64 ]] && ocf=openshift-client-linux-arm64.tar.gz
    curl -fsSL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/$ocf" | tar -xz -C "$TMP" oc &&
      install -m 0755 "$TMP/oc" "$BIN/oc" && ok "oc $(oc version --client 2>/dev/null | head -n1)" || warn "oc failed"
  else ok "oc already installed"; fi
  if want kubeconform; then
    install_tarball_bin yannh/kubeconform "kubeconform-linux-${GOARCH}\.tar\.gz$" kubeconform || true
  else ok "kubeconform already installed"; fi
  if want k9s; then
    install_tarball_bin derailed/k9s "k9s_Linux_${GOARCH}\.tar\.gz$" k9s || true
  else ok "k9s already installed"; fi
}

# --- install plugins, parsers and Mason tools headless, then run the tests ----------------
step_nvim_bootstrap() {
  [[ $WITH_NVIM_DEVOPS == 1 && $NVIM_BOOTSTRAP == 1 ]] || return 0
  log "nvim: plugins + Tree-sitter parsers + Mason tools (first run: 5–15 min)"
  nvim --headless -c "lua require('devops.install').run()" || warn "some Mason tools failed — see above"
  log "nvim: language tests"
  "$DOTDIR/nvim/tests/run.sh" || warn "nvim tests reported failures — fix, then rerun nvim/tests/run.sh"
}

STAMP="$(date +%Y%m%d-%H%M%S)"
# link <path inside the repo> <destination>
link() {
  local src="$DOTDIR/$1" dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    ok "${dst/#$HOME/\~} (already linked)"; return 0
  fi
  if [[ -e $dst || -L $dst ]]; then
    mv "$dst" "$dst.bak.$STAMP"
    warn "backed up ${dst/#$HOME/\~} → ${dst/#$HOME/\~}.bak.$STAMP"
  fi
  ln -s "$src" "$dst"
  ok "${dst/#$HOME/\~} → ${src/#$HOME/\~}"
}

step_links() {
  log "dotfiles"
  link bash/bashrc              "$HOME/.bashrc"
  link bash/bashrc.d            "$HOME/.bashrc.d"
  link bash/blerc               "$HOME/.blerc"
  link bash/inputrc             "$HOME/.inputrc"
  link shell                    "$HOME/.config/shell"
  if [[ $WITH_ZSH == 1 ]]; then
    link zsh/zshrc              "$HOME/.zshrc"
    link zsh/zshrc.d            "$HOME/.zshrc.d"
  fi
  link config/starship.toml     "$HOME/.config/starship.toml"
  link config/tmux/tmux.conf    "$HOME/.config/tmux/tmux.conf"
  link config/atuin/config.toml "$HOME/.config/atuin/config.toml"
  step_git_local
  link config/git/gitconfig     "$HOME/.gitconfig"
  link config/git/ignore        "$HOME/.config/git/ignore"
  link config/git/wsl-mnt       "$HOME/.config/git/wsl-mnt"
  link config/yamllint/config   "$HOME/.config/yamllint/config"
  [[ $WITH_NVIM_DEVOPS == 1 ]] && link nvim "$HOME/.config/nvim"
  local f
  for f in "$DOTDIR"/bin/*; do
    chmod +x "$f"
    link "bin/$(basename "$f")" "$BIN/$(basename "$f")"
  done
  if [[ ! -e $HOME/.bashrc.local ]]; then
    printf '%s\n' '# ~/.bashrc.local — machine-specific settings (not in the dotfiles repo)' \
      '# export DISPLAY_ID=...' >"$HOME/.bashrc.local"
    ok "created ~/.bashrc.local"
  fi
  if [[ $WITH_ZSH == 1 && ! -e $HOME/.zshrc.local ]]; then
    echo '# ~/.zshrc.local — machine-specific settings (not in the dotfiles repo)' >"$HOME/.zshrc.local"
    ok "created ~/.zshrc.local"
  fi
}

step_wsl_conf() {
  [[ $WSL_CONF == 1 ]] || return 0
  log "/etc/wsl.conf → appendWindowsPath=false (much faster completion)"
  if grep -qs 'appendWindowsPath' /etc/wsl.conf; then
    ok "appendWindowsPath already set — left unchanged"; return 0
  fi
  if grep -qs '^\[interop\]' /etc/wsl.conf; then
    sudo sed -i '/^\[interop\]/a appendWindowsPath=false' /etc/wsl.conf
  else
    printf '\n[interop]\nappendWindowsPath=false\n' | sudo tee -a /etc/wsl.conf >/dev/null
  fi
  warn "run  wsl.exe --shutdown  from Windows, then reopen the terminal"
}

# ------------------------------------------------------------------------------
main() {
  if [[ $LINKS_ONLY == 1 ]]; then step_links; exit 0; fi
  step_apt
  local s failed=()
  for s in step_fzf step_eza step_zoxide step_starship step_atuin step_blesh \
           step_lazygit step_nvim step_fzf_git step_ohmyzsh step_devops step_delta_tldr step_themes step_nvim_prereqs; do
    "$s" || failed+=("${s#step_}")
  done
  step_links
  step_tmux_plugins || failed+=(tmux_plugins)
  step_nvim_bootstrap || failed+=(nvim_bootstrap)
  step_wt || true
  step_wsl_conf
  step_default_shell

  log "done"
  ((${#failed[@]} == 0)) || warn "failed: ${failed[*]} — rerun ./install.sh to retry"
  cat <<EOF

  Next:
    1. exec bash   or   exec zsh -l       # start a new shell (tozsh / tobash later)
    2. Nerd Font on Windows:  winget install DEVCOM.JetBrainsMonoNerdFont
       then use the new "… · bash" / "… · zsh" Windows Terminal profiles
    3. default shell:  shell-switch zsh   (or bash) — shell-switch shows the current one
    4. optional: atuin login / atuin sync  # share history with your Mac
EOF
}
main
