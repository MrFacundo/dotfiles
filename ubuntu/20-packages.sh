#!/usr/bin/env bash
# Phase 4 - everything installable. Lists live in packages-ubuntu.sh.
# Idempotent: re-running skips what is already there.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/packages-ubuntu.sh"

KEYRING_DIR=/usr/share/keyrings
WORK_DIR="$(mktemp -d)"
# apt reads local .deb files as the _apt user, which cannot enter a 700 dir.
chmod 755 "$WORK_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

# Installers drop binaries here (claude, starship); put it on PATH for this
# run too, not just for the shells the stowed .zshrc configures.
export PATH="$HOME/.local/bin:$PATH"

have() { command -v "$1" >/dev/null 2>&1; }

gh_latest() { # repo, asset grep pattern; prints nothing when no asset matches
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -oE '"browser_download_url": *"[^"]+"' |
    cut -d'"' -f4 | grep -E "$2" | head -n1 || true
}

# Refresh only the given sources (file names or globs under
# /etc/apt/sources.list.d), leaving every other repo's lists in place.
apt_update_only() {
  local parts f
  parts="$(mktemp -d)"
  chmod 755 "$parts"
  for f in "$@"; do
    # shellcheck disable=SC2086
    cp /etc/apt/sources.list.d/$f "$parts/"
  done
  sudo apt-get update \
    -o Dir::Etc::sourcelist=/dev/null \
    -o Dir::Etc::sourceparts="$parts" \
    -o APT::Get::List-Cleanup=0
  rm -rf "$parts"
}

install_deb_from_url() { # name, url
  if [ -z "$2" ]; then
    echo "    $1: no matching release asset found; install by hand"
    return 0
  fi
  local dir="$WORK_DIR/$1"
  mkdir -p "$dir"
  curl -fsSL "$2" -o "$dir/pkg.deb"
  sudo apt-get install -y "$dir/pkg.deb"
}

# ------------------------------------------------------------------- apt base
install_apt() {
  echo "==> apt packages"
  # Lists were refreshed in 00-bootstrap.sh; a full update here would hit the
  # Neon CDN again.
  local p
  local -a ok=() missing=()
  for p in "${apt_pkgs[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      ok+=("$p")
    else
      missing+=("$p")
    fi
  done
  sudo apt-get install -y "${ok[@]}"
  [ ${#missing[@]} -eq 0 ] ||
    echo "    not in any configured repo, skipped: ${missing[*]}"
}

# --------------------------------------------------------- third-party repos
install_apt_repos() {
  echo "==> Third-party apt repositories"
  local entry name key_url repo_line pkg keyring
  local -a pkgs=() sources=()

  for entry in "${apt_repos[@]}"; do
    IFS='|' read -r name key_url repo_line pkg <<<"$entry"
    keyring="$KEYRING_DIR/$name.gpg"

    if [ ! -f "$keyring" ]; then
      echo "    key: $name"
      curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
      sudo chmod 644 "$keyring"
    fi

    echo "${repo_line//%KEY%/$keyring}" |
      sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
    pkgs+=("$pkg")
    sources+=("$name.list")
  done

  local ppa ppa_pkg owner ppa_name
  for entry in "${apt_ppas[@]}"; do
    IFS='|' read -r ppa ppa_pkg <<<"$entry"
    echo "    ppa: $ppa"
    # -n: no automatic full update; apt_update_only below refreshes it.
    sudo add-apt-repository -y -n "$ppa"
    pkgs+=("$ppa_pkg")
    owner="${ppa#ppa:}"
    owner="${owner%%/*}"
    ppa_name="${ppa##*/}"
    sources+=("$owner-ubuntu-$ppa_name-*")
  done

  # Prefer the PPA Firefox deb over the Ubuntu snap transitional package.
  printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' |
    sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null

  apt_update_only "${sources[@]}"
  sudo apt-get install -y "${pkgs[@]}"

  # The mozillateam PPA ships an enforcing AppArmor profile named "firefox"
  # that replaces Ubuntu's unconfined one and blocks the XDG profile path.
  if [ -f /etc/apparmor.d/usr.bin.firefox ]; then
    echo "    disabling the PPA's Firefox AppArmor profile"
    sudo ln -sf /etc/apparmor.d/usr.bin.firefox /etc/apparmor.d/disable/
    sudo apparmor_parser -R /etc/apparmor.d/usr.bin.firefox 2>/dev/null || true
    sudo apparmor_parser -r /etc/apparmor.d/firefox
  fi
}

# ----------------------------------------------------------------- flatpak
install_flatpak() {
  echo "==> flatpak"
  sudo apt-get install -y flatpak plasma-discover-backend-flatpak
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub "${flatpak_pkgs[@]}"
}

# -------------------------------------------------------------------- rust
install_cargo() {
  echo "==> rust toolchain and cargo packages"
  if ! have rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$WORK_DIR/rustup.sh"
    sh "$WORK_DIR/rustup.sh" -y --no-modify-path
  fi
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"

  local crate
  local -a failed=()
  for crate in "${cargo_pkgs[@]}"; do
    cargo install "$crate" || failed+=("$crate")
  done
  [ ${#failed[@]} -eq 0 ] ||
    echo "    cargo failed for: ${failed[*]} - check the build errors above"
}

# -------------------------------------------------------------------- node
install_node() {
  echo "==> nvm, node and global npm packages"
  if [ ! -d "$HOME/.nvm" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh |
      PROFILE=/dev/null bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  local v
  for v in "${node_versions[@]}"; do
    nvm install "$v"
  done
  nvm alias default "${node_versions[0]}"
  nvm use default

  npm install -g "${npm_global_pkgs[@]}"
}

# ------------------------------------------------------------------ python
install_python_tools() {
  echo "==> uv"
  have uv || curl -fsSL https://astral.sh/uv/install.sh | sh
}

# ------------------------------------------------- manual binaries/tarballs
install_manual() {
  echo "==> Manually installed tools"

  if ! have starship; then
    echo "    starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi

  if ! have claude; then
    echo "    claude"
    curl -fsSL https://claude.ai/install.sh | bash
    hash -r
    have claude || echo "    claude not on PATH after install; check ~/.local/bin"
  fi

  if ! have aichat; then
    echo "    aichat"
    local aichat_url
    aichat_url="$(gh_latest sigoden/aichat 'x86_64-unknown-linux-musl\.tar\.gz$')"
    if [ -n "$aichat_url" ]; then
      local dir="$WORK_DIR/aichat"
      mkdir -p "$dir"
      curl -fsSL "$aichat_url" -o "$dir/aichat.tar.gz"
      tar -C "$dir" -xzf "$dir/aichat.tar.gz"
      sudo install -m 755 "$dir/aichat" /usr/local/bin/aichat
    else
      echo "    aichat: no matching release asset found; install by hand"
    fi
  fi

  if ! have lazygit; then
    echo "    lazygit"
    local lazygit_url
    lazygit_url="$(gh_latest jesseduffield/lazygit 'Linux_x86_64\.tar\.gz$')"
    if [ -n "$lazygit_url" ]; then
      local dir="$WORK_DIR/lazygit"
      mkdir -p "$dir"
      curl -fsSL "$lazygit_url" -o "$dir/lazygit.tar.gz"
      tar -C "$dir" -xzf "$dir/lazygit.tar.gz" lazygit
      sudo install -m 755 "$dir/lazygit" /usr/local/bin/lazygit
    else
      echo "    lazygit: no matching release asset found; install by hand"
    fi
  fi

  if ! have fastfetch; then
    echo "    fastfetch"
    install_deb_from_url fastfetch "$(gh_latest fastfetch-cli/fastfetch 'linux-amd64\.deb$')"
  fi

  if [ ! -x /opt/nvim-linux-x86_64/bin/nvim ]; then
    echo "    neovim"
    local dir="$WORK_DIR/nvim"
    mkdir -p "$dir"
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      -o "$dir/nvim.tar.gz"
    sudo tar -C /opt -xzf "$dir/nvim.tar.gz"
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  fi

  if ! have go; then
    echo "    go"
    sudo apt-get install -y golang-go
  fi

  if ! have cliamp; then
    echo "    cliamp"
    curl -fsSL https://cliamp.stream/install.sh | sh
  fi

  if ! have nchat; then
    echo "    nchat"
    curl -fsSL https://raw.githubusercontent.com/d99kris/nchat/master/utils/install.sh | bash
  fi

  for tool in zen insomnia; do
    have "$tool" || echo "    $tool: install by hand, see ubuntu/README.md"
  done
}

# ------------------------------------------------------------------ docker
setup_containers() {
  echo "==> docker group"
  sudo groupadd -f docker
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "    $USER already in the docker group"
  else
    sudo usermod -aG docker "$USER"
    echo "    log out and back in for the docker group to take effect"
  fi
  sudo systemctl enable --now docker.service || true
}

enable_services() {
  echo "==> Services"
  # Only touch units that exist: a package may have been skipped above.
  has_unit() { systemctl list-unit-files --no-legend "$1" 2>/dev/null | grep -q .; }

  if has_unit bluetooth.service; then
    if systemctl is-enabled --quiet bluetooth.service 2>/dev/null; then
      echo "    bluetooth.service already enabled"
    else
      sudo systemctl enable --now bluetooth.service &&
        echo "    enabled bluetooth.service" ||
        echo "    could not enable bluetooth.service - check: systemctl status bluetooth"
    fi
  else
    echo "    bluez not installed; skipping bluetooth"
  fi

  # Syncthing as a user unit: it starts with the session and everything it
  # writes under $HOME stays owned by you.
  if systemctl --user list-unit-files --no-legend syncthing.service 2>/dev/null | grep -q .; then
    if systemctl --user is-enabled --quiet syncthing.service 2>/dev/null; then
      echo "    syncthing.service (user) already enabled"
    else
      systemctl --user enable --now syncthing.service &&
        echo "    enabled syncthing.service (user)" ||
        echo "    could not enable syncthing - check: systemctl --user status syncthing"
    fi
  else
    echo "    syncthing not installed; skipping"
  fi
}

main() {
  install_apt
  install_apt_repos
  install_flatpak
  install_cargo
  install_node
  install_python_tools
  install_manual
  setup_containers
  enable_services
  echo
  echo "Packages done. Next: 30-configure.sh"
}

main "$@"
